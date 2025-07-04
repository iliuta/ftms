import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/services/ftms_service.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import '../../core/bloc/ftms_bloc.dart';
import '../../core/services/fit/training_data_recorder.dart';
import '../../core/services/ftms_data_processor.dart';
import '../../core/services/strava/strava_service.dart';
import '../../core/services/strava/strava_activity_types.dart';
import '../../core/config/live_data_display_config.dart';
import '../../core/utils/logger.dart';
import 'model/training_session.dart';
import 'model/unit_training_interval.dart';

class TrainingSessionController extends ChangeNotifier {
  final TrainingSessionDefinition session;
  final BluetoothDevice ftmsDevice;
  late final FTMSService _ftmsService;
  late final List<UnitTrainingInterval> _intervals;
  late final List<int> _intervalStartTimes;
  late final int _totalDuration;
  late final Stream<DeviceData?> _ftmsStream;
  late final StreamSubscription<DeviceData?> _ftmsSub;
  Timer? _timer;

  // FIT file recording
  TrainingDataRecorder? _dataRecorder;
  final FtmsDataProcessor _dataProcessor = FtmsDataProcessor();
  bool _isRecordingConfigured = false;
  final bool _enableFitFileGeneration;
  late final StravaService _stravaService;

  bool hasControl = false;
  bool sessionCompleted = false;
  bool sessionPaused = false; // Add pause state
  int elapsed = 0;
  int intervalElapsed = 0;
  int currentInterval = 0;
  bool timerActive = false;
  List<dynamic>? _lastFtmsParams;
  String? lastGeneratedFitFile;
  bool stravaUploadAttempted = false;
  bool stravaUploadSuccessful = false;
  String? stravaActivityId;

  // Allow injection of dependencies for testing
  TrainingSessionController({
    required this.session,
    required this.ftmsDevice,
    FTMSService? ftmsService,
    StravaService? stravaService,
    TrainingDataRecorder? dataRecorder,
    bool enableFitFileGeneration = true, // Allow disabling for tests
  }) : _enableFitFileGeneration = enableFitFileGeneration {
    _ftmsService = ftmsService ?? FTMSService(ftmsDevice);
    _stravaService = stravaService ?? StravaService();
    _dataRecorder = dataRecorder; // Can be null, will be created in _initDataRecording if needed
    _intervals = session.unitIntervals;
    _intervalStartTimes = [];
    int acc = 0;
    for (final interval in _intervals) {
      _intervalStartTimes.add(acc);
      acc += interval.duration;
    }
    _totalDuration = acc;

    // Ensure wakelock stays enabled during training sessions
    WakelockPlus.enable().catchError((e) {
      debugPrint('Failed to enable wakelock during training: $e');
    });

    _ftmsStream = ftmsBloc.ftmsDeviceDataControllerStream;
    _ftmsSub = _ftmsStream.listen(_onFtmsData);
    _initFTMS();
    _initDataRecording();
  }

  int get totalDuration => _totalDuration;
  List<UnitTrainingInterval> get intervals => _intervals;
  List<int> get intervalStartTimes => _intervalStartTimes;

  UnitTrainingInterval get current => _intervals[currentInterval];
  List<UnitTrainingInterval> get remainingIntervals => _intervals.sublist(currentInterval);
  int get mainTimeLeft => _totalDuration - elapsed;
  int get intervalTimeLeft => current.duration - intervalElapsed;

  void _initFTMS() {
    // Request control after a short delay, then start session and set initial resistance if needed
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await _ftmsService.writeCommand(MachineControlPointOpcodeType.requestControl);
        hasControl = true;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 200));
        await _ftmsService.writeCommand(MachineControlPointOpcodeType.startOrResume);
        final firstResistance = _intervals.isNotEmpty ? _intervals[0].resistanceLevel : null;
        if (firstResistance != null) {
          await Future.delayed(const Duration(milliseconds: 200));
          await _ftmsService.writeCommand(MachineControlPointOpcodeType.setTargetResistanceLevel, resistanceLevel: firstResistance);
        }
      } catch (e) {
        debugPrint('Failed to request control/start: $e');
      }
    });
  }

  Future<void> _initDataRecording() async {
    try {
      // Get device type from the machine type string
      final deviceType = session.ftmsMachineType;
      
      // Load config for data processor
      final config = await LiveDataDisplayConfig.loadForFtmsMachineType(deviceType);
      if (config != null) {
        _dataProcessor.configure(config);
        _isRecordingConfigured = true;
      }

      // Initialize data recorder only if not injected for testing
      _dataRecorder ??= TrainingDataRecorder(
          sessionName: session.title,
          deviceType: deviceType,
        );
      _dataRecorder!.startRecording();
    } catch (e) {
      debugPrint('Failed to initialize data recording: $e');
    }
  }


  /* Future<void> setResistanceWithControl(int resistance) async {
    try {
      if (!hasControl) {
        debugPrint('Not in control, skipping resistance set');
        return;
      }
      await _ftmsService.writeCommand(MachineControlPointOpcodeType.setTargetResistanceLevel, resistanceLevel: resistance);
    } catch (e) {
      debugPrint('Failed to set resistance: $e');
    }
  } */

  void _onFtmsData(DeviceData? data) {
    if (data == null) return;
    
    if (timerActive || sessionPaused) {
      // Record training data if recording is active and configured
      if (_dataRecorder != null && _isRecordingConfigured && timerActive) {
        try {
          final paramValueMap = _dataProcessor.processDeviceData(data);
          // Pass FtmsParameter map directly to training data recorder
          _dataRecorder!.recordDataPoint(ftmsParams: paramValueMap);
        } catch (e) {
          debugPrint('Failed to record data point: $e');
        }
      }
      return;
    }
    
    final params = data.getDeviceDataParameterValues();
    // Only start timer if at least one value has changed since last update
    if (_lastFtmsParams != null) {
      bool changed = false;
      for (int i = 0; i < params.length; i++) {
        final prev = _lastFtmsParams![i];
        final curr = params[i].value;
        if (prev != curr) {
          changed = true;
          break;
        }
      }
      if (changed) {
        _startTimer();
        // Record the data point that triggered the timer start
        if (_dataRecorder != null && _isRecordingConfigured && timerActive) {
          try {
            final paramValueMap = _dataProcessor.processDeviceData(data);
            _dataRecorder!.recordDataPoint(ftmsParams: paramValueMap);
          } catch (e) {
            debugPrint('Failed to record data point: $e');
          }
        }
      }
    }
    // Store current values for next comparison
    _lastFtmsParams = params.map((p) => p.value).toList();
  }

  void _startTimer() {
    if (timerActive || sessionPaused) return;
    timerActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (sessionCompleted || sessionPaused) return;
    elapsed++;
    if (elapsed >= _totalDuration) {
      _timer?.cancel();
      timerActive = false;
      sessionCompleted = true;
      _ftmsService.writeCommand(MachineControlPointOpcodeType.stopOrPause);
      
      // Finish recording and generate FIT file (async)
      _finishRecording().then((_) {
        // Only notify listeners after recording is completely finished
        notifyListeners();
      });
    } else {
      // Update current interval
      int previousInterval = currentInterval;
      while (currentInterval < _intervals.length - 1 && elapsed >= _intervalStartTimes[currentInterval + 1]) {
        currentInterval++;
      }
      intervalElapsed = elapsed - _intervalStartTimes[currentInterval];
      // If interval changed and resistanceLevel is set, send command
      if (currentInterval != previousInterval) {
        /* final resistance = _intervals[currentInterval].resistanceLevel;
        if (resistance != null) {
          setResistanceWithControl(resistance);
        }*/
      }
      notifyListeners();
    }
  }

  Future<void> _finishRecording() async {
    if (_dataRecorder != null) {
      try {
        _dataRecorder!.stopRecording();
        
        // Only generate FIT file if enabled (disabled for tests to avoid path_provider dependency)
        if (_enableFitFileGeneration) {
          final fitFilePath = await _dataRecorder!.generateFitFile();
          lastGeneratedFitFile = fitFilePath;
          logger.i('***************** Training session completed successfully. FIT file saved to: $fitFilePath');
          debugPrint('FIT file generated: $fitFilePath');
          
          // Attempt automatic Strava upload if user is authenticated
          if (fitFilePath != null) {
            await _attemptStravaUpload(fitFilePath);
          }
        } else {
          logger.i('***************** Training session completed successfully. FIT file generation disabled.');
        }
      } catch (e) {
        logger.e('**************** Failed to generate FIT file: $e');
        debugPrint('***************** Failed to generate FIT file: $e');
      }
    }
  }

  Future<void> _attemptStravaUpload(String fitFilePath) async {
    stravaUploadAttempted = true;
    
    try {
      // Check if user is authenticated with Strava
      final isAuthenticated = await _stravaService.isAuthenticated();
      if (!isAuthenticated) {
        logger.i('Strava upload skipped: User not authenticated');
        notifyListeners();
        return;
      }

      logger.i('Attempting automatic Strava upload...');
      
      // Create activity name based on session
      final activityName = '${session.title} - FTMS Training';
      
      // Determine the appropriate activity type based on the device type
      final deviceType = session.ftmsMachineType;
      final activityType = StravaActivityTypes.fromFtmsMachineType(deviceType);
      
      // Upload to Strava with the correct activity type
      final uploadResult = await _stravaService.uploadActivity(
        fitFilePath, 
        activityName,
        activityType: activityType,
      );
      
      if (uploadResult != null) {
        stravaUploadSuccessful = true;
        stravaActivityId = uploadResult['id']?.toString();
        logger.i('✅ Successfully uploaded activity to Strava: ${uploadResult['id']}');
        debugPrint('Strava upload successful: ${uploadResult['id']}');
      } else {
        stravaUploadSuccessful = false;
        logger.w('❌ Failed to upload activity to Strava');
        debugPrint('Strava upload failed');
      }
    } catch (e) {
      stravaUploadSuccessful = false;
      logger.e('Error during Strava upload: $e');
      debugPrint('Strava upload error: $e');
    }
    
    notifyListeners();
  }

  /// Pause the current training session
  void pauseSession() {
    if (sessionCompleted || sessionPaused) return;
    
    sessionPaused = true;
    timerActive = false;
    _timer?.cancel();
    
    // Send pause command to FTMS device
    try {
      _ftmsService.writeCommand(MachineControlPointOpcodeType.stopOrPause);
    } catch (e) {
      debugPrint('Failed to send pause command: $e');
    }
    
    notifyListeners();
  }

  /// Resume the paused training session
  void resumeSession() {
    if (sessionCompleted || !sessionPaused) return;
    
    sessionPaused = false;
    
    // Send resume command to FTMS device
    try {
      _ftmsService.writeCommand(MachineControlPointOpcodeType.startOrResume);
    } catch (e) {
      debugPrint('Failed to send resume command: $e');
    }
    
    // Restart timer - it will start automatically when FTMS data changes
    notifyListeners();
  }

  /// Stop the training session completely
  void stopSession() {
    if (sessionCompleted) return;
    
    sessionCompleted = true;
    sessionPaused = false;
    timerActive = false;
    _timer?.cancel();
    
    // Send stop command to FTMS device
    try {
      _ftmsService.writeCommand(MachineControlPointOpcodeType.stopOrPause);
    } catch (e) {
      debugPrint('Failed to send stop command: $e');
    }
    
    // Finish recording and generate FIT file (async)
    _finishRecording().then((_) {
      // Only notify listeners if not disposed
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _ftmsSub.cancel();
    _timer?.cancel();
    
    // Clean up data recorder if session wasn't completed normally
    if (_dataRecorder != null && !sessionCompleted) {
      _finishRecording();
    }
    
    super.dispose();
  }
}

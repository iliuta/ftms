// (Removed accidental pasted debug output)
import 'package:flutter/material.dart';
import '../../core/services/ftms_service.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import '../../core/bloc/ftms_bloc.dart';

import 'training_session_loader.dart';



import 'fit_file_utils.dart';
import 'package:fit_tool/src/profile/messages/record_message.dart';
import 'dart:io';
import 'dart:async';



class TrainingSessionController extends ChangeNotifier {
  final TrainingSession session;
  final BluetoothDevice ftmsDevice;
  late final FTMSService _ftmsService;
  late final List<TrainingInterval> _intervals;
  late final List<int> _intervalStartTimes;
  late final int _totalDuration;
  late final Stream<DeviceData?> _ftmsStream;
  late final StreamSubscription<DeviceData?> _ftmsSub;
  Timer? _timer;

  bool hasControl = false;
  bool sessionCompleted = false;
  int elapsed = 0;
  int intervalElapsed = 0;
  int currentInterval = 0;
  bool timerActive = false;
  List<dynamic>? _lastFtmsParams;

  // FIT data collection (generic, map-based)
  final List<Map<String, dynamic>> fitDataPoints = [];
  DateTime? _sessionStartTime;

  TrainingSessionController({required this.session, required this.ftmsDevice}) {
    _ftmsService = FTMSService(ftmsDevice);
    _intervals = session.intervals;
    _intervalStartTimes = [];
    int acc = 0;
    for (final interval in _intervals) {
      _intervalStartTimes.add(acc);
      acc += interval.duration;
    }
    _totalDuration = acc;
    _ftmsStream = ftmsBloc.ftmsDeviceDataControllerStream;
    _ftmsSub = _ftmsStream.listen(_onFtmsData);
    _initFTMS();
    _sessionStartTime = DateTime.now();
  }

  int get totalDuration => _totalDuration;
  List<TrainingInterval> get intervals => _intervals;
  List<int> get intervalStartTimes => _intervalStartTimes;

  TrainingInterval get current => _intervals[currentInterval];
  List<TrainingInterval> get remainingIntervals => _intervals.sublist(currentInterval);
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

  Future<void> setResistanceWithControl(int resistance) async {
    try {
      if (!hasControl) {
        debugPrint('Not in control, skipping resistance set');
        return;
      }
      await _ftmsService.writeCommand(MachineControlPointOpcodeType.setTargetResistanceLevel, resistanceLevel: resistance);
    } catch (e) {
      debugPrint('Failed to set resistance: $e');
    }
  }

  void _onFtmsData(DeviceData? data) {
    if (timerActive || data == null) return;
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
      }
    }
    // Store current values for next comparison
    _lastFtmsParams = params.map((p) => p.value).toList();

    // Collect FIT data point
    _collectFitDataPoint(data);
  }

  void _collectFitDataPoint(DeviceData data) {
    // Store all FTMS/DeviceData parameters as a map, agnostic to machine type
    final params = data.getDeviceDataParameterValues();
    final now = DateTime.now();
    final elapsedSeconds = _sessionStartTime != null ? now.difference(_sessionStartTime!).inSeconds : 0;
    final dataMap = <String, dynamic>{
      'timestamp': now,
      'elapsedSeconds': elapsedSeconds,
    };
    for (final p in params) {
      dataMap[p.name.toString()] = p.value;
    }
    fitDataPoints.add(dataMap);
  }

  void _startTimer() {
    if (timerActive) return;
    timerActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (sessionCompleted) return;
    elapsed++;
    if (elapsed >= _totalDuration) {
      _timer?.cancel();
      timerActive = false;
      sessionCompleted = true;
      _ftmsService.writeCommand(MachineControlPointOpcodeType.stopOrPause);
      notifyListeners();
      generateAndSaveFitFile();
    } else {
      // Update current interval
      int previousInterval = currentInterval;
      while (currentInterval < _intervals.length - 1 && elapsed >= _intervalStartTimes[currentInterval + 1]) {
        currentInterval++;
      }
      intervalElapsed = elapsed - _intervalStartTimes[currentInterval];
      // If interval changed and resistanceLevel is set, send command
      if (currentInterval != previousInterval) {
        final resistance = _intervals[currentInterval].resistanceLevel;
        if (resistance != null) {
          setResistanceWithControl(resistance);
        }
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ftmsSub.cancel();
    _timer?.cancel();
    super.dispose();
  }

  // FIT file generation and saving
  Future<void> generateAndSaveFitFile({String? outFilePath}) async {
    await FitFileUtils.generateAndSaveFitFile<Map<String, dynamic>>(
      dataPoints: fitDataPoints,
      sessionStartTime: _sessionStartTime,
      outFilePath: outFilePath,
      recordBuilder: (dp, dateTimeToFitTimestamp) {
        final ts = dateTimeToFitTimestamp(dp['timestamp'] as DateTime);
        final record = RecordMessage()
          ..timestamp = ts;
        // Map known fields if present, but allow for any FTMS machine type
        if (dp.containsKey('power') && dp['power'] != null) record.power = dp['power'];
        if (dp.containsKey('cadence') && dp['cadence'] != null) record.cadence = dp['cadence'];
        if (dp.containsKey('heartRate') && dp['heartRate'] != null) record.heartRate = dp['heartRate'];
        if (dp.containsKey('resistanceLevel') && dp['resistanceLevel'] != null) record.resistance = dp['resistanceLevel'];
        // Also check for alternative field names (case-insensitive)
        if (record.power == null) {
          final altPower = dp.entries.firstWhere(
            (e) => e.key.toLowerCase().contains('power') && e.value is int,
            orElse: () => const MapEntry('', null),
          );
          if (altPower.value != null) record.power = altPower.value;
        }
        if (record.cadence == null) {
          final altCadence = dp.entries.firstWhere(
            (e) => e.key.toLowerCase().contains('cadence') && e.value is int,
            orElse: () => const MapEntry('', null),
          );
          if (altCadence.value != null) record.cadence = altCadence.value;
        }
        if (record.heartRate == null) {
          final altHR = dp.entries.firstWhere(
            (e) => (e.key.toLowerCase().contains('heartrate') || e.key.toLowerCase() == 'hr' || e.key.toLowerCase() == 'heart_rate') && e.value is int,
            orElse: () => const MapEntry('', null),
          );
          if (altHR.value != null) record.heartRate = altHR.value;
        }
        if (record.resistance == null) {
          final altRes = dp.entries.firstWhere(
            (e) => e.key.toLowerCase().contains('resistance') && e.value is int,
            orElse: () => const MapEntry('', null),
          );
          if (altRes.value != null) record.resistance = altRes.value;
        }
        return record;
      },
    );
  }
}

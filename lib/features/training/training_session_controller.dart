import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/ftms_service.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import '../../core/bloc/ftms_bloc.dart';
import 'training_session_loader.dart';
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

  bool hasControl = false;
  bool sessionCompleted = false;
  int elapsed = 0;
  int intervalElapsed = 0;
  int currentInterval = 0;
  bool timerActive = false;
  List<dynamic>? _lastFtmsParams;

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
}

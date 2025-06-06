// This file was moved from lib/training_session_progress_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/ftms_service.dart';
import 'training_session_loader.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import '../../core/bloc/ftms_bloc.dart';
import '../../core/utils/ftms_display_config.dart';
import '../../core/utils/ftms_display_widgets.dart';

class TrainingSessionProgressScreen extends StatefulWidget {
  final TrainingSession session;
  final BluetoothDevice ftmsDevice;
  const TrainingSessionProgressScreen({Key? key, required this.session, required this.ftmsDevice}) : super(key: key);

  @override
  State<TrainingSessionProgressScreen> createState() => _TrainingSessionProgressScreenState();
}

class _TrainingSessionProgressScreenState extends State<TrainingSessionProgressScreen> {
  bool _hasControl = false;

  Future<void> _setResistanceWithControl(int resistance) async {
    try {
      if (!_hasControl) {
        debugPrint('Not in control, skipping resistance set');
        return;
      }
      await _ftmsService.writeCommand(MachineControlPointOpcodeType.setTargetResistanceLevel, resistanceLevel: resistance);
    } catch (e) {
      debugPrint('Failed to set resistance: $e');
    }
  }
  late final FTMSService _ftmsService;
  List<dynamic>? _lastFtmsParams;
  bool _sessionCompleted = false;
  int _elapsed = 0; // seconds
  int _intervalElapsed = 0;
  int _currentInterval = 0;
  late final int _totalDuration;
  late final List<TrainingInterval> _intervals;
  late final List<int> _intervalStartTimes;
  bool _started = false;
  bool _timerActive = false;
  late final Stream<DeviceData?> _ftmsStream;
  late final StreamSubscription<DeviceData?> _ftmsSub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ftmsService = FTMSService(widget.ftmsDevice);
    _intervals = widget.session.intervals;
    _intervalStartTimes = [];
    int acc = 0;
    for (final interval in _intervals) {
      _intervalStartTimes.add(acc);
      acc += interval.duration;
    }
    _totalDuration = acc;
    _ftmsStream = ftmsBloc.ftmsDeviceDataControllerStream;
    _ftmsSub = _ftmsStream.listen(_onFtmsData);

    // Request control after a short delay, then start session and set initial resistance if needed
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await _ftmsService.writeCommand(MachineControlPointOpcodeType.requestControl);
        _hasControl = true;
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

  @override
  void dispose() {
    _ftmsSub.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _onFtmsData(DeviceData? data) {
    if (_timerActive || data == null) return;
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
    if (_timerActive) return;
    _timerActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (_sessionCompleted) return;
    setState(() {
      _elapsed++;
      if (_elapsed >= _totalDuration) {
        _timer?.cancel();
        _timerActive = false;
        _sessionCompleted = true;
        // Stop or pause the session on FTMS
        _ftmsService.writeCommand(MachineControlPointOpcodeType.stopOrPause);
        // Show session complete dialog
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Congratulations!'),
              content: const Text('You have completed the training session.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back one screen
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        });
      } else {
        // Update current interval
        int previousInterval = _currentInterval;
        while (_currentInterval < _intervals.length - 1 && _elapsed >= _intervalStartTimes[_currentInterval + 1]) {
          _currentInterval++;
        }
        _intervalElapsed = _elapsed - _intervalStartTimes[_currentInterval];
        // If interval changed and resistanceLevel is set, send command
        if (_currentInterval != previousInterval) {
          final resistance = _intervals[_currentInterval].resistanceLevel;
          if (resistance != null) {
            _setResistanceWithControl(resistance);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _intervals[_currentInterval];
    final remainingIntervals = _intervals.sublist(_currentInterval);
    final mainTimeLeft = _totalDuration - _elapsed;
    final intervalTimeLeft = current.duration - _intervalElapsed;
    String formatHHMMSS(int seconds) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      final s = seconds % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' ;
    }
    String formatMMSS(int seconds) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' ;
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.session.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Main progress bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _elapsed / _totalDuration,
                    minHeight: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatHHMMSS(mainTimeLeft),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  // Left: Remaining intervals (remove finished ones)
                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      itemCount: remainingIntervals.length,
                      itemBuilder: (context, idx) {
                        final interval = remainingIntervals[idx];
                        final isCurrent = idx == 0;
                        final intervalProgress = isCurrent ? _intervalElapsed / interval.duration : 0.0;
                        return Card(
                          color: isCurrent ? Colors.blue[50] : null,
                          child: ListTile(
                            title: Text(interval.title ?? 'Interval'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: intervalProgress,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isCurrent)
                                      Text(
                                        formatMMSS(intervalTimeLeft),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      )
                                    else
                                      Text('${interval.duration}s'),
                                  ],
                                ),
                                if (interval.targets != null)
                                  Text('Targets: ${interval.targets}')
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right: Live FTMS data
                  Expanded(
                    flex: 3,
                    child: _LiveFTMSDataWidget(
                      ftmsDevice: widget.ftmsDevice,
                      targets: current.targets,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _LiveFTMSDataWidget extends StatefulWidget {
  final BluetoothDevice ftmsDevice;
  final Map<String, dynamic>? targets;
  const _LiveFTMSDataWidget({Key? key, required this.ftmsDevice, this.targets}) : super(key: key);

  @override
  State<_LiveFTMSDataWidget> createState() => _LiveFTMSDataWidgetState();
}

class _LiveFTMSDataWidgetState extends State<_LiveFTMSDataWidget> {
  FtmsDisplayConfig? _config;
  String? _configError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final type = await _getDeviceType();
    if (type == null) return;
    final config = await loadFtmsDisplayConfig(type);
    setState(() {
      _config = config;
      _configError = config == null ? 'No config for this machine type' : null;
    });
  }

  Future<DeviceDataType?> _getDeviceType() async {
    // Try to get the latest device data from the stream
    final snapshot = await ftmsBloc.ftmsDeviceDataControllerStream.firstWhere((d) => d != null);
    return snapshot?.deviceDataType;
  }

  bool _isWithinTarget(num? value, num? target, {num factor = 1}) {
    if (value == null || target == null) return false;
    final scaledValue = value * factor;
    final lower = target * 0.9;
    final upper = target * 1.1;
    return scaledValue >= lower && scaledValue <= upper;
  }

  @override
  Widget build(BuildContext context) {
    if (_configError != null) {
      return Text(_configError!, style: const TextStyle(color: Colors.red));
    }
    if (_config == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DeviceData?>(
              stream: ftmsBloc.ftmsDeviceDataControllerStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No FTMS data'),
                  );
                }
                final deviceData = snapshot.data!;
                final parameterValues = deviceData.getDeviceDataParameterValues();
                final paramValueMap = {
                  for (final p in parameterValues)
                    if (p.name != null) p.name.name: p
                };
                return Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: _config!.fields.map((field) {
                    final param = paramValueMap[field.name];
                    Color? color;
                    FontWeight fontWeight = FontWeight.normal;
                    if (param == null) {
                      return Text('${field.label}: (not available)', style: const TextStyle(color: Colors.grey));
                    }
                    final value = param.value ?? param.toString();
                    final factor = (param.factor is num)
                        ? param.factor as num
                        : num.tryParse(param.factor?.toString() ?? '1') ?? 1;
                    final scaledValue = (value is num ? value : num.tryParse(value.toString()) ?? 0) * factor;
                    if (widget.targets != null && widget.targets![field.name] != null) {
                      final target = widget.targets![field.name];
                      fontWeight = FontWeight.bold;
                      if (_isWithinTarget(
                            value is num ? value : num.tryParse(value.toString()),
                            target is num ? target : num.tryParse(target.toString()),
                            factor: factor,
                          )) {
                        color = Colors.green[700];
                      } else {
                        color = Colors.red[700];
                      }
                    }
                    // Display widget selection
                    if (field.display == 'speedometer') {
                      return SpeedometerWidget(
                        value: scaledValue.toDouble(),
                        min: (field.min ?? 0).toDouble(),
                        max: (field.max ?? 100).toDouble(),
                        label: field.label,
                        unit: field.unit,
                        color: color ?? Colors.blue,
                      );
                    } else {
                      return SimpleNumberWidget(
                        label: field.label,
                        value: scaledValue,
                        unit: field.unit,
                        color: color,
                      );
                    }
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


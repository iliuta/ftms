import 'dart:async';
import 'dart:io';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fit_tool/fit_tool.dart';
import '../models/training_record.dart';
import 'distance_calculation_strategy.dart';
import '../utils/logger.dart';
import '../utils/fit_timestamp_utils.dart';

/// Service for recording training session data and generating FIT files
class TrainingDataRecorder {
  final List<TrainingRecord> _records = [];
  final DistanceCalculationStrategy _distanceStrategy;
  final String _sessionName;
  final DeviceDataType _deviceType;
  
  DateTime? _sessionStartTime;
  DateTime? _lastRecordTime;
  bool _isRecording = false;
  
  TrainingDataRecorder({
    required DeviceDataType deviceType,
    String? sessionName,
  }) : _deviceType = deviceType,
       _sessionName = sessionName ?? 'Training_${DateTime.now().millisecondsSinceEpoch}',
       _distanceStrategy = DistanceCalculationStrategyFactory.createStrategy(deviceType);
  
  /// Start recording training data
  void startRecording() {
    if (_isRecording) return;
    
    _sessionStartTime = DateTime.now();
    _lastRecordTime = _sessionStartTime;
    _isRecording = true;
    _records.clear();
    _distanceStrategy.reset();
    
    logger.i('Started recording training session: $_sessionName');
  }
  
  /// Stop recording training data
  void stopRecording() {
    _isRecording = false;
    logger.i('Stopped recording training session: $_sessionName (${_records.length} records)');
  }
  
  /// Add a new data point from FTMS device
  void recordDataPoint({
    required Map<String, dynamic> ftmsParams,
    double? resistanceLevel,
  }) {
    if (!_isRecording || _sessionStartTime == null) return;
    
    final now = DateTime.now();
    final elapsedTime = now.difference(_sessionStartTime!).inSeconds;
    final timeDelta = _lastRecordTime != null 
        ? now.difference(_lastRecordTime!).inMilliseconds / 1000.0
        : 1.0;
    
    // Calculate distance increment
    final previousData = _records.isNotEmpty 
        ? _convertRecordToMap(_records.last)
        : null;
    
    _distanceStrategy.calculateDistanceIncrement(
      currentData: ftmsParams,
      previousData: previousData,
      timeDeltaSeconds: timeDelta,
    );
    
    // Create training record
    final record = TrainingRecord.fromFtmsData(
      timestamp: now,
      elapsedTime: elapsedTime,
      ftmsParams: ftmsParams,
      calculatedDistance: _distanceStrategy.totalDistance,
      resistanceLevel: resistanceLevel,
    );
    
    _records.add(record);
    _lastRecordTime = now;
    
    // Log occasionally to track progress
    if (_records.length % 60 == 0) { // Every 60 records (roughly 1 minute)
      logger.i('Recorded ${_records.length} data points, distance: ${_distanceStrategy.totalDistance.toStringAsFixed(1)}m');
    }
  }
  
  Map<String, dynamic> _convertRecordToMap(TrainingRecord record) {
    return {
      'Instantaneous Power': record.instantaneousPower,
      'Instantaneous Speed': record.instantaneousSpeed,
      'Instantaneous Cadence': record.instantaneousCadence,
      'Heart Rate': record.heartRate,
      'Instantaneous Stroke Rate': record.instantaneousStrokeRate,
    };
  }
  
  /// Generate and save FIT file
  Future<String?> generateFitFile() async {
    if (_records.isEmpty || _sessionStartTime == null) {
      logger.w('No training data to export');
      return null;
    }
    
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fitDir = Directory('${directory.path}/fit_files');
      if (!await fitDir.exists()) {
        await fitDir.create(recursive: true);
      }
      
      final filename = '${_sessionName}_${_formatDateForFilename(_sessionStartTime!)}.fit';
      final filePath = '${fitDir.path}/$filename';
      
      logger.i('Generating FIT file: $filePath');
      
      // Create FIT file content
      final fitFile = await _createFitFile();
      
      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(fitFile);
      
      logger.i('FIT file generated successfully: $filePath (${_records.length} records)');
      return filePath;
      
    } catch (e, stackTrace) {
      logger.e('Failed to generate FIT file: $e\nStack trace: $stackTrace');
      return null;
    }
  }
  
  String _formatDateForFilename(DateTime dateTime) {
    return '${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}'
           '${dateTime.day.toString().padLeft(2, '0')}_'
           '${dateTime.hour.toString().padLeft(2, '0')}'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  Future<List<int>> _createFitFile() async {
    final builder = FitFileBuilder();

    // Create File ID message
    final fileIdMessage = FileIdMessage()
      ..type = FileType.activity
      ..timeCreated = millisecondsToFitTimestamp(_sessionStartTime!.millisecondsSinceEpoch)
      ..manufacturer = Manufacturer.development.value;

    // Create Activity message
    final activityMessage = ActivityMessage()
      ..timestamp = millisecondsToFitTimestamp(_records.last.timestamp.millisecondsSinceEpoch)
      ..type = Activity.manual
      ..totalTimerTime = (_records.last.elapsedTime * 1000).toDouble();

    // Create Session message
    final sessionMessage = SessionMessage()
      ..timestamp = millisecondsToFitTimestamp(_records.last.timestamp.millisecondsSinceEpoch)
      ..sport = _getSport()
      ..subSport = _getSubSport()
      ..startTime = millisecondsToFitTimestamp(_sessionStartTime!.millisecondsSinceEpoch)
      ..totalElapsedTime = (_records.last.elapsedTime * 1000).toDouble()
      ..totalTimerTime = (_records.last.elapsedTime * 1000).toDouble()
      ..totalDistance = _getTotalDistance()?.toDouble()
      ..avgPower = _getAveragePower()
      ..maxPower = _getMaximumPower()
      ..avgSpeed = _getAverageSpeed()
      ..maxSpeed = _getMaximumSpeed()
      ..avgHeartRate = _getAverageHeartRate()
      ..maxHeartRate = _getMaximumHeartRate()
      ..avgCadence = _getAverageCadence()
      ..maxCadence = _getMaximumCadence();

    // Create Lap message (one lap for the entire session)
    final lapMessage = LapMessage()
      ..timestamp = millisecondsToFitTimestamp(_records.last.timestamp.millisecondsSinceEpoch)
      ..startTime = millisecondsToFitTimestamp(_sessionStartTime!.millisecondsSinceEpoch)
      ..totalElapsedTime = (_records.last.elapsedTime * 1000).toDouble()
      ..totalTimerTime = (_records.last.elapsedTime * 1000).toDouble()
      ..totalDistance = _getTotalDistance()?.toDouble()
      ..avgPower = _getAveragePower()
      ..maxPower = _getMaximumPower()
      ..avgSpeed = _getAverageSpeed()
      ..maxSpeed = _getMaximumSpeed()
      ..avgHeartRate = _getAverageHeartRate()
      ..maxHeartRate = _getMaximumHeartRate()
      ..avgCadence = _getAverageCadence()
      ..maxCadence = _getMaximumCadence();

    // Add all messages to builder
    builder.add(fileIdMessage);
    builder.add(activityMessage);
    builder.add(sessionMessage);
    builder.add(lapMessage);

    // Create Record messages for each data point (sample to reduce file size)
    final sampleRate = _calculateSampleRate();
    for (int i = 0; i < _records.length; i += sampleRate) {
      final record = _records[i];
      final recordMessage = RecordMessage()
        ..timestamp = millisecondsToFitTimestamp(record.timestamp.millisecondsSinceEpoch)
        ..power = record.instantaneousPower?.round()
        ..speed = record.instantaneousSpeed != null 
            ? (record.instantaneousSpeed! / 3.6 * 1000).toDouble() // Convert km/h to mm/s
            : null
        ..cadence = record.instantaneousCadence?.round()
        ..heartRate = record.heartRate?.round()
        ..distance = record.totalDistance?.toDouble();

      builder.add(recordMessage);
    }

    final fitFile = builder.build();
    return fitFile.toBytes();
  }
  
  int _calculateSampleRate() {
    // Sample every 2-5 seconds depending on session length
    if (_records.length < 300) return 2; // < 5 minutes: every 2 seconds
    if (_records.length < 1800) return 3; // < 30 minutes: every 3 seconds  
    return 5; // 30+ minutes: every 5 seconds
  }
  
  Sport _getSport() {
    switch (_deviceType) {
      case DeviceDataType.indoorBike:
        return Sport.cycling;
      case DeviceDataType.rower:
        return Sport.rowing;
      default:
        return Sport.fitnessEquipment;
    }
  }
  
  SubSport _getSubSport() {
    switch (_deviceType) {
      case DeviceDataType.indoorBike:
        return SubSport.indoorCycling;
      case DeviceDataType.rower:
        return SubSport.indoorRowing;
      default:
        return SubSport.generic;
    }
  }
  
  int? _getTotalDistance() {
    return _distanceStrategy.totalDistance.round();
  }
  
  int? _getAveragePower() {
    final powers = _records
        .where((r) => r.instantaneousPower != null && r.instantaneousPower! > 0)
        .map((r) => r.instantaneousPower!)
        .toList();
    if (powers.isEmpty) return null;
    return (powers.reduce((a, b) => a + b) / powers.length).round();
  }
  
  int? _getMaximumPower() {
    final powers = _records
        .where((r) => r.instantaneousPower != null)
        .map((r) => r.instantaneousPower!)
        .toList();
    if (powers.isEmpty) return null;
    return powers.reduce((a, b) => a > b ? a : b).round();
  }
  
  double? _getAverageSpeed() {
    final speeds = _records
        .where((r) => r.instantaneousSpeed != null && r.instantaneousSpeed! > 0)
        .map((r) => r.instantaneousSpeed!)
        .toList();
    if (speeds.isEmpty) return null;
    // Convert km/h to mm/s for FIT format
    return (speeds.reduce((a, b) => a + b) / speeds.length) / 3.6 * 1000;
  }
  
  double? _getMaximumSpeed() {
    final speeds = _records
        .where((r) => r.instantaneousSpeed != null)
        .map((r) => r.instantaneousSpeed!)
        .toList();
    if (speeds.isEmpty) return null;
    // Convert km/h to mm/s for FIT format
    return speeds.reduce((a, b) => a > b ? a : b) / 3.6 * 1000;
  }
  
  int? _getAverageHeartRate() {
    final heartRates = _records
        .where((r) => r.heartRate != null && r.heartRate! > 0)
        .map((r) => r.heartRate!)
        .toList();
    if (heartRates.isEmpty) return null;
    return (heartRates.reduce((a, b) => a + b) / heartRates.length).round();
  }
  
  int? _getMaximumHeartRate() {
    final heartRates = _records
        .where((r) => r.heartRate != null)
        .map((r) => r.heartRate!)
        .toList();
    if (heartRates.isEmpty) return null;
    return heartRates.reduce((a, b) => a > b ? a : b).round();
  }
  
  int? _getAverageCadence() {
    final cadences = _records
        .where((r) => r.instantaneousCadence != null && r.instantaneousCadence! > 0)
        .map((r) => r.instantaneousCadence!)
        .toList();
    if (cadences.isEmpty) return null;
    return (cadences.reduce((a, b) => a + b) / cadences.length).round();
  }
  
  int? _getMaximumCadence() {
    final cadences = _records
        .where((r) => r.instantaneousCadence != null)
        .map((r) => r.instantaneousCadence!)
        .toList();
    if (cadences.isEmpty) return null;
    return cadences.reduce((a, b) => a > b ? a : b).round();
  }

  /// Get current statistics
  Map<String, dynamic> getStatistics() {
    if (_records.isEmpty) return {};
    
    return {
      'recordCount': _records.length,
      'duration': _records.last.elapsedTime,
      'totalDistance': _distanceStrategy.totalDistance,
      'averagePower': _getAveragePower(),
      'maxPower': _getMaximumPower(),
      'averageSpeed': _getAverageSpeed(),
      'maxSpeed': _getMaximumSpeed(),
      'averageHeartRate': _getAverageHeartRate(),
      'maxHeartRate': _getMaximumHeartRate(),
      'averageCadence': _getAverageCadence(),
      'maxCadence': _getMaximumCadence(),
    };
  }
  
  /// Check if currently recording
  bool get isRecording => _isRecording;
  
  /// Get number of recorded data points
  int get recordCount => _records.length;
  
  /// Get session name
  String get sessionName => _sessionName;
}

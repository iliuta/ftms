import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/logger.dart';
import 'dart:io';

/// Service to handle runtime permissions, especially for Bluetooth on Android
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request all necessary Bluetooth permissions for Android
  Future<bool> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) {
      logger.i('Not Android, skipping permission requests');
      return true; // No runtime permissions needed on other platforms
    }

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;
    
    logger.i('Android SDK version: $sdkInt');

    List<ph.Permission> permissions = [];

    // For Android 12+ (API level 31+), request new Bluetooth permissions
    if (sdkInt >= 31) {
      logger.i('Using Android 12+ permissions');
      permissions.addAll([
        ph.Permission.bluetoothScan,
        ph.Permission.bluetoothConnect,
        ph.Permission.locationWhenInUse, // Still needed for Bluetooth scanning
      ]);
    } else {
      logger.i('Using legacy Android permissions');
      permissions.addAll([
        ph.Permission.bluetooth,
        ph.Permission.location,
        ph.Permission.locationWhenInUse,
      ]);
    }

    logger.i('Requesting permissions: ${permissions.map((p) => p.toString()).join(', ')}');
    Map<ph.Permission, ph.PermissionStatus> statuses = await permissions.request();

    // Log the status of each permission
    statuses.forEach((permission, status) {
      logger.i('Permission $permission: $status');
    });

    // Check if all permissions are granted
    final allGranted = statuses.values.every((status) => 
        status == ph.PermissionStatus.granted || 
        status == ph.PermissionStatus.limited);
        
    logger.i('All permissions granted: $allGranted');
    return allGranted;
  }

  /// Check if Bluetooth permissions are granted
  Future<bool> hasBluetoothPermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 31) {
      final bluetoothScan = await ph.Permission.bluetoothScan.status;
      final bluetoothConnect = await ph.Permission.bluetoothConnect.status;
      final location = await ph.Permission.locationWhenInUse.status;

      return bluetoothScan.isGranted && 
             bluetoothConnect.isGranted && 
             location.isGranted;
    } else {
      final bluetooth = await ph.Permission.bluetooth.status;
      final location = await ph.Permission.locationWhenInUse.status;

      return bluetooth.isGranted && location.isGranted;
    }
  }

  /// Open app settings if permissions are permanently denied
  static Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
}

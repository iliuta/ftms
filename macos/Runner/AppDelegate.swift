import Cocoa
import FlutterMacOS
import CoreBluetooth

@main
class AppDelegate: FlutterAppDelegate, CBCentralManagerDelegate {
  var centralManager: CBCentralManager?
  var permissionResult: FlutterResult?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "flutter.baseflow.com/permissions/methods", binaryMessenger: controller.engine.binaryMessenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "requestPermissions" {
        self.permissionResult = result
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
      guard let result = permissionResult else { return }

      switch central.state {
      case .poweredOn:
        result([3: 1, 15: 1, 21: 1, 30: 1, 28: 1])
      default:
        result([3: 0, 15: 0, 21: 0, 30: 0, 28: 0])
      }
      permissionResult = nil
    }

    private func requestPermissions(result: @escaping FlutterResult) {
      centralManager = CBCentralManager(delegate: self, queue: nil)
      /*
      Location 3
      Storage 15
      Bluetooth 21
      bluetoothConnect 30
      BluetoothScan 28
       */
        // Wait for the centralManagerDidUpdateState to be called
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          if self.centralManager?.state == .poweredOn {
            result([3: 1, 15: 1, 21: 1, 30: 1, 28: 1])
          } else {
            result([3: 0, 15: 0, 21: 0, 30: 0, 28: 0])
          }
        }
    }
}

// This file was moved from lib/scan_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../ftms/ftms_page.dart';
import '../../core/bloc/ftms_bloc.dart';

/// Button for scanning FTMS Bluetooth devices (legacy, not used in auto-scan mode)
Widget scanBluetoothButton(bool? isScanning) {
  if (isScanning == null) {
    return Container();
  }
  return ElevatedButton(
    onPressed:
        isScanning ? null : () async => await FTMS.scanForBluetoothDevices(),
    child: isScanning
        ? const Text("Scanning...")
        : const Text("Scan FTMS Devices"),
  );
}

/// Widget to display scan results as a list of FTMS devices
Widget scanResultsToWidget(List<ScanResult> data, BuildContext context) {
  return Column(
    children: data
        .map(
          (d) => ListTile(
        title: FutureBuilder<bool>(
            future: FTMS.isBluetoothDeviceFTMSDevice(d.device),
            initialData: false,
            builder: (c, snapshot) {
              return Text(
                d.device.platformName.isEmpty
                    ? "(unknown device)"
                    : d.device.platformName,
              );
            }),
        subtitle: Text(d.device.remoteId.str),
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text(d.rssi.toString()),
          ),
        ),
        trailing: getButtonForBluetoothDevice(d.device, context),
      ),
    )
        .toList(),
  );
}

/// Button for connecting/disconnecting to a Bluetooth device and opening FTMS page
Widget getButtonForBluetoothDevice(
    BluetoothDevice device, BuildContext context) {
  return StreamBuilder<BluetoothConnectionState>(
      stream: device.connectionState,
      builder: (c, snapshot) {
        if (!snapshot.hasData) {
          return const Text("...");
        }
        var deviceState = snapshot.data!;
        switch (deviceState) {
          case BluetoothConnectionState.disconnected:
            return ElevatedButton(
              child: const Text("Connect"),
              onPressed: () async {
                final snackBar = SnackBar(
                  content: Text('Connecting to ${device.platformName}...'),
                  duration: const Duration(seconds: 2),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);

                await FTMS.connectToFTMSDevice(device);
                device.connectionState.listen((state) async {
                  if (state == BluetoothConnectionState.disconnected) {
                    ftmsBloc.ftmsDeviceDataControllerSink.add(null);
                    return;
                  }
                });
              },
            );
          case BluetoothConnectionState.connected:
            return SizedBox(
              width: 250,
              child: Wrap(
                spacing: 2,
                alignment: WrapAlignment.end,
                direction: Axis.horizontal,
                children: [
                  FutureBuilder<bool>(
                    future: FTMS.isBluetoothDeviceFTMSDevice(device),
                    initialData: false,
                    builder: (c, snapshot) => (snapshot.data ?? false)
                        ? ElevatedButton(
                      child: const Text("Open"),
                      onPressed: () async {
                        // Enable wakelock when device is selected
                        try {
                          await WakelockPlus.enable();
                        } catch (e) {
                          // Wakelock not supported on this platform
                          debugPrint('Wakelock not supported: $e');
                        }
                        
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FTMSPage(
                                ftmsDevice: device,
                              )),
                        );
                      },
                    )
                        : Container(),
                  ),
                  OutlinedButton(
                    child: const Text("Disconnect"),
                    onPressed: () async {
                      await FTMS.disconnectFromFTMSDevice(device);
                      // Disable wakelock when disconnecting
                      WakelockPlus.disable();
                    },
                  )
                ],
              ),
            );
          default:
            return Text(deviceState.name);
        }
      });
}

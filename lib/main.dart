import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart'; // For handling permissions
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: BluetoothScanScreen(),
    );
  }
}

class BluetoothScanScreen extends StatefulWidget {
  @override
  _BluetoothScanScreenState createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];
  StreamSubscription<List<ScanResult>>? scanSubscription;
  bool isScanning = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  // Request Bluetooth and Location Permissions
  void requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.location.request();
  }

  // Start scanning for Bluetooth devices
  void startScan() {
    if (!isScanning) {
      setState(() {
        isScanning = true;
      });
      scanSubscription = flutterBlue.scanResults.listen((results) {
        setState(() {
          devicesList = results
              .map((result) => result.device)
              .where((device) => device.name.contains(searchQuery))
              .toList();
        });

        // Show a dialog for newly detected device
        for (var result in results) {
          _showDeviceFoundDialog(result.device);
        }
      });

      flutterBlue.startScan(timeout: Duration(seconds: 4));
    }
  }

  // Stop scanning
  void stopScan() {
    flutterBlue.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  // Connect to the Bluetooth device
  // Connect to the Bluetooth device
  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    print('Connected to: ${device.name}');
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Connected'),
        content: Text('Successfully connected to ${device.name}'),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Show a dialog when a new device is found
  void _showDeviceFoundDialog(BluetoothDevice device) {
    if (device.name.isNotEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('New Device Found'),
          content: Text('Do you want to connect to ${device.name}?'),
          actions: [
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text('Connect'),
              onPressed: () {
                connectToDevice(device);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  // Filter devices by name
  void onSearchQueryChanged(String query) {
    setState(() {
      searchQuery = query;
      devicesList = devicesList
          .where((device) => device.name.contains(searchQuery))
          .toList();
    });
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Bluetooth Scanner'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(isScanning ? CupertinoIcons.stop : CupertinoIcons.search),
          onPressed: () {
            if (isScanning) {
              stopScan();
            } else {
              startScan();
            }
          },
        ),
      ),
      child: CupertinoScrollbar(
        child: Column(
          children: [
            CupertinoSearchTextField(
              onChanged: onSearchQueryChanged,
              placeholder: 'Search by device name...',
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Devices Found: ${devicesList.length}'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: devicesList.length,
                itemBuilder: (context, index) {
                  BluetoothDevice device = devicesList[index];
                  return CupertinoListTile(
                    title: Text(
                        device.name.isEmpty ? 'Unknown device' : device.name),
                    subtitle: Text('RSSI: ${device.id.toString()}'),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(CupertinoIcons.bluetooth),
                      onPressed: () {
                        connectToDevice(device);
                      },
                    ),
                    onTap: () => connectToDevice(device),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  CupertinoListTile(
      {required this.title,
      this.subtitle,
      required this.trailing,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          if (subtitle != null) subtitle!,
          trailing,
        ],
      ),
    );
  }
}

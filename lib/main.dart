import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermissions() async {
  final scanGranted = await Permission.bluetoothScan.request().isGranted;
  final connectGranted = await Permission.bluetoothConnect.request().isGranted;
  final locationGranted =
      await Permission.locationWhenInUse.request().isGranted;

  if (scanGranted && connectGranted && locationGranted) {
    debugPrint("Permissions granted");
    return true;
  } else {
    debugPrint("Permissions not granted");
    return false;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Battery Level',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BatteryLevelPage(),
    );
  }
}

class BatteryLevelPage extends StatefulWidget {
  const BatteryLevelPage({super.key});

  @override
  State<BatteryLevelPage> createState() => _BatteryLevelPageState();
}

class _BatteryLevelPageState extends State<BatteryLevelPage> {
  String _batteryLevel = 'Unknown';
  static const String batteryServiceUuid = "180F";
  static const String batteryCharacteristicUuid = "2A19";
  List<BluetoothService> _services = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final permissionsGranted = await requestPermissions();
    if (permissionsGranted) {
      _findAndReadBatteryLevel();
    } else {
      setState(() {
        _batteryLevel = "Permissions required to proceed.";
      });
    }
  }

  Future<void> _findAndReadBatteryLevel() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (result.device.platformName == "rGny") {
          FlutterBluePlus.stopScan();

          await result.device.connect();
          _services = await result.device.discoverServices();
          await updateBatteryLevel();

          return;
        }
      }
    });
  }

  Future<void> updateBatteryLevel() async {
    final service = _services.firstWhere((element) =>
        element.uuid.toString().toUpperCase().contains(batteryServiceUuid));

    final characteristic = service.characteristics.firstWhere((element) =>
        element.uuid
            .toString()
            .toUpperCase()
            .contains(batteryCharacteristicUuid));

    await Future.delayed(const Duration(milliseconds: 500));
    List<int> value = await characteristic.read();
    setState(() {
      _batteryLevel = "Battery Level: ${value.first}%";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Battery Level'),
      ),
      body: Center(
        child: Text(
          _batteryLevel,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

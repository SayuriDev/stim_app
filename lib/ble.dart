import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

enum BleInitResult {
  ok,
  notSupported,
  disabled,
}

class Ble {
  static const serviceUuid = "f7dbcda5-e68c-45ea-a05e-45f7a67fea2d";
  static const controlsUUID = "93710001-0000-0000-0000-000000000000";
  static const filesUUID = "93710002-0000-0000-0000-000000000000";

  BluetoothDevice? device;
  BluetoothCharacteristic? _controlChar;
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;
  Timer? _heartbeatTimer;
  ValueNotifier<bool> isConnected = ValueNotifier(false);

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => writeArray([255, 0]),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<BleInitResult> init() async {
    if (!await FlutterBluePlus.isSupported) {
      return BleInitResult.notSupported;
    }
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      return BleInitResult.disabled;
    }
    scan();
    return BleInitResult.ok;
  }

  // scan
  void scan() {
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      androidUsesFineLocation: true,
    );
  }

  Stream<List<ScanResult>> get results => FlutterBluePlus.scanResults;

  // connect
  Future<void> connect(BluetoothDevice d) async {
    await FlutterBluePlus.stopScan();
    _deviceStateSubscription?.cancel();
    device = d;
    try {
      await device!.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      final services = await device!.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString() == serviceUuid,
      );
      _controlChar = service.characteristics.firstWhere(
        (c) => c.uuid.toString() == controlsUUID,
      );

      isConnected.value = true;
      _startHeartbeat();

      _deviceStateSubscription = device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _stopHeartbeat();
          isConnected.value = false;
          _controlChar = null;
          device = null;
          _deviceStateSubscription?.cancel();
          _deviceStateSubscription = null;
        }
      });
    } on FlutterBluePlusException catch (e) {
      isConnected.value = false;
      print("BLE connect error: $e");
    } catch (e) {
      isConnected.value = false;
      print("Unknown error: $e");
    }
  }

  // write
  Future<void> writeArray(List<int> value) async {
    if (_controlChar == null) {
      print("writeArray: no characteristic, are you connected?");
      return;
    }
    try {
      await _controlChar!.write(value);
    } catch (e) {
      print("writeArray error: $e");
      isConnected.value = false;
    }
  }

  // disconnect
  Future<void> disconnect() async {
    _stopHeartbeat();
    if (device == null) return;
    try {
      await device!.disconnect();
    } catch (_) {
      // ignore errors on disconnect
    } finally {
      _deviceStateSubscription?.cancel();
      _deviceStateSubscription = null;
      isConnected.value = false;
      _controlChar = null;
      device = null;
    }
  }
}
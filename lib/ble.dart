import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BleInitResult {
  ok,
  notSupported,
  disabled,
}


class Ble {
  // UUID ESP32
  static const serviceUuid =
      "f7dbcda5-e68c-45ea-a05e-45f7a67fea2d";

  static const controlsUUID =
      "93710001-0000-0000-0000-000000000000";

  static const filesUUID =
      "93710002-0000-0000-0000-000000000000";

  BluetoothDevice? device;

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
      androidUsesFineLocation: true
    );
  }

  Stream<List<ScanResult>> get results =>
      FlutterBluePlus.scanResults;

  // connect
  Future<void> connect(BluetoothDevice d) async {
    await FlutterBluePlus.stopScan();

    device = d;

    try {
      await device!.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );
    } on FlutterBluePlusException catch (e) {
      print("BLE connect error: $e");
    } catch (e) {
      print("Unknown error: $e");
    }
  }

  // write
  Future<void> write(int value) async {
    final services = await device!.discoverServices();

    final service = services.firstWhere(
      (s) => s.uuid.toString() == serviceUuid,
    );

    final char = service.characteristics.firstWhere(
      (c) => c.uuid.toString() == controlsUUID,
    );

    await char.write([value]);
  }
}
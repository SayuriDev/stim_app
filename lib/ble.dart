import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

enum BleInitResult {
  ok,
  notSupported,
  disabled,
}

class Ble {
  static const serviceUuid = "f7dbcda5-e68c-45ea-a05e-45f7a67fea2d";
  static const controlsUUID = "93710001-0000-0000-0000-000000000000";
  static const filesUUID = "93710002-0000-0000-0000-000000000000";
  static const _lastDeviceKey = 'ble_last_device_id';

  BluetoothDevice? device;
  BluetoothCharacteristic? _controlChar;
  BluetoothCharacteristic? _filesChar;
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _filesSubscription;
  StreamController<String> _filePathController = StreamController.broadcast();
  Timer? _heartbeatTimer;
  bool _isConnecting = false;
  ValueNotifier<bool> isConnected = ValueNotifier(false);

  Stream<String> get filePathStream => _filePathController.stream;

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
    if (_isConnecting) return;
    _isConnecting = true;

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
      final fileChars = service.characteristics
          .where((c) => c.uuid.toString() == filesUUID);
      if (fileChars.isNotEmpty) {
        _filesChar = fileChars.first;
      }

      if (_filesChar != null) {
        await _filesChar!.setNotifyValue(true);
        _filesSubscription?.cancel();
        _filesSubscription = _filesChar!.value.listen(_handleFileNotification);
      }

      isConnected.value = true;
      _startHeartbeat();

      // remember the device
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastDeviceKey, device!.remoteId.str);

      _deviceStateSubscription = device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _stopHeartbeat();
          isConnected.value = false;
          _controlChar = null;
          _filesChar = null;
          _filesSubscription?.cancel();
          _filesSubscription = null;
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
    } finally {
      _isConnecting = false;
    }
  }

  Future<bool> tryAutoConnect() async {
    if (isConnected.value || _isConnecting) return isConnected.value;

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_lastDeviceKey);
    if (id == null) return false;

    final d = BluetoothDevice.fromId(id);
    await connect(d);
    return isConnected.value;
  }


  Future<void> forgetDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastDeviceKey);
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

  Future<void> requestFileList() async {
    if (!isConnected.value) {
      print("requestFileList: not connected");
      return;
    }
    await writeArray([2, 0]);
  }

  void _handleFileNotification(List<int> bytes) {
    if (bytes.isEmpty) return;

    final rawValue = utf8.decode(bytes, allowMalformed: true).trim();
    if (rawValue.isEmpty) return;

    final records = _splitJsonRecords(rawValue);
    for (final record in records) {
      final normalizedRecord = record.trim();
      if (normalizedRecord.isEmpty) continue;

      String? path;
      try {
        final decoded = json.decode(normalizedRecord);
        path = _extractPath(decoded);
      } catch (_) {
        path = _normalizeRawPath(normalizedRecord);
      }

      if (path != null) {
        _filePathController.add(path);
      } else {
        debugPrint('Unhandled file notification payload: $normalizedRecord');
      }
    }
  }

  List<String> _splitJsonRecords(String raw) {
    final records = <String>[];
    int depth = 0;
    bool inString = false;
    bool escaped = false;
    int? recordStart;

    for (var i = 0; i < raw.length; i++) {
      final char = raw[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == '\\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;

      if (char == '{' || char == '[') {
        if (depth == 0) {
          recordStart = i;
        }
        depth++;
      } else if (char == '}' || char == ']') {
        depth--;
        if (depth == 0 && recordStart != null) {
          records.add(raw.substring(recordStart, i + 1));
          recordStart = null;
        }
      }
    }

    if (records.isEmpty) {
      return [raw];
    }
    return records;
  }

  String? _normalizeRawPath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('/') || trimmed.contains('/')) {
      return trimmed.startsWith('/') ? trimmed : '/$trimmed';
    }
    return null;
  }

  String? _extractPath(dynamic decoded) {
    if (decoded is String) {
      return _normalizeRawPath(decoded);
    }

    if (decoded is List || decoded is Iterable) {
      final segments = decoded.cast<String>();
      return '/${segments.join('/')}';
    }

    if (decoded is Map) {
      final knownKeys = [
        'path',
        'filePath',
        'fullPath',
        'pathSegments',
        'segments',
        'name',
        'file',
      ];

      for (final key in knownKeys) {
        if (!decoded.containsKey(key)) continue;
        final pathVal = decoded[key];
        if (pathVal is String) {
          return _normalizeRawPath(pathVal);
        }
        if (pathVal is List) {
          final segments = pathVal.cast<String>();
          return '/${segments.join('/')}';
        }
      }
    }

    return null;
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
      _filesSubscription?.cancel();
      _filesSubscription = null;
      isConnected.value = false;
      _controlChar = null;
      _filesChar = null;
      device = null;
    }
  }
}
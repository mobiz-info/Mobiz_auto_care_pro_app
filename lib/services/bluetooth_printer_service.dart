import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance = BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  static const String keyPrinterMac = 'bt_printer_mac';
  static const String keyPrinterName = 'bt_printer_name';
  static const String keyPaperSize = 'bt_paper_size'; // '3inch' (80mm) or '4inch' (100mm)
  static const String keyAutoPrint = 'bt_auto_print';

  bool _isConnected = false;
  String? _connectedMac;
  String? _connectedName;
  String _paperSize = '3inch';
  bool _autoPrint = false;
  bool _hasPermission = false;

  bool get isConnected => _isConnected;
  String? get connectedMac => _connectedMac;
  String? get connectedName => _connectedName;
  String get paperSize => _paperSize; // '3inch' or '4inch'
  bool get autoPrint => _autoPrint;
  bool get hasPermission => _hasPermission;

  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> permissionNotifier = ValueNotifier<bool>(true);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _connectedMac = prefs.getString(keyPrinterMac);
    _connectedName = prefs.getString(keyPrinterName);
    _paperSize = prefs.getString(keyPaperSize) ?? '3inch';
    _autoPrint = prefs.getBool(keyAutoPrint) ?? false;

    // Check permission first before invoking any hardware calls
    _hasPermission = await checkAndRequestPermissions();
    permissionNotifier.value = _hasPermission;

    if (_hasPermission) {
      await checkConnection();
    }
  }

  /// Checks if required Bluetooth permissions are granted, and requests them if not.
  Future<bool> checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // First check with plugin's non-blocking call
        final bool pluginPermission = await PrintBluetoothThermal.isPermissionBluetoothGranted
            .timeout(const Duration(seconds: 2), onTimeout: () => false);

        if (pluginPermission) {
          _hasPermission = true;
          permissionNotifier.value = true;
          return true;
        }

        // Request Bluetooth permissions using permission_handler
        final statuses = await [
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
        ].request();

        final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
        final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;

        bool granted = connectGranted && scanGranted;

        // On older Android (API < 31), check location permission
        if (!granted) {
          final locationStatus = await Permission.locationWhenInUse.status;
          if (!locationStatus.isGranted) {
            final locRes = await Permission.locationWhenInUse.request();
            if (locRes.isGranted) {
              granted = await PrintBluetoothThermal.isPermissionBluetoothGranted
                  .timeout(const Duration(seconds: 2), onTimeout: () => false);
            }
          }
        }

        _hasPermission = granted;
        permissionNotifier.value = granted;
        return granted;
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.status;
        if (!status.isGranted) {
          final res = await Permission.bluetooth.request();
          _hasPermission = res.isGranted;
          permissionNotifier.value = res.isGranted;
          return res.isGranted;
        }
        _hasPermission = true;
        permissionNotifier.value = true;
        return true;
      }
      _hasPermission = true;
      permissionNotifier.value = true;
      return true;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      _hasPermission = false;
      permissionNotifier.value = false;
      return false;
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<bool> checkConnection() async {
    if (!_hasPermission) {
      _isConnected = false;
      connectionNotifier.value = false;
      return false;
    }

    try {
      final status = await PrintBluetoothThermal.connectionStatus
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      _isConnected = status;
      connectionNotifier.value = status;
      return status;
    } catch (e) {
      debugPrint('Error checking bluetooth connection: $e');
      _isConnected = false;
      connectionNotifier.value = false;
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    if (!_hasPermission) return false;

    try {
      return await PrintBluetoothThermal.bluetoothEnabled
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (e) {
      debugPrint('Error checking bluetooth enabled: $e');
      return false;
    }
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    if (!_hasPermission) return [];

    try {
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths
          .timeout(const Duration(seconds: 4), onTimeout: () => []);
      return devices;
    } catch (e) {
      debugPrint('Error fetching paired bluetooth devices: $e');
      return [];
    }
  }

  Future<bool> connect(String macAddress, {String? deviceName}) async {
    if (!_hasPermission) {
      final granted = await checkAndRequestPermissions();
      if (!granted) return false;
    }

    try {
      if (_isConnected) {
        await disconnect();
      }

      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress)
          .timeout(const Duration(seconds: 6), onTimeout: () => false);
      _isConnected = result;
      connectionNotifier.value = result;

      if (result) {
        _connectedMac = macAddress;
        if (deviceName != null) _connectedName = deviceName;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyPrinterMac, macAddress);
        if (deviceName != null) {
          await prefs.setString(keyPrinterName, deviceName);
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error connecting to bluetooth printer: $e');
      _isConnected = false;
      connectionNotifier.value = false;
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      _isConnected = false;
      connectionNotifier.value = false;
      return result;
    } catch (e) {
      debugPrint('Error disconnecting bluetooth printer: $e');
      _isConnected = false;
      connectionNotifier.value = false;
      return false;
    }
  }

  Future<void> setPaperSize(String size) async {
    _paperSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyPaperSize, size);
  }

  Future<void> setAutoPrint(bool value) async {
    _autoPrint = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAutoPrint, value);
  }

  Future<bool> printBytes(List<int> bytes) async {
    if (!_hasPermission) {
      final granted = await checkAndRequestPermissions();
      if (!granted) return false;
    }

    try {
      final bool connected = await checkConnection();
      if (!connected) {
        if (_connectedMac != null && _connectedMac!.isNotEmpty) {
          final reconnected = await connect(_connectedMac!, deviceName: _connectedName);
          if (!reconnected) return false;
        } else {
          return false;
        }
      }
      final bool result = await PrintBluetoothThermal.writeBytes(bytes)
          .timeout(const Duration(seconds: 8), onTimeout: () => false);
      return result;
    } catch (e) {
      debugPrint('Error printing bytes: $e');
      return false;
    }
  }
}

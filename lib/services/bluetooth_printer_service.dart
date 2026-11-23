import 'dart:async';
import 'package:flutter/foundation.dart';
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

  bool get isConnected => _isConnected;
  String? get connectedMac => _connectedMac;
  String? get connectedName => _connectedName;
  String get paperSize => _paperSize; // '3inch' or '4inch'
  bool get autoPrint => _autoPrint;

  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(false);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _connectedMac = prefs.getString(keyPrinterMac);
    _connectedName = prefs.getString(keyPrinterName);
    _paperSize = prefs.getString(keyPaperSize) ?? '3inch';
    _autoPrint = prefs.getBool(keyAutoPrint) ?? false;

    await checkConnection();
  }

  Future<bool> checkConnection() async {
    try {
      final status = await PrintBluetoothThermal.connectionStatus;
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
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      debugPrint('Error checking bluetooth enabled: $e');
      return false;
    }
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices;
    } catch (e) {
      debugPrint('Error fetching paired bluetooth devices: $e');
      return [];
    }
  }

  Future<bool> connect(String macAddress, {String? deviceName}) async {
    try {
      // Disconnect if already connected to another device
      if (_isConnected) {
        await disconnect();
      }

      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
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
      final bool result = await PrintBluetoothThermal.disconnect;
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
    try {
      final bool connected = await checkConnection();
      if (!connected) {
        // Try to reconnect if saved mac exists
        if (_connectedMac != null && _connectedMac!.isNotEmpty) {
          final reconnected = await connect(_connectedMac!, deviceName: _connectedName);
          if (!reconnected) return false;
        } else {
          return false;
        }
      }
      final bool result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      debugPrint('Error printing bytes: $e');
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../services/bluetooth_printer_service.dart';
import '../utils/thermal_receipt_generator.dart';
import '../providers/language_provider.dart';

class BluetoothPrinterScreen extends StatefulWidget {
  const BluetoothPrinterScreen({super.key});

  @override
  State<BluetoothPrinterScreen> createState() => _BluetoothPrinterScreenState();
}

class _BluetoothPrinterScreenState extends State<BluetoothPrinterScreen> {
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  bool _isLoading = false;
  bool _isBluetoothEnabled = true;
  List<BluetoothInfo> _pairedDevices = [];
  String _selectedPaperSize = '3inch';
  bool _autoPrint = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    setState(() => _isLoading = true);
    await _printerService.init();
    _selectedPaperSize = _printerService.paperSize;
    _autoPrint = _printerService.autoPrint;
    await _refreshDevices();
    setState(() => _isLoading = false);
  }

  Future<void> _refreshDevices() async {
    final btEnabled = await _printerService.isBluetoothEnabled();
    _isBluetoothEnabled = btEnabled;
    if (btEnabled) {
      final devices = await _printerService.getPairedDevices();
      setState(() {
        _pairedDevices = devices;
      });
    } else {
      setState(() {
        _pairedDevices = [];
      });
    }
  }

  Future<void> _connectToDevice(BluetoothInfo device) async {
    setState(() => _isLoading = true);
    final success = await _printerService.connect(device.macAdress, deviceName: device.name);
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('Connected to')} ${device.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Failed to connect to printer. Please check if printer is ON.')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    await _printerService.disconnect();
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Printer disconnected')),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _onPaperSizeChanged(String size) async {
    setState(() => _selectedPaperSize = size);
    await _printerService.setPaperSize(size);
  }

  Future<void> _onAutoPrintChanged(bool value) async {
    setState(() => _autoPrint = value);
    await _printerService.setAutoPrint(value);
  }

  Future<void> _printTestReceipt() async {
    final connected = await _printerService.checkConnection();
    if (!connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Please connect to a printer first')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await ThermalReceiptGenerator.generateTestReceipt(
        paperSize: _selectedPaperSize,
      );
      final success = await _printerService.printBytes(bytes);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('Test receipt printed successfully!')),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('Failed to print test receipt')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _printerService.isConnected;
    final connectedName = _printerService.connectedName ?? 'Unknown Printer';
    final connectedMac = _printerService.connectedMac ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          context.tr('Bluetooth Printer Setup'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDevices,
            tooltip: context.tr('Refresh Devices'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                // ── 1. Bluetooth Status & Warning ────────────────────────────
                if (!_isBluetoothEnabled)
                  Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bluetooth_disabled, color: Colors.red.shade700, size: 28.sp),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            context.tr('Bluetooth is turned off. Please turn on Bluetooth in device settings.'),
                            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── 2. Connection Status Banner ──────────────────────────────
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: isConnected ? Colors.green.shade50 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isConnected ? Icons.print : Icons.print_disabled,
                          color: isConnected ? Colors.green.shade700 : Colors.grey.shade500,
                          size: 26.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isConnected ? context.tr('Printer Connected') : context.tr('No Printer Connected'),
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: isConnected ? Colors.green.shade800 : Colors.grey.shade800,
                              ),
                            ),
                            if (isConnected) ...[
                              SizedBox(height: 2.h),
                              Text(
                                '$connectedName ($connectedMac)',
                                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade600),
                              ),
                            ] else ...[
                              SizedBox(height: 2.h),
                              Text(
                                context.tr('Select a paired printer below to connect'),
                                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isConnected)
                        TextButton(
                          onPressed: _disconnect,
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text(context.tr('Disconnect')),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // ── 3. Paper Size Selection ──────────────────────────────────
                Text(
                  context.tr('THERMAL PAPER SIZE'),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: '3inch',
                        groupValue: _selectedPaperSize,
                        onChanged: (val) {
                          if (val != null) _onPaperSizeChanged(val);
                        },
                        title: Text(
                          context.tr('3 Inch (80mm) — Standard POS'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.sp),
                        ),
                        subtitle: Text(
                          context.tr('Most common portable & desktop receipt printer format'),
                          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                        ),
                        activeColor: const Color(0xFF000080),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        value: '4inch',
                        groupValue: _selectedPaperSize,
                        onChanged: (val) {
                          if (val != null) _onPaperSizeChanged(val);
                        },
                        title: Text(
                          context.tr('4 Inch (100mm / 112mm) — Wide Format'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.sp),
                        ),
                        subtitle: Text(
                          context.tr('Extra wide paper with detailed rate & discount columns'),
                          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                        ),
                        activeColor: const Color(0xFF000080),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // ── 4. Quick Thermal Print Preference ────────────────────────
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _autoPrint,
                    onChanged: _onAutoPrintChanged,
                    title: Text(
                      context.tr('One-Tap Thermal Print'),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.sp),
                    ),
                    subtitle: Text(
                      context.tr('Tapping Print in Bills directly prints without showing options dialog'),
                      style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                    ),
                    activeColor: const Color(0xFF000080),
                  ),
                ),
                SizedBox(height: 20.h),

                // ── 5. Test Print Action ─────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: isConnected ? _printTestReceipt : null,
                  icon: const Icon(Icons.receipt_long),
                  label: Text(
                    context.tr('Print Test Receipt'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(height: 24.h),

                // ── 6. Paired Bluetooth Devices ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('PAIRED BLUETOOTH DEVICES'),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _refreshDevices,
                      icon: Icon(Icons.refresh, size: 14.sp),
                      label: Text(context.tr('Refresh'), style: GoogleFonts.inter(fontSize: 12.sp)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF000080)),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                if (_pairedDevices.isEmpty)
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.bluetooth_searching, size: 40.sp, color: Colors.grey.shade400),
                        SizedBox(height: 10.h),
                        Text(
                          context.tr('No paired Bluetooth devices found'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.grey.shade700),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          context.tr('Please turn ON your thermal printer and pair it in your phone\'s Bluetooth Settings first.'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                else
                  ..._pairedDevices.map((device) {
                    final bool isThisDeviceConnected = isConnected && connectedMac == device.macAdress;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: isThisDeviceConnected ? Border.all(color: Colors.green, width: 1.5) : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isThisDeviceConnected ? Colors.green.shade50 : const Color(0xFFEFF6FF),
                          child: Icon(
                            Icons.print,
                            color: isThisDeviceConnected ? Colors.green : const Color(0xFF000080),
                            size: 20.sp,
                          ),
                        ),
                        title: Text(
                          device.name.isNotEmpty ? device.name : 'Unknown Device',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.sp),
                        ),
                        subtitle: Text(
                          device.macAdress,
                          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                        ),
                        trailing: isThisDeviceConnected
                            ? Chip(
                                label: Text(
                                  context.tr('Connected'),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: Colors.green.shade50,
                                side: BorderSide(color: Colors.green.shade200),
                              )
                            : OutlinedButton(
                                onPressed: () => _connectToDevice(device),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF000080),
                                  side: const BorderSide(color: Color(0xFF000080)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                ),
                                child: Text(context.tr('Connect'), style: GoogleFonts.inter(fontSize: 12.sp)),
                              ),
                      ),
                    );
                  }),
                SizedBox(height: 40.h),
              ],
            ),
    );
  }
}

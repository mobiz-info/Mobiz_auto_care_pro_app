import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String appName = "Mobiz Auto Care Pro";
  static const String appIconPath = "assets/icons/mobiz_logo.png";
  // Use 10.0.2.2 for Android Emulator, or your local IP if on a real device
  // static const String baseUrl = "http://10.54.237.238:8000/api";
  static const String baseUrl = "http://68.183.94.11:78/api";

  static final Map<String, String> _modelToTypeMap = {};

  static Map<String, dynamic> _decodeJobCardResponse(http.Response response) {
    if (response.statusCode == 413) {
      return {
        'success': false,
        'message':
            'The Job Card upload is too large. Reduce the number or size of issue photos and try again.',
      };
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {
        'success': false,
        'message': 'Unexpected server response (${response.statusCode}).',
      };
    } on FormatException {
      return {
        'success': false,
        'message':
            'The server returned an unreadable response (${response.statusCode}). Please try again or contact support.',
      };
    }
  }

  static Future<void> ensureModelToTypeMap(String token) async {
    if (_modelToTypeMap.isNotEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/form-data/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['success'] == true) {
          final models = res['vehicle_models'] as List<dynamic>;
          for (final m in models) {
            final modelName = m['name'] as String;
            final typeName = m['vehicle_type'] as String;
            _modelToTypeMap[modelName] = typeName;
          }
        }
      }
    } catch (_) {}
  }

  static Map<String, dynamic> _mapVehicleTypesInResponse(
    Map<String, dynamic> data,
  ) {
    if (data['customer'] != null && data['customer']['vehicles'] != null) {
      final vehicles = data['customer']['vehicles'] as List<dynamic>;
      for (final v in vehicles) {
        if (v is Map) {
          final typeVal = v['vehicle_type']?.toString() ?? '';
          if (typeVal.isEmpty) {
            final modelName = (v['type'] ?? v['vehicle_model_name'] ?? '')
                .toString();
            if (modelName.isNotEmpty) {
              v['vehicle_type'] = _modelToTypeMap[modelName] ?? '';
            }
          }
        }
      }
    }
    if (data['vehicle'] != null) {
      final v = data['vehicle'];
      if (v is Map) {
        final typeVal = v['vehicle_type']?.toString() ?? '';
        if (typeVal.isEmpty) {
          final modelName = (v['model'] ?? '').toString();
          if (modelName.isNotEmpty) {
            v['vehicle_type'] = _modelToTypeMap[modelName] ?? '';
          }
        }
      }
    }
    return data;
  }
  // "http://10.17.6.238:8000/api";
  // 'http://68.183.94.11:78/api';
  // http://172.20.10.5:8000/api
  // Update this to 'http://10.0.2.2:8000/api' if testing on Android Emulator

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    print(response.body);
    print(response.statusCode);
    if (response.statusCode == 200 ||
        response.statusCode == 401 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<void> pingAppOpen(String token) async {
    try {
      await http.get(
        Uri.parse('$baseUrl/user/ping/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> searchCustomer(
    String query,
    String token, {
    String? branchId,
    bool isVehicle = false,
  }) async {
    await ensureModelToTypeMap(token);
    String url = '$baseUrl/customer/search/?';
    if (isVehicle) {
      url += 'vehicle_number=${Uri.encodeComponent(query)}';
    } else {
      url += 'mobile=${Uri.encodeComponent(query)}';
    }
    if (branchId != null && branchId.isNotEmpty) {
      url += '&branch_id=${Uri.encodeComponent(branchId)}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 ||
        response.statusCode == 404 ||
        response.statusCode == 401) {
      return _mapVehicleTypesInResponse(jsonDecode(response.body));
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> searchCustomerList(
    String query,
    String token, {
    String? branchId,
  }) async {
    final queryParameters = <String, String>{'q': query};
    if (branchId != null && branchId.isNotEmpty) {
      queryParameters['branch_id'] = branchId;
    }
    final uri = Uri.parse(
      '$baseUrl/customer/search-list/',
    ).replace(queryParameters: queryParameters);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> getInvoiceServices(
    dynamic customerId,
    dynamic vehicleId,
    String token,
  ) async {
    final cId = customerId?.toString() ?? '';
    final vId = vehicleId?.toString() ?? '';
    final response = await http.get(
      Uri.parse('$baseUrl/invoice/services/?customer_id=$cId&vehicle_id=$vId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> createInvoice(
    Map<String, dynamic> invoiceData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoice/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(invoiceData),
    );

    try {
      final res = jsonDecode(response.body);
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (_) {}

    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to connect to the server (${response.statusCode}).',
      );
    }
  }

  static Future<Map<String, dynamic>> updateInvoice(
    String invoiceId,
    Map<String, dynamic> invoiceData,
    String token,
  ) async {
    final payload = {'invoice_id': invoiceId, ...invoiceData};
    final response = await http.post(
      Uri.parse('$baseUrl/invoice/update/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    try {
      final res = jsonDecode(response.body);
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (_) {}

    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to connect to the server (${response.statusCode}).',
      );
    }
  }

  static Future<Map<String, dynamic>> sendInvoiceWhatsApp(
    String invoiceId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoice/send-whatsapp/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'invoice_id': invoiceId}),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> getFormData(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/customer/form-data/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> getBatteries(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/batteries/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load batteries.');
    }
  }

  static Future<Map<String, dynamic>> addCustomer(
    Map<String, dynamic> data,
    String token,
  ) async {
    await ensureModelToTypeMap(token);
    final response = await http.post(
      Uri.parse('$baseUrl/customer/add/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 401) {
      return _mapVehicleTypesInResponse(jsonDecode(response.body));
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> listCustomers(
    String token, {
    String? search,
  }) async {
    String url = '$baseUrl/customer/list/';
    if (search != null && search.isNotEmpty) {
      url += '?q=${Uri.encodeComponent(search)}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load customers.');
    }
  }

  static Future<Map<String, dynamic>> getInactiveCustomers(
    String token, {
    int days = 60,
  }) async {
    final url = '$baseUrl/customer/inactive/?days=$days';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load inactive customers.');
    }
  }

  static Future<Map<String, dynamic>> getWhatsAppTemplates(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/whatsapp/templates/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load WhatsApp templates.');
    }
  }

  static Future<Map<String, dynamic>> sendWhatsAppBroadcast(
    String token, {
    required String recipientType,
    required String message,
    String var2 = '',
    String templateName = '',
    List<String> customerIds = const [],
    int inactiveDays = 60,
  }) async {
    final body = jsonEncode({
      'recipient_type': recipientType,
      'message': message,
      'var_2': var2,
      'template_name': templateName,
      'customer_ids': customerIds,
      'inactive_days': inactiveDays,
    });
    final response = await http.post(
      Uri.parse('$baseUrl/whatsapp/broadcast/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send broadcast.');
    }
  }

  static Future<Map<String, dynamic>> searchVehicle(
    String vehicleNumber,
    String token,
  ) async {
    await ensureModelToTypeMap(token);
    final response = await http.get(
      Uri.parse('$baseUrl/vehicle/search/?vehicle_number=$vehicleNumber'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 ||
        response.statusCode == 404 ||
        response.statusCode == 401) {
      return _mapVehicleTypesInResponse(jsonDecode(response.body));
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> searchVehicleList(
    String query,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vehicle/search-list/?q=$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> getReminderPlans(
    String token, {
    String? date,
    String? search,
  }) async {
    String url = '$baseUrl/booking/reminder/list/';
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (date == null || date == 'all') params['show_all'] = 'true';
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> sendReminders(
    String token,
    List<String> planIds, {
    String? action,
    String? templateName,
    Map<String, dynamic>? planDetails,
  }) async {
    final Map<String, dynamic> bodyPayload = {
      'plan_ids': planIds,
      if (action != null) 'action': action,
      'template_name': templateName ?? 'wheelalignment',
      'wawy_template_name': templateName ?? 'wheelalignment',
      'name': templateName ?? 'wheelalignment',
    };

    if (planDetails != null) {
      final custName = (planDetails['customer_name'] ?? '').toString();
      final vehicleNum = (planDetails['vehicle_number'] ?? '').toString();
      final serviceName = (planDetails['service_name'] ?? '').toString();
      final nextKm =
          (planDetails['next_alignment_km'] ??
                  planDetails['next_oil_change_km'] ??
                  planDetails['next_km'] ??
                  planDetails['due_km'] ??
                  '')
              .toString();

      bodyPayload['value1'] = custName;
      bodyPayload['value2'] = vehicleNum;
      bodyPayload['value3'] = serviceName;
      bodyPayload['value4'] = nextKm;
      bodyPayload['var1'] = custName;
      bodyPayload['var2'] = vehicleNum;
      bodyPayload['var3'] = serviceName;
      bodyPayload['var4'] = nextKm;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/booking/reminder/send/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyPayload),
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<bool> sendWawyReminderDirect({
    required String toPhone,
    String templateName = 'wheelalignment',
    required String value1,
    required String value2,
    required String value3,
    required String value4,
  }) async {
    try {
      String cleanedPhone = toPhone.replaceAll(RegExp(r'\D'), '');
      if (cleanedPhone.length == 10) {
        cleanedPhone = '91$cleanedPhone';
      }
      if (cleanedPhone.isEmpty) return false;

      final url = Uri.parse(
        'http://wawy.org/pushwhatsapp.php?'
        'sender=919496007007&'
        'priority=21&'
        'name=${Uri.encodeComponent(templateName)}&'
        'to=${Uri.encodeComponent(cleanedPhone)}&'
        'value1=${Uri.encodeComponent(value1)}&'
        'value2=${Uri.encodeComponent(value2)}&'
        'value3=${Uri.encodeComponent(value3)}&'
        'value4=${Uri.encodeComponent(value4)}',
      );

      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> listBookings(
    String token, {
    String? fromDate,
    String? toDate,
    String? serviceId,
  }) async {
    String url = '$baseUrl/booking/list/';
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (serviceId != null && serviceId != 'all')
      params['service_id'] = serviceId;
    if (params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    String status,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/$bookingId/status/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> sendBookingReadyAlert(
    String bookingId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/$bookingId/ready-alert/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> sendVehicleReadyAlertGeneric({
    required String phone,
    required String vehicleNumber,
    required String customerName,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/ready-alert/generic/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'phone': phone,
        'vehicle_number': vehicleNumber,
        'customer_name': customerName,
      }),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> sendOilReminderGeneric({
    required String phone,
    required String vehicleNumber,
    required String customerName,
    required String nextOilChangeKm,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/oil-reminder/generic/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'phone': phone,
        'vehicle_number': vehicleNumber,
        'customer_name': customerName,
        'next_oil_change_km': nextOilChangeKm,
      }),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> sendVehicleWelcomeMessageGeneric({
    required String phone,
    required String vehicleNumber,
    required String customerName,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/welcome-msg/generic/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'phone': phone,
        'vehicle_number': vehicleNumber,
        'customer_name': customerName,
      }),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> sendVehicleThanksMessageGeneric({
    required String phone,
    required String vehicleNumber,
    required String customerName,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/thanks-msg/generic/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'phone': phone,
        'vehicle_number': vehicleNumber,
        'customer_name': customerName,
      }),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> getBranchSchemes(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/schemes/branch/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> getCompanyBranches(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/company/branches/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load branches.');
    }
  }

  static Future<Map<String, dynamic>> getSchemeOptions(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/schemes/options/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 ||
        response.statusCode == 401 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load scheme options.');
    }
  }

  static Future<Map<String, dynamic>> createScheme(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/schemes/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 401 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create scheme.');
    }
  }

  static Future<Map<String, dynamic>> listInvoices(
    String token, {
    String? invoiceId,
    String? fromDate,
    String? toDate,
    String? paymentMode,
  }) async {
    String url = '$baseUrl/invoice/list/';
    final params = <String, String>{};
    if (invoiceId != null && invoiceId.isNotEmpty)
      params['invoice_id'] = invoiceId;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (paymentMode != null && paymentMode.isNotEmpty)
      params['payment_mode'] = paymentMode;
    if (params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats(
    String token, {
    String? branchId,
  }) async {
    String url = '$baseUrl/dashboard/stats/';
    if (branchId != null && branchId.isNotEmpty) {
      url += '?branch_id=${Uri.encodeComponent(branchId)}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to the server.');
    }
  }

  static Future<Map<String, dynamic>> getAvailableSchemes(
    dynamic customerId,
    dynamic vehicleId,
    dynamic serviceId,
    String token,
  ) async {
    final cId = customerId?.toString() ?? '';
    final vId = vehicleId?.toString() ?? '';
    final sId = serviceId?.toString() ?? '';
    final response = await http.get(
      Uri.parse('$baseUrl/schemes/available/').replace(
        queryParameters: {
          'customer_id': cId,
          'vehicle_id': vId,
          'service_id': sId,
        },
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load schemes.');
    }
  }

  /// Validate a voucher number for a scheme and return the discount amount.
  static Future<Map<String, dynamic>> validateVoucher(
    String schemeId,
    String voucherNumber,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/schemes/validate-voucher/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'scheme_id': schemeId,
        'voucher_number': voucherNumber,
      }),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to validate voucher.');
    }
  }

  /// Outstanding invoices list
  static Future<Map<String, dynamic>> getOutstandingList(
    String token, {
    String? fromDate,
    String? toDate,
    String? branchId,
  }) async {
    String url = '$baseUrl/outstanding/list/';
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load outstanding list.');
    }
  }

  static Future<Map<String, dynamic>> getReceiptList(
    String token, {
    String? fromDate,
    String? toDate,
    String? branchId,
    String? paymentMode,
  }) async {
    String url = '$baseUrl/receipt/list/';
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    if (paymentMode != null && paymentMode.isNotEmpty)
      params['payment_mode'] = paymentMode;
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load receipts.');
    }
  }

  /// Collect payment for an invoice
  static Future<Map<String, dynamic>> collectPayment({
    required String invoiceId,
    required double amount,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/outstanding/collect/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'invoice_id': invoiceId, 'amount': amount}),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to collect payment.');
    }
  }

  /// Fetch customer outstanding list (customer-wise totals)
  static Future<Map<String, dynamic>> getCustomerOutstandingList(
    String token, {
    String? fromDate,
    String? toDate,
    String? branchId,
  }) async {
    String url = '$baseUrl/outstanding/customer-list/';
    final params = <String, String>{};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load customer outstanding list.');
    }
  }

  /// Collect bulk payment sequentially for customer's outstanding invoices
  static Future<Map<String, dynamic>> collectCustomerOutstanding({
    required String customerId,
    required double amount,
    required String paymentMode,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/outstanding/customer-collect/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'customer_id': customerId,
        'amount': amount,
        'payment_mode': paymentMode,
      }),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to collect customer payment.');
    }
  }

  /// Fetch full customer details for editing
  static Future<Map<String, dynamic>> getCustomer(
    String customerId,
    String token,
  ) async {
    await ensureModelToTypeMap(token);
    final response = await http.get(
      Uri.parse('$baseUrl/customer/get/?customer_id=$customerId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404 ||
        response.statusCode == 401) {
      return _mapVehicleTypesInResponse(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load customer.');
    }
  }

  /// Update customer details (name, type, whatsapp, email, address, add vehicles)
  static Future<Map<String, dynamic>> editCustomer(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customer/edit/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update customer.');
    }
  }

  static Future<Map<String, dynamic>> deleteCustomer(
    String customerId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customer/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'customer_id': customerId}),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404 ||
        response.statusCode == 401 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete customer.');
    }
  }

  /// Soft-delete an invoice and all its associated receipts.
  static Future<Map<String, dynamic>> deleteInvoice(
    String invoiceId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoice/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'invoice_id': invoiceId}),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete invoice.');
    }
  }

  /// Soft-delete a receipt and restore the invoice outstanding balance.
  static Future<Map<String, dynamic>> deleteReceipt(
    String receiptId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/receipt/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'receipt_id': receiptId}),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete receipt.');
    }
  }

  /// Get credit note pre-population info for an invoice
  static Future<Map<String, dynamic>> getCreditNoteInfo(
    String invoiceId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/credit-notes/info/?invoice_id=$invoiceId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get credit note info.');
    }
  }

  /// Create a credit note for an invoice
  static Future<Map<String, dynamic>> createCreditNote(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/credit-notes/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 403 ||
        response.statusCode == 404 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create credit note.');
    }
  }

  static Future<Map<String, dynamic>> _reportGet(
    String path,
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
    String? paymentMode,
    String? category,
  }) async {
    final params = <String, String>{'from_date': fromDate, 'to_date': toDate};
    if (branchId != null && branchId.isNotEmpty) {
      params['branch_id'] = branchId;
    }
    if (paymentMode != null && paymentMode.isNotEmpty) {
      params['payment_mode'] = paymentMode;
    }
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    final response = await http.get(
      Uri.parse('$baseUrl/$path').replace(queryParameters: params),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load report.');
  }

  static Future<Map<String, dynamic>> getJobReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
    String? category,
  }) => _reportGet(
    'reports/jobs/',
    token,
    fromDate,
    toDate,
    branchId: branchId,
    category: category,
  );

  static Future<Map<String, dynamic>> getSchemeBeneficiaryReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
  }) => _reportGet(
    'reports/scheme-beneficiary/',
    token,
    fromDate,
    toDate,
    branchId: branchId,
  );

  static Future<Map<String, dynamic>> getCollectionReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
    String? paymentMode,
  }) => _reportGet(
    'reports/collection/',
    token,
    fromDate,
    toDate,
    branchId: branchId,
    paymentMode: paymentMode,
  );

  static Future<Map<String, dynamic>> getOutstandingReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
  }) => _reportGet(
    'reports/outstanding/',
    token,
    fromDate,
    toDate,
    branchId: branchId,
  );

  static Future<Map<String, dynamic>> getDaywiseConsolidatedReport(
    String token,
    String type,
    String fromDate,
    String toDate, {
    String? branchId,
  }) async {
    final params = <String, String>{
      'type': type,
      'from_date': fromDate,
      'to_date': toDate,
    };
    if (branchId != null && branchId.isNotEmpty) {
      params['branch_id'] = branchId;
    }
    final response = await http.get(
      Uri.parse('$baseUrl/reports/daywise/').replace(queryParameters: params),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load daywise report.');
  }

  static Future<Map<String, dynamic>> getBookingReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
  }) => _reportGet(
    'reports/bookings/',
    token,
    fromDate,
    toDate,
    branchId: branchId,
  );

  static Future<Map<String, dynamic>> getCancellationReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
  }) => _reportGet(
    'reports/cancellations/',
    token,
    fromDate,
    toDate,
    branchId: branchId,
  );

  static Future<Map<String, dynamic>> getServiceTypeReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
  }) => _reportGet(
    'reports/service-type/',
    token,
    fromDate,
    toDate,
    branchId: branchId,
  );

  static Future<Map<String, dynamic>> getStockConsumptionReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
  }) => _reportGet(
    'reports/stock-consumption/',
    token,
    fromDate,
    toDate,
    branchId: branchId,
  );

  static Future<Map<String, dynamic>> getStaffIncomeReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
    String? staffId,
  }) async {
    final query = <String, String>{
      'from_date': fromDate,
      'to_date': toDate,
      if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      if (staffId != null && staffId.isNotEmpty) 'staff_id': staffId,
    };
    final uri = Uri.parse(
      '$baseUrl/reports/staff-income/',
    ).replace(queryParameters: query);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load staff income report.');
  }

  static Future<Map<String, dynamic>> listComplaintTypes(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/complaint-types/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load complaint types.');
    }
  }

  static Future<Map<String, dynamic>> createComplaintType(
    String token,
    String name,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/complaint-types/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create complaint type.');
    }
  }

  static Future<Map<String, dynamic>> createComplaint({
    required String token,
    required String complaintTypeId,
    required String priority,
    required String complaint,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/complaints/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'complaint_type_id': complaintTypeId,
        'priority': priority,
        'complaint': complaint,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create complaint.');
    }
  }

  static Future<Map<String, dynamic>> listComplaints(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/complaints/list/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load complaints.');
    }
  }

  static Future<Map<String, dynamic>> updateComplaintStatus({
    required String token,
    required String complaintId,
    required String status,
    String? remarks,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/complaints/update-status/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'complaint_id': complaintId,
        'status': status,
        if (remarks != null) 'remarks': remarks,
      }),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update complaint status.');
    }
  }

  static Future<Map<String, dynamic>> getExpenseHeads(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/expenses/heads/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load expense heads.');
    }
  }

  static Future<Map<String, dynamic>> getExpenseItemsByHead(
    String token,
    String headId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/expenses/items-by-head/?expense_head_id=$headId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load expense items.');
    }
  }

  static Future<Map<String, dynamic>> createExpenseEntry(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    try {
      final res = jsonDecode(response.body);
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}
    throw Exception(
      'Failed to create expense (Status: ${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> deleteExpenseEntry(
    String token,
    String id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id}),
    );
    try {
      final res = jsonDecode(response.body);
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}
    throw Exception(
      'Failed to delete expense (Status: ${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> getPurchaseExpensesList(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/purchase-expenses/list/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load purchase expenses.');
    }
  }

  static Future<Map<String, dynamic>> updatePurchaseExpensePayment(
    String token,
    String id,
    double additionalPaid,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/purchase-expenses/update-payment/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id, 'additional_paid': additionalPaid}),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update payment.');
    }
  }

  static Future<Map<String, dynamic>> getSuppliersList(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/supplier/list/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load suppliers.');
    }
  }

  static Future<Map<String, dynamic>> createSupplier(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/supplier/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save supplier.');
    }
  }

  static Future<Map<String, dynamic>> deleteSupplier(
    String token,
    String id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/supplier/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id}),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete supplier.');
    }
  }

  static Future<Map<String, dynamic>> getStaffList(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/staff/list/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load staff list.');
    }
  }

  static Future<Map<String, dynamic>> getStaffLeaves(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/staff/leaves/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load staff leaves.');
    }
  }

  static Future<Map<String, dynamic>> createStaffLeave(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/staff/leaves/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to record staff leave.');
    }
  }

  static Future<Map<String, dynamic>> getStockList(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/stock/list/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load stock list.');
    }
  }

  static Future<Map<String, dynamic>> getStockGroups(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/stock-groups/list/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load stock groups.');
    }
  }

  static Future<Map<String, dynamic>> adjustStock({
    required String stockId,
    required String transactionType, // 'in' or 'out'
    required double quantity,
    String reason = 'other',
    String notes = '',
    double unitCost = 0.0,
    String? referenceNumber,
    String? branchId,
    required String token,
  }) async {
    final bodyMap = <String, dynamic>{
      'stock_id': stockId,
      'transaction_type': transactionType,
      'quantity': quantity,
      'reason': reason,
      'notes': notes,
      'unit_cost': unitCost,
      if (referenceNumber != null && referenceNumber.isNotEmpty)
        'reference_number': referenceNumber,
    };
    if (branchId != null && branchId.isNotEmpty) {
      bodyMap['branch_id'] = branchId;
    }
    final response = await http.post(
      Uri.parse('$baseUrl/stock/adjust/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyMap),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Failed to adjust stock.');
  }

  static Future<Map<String, dynamic>> getStockTransactions({
    String? stockId,
    String? transactionType,
    int limit = 50,
    required String token,
  }) async {
    String url = '$baseUrl/stock/transactions/?limit=$limit';
    if (stockId != null && stockId.isNotEmpty) {
      url += '&stock_id=$stockId';
    }
    if (transactionType != null && transactionType.isNotEmpty) {
      url += '&transaction_type=$transactionType';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load stock transactions.');
  }

  static Future<Map<String, dynamic>> getPurchaseRequests(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/purchase-requests/list/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load purchase requests.');
    }
  }

  static Future<Map<String, dynamic>> createPurchaseRequest(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/purchase-requests/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit purchase request.');
    }
  }

  static Future<Map<String, dynamic>> createExpenseHead(
    String token,
    String name,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses/heads/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create expense head.');
    }
  }

  static Future<Map<String, dynamic>> createStock(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stock/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create stock item.');
    }
  }

  static Future<Map<String, dynamic>> editStock(
    String token,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stock/edit/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to edit stock item.');
    }
  }

  static Future<Map<String, dynamic>> editExpenseHead(
    String token,
    String id,
    String name,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses/heads/edit/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to edit expense head.');
    }
  }

  static Future<Map<String, dynamic>> deleteExpenseHead(
    String token,
    String id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses/heads/delete/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete expense head.');
    }
  }

  static Future<Map<String, dynamic>> deleteStock(
    String token,
    String id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stock/delete/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete stock item.');
    }
  }

  static Future<Map<String, dynamic>> getExtrasList(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/extras/list/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load extras list.');
    }
  }

  static Future<Map<String, dynamic>> createExtra(
    String token,
    String name, {
    String? serviceTypeId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/extras/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        if (serviceTypeId != null && serviceTypeId.isNotEmpty)
          'service_type_id': serviceTypeId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create extra item.');
    }
  }

  static Future<Map<String, dynamic>> deleteExtra(
    String token,
    String id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/extras/delete/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete extra item.');
    }
  }

  static Future<Map<String, dynamic>> getServiceCategories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/service-categories/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load service categories.');
    }
  }

  static Future<Map<String, dynamic>> getExpenseHeadWiseReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
  }) async {
    final params = <String, String>{'from_date': fromDate, 'to_date': toDate};
    if (branchId != null && branchId.isNotEmpty) {
      params['branch_id'] = branchId;
    }
    final url = Uri.parse(
      '$baseUrl/reports/expense-head-wise/',
    ).replace(queryParameters: params);
    print('DEBUG getExpenseHeadWiseReport URL: $url');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('DEBUG getExpenseHeadWiseReport STATUS: ${response.statusCode}');
    print('DEBUG getExpenseHeadWiseReport BODY: ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
      'Failed to load expense head report (status: ${response.statusCode}, body: ${response.body}).',
    );
  }

  static Future<Map<String, dynamic>> getExpenseHeadDetailReport(
    String token,
    String expenseHeadId,
    String fromDate,
    String toDate, {
    String? branchId,
  }) async {
    final params = <String, String>{
      'expense_head_id': expenseHeadId,
      'from_date': fromDate,
      'to_date': toDate,
    };
    if (branchId != null && branchId.isNotEmpty) {
      params['branch_id'] = branchId;
    }
    final url = Uri.parse(
      '$baseUrl/reports/expense-head-wise/detail/',
    ).replace(queryParameters: params);
    print('DEBUG getExpenseHeadDetailReport URL: $url');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('DEBUG getExpenseHeadDetailReport STATUS: ${response.statusCode}');
    print('DEBUG getExpenseHeadDetailReport BODY: ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
      'Failed to load expense head detail report (status: ${response.statusCode}, body: ${response.body}).',
    );
  }

  static Future<Map<String, dynamic>> getAllExpenses(
    String token, {
    String search = '',
    String? branchId,
    String? fromDate,
    String? toDate,
  }) async {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    if (fromDate != null && fromDate.isNotEmpty) params['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) params['to_date'] = toDate;
    final url = Uri.parse(
      '$baseUrl/expenses/list/',
    ).replace(queryParameters: params);
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load expenses list.');
  }

  static Future<Map<String, dynamic>> getLeaveReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
  }) async {
    final params = <String, String>{'from_date': fromDate, 'to_date': toDate};
    if (branchId != null && branchId.isNotEmpty) {
      params['branch_id'] = branchId;
    }
    final url = Uri.parse(
      '$baseUrl/reports/leave/',
    ).replace(queryParameters: params);
    print('DEBUG getLeaveReport URL: $url');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('DEBUG getLeaveReport STATUS: ${response.statusCode}');
    print('DEBUG getLeaveReport BODY: ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
      'Failed to load leave report (status: ${response.statusCode}, body: ${response.body}).',
    );
  }

  static Future<Map<String, dynamic>> getServiceTypeDetailReport(
    String token,
    String serviceName,
    String fromDate,
    String toDate, {
    String? branchId,
    String? vehicleTypeId,
    String? vehicleTypeModelId,
  }) async {
    final Map<String, String> params = {
      'service_name': serviceName,
      'from_date': fromDate,
      'to_date': toDate,
    };
    if (branchId != null && branchId.isNotEmpty) {
      params['branch_id'] = branchId;
    }
    if (vehicleTypeId != null && vehicleTypeId.isNotEmpty) {
      params['vehicle_type_id'] = vehicleTypeId;
    }
    if (vehicleTypeModelId != null && vehicleTypeModelId.isNotEmpty) {
      params['vehicle_type_model_id'] = vehicleTypeModelId;
    }
    final url = Uri.parse(
      '$baseUrl/reports/service-type/detail/',
    ).replace(queryParameters: params);
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load service type detail report.');
  }

  static Future<Map<String, dynamic>> getServiceTypeVehicleBreakdownReport(
    String token,
    String serviceName,
    String fromDate,
    String toDate, {
    String? branchId,
  }) async {
    final Map<String, String> params = {
      'service_name': serviceName,
      'from_date': fromDate,
      'to_date': toDate,
    };
    if (branchId != null && branchId.isNotEmpty) {
      params['branch_id'] = branchId;
    }
    final url = Uri.parse(
      '$baseUrl/reports/service-type/vehicle-breakdown/',
    ).replace(queryParameters: params);
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load service type vehicle breakdown report.');
  }

  static Future<Map<String, dynamic>> getProfitLossReport(
    String token,
    String fromDate,
    String toDate, {
    String? branchId,
  }) async {
    final Map<String, String> params = {
      'from_date': fromDate,
      'to_date': toDate,
    };
    if (branchId != null && branchId.isNotEmpty) {
      params['branch_id'] = branchId;
    }
    final url = Uri.parse(
      '$baseUrl/reports/profit-loss/',
    ).replace(queryParameters: params);
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load profit/loss report.');
  }

  // --- Booking Settings APIs ---

  static Future<Map<String, dynamic>> getBookingSettings(
    String token, {
    String? branchId,
  }) async {
    String url = '$baseUrl/booking/settings/';
    if (branchId != null && branchId.isNotEmpty) {
      url += '?branch_id=$branchId';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load booking settings.');
  }

  static Future<Map<String, dynamic>> updateBookingSettings(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/settings/update/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update booking settings.');
  }

  // --- Holiday Calendar APIs ---

  static Future<Map<String, dynamic>> getHolidays(
    String token, {
    String? branchId,
  }) async {
    String url = '$baseUrl/booking/holiday/list/';
    if (branchId != null && branchId.isNotEmpty) {
      url += '?branch_id=$branchId';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load holidays.');
  }

  static Future<Map<String, dynamic>> createHoliday(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/holiday/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create holiday.');
  }

  static Future<Map<String, dynamic>> deleteHoliday(
    String token,
    String id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/holiday/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id}),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to delete holiday.');
  }

  // --- Weekly Off Days APIs ---

  static Future<Map<String, dynamic>> getWeeklyOffs(
    String token, {
    String? branchId,
  }) async {
    String url = '$baseUrl/booking/weekly-off/list/';
    if (branchId != null && branchId.isNotEmpty) {
      url += '?branch_id=$branchId';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load weekly offs.');
  }

  static Future<Map<String, dynamic>> createWeeklyOff(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/weekly-off/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create weekly off.');
  }

  static Future<Map<String, dynamic>> deleteWeeklyOff(
    String token,
    String id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/weekly-off/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id}),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to delete weekly off.');
  }

  // --- Booking Pause APIs ---

  static Future<Map<String, dynamic>> getBookingPauses(
    String token, {
    String? branchId,
  }) async {
    String url = '$baseUrl/booking/pause/list/';
    if (branchId != null && branchId.isNotEmpty) {
      url += '?branch_id=$branchId';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load booking pauses.');
  }

  static Future<Map<String, dynamic>> createBookingPause(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/pause/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create booking pause.');
  }

  static Future<Map<String, dynamic>> deleteBookingPause(
    String token,
    String id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/booking/pause/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id}),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 400 ||
        response.statusCode == 404 ||
        response.statusCode == 403) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to delete booking pause.');
  }

  // ── Multi-Category Vehicle Service Platform APIs ──────────────────────────

  static Future<Map<String, dynamic>> getOilProducts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/oil-products/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load oil products.');
  }

  static Future<Map<String, dynamic>> getOilFilters(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/oil-filters/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load oil filters.');
  }

  static Future<Map<String, dynamic>> getInsuranceCompanies(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/insurance-companies/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load insurance companies.');
  }

  static Future<Map<String, dynamic>> getTyreBrands(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tyre-brands/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load tyre brands.');
  }

  static Future<Map<String, dynamic>> getOilStock(
    String token, {
    String? branchId,
  }) async {
    var url = '$baseUrl/oil-stock/';
    if (branchId != null && branchId.isNotEmpty) {
      url += '?branch_id=$branchId';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load oil stock.');
  }

  static Future<Map<String, dynamic>> addOilStock(
    String oilProductId,
    double quantity,
    String notes,
    String token, {
    String? branchId,
  }) async {
    final bodyMap = <String, dynamic>{
      'oil_product_id': oilProductId,
      'quantity_litres': quantity,
      'notes': notes,
    };
    if (branchId != null && branchId.isNotEmpty) {
      bodyMap['branch_id'] = branchId;
    }
    final response = await http.post(
      Uri.parse('$baseUrl/oil-stock/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyMap),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update oil stock.');
  }

  static Future<Map<String, dynamic>> addOilFilterStock(
    String oilFilterId,
    int quantity,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/oil-filters/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'oil_filter_id': oilFilterId, 'quantity': quantity}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update filter stock.');
  }

  static Future<Map<String, dynamic>> getVehicleServiceHistory(
    String vehicleId,
    String token, {
    String? fromDate,
    String? toDate,
  }) async {
    String url = '$baseUrl/vehicle-service-history/$vehicleId/';
    final params = <String>[];
    if (fromDate != null && fromDate.isNotEmpty)
      params.add('from_date=$fromDate');
    if (toDate != null && toDate.isNotEmpty) params.add('to_date=$toDate');
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load vehicle service history.');
  }

  /// Fetch oil price per litre from backend for a given oil product + vehicle make/type.
  /// Returns { price_per_litre: double?, recommended_qty_litres: double? }
  static Future<Map<String, dynamic>> getOilPrice(
    String token,
    String oilProductId, {
    String? vehicleMakeId,
    String? vehicleTypeId,
  }) async {
    final params = <String, String>{'oil_product_id': oilProductId};
    if (vehicleMakeId != null && vehicleMakeId.isNotEmpty) {
      params['vehicle_make_id'] = vehicleMakeId;
    }
    if (vehicleTypeId != null && vehicleTypeId.isNotEmpty) {
      params['vehicle_type_id'] = vehicleTypeId;
    }
    final url = Uri.parse(
      '$baseUrl/oil-price/',
    ).replace(queryParameters: params);
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch oil price.');
  }

  /// Fetch active tyres master list for company / branch.
  static Future<Map<String, dynamic>> getTyres(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tyres/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load tyres.');
  }

  /// Update stock quantity for a tyre.
  static Future<Map<String, dynamic>> addTyreStock(
    String tyreId,
    int stockQtyAdd,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tyres/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'tyre_id': tyreId, 'stock_qty_add': stockQtyAdd}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update tyre stock.');
  }

  /// Create a new quotation.
  static Future<Map<String, dynamic>> createQuotation(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quotation/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    }
    throw Exception(
      'Failed to create quotation (Status: ${response.statusCode}).',
    );
  }

  /// Get list of quotations.
  static Future<Map<String, dynamic>> getQuotationList(
    String token, {
    String? fromDate,
    String? toDate,
  }) async {
    String url = '$baseUrl/quotation/list/';
    final params = <String>[];
    if (fromDate != null && fromDate.isNotEmpty)
      params.add('from_date=$fromDate');
    if (toDate != null && toDate.isNotEmpty) params.add('to_date=$toDate');
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load quotation list.');
  }

  /// Get quotation details by ID.
  static Future<Map<String, dynamic>> getQuotationDetail(
    String id,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quotation/detail/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load quotation details.');
  }

  /// Update an existing quotation.
  static Future<Map<String, dynamic>> updateQuotation(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quotation/edit/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    }
    throw Exception(
      'Failed to update quotation (Status: ${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> acceptQuotation(
    String quotationId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quotation/$quotationId/accept/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> convertQuotationToJobCard(
    String quotationId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-cards/from-quotation/$quotationId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> listJobLeads(
    String token, {
    String? status,
    bool unconverted = false,
    String? search,
  }) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (unconverted) query['unconverted'] = 'true';
    if (search != null && search.trim().isNotEmpty)
      query['search'] = search.trim();
    final response = await http.get(
      Uri.parse('$baseUrl/job-leads/').replace(queryParameters: query),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createJobLead(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-leads/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getJobLeadFormData(
    String token, {
    String? branchId,
  }) async {
    final uri = Uri.parse('$baseUrl/job-leads/form-data/').replace(
      queryParameters: branchId == null || branchId.isEmpty
          ? null
          : {'branch_id': branchId},
    );
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getJobLeadHistory(
    String token,
    String id,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/job-leads/$id/history/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateJobLead(
    String token,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-leads/$id/update/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteJobLead(
    String token,
    String id,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-leads/$id/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteJobQuotation(
    String id,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-quotations/$id/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createJobLeadFollowUp(
    String token,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-leads/$id/follow-ups/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createJobQuotation(
    Map<String, dynamic> data,
    String token, {
    List<List<XFile>> issuePhotos = const [],
  }) async {
    if (issuePhotos.any((photos) => photos.isNotEmpty)) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/job-quotations/create/'),
      )..headers['Authorization'] = 'Bearer $token';
      request.fields['payload'] = jsonEncode(data);
      for (var issueIndex = 0; issueIndex < issuePhotos.length; issueIndex++) {
        for (final photo in issuePhotos[issueIndex]) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'issue_${issueIndex}_photos',
              await photo.readAsBytes(),
              filename: photo.name,
            ),
          );
        }
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return jsonDecode(response.body);
    }
    final response = await http.post(
      Uri.parse('$baseUrl/job-quotations/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> getOilBrands(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/oil-brands/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createOilBrand(String name, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/oil-brands/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getOilGrades(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/oil-grades/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createOilGrade(String name, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/oil-grades/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    return jsonDecode(response.body);
  }
  static Future<Map<String, dynamic>> getJobCardIssueOptions(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/job-card-issues/options/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createJobCardIssue(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-card-issues/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createJobCardActivityOption(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-card-activities/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateJobQuotation(
    String id,
    Map<String, dynamic> data,
    String token, {
    List<List<XFile>> issuePhotos = const [],
  }) async {
    if (issuePhotos.any((photos) => photos.isNotEmpty)) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/job-quotations/$id/update/'),
      )..headers['Authorization'] = 'Bearer $token';
      request.fields['payload'] = jsonEncode(data);
      for (var issueIndex = 0; issueIndex < issuePhotos.length; issueIndex++) {
        for (final photo in issuePhotos[issueIndex]) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'issue_${issueIndex}_photos',
              await photo.readAsBytes(),
              filename: photo.name,
            ),
          );
        }
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return jsonDecode(response.body);
    }
    final response = await http.post(
      Uri.parse('$baseUrl/job-quotations/$id/update/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getJobQuotationList(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/job-quotations/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getJobQuotationDetail(
    String id,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/job-quotations/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> acceptJobQuotation(
    String id,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-quotations/$id/accept/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> convertJobQuotationToJobCard(
    String id,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-cards/from-job-quotation/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadJobQuotationPdf(
    String id,
    Uint8List pdfBytes,
    String token, {
    bool sendWhatsapp = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/job-quotations/$id/upload-pdf/');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';
      if (sendWhatsapp) {
        request.fields['send_whatsapp'] = 'true';
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'pdf',
          pdfBytes,
          filename: 'quotation-$id.pdf',
        ),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {
        'success': false,
        'message': 'Upload failed (${response.statusCode}): ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  // --- Senior ERP Purchase & Supplier Payables ---

  static Future<Map<String, dynamic>> getSuppliers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/supplier/list/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load suppliers.');
  }

  static Future<Map<String, dynamic>> getSupplierPayables(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/erp/suppliers-payables/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load supplier payables.');
  }

  static Future<Map<String, dynamic>> createSupplierPayment(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/erp/supplier-payment/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to record supplier payment.');
  }

  static Future<Map<String, dynamic>> createPurchaseInvoice(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/erp/purchase-invoice/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create purchase invoice.');
  }

  static Future<Map<String, dynamic>> getPurchaseInvoices(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/erp/purchase-invoices/list/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load purchase invoices.');
  }

  // ── Leads APIs ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> listLeads(
    String token, {
    String? search,
    String? status,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final uri = Uri.parse(
      '$baseUrl/leads/list/',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load leads.');
  }

  static Future<Map<String, dynamic>> createLead(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/leads/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    throw Exception('Failed to create lead (Status ${response.statusCode}).');
  }

  static Future<Map<String, dynamic>> createLeadFollowUp(
    String token,
    String leadId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/leads/$leadId/follow-ups/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> editLead(
    String token,
    String leadId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/leads/edit/$leadId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    throw Exception('Failed to update lead (Status ${response.statusCode}).');
  }

  static Future<Map<String, dynamic>> deleteLead(
    String token,
    String leadId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/leads/delete/$leadId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 ||
        response.statusCode == 404 ||
        response.statusCode == 401) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to delete lead.');
  }

  static Future<Map<String, dynamic>> getLeadsReminders(
    String token, {
    bool showAll = false,
    int daysAhead = 30,
    String? search,
  }) async {
    String url = '$baseUrl/leads/reminders/?days=$daysAhead';
    if (showAll) url += '&show_all=true';
    if (search != null && search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load leads reminders.');
  }

  // ─── Insurance Module APIs ───────────────────────────────────────────────

  // ─── Insurance Module APIs ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> insuranceCustomerSearch(
    String token, {
    String? search,
  }) async {
    String url = '$baseUrl/insurance/customer-search/';
    if (search != null && search.isNotEmpty) {
      url += '?q=${Uri.encodeComponent(search)}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to search customers.');
  }

  static Future<Map<String, dynamic>> insuranceServices(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/insurance/services/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load insurance services.');
  }

  static Future<Map<String, dynamic>> insuranceReminders(
    String token, {
    String? date,
    bool showAll = false,
    String? search,
  }) async {
    String url = '$baseUrl/insurance/reminders/';
    final params = <String, String>{};
    if (date != null && date.isNotEmpty) params['date'] = date;
    if (showAll) params['show_all'] = 'true';
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (params.isNotEmpty) {
      final queryStr = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url += '?$queryStr';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 401) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load insurance reminders.');
  }

  // ─── Job Card APIs ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getJobCards(
    String token, {
    String tab = 'all',
    String search = '',
  }) async {
    final Map<String, String> params = {'tab': tab};
    if (search.isNotEmpty) {
      params['search'] = search;
    }
    final url = Uri.parse(
      '$baseUrl/job-cards/',
    ).replace(queryParameters: params);
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'success': false, 'message': 'Failed to load job cards'};
  }

  static Future<Map<String, dynamic>> getJobCardDetail(
    String id,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/job-cards/$id/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'success': false, 'message': 'Failed to load job card details'};
  }

  static Future<Map<String, dynamic>> getJobCardInvoice(
    String jobCardId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/job-cards/$jobCardId/invoice/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _decodeJobCardResponse(response);
  }

  static Future<Map<String, dynamic>> createJobCardInvoice(
    String jobCardId,
    String token, {
    required double amountCollected,
    required String paymentMode,
    double discount = 0.0,
    String discountType = 'amount',
    double discountPercentage = 0.0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-cards/$jobCardId/invoice/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount_collected': amountCollected,
        'payment_mode': paymentMode,
        'discount': discount,
        'discount_type': discountType,
        'discount_percentage': discountPercentage,
      }),
    );
    return _decodeJobCardResponse(response);
  }

  static Future<Map<String, dynamic>> createJobCard(
    Map<String, dynamic> data,
    String token, {
    List<List<XFile>> issuePhotos = const [],
    List<XFile> beforePhotos = const [],
    List<XFile> afterPhotos = const [],
    Map<int, List<XFile>> qualityCheckPhotos = const {},
  }) async {
    final hasIssuePhotos = issuePhotos.any((photos) => photos.isNotEmpty);
    final hasVehiclePhotos = beforePhotos.isNotEmpty || afterPhotos.isNotEmpty;
    final hasQcPhotos = qualityCheckPhotos.values.any((photos) => photos.isNotEmpty);
    if (hasIssuePhotos || hasVehiclePhotos || hasQcPhotos) {
      final photoBytes = <(XFile, List<int>)>[];
      var totalPhotoBytes = 0;
      for (final photos in issuePhotos) {
        for (final photo in photos) {
          final bytes = await photo.readAsBytes();
          totalPhotoBytes += bytes.length;
          photoBytes.add((photo, bytes));
        }
      }
      for (final photo in beforePhotos) {
        final bytes = await photo.readAsBytes();
        totalPhotoBytes += bytes.length;
        photoBytes.add((photo, bytes));
      }
      for (final photo in afterPhotos) {
        final bytes = await photo.readAsBytes();
        totalPhotoBytes += bytes.length;
        photoBytes.add((photo, bytes));
      }
      for (final photos in qualityCheckPhotos.values) {
        for (final photo in photos) {
          final bytes = await photo.readAsBytes();
          totalPhotoBytes += bytes.length;
          photoBytes.add((photo, bytes));
        }
      }
      if (totalPhotoBytes > 15 * 1024 * 1024) {
        return {
          'success': false,
          'message':
              'Photos are too large to upload together. Remove some photos and try again.',
        };
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/job-cards/create/'),
      )..headers['Authorization'] = 'Bearer $token';
      request.fields['payload'] = jsonEncode(data);
      var photoIndex = 0;
      for (var issueIndex = 0; issueIndex < issuePhotos.length; issueIndex++) {
        for (final photo in issuePhotos[issueIndex]) {
          final bytes = photoBytes[photoIndex++].$2;
          request.files.add(
            http.MultipartFile.fromBytes(
              'issue_${issueIndex}_photos',
              bytes,
              filename: photo.name,
            ),
          );
        }
      }
      for (final photo in beforePhotos) {
        final bytes = photoBytes[photoIndex++].$2;
        request.files.add(
          http.MultipartFile.fromBytes(
            'before_photos',
            bytes,
            filename: photo.name,
          ),
        );
      }
      for (final photo in afterPhotos) {
        final bytes = photoBytes[photoIndex++].$2;
        request.files.add(
          http.MultipartFile.fromBytes(
            'after_photos',
            bytes,
            filename: photo.name,
          ),
        );
      }
      for (final entry in qualityCheckPhotos.entries) {
        final qcIdx = entry.key;
        for (final photo in entry.value) {
          final bytes = photoBytes[photoIndex++].$2;
          request.files.add(
            http.MultipartFile.fromBytes(
              'qc_photos_$qcIdx',
              bytes,
              filename: photo.name,
            ),
          );
        }
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _decodeJobCardResponse(response);
    }
    final url = Uri.parse('$baseUrl/job-cards/create/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return _decodeJobCardResponse(response);
  }

  static Future<Map<String, dynamic>> updateJobCard(
    String id,
    Map<String, dynamic> data,
    String token, {
    List<List<XFile>> issuePhotos = const [],
    List<XFile> beforePhotos = const [],
    List<XFile> afterPhotos = const [],
    Map<int, List<XFile>> qualityCheckPhotos = const {},
  }) async {
    final hasIssuePhotos = issuePhotos.any((photos) => photos.isNotEmpty);
    final hasVehiclePhotos = beforePhotos.isNotEmpty || afterPhotos.isNotEmpty;
    final hasQcPhotos = qualityCheckPhotos.values.any((photos) => photos.isNotEmpty);
    if (hasIssuePhotos || hasVehiclePhotos || hasQcPhotos) {
      final photoBytes = <(XFile, List<int>)>[];
      var totalPhotoBytes = 0;
      for (final photos in issuePhotos) {
        for (final photo in photos) {
          final bytes = await photo.readAsBytes();
          totalPhotoBytes += bytes.length;
          photoBytes.add((photo, bytes));
        }
      }
      for (final photo in beforePhotos) {
        final bytes = await photo.readAsBytes();
        totalPhotoBytes += bytes.length;
        photoBytes.add((photo, bytes));
      }
      for (final photo in afterPhotos) {
        final bytes = await photo.readAsBytes();
        totalPhotoBytes += bytes.length;
        photoBytes.add((photo, bytes));
      }
      for (final photos in qualityCheckPhotos.values) {
        for (final photo in photos) {
          final bytes = await photo.readAsBytes();
          totalPhotoBytes += bytes.length;
          photoBytes.add((photo, bytes));
        }
      }
      if (totalPhotoBytes > 15 * 1024 * 1024) {
        return {
          'success': false,
          'message':
              'Photos are too large to upload together. Remove some photos and try again.',
        };
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/job-cards/$id/update/'),
      )..headers['Authorization'] = 'Bearer $token';
      request.fields['payload'] = jsonEncode(data);
      var photoIndex = 0;
      for (var issueIndex = 0; issueIndex < issuePhotos.length; issueIndex++) {
        for (final photo in issuePhotos[issueIndex]) {
          final bytes = photoBytes[photoIndex++].$2;
          request.files.add(
            http.MultipartFile.fromBytes(
              'issue_${issueIndex}_photos',
              bytes,
              filename: photo.name,
            ),
          );
        }
      }
      for (final photo in beforePhotos) {
        final bytes = photoBytes[photoIndex++].$2;
        request.files.add(
          http.MultipartFile.fromBytes(
            'before_photos',
            bytes,
            filename: photo.name,
          ),
        );
      }
      for (final photo in afterPhotos) {
        final bytes = photoBytes[photoIndex++].$2;
        request.files.add(
          http.MultipartFile.fromBytes(
            'after_photos',
            bytes,
            filename: photo.name,
          ),
        );
      }
      for (final entry in qualityCheckPhotos.entries) {
        final qcIdx = entry.key;
        for (final photo in entry.value) {
          final bytes = photoBytes[photoIndex++].$2;
          request.files.add(
            http.MultipartFile.fromBytes(
              'qc_photos_$qcIdx',
              bytes,
              filename: photo.name,
            ),
          );
        }
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _decodeJobCardResponse(response);
    }
    final url = Uri.parse('$baseUrl/job-cards/$id/update/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return _decodeJobCardResponse(response);
  }

  static Future<Map<String, dynamic>> uploadJobCardVehiclePhoto({
    required String jobCardId,
    required XFile photo,
    required String photoType,
    required String token,
    String? caption,
  }) async {
    final url = Uri.parse('$baseUrl/job-cards/$jobCardId/photos/');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['photo_type'] = photoType;
    if (caption != null && caption.isNotEmpty) {
      request.fields['caption'] = caption;
    }
    final bytes = await photo.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('photo', bytes, filename: photo.name),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeJobCardResponse(response);
  }


  static Future<Map<String, dynamic>> uploadJobCardQualityCheckPhoto({
    required String jobCardId,
    required XFile photo,
    required String serviceName,
    required String token,
    String? status,
    String? remarks,
  }) async {
    final url = Uri.parse('$baseUrl/job-cards/$jobCardId/quality-checks/');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['service_name'] = serviceName
      ..fields['status'] = status ?? 'satisfied';
    if (remarks != null && remarks.isNotEmpty) {
      request.fields['remarks'] = remarks;
    }
    final bytes = await photo.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('qc_photos_0', bytes, filename: photo.name),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeJobCardResponse(response);
  }

  static Future<Map<String, dynamic>> deleteJobCardQualityCheckPhoto({
    required String jobCardId,
    required String photoId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/job-cards/$jobCardId/quality-checks/photos/$photoId/');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _decodeJobCardResponse(response);
  }
  static Future<Map<String, dynamic>> deleteJobCardVehiclePhoto({
    required String jobCardId,
    required String photoId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/job-cards/$jobCardId/photos/?photo_id=$photoId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _decodeJobCardResponse(response);
  }

  static Future<Map<String, dynamic>> deleteJobCard(
    String id,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/job-cards/$id/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateJobCardStatus(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/job-cards/$id/status/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> searchJobCardAccessories(
    String query,
    String token,
  ) async {
    final url = Uri.parse(
      '$baseUrl/job-cards/accessories-search/',
    ).replace(queryParameters: {'q': query});
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'success': false, 'results': []};
  }

  static Future<Map<String, dynamic>> getJobCardMetadata(String token) async {
    final url = Uri.parse('$baseUrl/job-cards/metadata/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'success': false};
  }

  static Future<Map<String, dynamic>> addJobCardVehicle(
    Map<String, dynamic> data,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/job-cards/vehicle/add/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getInspectionChecklist(String token) async {
    final url = Uri.parse('$baseUrl/job-cards/inspection-checklist/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'success': false, 'categories': []};
  }
}

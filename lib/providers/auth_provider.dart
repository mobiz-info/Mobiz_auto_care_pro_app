import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/country_config.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _token;
  String? _role;
  String? _companyName;
  String? _branchName;
  String? _displayName;
  String? _username;
  String? _companyLogo;
  // Currency is always driven by CountryConfig (set via dart tools/setup_country.dart)
  // Do NOT store/restore from SharedPreferences — that would override the build-time setting.
  bool _subscriptionActive = true;
  int _subscriptionDaysLeft = 999;
  String? _subscriptionEndDate;
  bool _hasInsuranceModule = false;
  bool _isFullAccess = true;
  String _designationName = '';
  Map<String, dynamic> _permissions = {};

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get role => _role;
  String? get companyName => _companyName;
  String? get branchName => _branchName;
  String? get displayName => _displayName;
  String? get username => _username;
  String? get companyLogo => _companyLogo;
  bool get isFullAccess => _isFullAccess;
  String get designationName => _designationName;
  Map<String, dynamic> get permissions => _permissions;

  bool get isBranchAdmin =>
      _role == 'BRANCH_ADMIN' ||
      _role == 'BRANCH_MANAGER' ||
      _role == 'MARKETING' ||
      _role == 'CLERICAL' ||
      _role == 'SERVICE' ||
      _role == 'STAFF';
  bool get isCompanyAdmin => _role == 'COMPANY_ADMIN';
  bool get canBroadcast => hasPermission('notifications', 'send');

  bool hasPermission(String menuKey, [String actionKey = 'view']) {
    if (_isFullAccess || _role == 'COMPANY_ADMIN' || _role == 'BRANCH_ADMIN') {
      return true;
    }
    final menuPerms = _permissions[menuKey];
    if (menuPerms is Map) {
      return menuPerms[actionKey] == true;
    }
    return false;
  }
  /// Always returns the symbol for the country selected via setup_country.dart
  /// A trailing space is included so currency amounts are formatted as "₹ 100" / "AED 50".
  String get currencySymbol => '${CountryConfig.currencySymbol} ';
  bool get subscriptionActive => _subscriptionActive;
  int get subscriptionDaysLeft => _subscriptionDaysLeft;
  String? get subscriptionEndDate => _subscriptionEndDate;
  bool get hasInsuranceModule => _hasInsuranceModule;

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Migration guard: if old session lacks the new display_name key, clear it
    // so the user is prompted to log in again and get fresh data.
    final hasDisplayName = prefs.containsKey('auth_display_name');
    final token = prefs.getString('auth_token');
    if (token != null && !hasDisplayName) {
      await prefs.clear();
      notifyListeners();
      return;
    }

    _token = prefs.getString('auth_token');
    _role = prefs.getString('auth_role');
    _companyName = prefs.getString('auth_company');
    _branchName = prefs.getString('auth_branch');
    _displayName = prefs.getString('auth_display_name');
    _username = prefs.getString('auth_username');
    _companyLogo = prefs.getString('auth_company_logo');
    // Currency symbol is NOT read from prefs — always use CountryConfig
    _subscriptionActive = prefs.getBool('subscription_active') ?? true;
    _subscriptionDaysLeft = prefs.getInt('subscription_days_left') ?? 999;
    _subscriptionEndDate = prefs.getString('subscription_end_date');
    _hasInsuranceModule = prefs.getBool('has_insurance_module') ?? false;
    _isFullAccess = prefs.getBool('auth_is_full_access') ?? true;
    _designationName = prefs.getString('auth_designation_name') ?? '';
    final permsJson = prefs.getString('auth_permissions');
    if (permsJson != null && permsJson.isNotEmpty) {
      try {
        _permissions = Map<String, dynamic>.from(jsonDecode(permsJson));
      } catch (_) {
        _permissions = {};
      }
    }
    final savedIso = prefs.getString('auth_country_iso');
    if (savedIso != null && savedIso.isNotEmpty) {
      await CountryConfig.setCountryByIso(savedIso);
    }
    notifyListeners();
    if (_token != null) {
      refreshPermissions();
    }
  }

  Future<void> refreshPermissions() async {
    if (_token == null) return;
    try {
      final res = await ApiService.getMyPermissions(_token!);
      if (res['success'] == true) {
        _isFullAccess = res['is_full_access'] ?? true;
        _designationName = res['designation_name']?.toString() ?? '';
        _permissions = res['permissions'] is Map
            ? Map<String, dynamic>.from(res['permissions'])
            : {};
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auth_is_full_access', _isFullAccess);
        await prefs.setString('auth_designation_name', _designationName);
        await prefs.setString('auth_permissions', jsonEncode(_permissions));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.login(username, password);

      if (data['success'] == true) {
        _token = data['token'];
        _role = data['role'];
        _companyName = data['company_name'];
        _branchName = data['branch_name'] ?? '';
        _displayName = data['display_name'] ?? data['company_name'];
        _username = data['username'];
        _companyLogo = data['company_logo'] ?? '';
        _subscriptionActive = data['subscription_active'] ?? true;
        _subscriptionDaysLeft = data['subscription_days_left'] ?? 999;
        _subscriptionEndDate = data['subscription_end_date'];
        _hasInsuranceModule = data['has_insurance_module'] == true;
        _isFullAccess = data['is_full_access'] ?? true;
        _designationName = data['designation_name']?.toString() ?? '';
        _permissions = data['permissions'] is Map
            ? Map<String, dynamic>.from(data['permissions'])
            : {};

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_role', _role ?? '');
        await prefs.setString('auth_company', _companyName ?? '');
        await prefs.setString('auth_branch', _branchName ?? '');
        await prefs.setString('auth_display_name', _displayName ?? '');
        await prefs.setString('auth_username', _username ?? '');
        await prefs.setString('auth_company_logo', _companyLogo ?? '');
        await prefs.setBool('auth_is_full_access', _isFullAccess);
        await prefs.setString('auth_designation_name', _designationName);
        await prefs.setString('auth_permissions', jsonEncode(_permissions));
        // Auto-switch country based on company country from backend
        final countryIso = data['country_iso_code'];
        if (countryIso != null && countryIso.toString().trim().isNotEmpty) {
          await CountryConfig.setCountryByIso(countryIso.toString().trim());
          await prefs.setString('auth_country_iso', countryIso.toString().trim());
        }

        // Currency symbol is driven by CountryConfig
        await prefs.setBool('subscription_active', _subscriptionActive);
        await prefs.setInt('subscription_days_left', _subscriptionDaysLeft);
        await prefs.setBool('has_insurance_module', _hasInsuranceModule);
        if (_subscriptionEndDate != null) {
          await prefs.setString('subscription_end_date', _subscriptionEndDate!);
        } else {
          await prefs.remove('subscription_end_date');
        }

        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        _isLoading = false;
        notifyListeners();
        return data['message'] ?? 'Login failed';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> updateSubscriptionStatus({
    required bool active,
    required int daysLeft,
    required String? endDate,
  }) async {
    _subscriptionActive = active;
    _subscriptionDaysLeft = daysLeft;
    _subscriptionEndDate = endDate;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('subscription_active', active);
    await prefs.setInt('subscription_days_left', daysLeft);
    if (endDate != null) {
      await prefs.setString('subscription_end_date', endDate);
    } else {
      await prefs.remove('subscription_end_date');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _companyName = null;
    _branchName = null;
    _displayName = null;
    _username = null;
    _companyLogo = null;
    _subscriptionActive = true;
    _subscriptionDaysLeft = 999;
    _subscriptionEndDate = null;
    _hasInsuranceModule = false;
    _isFullAccess = true;
    _designationName = '';
    _permissions = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}

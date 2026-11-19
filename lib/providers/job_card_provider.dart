import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../services/api_service.dart';

class JobCardProvider extends ChangeNotifier {
  void _safeNotify() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  List<dynamic> _jobCards = [];
  bool _isLoadingJobCards = false;
  String _jobCardsError = '';
  List<dynamic> _successfulLeads = [];
  bool _isLoadingSuccessfulLeads = false;
  String _successfulLeadsError = '';
  final Map<String, Map<String, dynamic>> _jobCardDetails = {};
  final Set<String> _loadingDetails = {};
  final Map<String, String> _detailErrors = {};

  List<dynamic> get jobCards => _jobCards;
  bool get isLoadingJobCards => _isLoadingJobCards;
  String get jobCardsError => _jobCardsError;
  List<dynamic> get successfulLeads => _successfulLeads;
  bool get isLoadingSuccessfulLeads => _isLoadingSuccessfulLeads;
  String get successfulLeadsError => _successfulLeadsError;

  Future<void> fetchSuccessfulLeads(String token, {String search = ''}) async {
    _isLoadingSuccessfulLeads = true;
    _successfulLeadsError = '';
    _safeNotify();
    try {
      final response = await ApiService.listJobLeads(
        token,
        status: 'success',
        unconverted: true,
        search: search,
      );
      if (response['success'] == true || response['status'] == 'success') {
        _successfulLeads = response['leads'] ?? [];
      } else {
        _successfulLeadsError =
            response['message'] ?? 'Failed to load successful leads';
      }
    } catch (error) {
      _successfulLeadsError = error.toString();
    } finally {
      _isLoadingSuccessfulLeads = false;
      _safeNotify();
    }
  }

  Map<String, dynamic>? detailFor(String id) => _jobCardDetails[id];
  bool isLoadingDetail(String id) => _loadingDetails.contains(id);
  String detailError(String id) => _detailErrors[id] ?? '';

  Future<void> fetchJobCards(
    String token, {
    required String tab,
    required String search,
  }) async {
    _isLoadingJobCards = true;
    _jobCardsError = '';
    _safeNotify();
    try {
      final response = await ApiService.getJobCards(
        token,
        tab: tab,
        search: search,
      );
      if (response['success'] == true) {
        _jobCards = response['job_cards'] ?? [];
      } else {
        _jobCardsError = response['message'] ?? 'Failed to load job cards';
      }
    } catch (error) {
      _jobCardsError = error.toString();
    } finally {
      _isLoadingJobCards = false;
      _safeNotify();
    }
  }

  Future<void> fetchJobCardDetail(String id, String token) async {
    _loadingDetails.add(id);
    _detailErrors.remove(id);
    _safeNotify();
    try {
      final response = await ApiService.getJobCardDetail(id, token);
      if (response['success'] == true && response['job_card'] != null) {
        _jobCardDetails[id] = Map<String, dynamic>.from(
          response['job_card'] as Map,
        );
      } else {
        _detailErrors[id] = response['message'] ?? 'Failed to load details';
      }
    } catch (error) {
      _detailErrors[id] = error.toString();
    } finally {
      _loadingDetails.remove(id);
      _safeNotify();
    }
  }
}

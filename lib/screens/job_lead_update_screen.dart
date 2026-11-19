import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../widgets/job_card_responsive.dart';

class JobLeadUpdateScreen extends StatefulWidget {
  final Map<String, dynamic> lead;

  const JobLeadUpdateScreen({super.key, required this.lead});

  @override
  State<JobLeadUpdateScreen> createState() => _JobLeadUpdateScreenState();
}

class _JobLeadUpdateScreenState extends State<JobLeadUpdateScreen> {
  final _remarksController = TextEditingController();
  final _chanceController = TextEditingController();
  final _lostReasonController = TextEditingController();
  late String _status;
  DateTime? _nextDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = (widget.lead['status'] ?? 'follow_up').toString();
    if (_status == 'quoted') _status = 'follow_up';
    _chanceController.text = (widget.lead['success_chance'] ?? '').toString();
    _lostReasonController.text = (widget.lead['lost_reason'] ?? '').toString();
    _nextDate = DateTime.tryParse(
      (widget.lead['next_follow_up_date'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _chanceController.dispose();
    _lostReasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString().padLeft(4, '0')}';

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _nextDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) setState(() => _nextDate = selected);
  }

  Future<void> _save() async {
    final remarks = _remarksController.text.trim();
    final lostReason = _lostReasonController.text.trim();
    final chance = double.tryParse(_chanceController.text.trim());
    if (remarks.isEmpty || (_status == 'follow_up' && _nextDate == null)) {
      _showMessage(
        'Enter a remark and a next follow-up date for Active leads.',
      );
      return;
    }
    if (_status == 'follow_up' &&
        (chance == null || chance < 0 || chance > 100)) {
      _showMessage('Success chance must be between 0 and 100.');
      return;
    }
    if (_status == 'lost' && lostReason.isEmpty) {
      _showMessage('Enter a reason for Lost leads.');
      return;
    }
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isSaving = true);
    try {
      final response = await ApiService.createJobLeadFollowUp(
        token,
        widget.lead['id'].toString(),
        {
          'remarks': remarks,
          'status': _status,
          'next_follow_up_date': _status == 'follow_up'
              ? '${_nextDate!.year.toString().padLeft(4, '0')}-${_nextDate!.month.toString().padLeft(2, '0')}-${_nextDate!.day.toString().padLeft(2, '0')}'
              : '',
          'success_chance': _status == 'success' ? 100 : chance,
          'lost_reason': lostReason,
        },
      );
      if (!mounted) return;
      if (response['success'] == true) {
        Navigator.pop(context, true);
      } else {
        _showMessage(response['message'] ?? 'Failed to update lead.');
      }
    } catch (error) {
      if (mounted) _showMessage('Unable to update lead: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr(message))));
  }

  @override
  Widget build(BuildContext context) {
    final leadNumber = widget.lead['lead_number']?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Update Lead'))),
      body: SafeArea(
        child: JobCardContent(
          padding: EdgeInsets.zero,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${widget.lead['customer_name'] ?? ''} · $leadNumber',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _remarksController,
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: context.tr('Remark *'),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: ['follow_up', 'success', 'lost'].contains(_status)
                    ? _status
                    : 'follow_up',
                decoration: InputDecoration(
                  labelText: context.tr('Status'),
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'follow_up', child: Text('Active')),
                  DropdownMenuItem(value: 'success', child: Text('Success')),
                  DropdownMenuItem(value: 'lost', child: Text('Lost')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _status = value);
                      },
              ),
              if (_status == 'follow_up') ...[
                const SizedBox(height: 16),
                JobCardResponsiveFields(
                  children: [
                    TextField(
                      controller: _chanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: context.tr('Success Chance %'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: Text(context.tr('Next Follow-up Date *')),
                      subtitle: Text(
                        _nextDate == null
                            ? context.tr('Select date')
                            : _formatDate(_nextDate!),
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: _isSaving ? null : _pickDate,
                    ),
                  ],
                ),
              ],
              if (_status == 'lost') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _lostReasonController,
                  decoration: InputDecoration(
                    labelText: context.tr('Lost reason *'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(context.tr('Save Update')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

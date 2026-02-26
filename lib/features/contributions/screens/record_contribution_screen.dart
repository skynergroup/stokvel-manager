import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class RecordContributionScreen extends StatefulWidget {
  final String groupId;
  const RecordContributionScreen({super.key, required this.groupId});

  @override
  State<RecordContributionScreen> createState() =>
      _RecordContributionScreenState();
}

class _RecordContributionScreenState extends State<RecordContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '500');
  final _notesController = TextEditingController();
  String _selectedMember = 'Thabo M.';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _proofFileName;

  static const _members = [
    'Nomsa M.',
    'Sipho S.',
    'Thabo M.',
    'Lerato K.',
    'Bongani D.',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _pickProof(String source) {
    // TODO: Implement image picker
    setState(() => _proofFileName = 'proof_${source}_photo.jpg');
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // TODO: Save to Firestore
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Member',
                    style: Theme.of(context).textTheme.labelLarge),
                const Gap(8),
                DropdownButtonFormField<String>(
                  value: _selectedMember,
                  decoration: const InputDecoration(),
                  items: _members
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedMember = v);
                  },
                ),
                const Gap(20),
                AppTextField(
                  label: 'Amount',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  prefix: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('R',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const Gap(4),
                Text(
                  'Pre-filled from group settings',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Gap(20),
                Text('Payment Date',
                    style: Theme.of(context).textTheme.labelLarge),
                const Gap(8),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateFormat.format(_selectedDate)),
                        const Icon(Icons.calendar_today_outlined, size: 20),
                      ],
                    ),
                  ),
                ),
                const Gap(20),
                Text('Proof of Payment',
                    style: Theme.of(context).textTheme.labelLarge),
                const Gap(8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _proofFileName != null
                      ? Row(
                          children: [
                            const Icon(Icons.image, color: AppColors.success),
                            const Gap(8),
                            Expanded(child: Text(_proofFileName!)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () =>
                                  setState(() => _proofFileName = null),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _pickProof('camera'),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Take Photo'),
                                ),
                                const Gap(16),
                                TextButton.icon(
                                  onPressed: () => _pickProof('gallery'),
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text('Upload File'),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const Gap(20),
                AppTextField(
                  label: 'Notes (optional)',
                  hint: 'Cash at meeting',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const Gap(32),
                AppButton(
                  label: 'Record Payment',
                  onPressed: _save,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

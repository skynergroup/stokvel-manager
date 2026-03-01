import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/member.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../providers/contribution_provider.dart';

class RecordContributionScreen extends ConsumerStatefulWidget {
  final String groupId;
  const RecordContributionScreen({super.key, required this.groupId});

  @override
  ConsumerState<RecordContributionScreen> createState() =>
      _RecordContributionScreenState();
}

class _RecordContributionScreenState
    extends ConsumerState<RecordContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  StokvelMember? _selectedMember;
  DateTime _selectedDate = DateTime.now();
  File? _proofFile;
  bool _amountPreFilled = false;

  final _imagePicker = ImagePicker();

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

  Future<void> _pickProof(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _proofFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    if (authState.user == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final success = await ref.read(recordContributionProvider.notifier).record(
          stokvelId: widget.groupId,
          memberId: _selectedMember!.id,
          memberName: _selectedMember!.displayName,
          amount: amount,
          recordedBy: authState.user!.uid,
          paidDate: _selectedDate,
          proofFile: _proofFile,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record payment. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(stokvelMembersProvider(widget.groupId));
    final groupAsync = ref.watch(stokvelDetailProvider(widget.groupId));
    final recordState = ref.watch(recordContributionProvider);
    final isLoading = recordState is AsyncLoading;
    final dateFormat = DateFormat('d MMM yyyy');

    // Pre-fill amount from group settings
    if (!_amountPreFilled) {
      groupAsync.whenData((group) {
        if (group != null && _amountController.text.isEmpty) {
          _amountController.text = group.contributionAmount.toInt().toString();
          _amountPreFilled = true;
        }
      });
    }

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
                // Member dropdown from Firestore
                Text('Member',
                    style: Theme.of(context).textTheme.labelLarge),
                const Gap(8),
                membersAsync.when(
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (error, _) => Text('Error loading members: $error'),
                  data: (members) {
                    final activeMembers = members
                        .where((m) => m.status == MemberStatus.active)
                        .toList();
                    return DropdownButtonFormField<StokvelMember>(
                      initialValue: _selectedMember,
                      decoration: const InputDecoration(),
                      hint: const Text('Select member'),
                      items: activeMembers
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                  '${m.displayName} (${m.role.displayName})',
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedMember = v);
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                ),
                const Gap(20),

                // Amount
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

                // Payment date
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

                // Proof of payment
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
                  child: _proofFile != null
                      ? Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _proofFile!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const Gap(8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image,
                                    color: AppColors.success, size: 16),
                                const Gap(4),
                                Expanded(
                                  child: Text(
                                    _proofFile!.path.split('/').last,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () =>
                                      setState(() => _proofFile = null),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _pickProof(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Take Photo'),
                            ),
                            const Gap(16),
                            TextButton.icon(
                              onPressed: () =>
                                  _pickProof(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Upload File'),
                            ),
                          ],
                        ),
                ),
                const Gap(20),

                // Notes
                AppTextField(
                  label: 'Notes (optional)',
                  hint: 'Cash at meeting',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const Gap(32),

                // Submit
                AppButton(
                  label: 'Record Payment',
                  onPressed: isLoading ? null : _save,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

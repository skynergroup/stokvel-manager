import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/stokvel.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/groups_provider.dart';
import '../services/invite_service.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  int _currentStep = 0;
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  bool _isCreating = false;

  // Step 1
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  StokvelType _selectedType = StokvelType.rotational;

  // Step 2
  final _amountController = TextEditingController();
  String _frequency = 'Monthly';

  // Step 3
  String _constitutionChoice = 'skip';

  // Step 4
  final _invitePhoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _invitePhoneController.dispose();
    super.dispose();
  }

  void _next() {
    if (_formKeys[_currentStep].currentState?.validate() ?? true) {
      if (_currentStep < 3) {
        setState(() => _currentStep++);
      } else {
        _createGroup();
      }
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _createGroup() async {
    final authState = ref.read(authStateProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (authState.user == null) return;

    setState(() => _isCreating = true);

    final frequencyMap = {
      'Weekly': 'weekly',
      'Biweekly': 'biweekly',
      'Monthly': 'monthly',
    };

    try {
      final stokvelId =
          await ref.read(createStokvelProvider.notifier).create(
                name: _nameController.text.trim(),
                type: _selectedType.name,
                contributionAmount:
                    double.tryParse(_amountController.text) ?? 0,
                contributionFrequency: frequencyMap[_frequency] ?? 'monthly',
                createdBy: authState.user!.uid,
                creatorName: profile?.displayName ?? 'Unknown',
                creatorPhone: authState.user!.phoneNumber ?? '',
                description: _descriptionController.text.trim().isNotEmpty
                    ? _descriptionController.text.trim()
                    : null,
              );

      if (stokvelId != null) {
        // Generate invite code
        final code = await InviteService().createInvite(
          stokvelId: stokvelId,
          createdBy: authState.user!.uid,
        );
        if (mounted) {
          // Navigate to invite screen
          context.pushNamed(
            RouteNames.invite,
            pathParameters: {'stokvelId': stokvelId},
            queryParameters: {
              'name': _nameController.text.trim(),
              'code': code,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Stokvel  ${_currentStep + 1}/4'),
        leading: BackButton(onPressed: _back),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _isCreating ? null : _next,
        onStepCancel: _back,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: _currentStep == 3 ? 'Create Stokvel' : 'Next',
                    onPressed: _isCreating ? null : details.onStepContinue,
                    isLoading: _isCreating,
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          // Step 1: Group Info
          Step(
            title: const Text('Group Info'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKeys[0],
              child: Column(
                children: [
                  AppTextField(
                    label: 'Group Name',
                    hint: 'Umoja Savings',
                    controller: _nameController,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const Gap(16),
                  Text(
                    'Stokvel Type',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Gap(8),
                  DropdownButtonFormField<StokvelType>(
                    value: _selectedType,
                    decoration: const InputDecoration(),
                    items: StokvelType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedType = v);
                    },
                  ),
                  const Gap(16),
                  AppTextField(
                    label: 'Description (optional)',
                    hint: 'Monthly savings club for our community',
                    controller: _descriptionController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),

          // Step 2: Contribution Setup
          Step(
            title: const Text('Contribution Setup'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKeys[1],
              child: Column(
                children: [
                  AppTextField(
                    label: 'Contribution Amount',
                    hint: '500',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('R',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const Gap(16),
                  Text(
                    'Frequency',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    children: ['Weekly', 'Biweekly', 'Monthly'].map((f) {
                      return ChoiceChip(
                        label: Text(f),
                        selected: _frequency == f,
                        onSelected: (selected) {
                          if (selected) setState(() => _frequency = f);
                        },
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.2),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Step 3: Constitution
          Step(
            title: const Text('Constitution'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKeys[2],
              child: Column(
                children: [
                  Text(
                    'Every stokvel needs rules. Choose how:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Gap(16),
                  _ConstitutionOption(
                    icon: Icons.edit_note,
                    title: 'Use our template',
                    subtitle: 'Pre-filled based on your stokvel type',
                    selected: _constitutionChoice == 'template',
                    onTap: () =>
                        setState(() => _constitutionChoice = 'template'),
                  ),
                  const Gap(8),
                  _ConstitutionOption(
                    icon: Icons.upload_file,
                    title: 'Upload your own',
                    subtitle: 'PDF or photo of your existing constitution',
                    selected: _constitutionChoice == 'upload',
                    onTap: () =>
                        setState(() => _constitutionChoice = 'upload'),
                  ),
                  const Gap(8),
                  _ConstitutionOption(
                    icon: Icons.skip_next,
                    title: 'Skip for now',
                    subtitle: 'You can add this later in settings',
                    selected: _constitutionChoice == 'skip',
                    onTap: () =>
                        setState(() => _constitutionChoice = 'skip'),
                  ),
                ],
              ),
            ),
          ),

          // Step 4: Invite Members
          Step(
            title: const Text('Invite Members'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKeys[3],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'After creating the group, you can invite members via a link or QR code.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Gap(16),
                  const Icon(
                    Icons.qr_code_2,
                    size: 80,
                    color: AppColors.textSecondaryLight,
                  ),
                  const Gap(16),
                  Text(
                    'An invite link and QR code will be generated after the group is created.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConstitutionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ConstitutionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          color: selected ? AppColors.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : null),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

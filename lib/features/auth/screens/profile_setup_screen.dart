import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../core/services/user_service.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedLanguage = 'English';
  bool _isLoading = false;
  File? _avatarFile;

  static const _languages = [
    'English',
    'isiZulu',
    'isiXhosa',
    'Sesotho',
  ];

  static const _langCodes = {
    'English': 'en',
    'isiZulu': 'zu',
    'isiXhosa': 'xh',
    'Sesotho': 'st',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (image != null) {
      setState(() => _avatarFile = File(image.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('avatars/${user.uid}.jpg');
        await storageRef.putFile(_avatarFile!);
        avatarUrl = await storageRef.getDownloadURL();
      }

      final profile = UserProfile(
        uid: user.uid,
        displayName: _nameController.text.trim(),
        phone: user.phoneNumber ?? '',
        avatarUrl: avatarUrl,
        createdAt: DateTime.now(),
        settings: UserSettings(
          language: _langCodes[_selectedLanguage] ?? 'en',
        ),
      );

      await UserService().createProfile(profile);

      if (mounted) {
        context.goNamed(RouteNames.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(16),
                Text(
                  'Set up your profile',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const Gap(32),
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: _avatarFile != null
                              ? FileImage(_avatarFile!)
                              : null,
                          child: _avatarFile == null
                              ? const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 32,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                        const Gap(8),
                        Text(
                          'Tap to add photo',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(32),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Thabo Molefe',
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const Gap(24),
                Text(
                  'Preferred Language',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Gap(8),
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: const InputDecoration(),
                  items: _languages
                      .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(lang),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLanguage = value);
                    }
                  },
                ),
                const Spacer(),
                AppButton(
                  label: 'Save & Continue',
                  onPressed: _isLoading ? null : _save,
                  isLoading: _isLoading,
                ),
                const Gap(16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

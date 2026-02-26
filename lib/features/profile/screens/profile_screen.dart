import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final authState = ref.watch(authStateProvider);
    final isDark = ref.watch(darkModeProvider);

    final profile = profileAsync.valueOrNull;
    final displayName = profile?.displayName ?? 'Loading...';
    final phone = profile?.phone ?? authState.user?.phoneNumber ?? '';
    final avatarUrl = profile?.avatarUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person,
                          size: 48, color: AppColors.primary)
                      : null,
                ),
                const Gap(12),
                Text(displayName,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(phone, style: Theme.of(context).textTheme.bodySmall),
                const Gap(8),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          const Gap(24),

          // Settings section
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          _SettingsRow(
            title: 'Language',
            trailing: DropdownButton<String>(
              value: profile?.settings.language.toUpperCase() ?? 'EN',
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'EN', child: Text('EN')),
                DropdownMenuItem(value: 'ZU', child: Text('ZU')),
                DropdownMenuItem(value: 'XH', child: Text('XH')),
                DropdownMenuItem(value: 'ST', child: Text('ST')),
              ],
              onChanged: (v) {
                if (v != null && authState.user != null) {
                  UserService().updateSettings(authState.user!.uid, {
                    'darkMode': isDark,
                    'language': v.toLowerCase(),
                    'notificationsEnabled':
                        profile?.settings.notificationsEnabled ?? true,
                  });
                }
              },
            ),
          ),
          _SettingsRow(
            title: 'Dark Mode',
            trailing: Switch(
              value: isDark,
              onChanged: (v) {
                ref.read(darkModeProvider.notifier).state = v;
                if (authState.user != null) {
                  UserService().updateSettings(authState.user!.uid, {
                    'darkMode': v,
                    'language': profile?.settings.language ?? 'en',
                    'notificationsEnabled':
                        profile?.settings.notificationsEnabled ?? true,
                  });
                }
              },
            ),
          ),
          _SettingsRow(
            title: 'Notifications',
            trailing: Switch(
              value: profile?.settings.notificationsEnabled ?? true,
              onChanged: (v) {
                if (authState.user != null) {
                  UserService().updateSettings(authState.user!.uid, {
                    'darkMode': isDark,
                    'language': profile?.settings.language ?? 'en',
                    'notificationsEnabled': v,
                  });
                }
              },
            ),
          ),
          const Gap(24),

          // About section
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          _AboutRow(title: 'Terms of Service', onTap: () {}),
          _AboutRow(title: 'Privacy Policy', onTap: () {}),
          _AboutRow(title: 'Help & Support', onTap: () {}),
          _AboutRow(title: 'Rate the App', onTap: () {}),
          const Gap(24),

          // Account section
          Text('Account', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          AppButton(
            label: 'Log Out',
            variant: AppButtonVariant.outline,
            onPressed: () async {
              await ref.read(authStateProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/onboarding');
              }
            },
          ),
          const Gap(8),
          AppButton(
            label: 'Delete Account',
            variant: AppButtonVariant.outline,
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                      'Are you sure? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Account deletion would require re-auth + Cloud Function
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ),
          const Gap(16),
          Center(
            child: Text(
              'v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Gap(16),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final Widget trailing;

  const _SettingsRow({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          trailing,
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _AboutRow({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

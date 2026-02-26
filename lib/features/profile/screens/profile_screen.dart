import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _language = 'EN';
  bool _darkMode = false;
  bool _notifications = true;
  bool _whatsappAlerts = true;

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(Icons.person,
                      size: 48, color: AppColors.primary),
                ),
                const Gap(12),
                Text('Thabo Molefe',
                    style: Theme.of(context).textTheme.headlineSmall),
                Text('+27 82 123 4567',
                    style: Theme.of(context).textTheme.bodySmall),
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
              value: _language,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'EN', child: Text('EN')),
                DropdownMenuItem(value: 'ZU', child: Text('ZU')),
                DropdownMenuItem(value: 'XH', child: Text('XH')),
                DropdownMenuItem(value: 'ST', child: Text('ST')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _language = v);
              },
            ),
          ),
          _SettingsRow(
            title: 'Dark Mode',
            trailing: Switch(
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
          ),
          _SettingsRow(
            title: 'Notifications',
            trailing: Switch(
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
          ),
          _SettingsRow(
            title: 'WhatsApp Alerts',
            trailing: Switch(
              value: _whatsappAlerts,
              onChanged: (v) => setState(() => _whatsappAlerts = v),
            ),
          ),
          const Gap(24),

          // About section
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          _AboutRow(
            title: 'Terms of Service',
            onTap: () {},
          ),
          _AboutRow(
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _AboutRow(
            title: 'Help & Support',
            onTap: () {},
          ),
          _AboutRow(
            title: 'Rate the App',
            onTap: () {},
          ),
          const Gap(24),

          // Account section
          Text('Account', style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          AppButton(
            label: 'Log Out',
            variant: AppButtonVariant.outline,
            onPressed: () {
              // TODO: Implement logout
            },
          ),
          const Gap(8),
          AppButton(
            label: 'Delete Account',
            variant: AppButtonVariant.outline,
            onPressed: () {
              // TODO: Implement account deletion
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

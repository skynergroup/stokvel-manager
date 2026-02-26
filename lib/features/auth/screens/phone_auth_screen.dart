import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.phoneValidationEmpty;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) {
      return l10n.phoneValidationInvalid;
    }
    return null;
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final phoneNumber = '+27$digits';
    ref.read(authStateProvider.notifier).verifyPhoneNumber(phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.status == AuthStatus.codeSent) {
        context.goNamed(RouteNames.otp);
      }
      if (next.status == AuthStatus.verified) {
        return;
      }
      if (next.status == AuthStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcomeTo,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  l10n.appName,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const Gap(8),
                Text(
                  l10n.phoneAuthTitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
                const Gap(32),
                AppTextField(
                  label: l10n.phoneNumber,
                  hint: l10n.phoneHint,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  prefix: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\u{1F1FF}\u{1F1E6}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Gap(4),
                        Text(
                          '+27',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Gap(8),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.divider,
                        ),
                      ],
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                ),
                const Gap(12),
                Text(
                  l10n.phoneSmsNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Gap(32),
                AppButton(
                  label: l10n.continueButton,
                  onPressed: isLoading ? null : _continue,
                  isLoading: isLoading,
                ),
                const Gap(24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.or,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const Gap(24),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(authStateProvider.notifier)
                          .signInWithGoogle(),
                  icon: Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    height: 20,
                    width: 20,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                    ),
                  ),
                  label: Text(l10n.continueWithGoogle),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.divider),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: l10n.termsPrefix,
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: l10n.terms,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: l10n.and),
                        TextSpan(
                          text: l10n.privacyPolicy,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

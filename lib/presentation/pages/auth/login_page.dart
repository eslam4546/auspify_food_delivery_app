import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:food_delivery_application/main.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_cubit.dart';
import 'package:food_delivery_application/presentation/cubits/auth/auth_state.dart';
import 'package:food_delivery_application/presentation/cubits/theme/theme_cubit.dart';
import 'package:food_delivery_application/presentation/pages/auth/register_page.dart';

/// Stitch Screen 1 (`d2f8c483b5094b2d94af6d5221410993`): Sign In View.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitSignIn() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _openRegisterPage() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const RegisterPage(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          (current.isAuthenticated && !previous.isAuthenticated) ||
          (current.errorMessage != null &&
              current.errorMessage != previous.errorMessage),
      listener: (context, state) {
        if (state.isAuthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const AuthenticatedShellPage(),
            ),
            (route) => false,
          );
          return;
        }
        final message = state.errorMessage;
        if (message != null && message.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.error,
              ),
            );
          context.read<AuthCubit>().clearError();
        }
      },
      builder: (context, authState) {
        final isSubmitting = authState.isSubmitting;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColors.spaceLg,
                vertical: AppColors.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildUtilityBar(context, isDark),
                  const SizedBox(height: AppColors.spaceMd),
                  _buildBrandHeader(theme, isDark),
                  const SizedBox(height: AppColors.spaceXl),
                  _buildModeSwitcher(isDark),
                  const SizedBox(height: AppColors.spaceLg),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Email Address',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified Safe',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            hintText: 'name@example.com',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Email address is required.';
                            }
                            if (!text.contains('@') || !text.contains('.')) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppColors.spaceMd),
                        Text(
                          'Password',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !isSubmitting,
                          onFieldSubmitted: (_) => _submitSignIn(),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Password is required.';
                            }
                            if ((value ?? '').length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppColors.spaceSm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () =>
                                  setState(() => _rememberMe = !_rememberMe),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v ?? true),
                                    activeColor: AppColors.primary,
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  Text(
                                    'Remember me',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Use your registered email or Continue with Google.',
                                              ),
                                            ),
                                          );
                                    },
                              child: Text(
                                'Forgot Password?',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppColors.spaceSm),
                        ElevatedButton(
                          onPressed: isSubmitting ? null : _submitSignIn,
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Sign In to Cravee'),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppColors.spaceLg),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Or continue with',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppColors.spaceLg),
                  OutlinedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () => context.read<AuthCubit>().signInWithGoogle(),
                    icon: const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 28,
                      color: AppColors.primary,
                    ),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: AppColors.spaceLg),
                  Container(
                    padding: const EdgeInsets.all(AppColors.spaceMd),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : const Color(0xFFEAEDFF).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(
                        AppColors.radiusControl,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft.withValues(
                              alpha: isDark ? 0.2 : 1.0,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppColors.spaceMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instant Onboarding',
                                style: theme.textTheme.labelLarge,
                              ),
                              Text(
                                'Order your first feast in under 30 seconds',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppColors.spaceLg),
                  Text(
                    'By signing in, you agree to Cravee\'s Terms of Service and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUtilityBar(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondarySoft,
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 4, backgroundColor: AppColors.secondary),
              SizedBox(width: 6),
              Text(
                'CRAVEE • WARM COURIER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryDeep,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            final dark = mode == ThemeMode.dark;
            return InkWell(
              borderRadius: BorderRadius.circular(AppColors.radiusPill),
              onTap: () => context.read<ThemeCubit>().toggleTheme(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      size: 16,
                      color: AppColors.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dark ? 'Dark' : 'Light',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBrandHeader(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [AppColors.primaryDeep, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.cardShadow(theme.brightness),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppColors.spaceMd),
        Text('Cravee', style: theme.textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(
          'Satisfy your cravings in minutes. Fresh, hot, and right to your door.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFE2E7FF),
        borderRadius: BorderRadius.circular(AppColors.radiusControl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardElevated : Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: AppColors.cardShadow(
                  isDark ? Brightness.dark : Brightness.light,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.login_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sign In',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: _openRegisterPage,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../services/auth_service.dart';
import 'auth_input_field.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg     = AppColors.surface;
const _kCard   = AppColors.card;
const _kGreen  = AppColors.primary;
const _kGrey   = AppColors.textSecondary;
const _kBorder = AppColors.border;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading       = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await AuthService.signIn(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // Router redirect fires automatically — no manual navigation needed.
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading    = false;
          _errorMessage = AuthService.friendlyError(e);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading    = false;
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  void _onForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ForgotPasswordSheet(),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBranding(),
                const SizedBox(height: 48),
                _buildHeadline(),
                const SizedBox(height: 32),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 10),
                _buildForgotLink(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBanner(),
                ],
                const SizedBox(height: 28),
                _buildLoginButton(),
                const SizedBox(height: 32),
                _buildSignupRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildBranding() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _kGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.medication_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'CarerMeds',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeadline() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Sign in to manage your family medicines.',
          style: TextStyle(fontSize: 14, color: _kGrey),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return AuthInputField(
      controller:   _emailCtrl,
      label:        'Email address',
      hint:         'you@example.com',
      icon:         Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Please enter your email';
        if (!v.contains('@')) return 'Enter a valid email address';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return AuthInputField(
      controller:    _passwordCtrl,
      label:         'Password',
      hint:          '••••••••',
      icon:          Icons.lock_outline_rounded,
      obscureText:   _obscurePassword,
      suffixIcon:    GestureDetector(
        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
        child: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: _kGrey,
          size: 20,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please enter your password';
        return null;
      },
    );
  }

  Widget _buildForgotLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _onForgotPassword,
        child: const Text(
          'Forgot password?',
          style: TextStyle(
            fontSize: 13,
            color: _kGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isLoading ? _kGreen.withOpacity(0.6) : _kGreen,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: _kGreen.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Sign in',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSignupRow() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'New to CarerMeds? ',
            style: TextStyle(fontSize: 14, color: _kGrey),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.signup),
            child: const Text(
              'Create account',
              style: TextStyle(
                fontSize: 14,
                color: _kGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Forgot password bottom sheet ──────────────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  bool   _isSending  = false;
  bool   _sent        = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    setState(() { _isSending = true; _error = null; });
    try {
      await AuthService.resetPassword(email);
      if (mounted) setState(() { _isSending = false; _sent = true; });
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() {
        _isSending = false;
        _error = AuthService.friendlyError(e);
      });
    } catch (_) {
      if (mounted) setState(() {
        _isSending = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Reset your password',
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Enter your email and we'll send you a reset link.",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_sent)
            _SentConfirmation(email: _emailCtrl.text.trim())
          else ...[
            AuthInputField(
              controller:   _emailCtrl,
              label:        'Email address',
              hint:         'you@example.com',
              icon:         Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(fontSize: 13, color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isSending ? null : _onSend,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _isSending
                      ? AppColors.primary.withOpacity(0.6)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send reset link',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  final String email;
  const _SentConfirmation({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reset link sent to $email. Check your inbox.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import 'auth_input_field.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kGreen = AppColors.primary;
const _kGrey  = AppColors.textSecondary;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _isLoading       = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _onSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await AuthService.signUp(
        name:     _nameCtrl.text.trim(),
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // Router redirect fires automatically on auth state change.
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                const SizedBox(height: 32),
                _buildHeadline(),
                const SizedBox(height: 32),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildConfirmField(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBanner(),
                ],
                const SizedBox(height: 28),
                _buildSignupButton(),
                const SizedBox(height: 32),
                _buildLoginRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chevron_left_rounded, color: _kGreen, size: 24),
          const Text(
            'Sign in',
            style: TextStyle(
              fontSize: 14,
              color: _kGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Keep your family medicines safe and organised.',
          style: TextStyle(fontSize: 14, color: _kGrey),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return AuthInputField(
      controller: _nameCtrl,
      label:      'Your name',
      hint:       'e.g. Pradeep Kumar',
      icon:       Icons.person_outline_rounded,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Please enter your name';
        return null;
      },
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
      controller:  _passwordCtrl,
      label:       'Password',
      hint:        '••••••••',
      icon:        Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
        child: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: _kGrey, size: 20,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please enter a password';
        if (v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }

  Widget _buildConfirmField() {
    return AuthInputField(
      controller:  _confirmCtrl,
      label:       'Confirm password',
      hint:        '••••••••',
      icon:        Icons.lock_outline_rounded,
      obscureText: _obscureConfirm,
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
        child: Icon(
          _obscureConfirm
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: _kGrey, size: 20,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please confirm your password';
        if (v != _passwordCtrl.text) return 'Passwords do not match';
        return null;
      },
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

  Widget _buildSignupButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onSignup,
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
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white,
                  ),
                )
              : const Text(
                  'Create account',
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

  Widget _buildLoginRow(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Already have an account? ',
            style: TextStyle(fontSize: 14, color: _kGrey),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: const Text(
              'Sign in',
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../services/auth_service.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kCard  = AppColors.card;
const _kGreen = AppColors.primary;
const _kGrey  = AppColors.textSecondary;
const _kRed   = AppColors.danger;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user      = FirebaseAuth.instance.currentUser;
    final name      = user?.displayName ?? '';
    final email     = user?.email ?? '';
    final initial   = (name.isNotEmpty ? name[0] : email.isNotEmpty ? email[0] : '?')
        .toUpperCase();

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar + name + email ──────────────────────────────────
                    _buildAccountCard(initial, name, email),
                    const SizedBox(height: 28),

                    // ── Preferences ────────────────────────────���──────────────
                    _sectionLabel('PREFERENCES'),
                    const SizedBox(height: 10),
                    _buildPreferencesCard(context),
                    const SizedBox(height: 28),

                    // ─��� About ─────────────────────────���───────────────────────
                    _sectionLabel('ABOUT'),
                    const SizedBox(height: 10),
                    _buildAboutCard(),
                    const SizedBox(height: 36),

                    // ── Sign out ──────────────────────────��────────────────────
                    _buildSignOutButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────���──────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Row(
              children: [
                Icon(Icons.chevron_left_rounded, color: _kGreen, size: 22),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 14,
                    color: _kGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Text(
              'Profile & Settings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 52), // balance the back button
        ],
      ),
    );
  }

  // ── Account card ─────────────────────────────���──────────────���─────────────────

  Widget _buildAccountCard(String initial, String name, String email) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _kGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kGreen.withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (name.isNotEmpty) const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: name.isNotEmpty ? _kGrey : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Caregiver',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Preferences card ────────────────────────────────────────────────��─────────

  Widget _buildPreferencesCard(BuildContext context) {
    return _card([
      _navRow(
        context: context,
        iconBg: AppColors.dangerLight,
        icon: Icons.notifications_outlined,
        iconColor: _kRed,
        title: 'Alert settings',
        subtitle: 'Expiry, opened & notification preferences',
        onTap: () => context.push(AppRoutes.alertSettings),
      ),
    ]);
  }

  // ── About card ────────────────────────────────��───────────────────────────────

  Widget _buildAboutCard() {
    return _card([
      _infoRow(
        iconBg: AppColors.primaryLight,
        icon: Icons.medication_rounded,
        iconColor: _kGreen,
        title: 'MedBox',
        trailing: 'Version 1.0.0',
      ),
      _divider(),
      _infoRow(
        iconBg: const Color(0xFFF0F0EB),
        icon: Icons.shield_outlined,
        iconColor: _kGrey,
        title: 'Privacy & data',
        trailing: 'Data stored securely in Firebase',
      ),
    ]);
  }

  // ── Sign-out button ─────────────────────────────���───────────────────────────���─

  Widget _buildSignOutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmSignOut(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dangerBorder),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: _kRed, size: 18),
            SizedBox(width: 8),
            Text(
              'Sign out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign out?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'You will need to sign in again to access your medicines.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'Sign out',
              style: TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) await AuthService.signOut();
    // Router redirect fires automatically after sign-out.
  }

  // ── Component helpers ───────────────────────��─────────────────────────────────

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: _kGrey,
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _navRow({
    required BuildContext context,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _iconBox(iconBg, icon, iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: _kGrey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kGrey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _iconBox(iconBg, icon, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(fontSize: 12, color: _kGrey),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(Color bg, IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border,
        indent: 14,
        endIndent: 14,
      );
}

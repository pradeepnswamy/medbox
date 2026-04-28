import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kCard  = AppColors.card;
const _kGreen = AppColors.primary;
const _kAmber = AppColors.warning;
const _kBlue  = AppColors.rxBlue;
const _kRed   = AppColors.danger;
const _kGrey  = AppColors.textSecondary;

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  // ── Settings state ────────────────────────────────────────────────────────────
  bool _expiryAlertsEnabled      = true;
  bool _openedAlertsEnabled      = true;
  bool _pushNotificationsEnabled = true;
  bool _inAppBanners             = true;
  bool _showBadgeCount           = true;

  // Multi-select day thresholds (1 / 7 / 30 / 60)
  final Set<int> _selectedDays = {7, 30};

  // Single-select month threshold (1 / 2 / 3 / 6)
  int _selectedMonths = 3;

  // Daily check time
  TimeOfDay _checkTime = const TimeOfDay(hour: 9, minute: 0);

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('EXPIRY ALERTS'),
                    const SizedBox(height: 10),
                    _buildExpirySection(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('OPENED MEDICINE ALERTS'),
                    const SizedBox(height: 10),
                    _buildOpenedSection(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('NOTIFICATION DELIVERY'),
                    const SizedBox(height: 10),
                    _buildNotificationSection(context),
                    const SizedBox(height: 20),
                    _buildSectionLabel('ALERT BADGE'),
                    const SizedBox(height: 10),
                    _buildBadgeSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Row(
              children: [
                Icon(Icons.chevron_left_rounded, color: _kRed, size: 22),
                Text(
                  'Alerts',
                  style: TextStyle(
                      fontSize: 14,
                      color: _kRed,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Text(
              'Alert settings',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: const Text(
              'Done',
              style: TextStyle(
                  fontSize: 15,
                  color: _kGreen,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Blue-tinted info banner at the top of settings.
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.rxBlueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlue.withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _kBlue, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Alerts run daily in the background and send push notifications even when the app is closed.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.rxBlueDark, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
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

  // ── EXPIRY ALERTS card ────────────────────────────────────────────────────────

  Widget _buildExpirySection() {
    return _settingsCard([
      _toggleRow(
        iconBg: AppColors.warningLight,
        icon: Icons.timer_outlined,
        iconColor: _kAmber,
        title: 'Expiry alerts',
        subtitle: 'Notify when medicines are near expiry',
        value: _expiryAlertsEnabled,
        onChanged: (v) => setState(() => _expiryAlertsEnabled = v),
      ),
      _divider(),
      _chipRow(
        iconBg: AppColors.surface,
        icon: Icons.calendar_today_rounded,
        iconColor: _kGrey,
        title: 'Alert me at',
        subtitle: 'Days before expiry date',
        child: _buildDayChips(),
      ),
    ]);
  }

  Widget _buildDayChips() {
    final options = [
      (1, '1\nday'),
      (7, '7\ndays'),
      (30, '30\ndays'),
      (60, '60\ndays'),
    ];
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final selected = _selectedDays.contains(opt.$1);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedDays.remove(opt.$1);
            } else {
              _selectedDays.add(opt.$1);
            }
          }),
          child: Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? _kGreen.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? _kGreen : AppColors.border,
              ),
            ),
            child: Text(
              opt.$2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? _kGreen : _kGrey,
                height: 1.3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── OPENED MEDICINE ALERTS card ───────────────────────────────────────────────

  Widget _buildOpenedSection() {
    return _settingsCard([
      _toggleRow(
        iconBg: AppColors.warningLight,
        icon: Icons.warning_amber_rounded,
        iconColor: _kAmber,
        title: 'Opened alerts',
        subtitle: 'Notify when opened medicine is aging',
        value: _openedAlertsEnabled,
        onChanged: (v) => setState(() => _openedAlertsEnabled = v),
      ),
      _divider(),
      _chipRow(
        iconBg: AppColors.surface,
        icon: Icons.schedule_rounded,
        iconColor: _kGrey,
        title: 'Alert threshold',
        subtitle: 'Fire alert after this many months opened',
        child: _buildMonthChips(),
      ),
    ]);
  }

  Widget _buildMonthChips() {
    final options = [
      (1, '1\nmonth'),
      (2, '2\nmonths'),
      (3, '3\nmonths'),
      (6, '6\nmonths'),
    ];
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final selected = _selectedMonths == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedMonths = opt.$1),
          child: Container(
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? _kGreen.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? _kGreen : AppColors.border,
              ),
            ),
            child: Text(
              opt.$2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? _kGreen : _kGrey,
                height: 1.3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── NOTIFICATION DELIVERY card ─────────────────────────────────────────────────

  Widget _buildNotificationSection(BuildContext context) {
    final h   = _checkTime.hourOfPeriod == 0 ? 12 : _checkTime.hourOfPeriod;
    final m   = _checkTime.minute.toString().padLeft(2, '0');
    final p   = _checkTime.period == DayPeriod.am ? 'AM' : 'PM';
    final timeLabel = '$h:$m $p';

    return _settingsCard([
      _toggleRow(
        iconBg: AppColors.rxBlueLight,
        icon: Icons.notifications_outlined,
        iconColor: _kBlue,
        title: 'Push notifications',
        subtitle: 'System notifications on your phone',
        value: _pushNotificationsEnabled,
        onChanged: (v) => setState(() => _pushNotificationsEnabled = v),
      ),
      _divider(),
      // Daily check time — tappable row with time on right
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _iconContainer(
              bg: AppColors.rxBlueLight,
              icon: Icons.access_time_rounded,
              color: _kBlue,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily check time',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'When to run the daily alert check',
                    style: TextStyle(fontSize: 12, color: _kGrey),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _checkTime,
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: _kGreen,
                        surface: AppColors.card,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _checkTime = picked);
              },
              child: Text(
                '$timeLabel ›',
                style: const TextStyle(
                  fontSize: 13,
                  color: _kBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      _divider(),
      _toggleRow(
        iconBg: AppColors.surface,
        icon: Icons.phone_android_rounded,
        iconColor: _kGrey,
        title: 'In-app banners',
        subtitle: 'Show alert banners on dashboard',
        value: _inAppBanners,
        onChanged: (v) => setState(() => _inAppBanners = v),
      ),
    ]);
  }

  // ── ALERT BADGE card ──────────────────────────────────────────────────────────

  Widget _buildBadgeSection() {
    return _settingsCard([
      _toggleRow(
        iconBg: AppColors.dangerLight,
        icon: Icons.circle_notifications_rounded,
        iconColor: _kRed,
        title: 'Show badge count',
        subtitle: 'Red dot on app icon with alert count',
        value: _showBadgeCount,
        onChanged: (v) => setState(() => _showBadgeCount = v),
      ),
    ]);
  }

  // ── Component helpers ─────────────────────────────────────────────────────────

  /// Wraps a list of widgets in a white rounded card.
  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  /// A row with icon container + title/subtitle + green toggle.
  Widget _toggleRow({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _iconContainer(bg: iconBg, icon: icon, color: iconColor),
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
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: _kGreen,
              inactiveTrackColor: AppColors.border,
              inactiveThumbColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// A row with icon + title/subtitle + a chip grid below.
  Widget _chipRow({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconContainer(bg: iconBg, icon: icon, color: iconColor),
              const SizedBox(width: 12),
              Column(
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
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _iconContainer(
      {required Color bg, required IconData icon, required Color color}) {
    return Container(
      width: 40,
      height: 40,
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
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

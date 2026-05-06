import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';
import '../screens/dashboard/dashboard_screen.dart';

/// Persistent bottom-navigation shell used by [StatefulShellRoute].
///
/// Layout (visual left → right):  Medicines | Patients | [HOME] | Prescriptions | Alerts
/// Branch mapping (go_router branches): Home=0, Medicines=1, Patients=2, Prescriptions=3, Alerts=4
///
/// Visual index → branch index:  0→1, 1→2, 2→0 (Home), 3→3, 4→4
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {

  // Maps visual slot (0–4) to go_router branch index
  static const _branchForVisual = [1, 2, 0, 3, 4];

  // Per-tab animation controllers for bounce
  late final List<AnimationController> _controllers;
  late final List<Animation<double>>   _scales;

  static const _regularTabs = [
    _TabItem(icon: Icons.medication_rounded,    label: 'Medicines'),
    _TabItem(icon: Icons.people_rounded,        label: 'Patients'),
    null, // center slot — rendered as raised HOME button
    _TabItem(icon: Icons.description_rounded,   label: 'Prescriptions'),
    _TabItem(icon: Icons.notifications_rounded, label: 'Alerts'),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    ));
    _scales = _controllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.80), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.80, end: 1.10), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.10, end: 1.0),  weight: 30),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _currentBranch => widget.navigationShell.currentIndex;

  // Visual index for the currently-selected branch
  int get _selectedVisual =>
      _branchForVisual.indexOf(_currentBranch).clamp(0, 4);

  void _onTap(int visualIndex) {
    final branch = _branchForVisual[visualIndex];
    _controllers[visualIndex].forward(from: 0);

    // When switching TO the dashboard (branch 0) from a different tab,
    // trigger a data reload so newly added medicines / patients / prescriptions
    // are reflected immediately.  StatefulShellRoute keeps widget state alive,
    // so initState() only runs once — the callback bridges that gap.
    if (branch == 0 && branch != _currentBranch) {
      DashboardScreen.onBranchActivated?.call();
    }

    widget.navigationShell.goBranch(
      branch,
      initialLocation: branch == _currentBranch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: widget.navigationShell,
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Row of 5 equal slots ──────────────────────────────────────
              Row(
                children: List.generate(5, (visual) {
                  if (visual == 2) {
                    // Center slot: transparent placeholder — button drawn in Stack
                    return const Expanded(child: SizedBox());
                  }
                  return Expanded(child: _buildRegularTab(visual));
                }),
              ),

              // ── Raised Home button (center slot) ─────────────────────────
              Positioned(
                top: -18,
                left: 0,
                right: 0,
                child: Center(child: _buildHomeButton()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Regular tab (non-home) ────────────────────────────────────────────────

  Widget _buildRegularTab(int visual) {
    final tab      = _regularTabs[visual]!;
    final selected = visual == _selectedVisual;
    final isAlerts = visual == 4;
    final color    = selected
        ? (isAlerts ? AppColors.danger : AppColors.primary)
        : AppColors.textSecondary;

    return Semantics(
      label: tab.label,
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(visual),
        child: AnimatedBuilder(
          animation: _scales[visual],
          builder: (_, child) => Transform.scale(
            scale: _scales[visual].value,
            child: child,
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: selected
                  ? BoxDecoration(
                      color: isAlerts
                          ? AppColors.dangerLight
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isAlerts ? AppColors.danger : AppColors.primary)
                              .withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    )
                  : const BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, color: color, size: 21),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tab.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Raised Home button ────────────────────────────────────────────────────

  Widget _buildHomeButton() {
    final isHome   = _currentBranch == 0;
    final baseColor = AppColors.primary;

    return Semantics(
      label: 'Home, dashboard',
      button: true,
      selected: isHome,
      child: GestureDetector(
        onTap: () => _onTap(2),
        child: AnimatedBuilder(
          animation: _scales[2],
          builder: (_, child) => Transform.scale(
            scale: _scales[2].value,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              // Active: full-saturation green. Inactive: lighter tint so it
              // doesn't compete with the currently-selected regular tab pill.
              color: isHome ? baseColor : AppColors.primaryLight,
              shape: BoxShape.circle,
              border: isHome
                  ? null
                  : Border.all(color: baseColor.withOpacity(0.35), width: 1.5),
              boxShadow: isHome
                  ? [
                      BoxShadow(
                        color: baseColor.withOpacity(0.40),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: baseColor.withOpacity(0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: baseColor.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: ExcludeSemantics(
              child: Icon(
                Icons.home_rounded,
                // White icon on solid green when active; green icon on light pill when inactive
                color: isHome ? Colors.white : baseColor,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final String   label;
  const _TabItem({required this.icon, required this.label});
}

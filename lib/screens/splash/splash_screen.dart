import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';

/// App splash screen — shown on cold start while Firebase finishes any
/// remaining async work. Fades in the CarerMeds branding, then navigates to
/// the dashboard after a short delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double>    _fade;
  late final Animation<double>    _scale;

  @override
  void initState() {
    super.initState();

    // Force status-bar icons to white while on the green splash background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade  = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Navigate to home once the brief branding moment is over.
    // Firebase is already initialised synchronously in main() so no
    // additional waiting is needed here.
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        // Restore default status-bar style for the rest of the app
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        context.go(AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Clamp text scaling on the splash so the animated layout stays stable.
    // The branded title and tagline are decorative here — body content
    // elsewhere in the app scales freely.
    final splashScaler = MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── App icon ──────────────────────────────────────────────────
                Semantics(
                  label: 'CarerMeds',
                  header: true,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── App name ──────────────────────────────────────────────────
                ExcludeSemantics(
                  child: Text(
                    'CarerMeds',
                    textScaler: splashScaler,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Tagline ───────────────────────────────────────────────────
                Text(
                  'Your family medicine manager',
                  textScaler: splashScaler,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 64),

                // ── Subtle loading indicator ──────────────────────────────────
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.5),
                    ),
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

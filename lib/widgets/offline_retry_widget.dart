import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Full-screen error state shown when a Firestore fetch fails because the
/// device is offline and no locally-cached data is available.
///
/// Displays a contextual message and a "Try again" button that calls [onRetry].
class OfflineRetryWidget extends StatelessWidget {
  final VoidCallback onRetry;

  /// Override the default message when you have something more specific to say.
  final String? message;

  const OfflineRetryWidget({
    super.key,
    required this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 34,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'No internet connection',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Body
            Text(
              message ??
                  'Connect to the internet and tap Retry.\n'
                  'Your data will load from the server.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Retry button
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

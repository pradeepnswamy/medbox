import 'package:flutter/material.dart';

/// One cell of the 2×2 Overview grid.
///
/// [backgroundColor] is the card fill (mint, pink, amber, or dark).
/// [textColor] adjusts heading/value/subtitle for light vs dark cards.
///
/// Usage:
///   OverviewCard(
///     title: 'Total medicines',
///     value: '14',
///     subtitle: 'across 3 patients',
///     backgroundColor: Color(0xFFA8DDD0),
///     textColor: Color(0xFF1A1A2E),
///   )
class OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color backgroundColor;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback? onTap;

  const OverviewCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.backgroundColor,
    this.textColor = const Color(0xFF1A1A2E),
    this.subtitleColor = const Color(0xFF4ECBA0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

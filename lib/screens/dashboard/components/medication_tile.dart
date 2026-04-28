import 'package:flutter/material.dart';

/// Enum representing the current status of a medication dose.
enum MedicationStatus { taken, missed, upcoming }

/// A list tile that displays one medication entry with its name, dosage,
/// scheduled time, and a colour-coded status badge.
///
/// Usage:
///   MedicationTile(
///     name: 'Paracetamol',
///     dosage: '500 mg',
///     time: '08:00 AM',
///     status: MedicationStatus.taken,
///   )
class MedicationTile extends StatelessWidget {
  final String name;
  final String dosage;
  final String time;
  final MedicationStatus status;

  const MedicationTile({
    super.key,
    required this.name,
    required this.dosage,
    required this.time,
    required this.status,
  });

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Color get _statusColor {
    switch (status) {
      case MedicationStatus.taken:
        return const Color(0xFF4CAF50);
      case MedicationStatus.missed:
        return const Color(0xFFE53935);
      case MedicationStatus.upcoming:
        return const Color(0xFF1E88E5);
    }
  }

  String get _statusLabel {
    switch (status) {
      case MedicationStatus.taken:
        return 'Taken';
      case MedicationStatus.missed:
        return 'Missed';
      case MedicationStatus.upcoming:
        return 'Upcoming';
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case MedicationStatus.taken:
        return Icons.check_circle_rounded;
      case MedicationStatus.missed:
        return Icons.cancel_rounded;
      case MedicationStatus.upcoming:
        return Icons.schedule_rounded;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pill icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.medication_rounded, color: _statusColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Name & dosage
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dosage,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // Time & status badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(_statusIcon, color: _statusColor, size: 13),
                  const SizedBox(width: 3),
                  Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

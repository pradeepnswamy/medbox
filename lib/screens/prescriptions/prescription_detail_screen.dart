import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/medicine.dart';
import '../../models/prescription.dart';
import '../../services/data_service.dart';
import '../medicines/components/badge_chip.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kCard  = AppColors.card;
const _kGreen = AppColors.primary;
const _kGrey  = AppColors.textSecondary;

class PrescriptionDetailScreen extends StatefulWidget {
  final PrescriptionData prescription;

  const PrescriptionDetailScreen({super.key, required this.prescription});

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {

  PrescriptionData get _rx => widget.prescription;

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoCard(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('VISIT DETAILS'),
                    const SizedBox(height: 10),
                    _buildVisitDetailsTable(),
                    const SizedBox(height: 24),
                    _buildMedicinesHeader(context),
                    const SizedBox(height: 10),
                    _buildMedicinesList(context),
                    const SizedBox(height: 32),
                    _buildDeleteButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Row(
                  children: [
                    Icon(Icons.chevron_left_rounded, color: _kGreen, size: 22),
                    Text(
                      'Prescriptions',
                      style: TextStyle(fontSize: 14, color: _kGreen, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.prescriptionsAdd, extra: widget.prescription),
                child: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 14, color: _kGreen, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'Prescription detail',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.rxBlueLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_rounded, size: 40,
                color: AppColors.rxBlue),
            const SizedBox(height: 10),
            const Text('Prescription image',
                style: TextStyle(fontSize: 14, color: AppColors.rxBlue, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Tap to view full size',
                style: TextStyle(fontSize: 12, color: AppColors.rxBlue)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            letterSpacing: 1.2, color: _kGrey));
  }

  Widget _buildVisitDetailsTable() {
    return Container(
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          _infoRow('Patient', _rx.patientName, initials: _rx.patientInitials,
              avatarColor: _rx.patientAvatarColor),
          _divider(),
          _infoRow('Cause', _rx.cause),
          _divider(),
          _infoRow('Visit date', _rx.dateFull),
          _divider(),
          _infoRow('Doctor', _rx.doctor),
          _divider(),
          _infoRow('Hospital', _rx.hospitalFull),
          _divider(),
          _infoRow('Notes', _rx.notes),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {String? initials, Color? avatarColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13, color: _kGrey)),
          ),
          const SizedBox(width: 12),
          if (initials != null && avatarColor != null)
            Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
                child: Center(child: Text(initials,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            ])
          else
            Expanded(child: Text(value,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 1,
      color: AppColors.border, indent: 16, endIndent: 16);

  Widget _buildMedicinesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('MEDICINES (${_rx.medicines.length})',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: _kGrey)),
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Add medicine to prescription'))),
          child: const Text('Add medicine',
              style: TextStyle(fontSize: 12, color: _kGreen, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildMedicinesList(BuildContext context) {
    return Column(
      children: _rx.medicines.map((med) {
        BadgeStyle badgeStyle;
        Color iconColor;
        String statusLabel;
        switch (med.status) {
          case RxMedicineStatus.expiring:
            badgeStyle = BadgeStyle.expiring;
            iconColor = AppColors.danger;
            statusLabel = 'Expiring!';
            break;
          case RxMedicineStatus.opened:
            badgeStyle = BadgeStyle.opened;
            iconColor = AppColors.warning;
            statusLabel = 'Opened';
            break;
          default:
            badgeStyle = BadgeStyle.available;
            iconColor = _kGreen;
            statusLabel = 'Available';
        }

        return GestureDetector(
          onTap: () {
            final mockMed = MedicineData(
              id: '',
              name: med.name,
              patient: _rx.patientName,
              patientInitials: _rx.patientInitials,
              patientAvatarColor: _rx.patientAvatarColor,
              acquiredDate: 'Got ${_rx.date}',
              acquiredDateFull: _rx.dateFull,
              expiryLabel: med.expiryLabel,
              expiryDateFull: med.expiryLabel,
              expiryColor: iconColor,
              badges: [(statusLabel, badgeStyle)],
              attentionColor: null,
              form: 'Tablet',
              dosage: med.dosage,
              quantity: '—',
              notes: '—',
              linkedPrescription: _rx.cause,
              linkedPrescriptionMeta:
                  '${_rx.patientName} · ${_rx.date} · ${_rx.medicines.length} medicines',
              isOpened: med.status == RxMedicineStatus.opened,
              openedOn: 'Not recorded',
              topStatus: statusLabel,
            );
            context.push(AppRoutes.medicineDetail, extra: mockMed);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.medication_rounded, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(med.dosage, style: const TextStyle(fontSize: 12, color: _kGrey)),
                    ],
                  ),
                ),
                BadgeChip(label: statusLabel, style: badgeStyle),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: _kGrey, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Delete prescription?', style: TextStyle(color: AppColors.textPrimary)),
          content: const Text('This action cannot be undone.', style: TextStyle(color: _kGrey)),
          actions: [
            TextButton(onPressed: () => context.pop(),
                child: const Text('Cancel', style: TextStyle(color: _kGrey))),
            TextButton(
              onPressed: () async {
                context.pop(); // close dialog
                try {
                  await DataService.instance.deletePrescription(_rx.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prescription deleted'),
                        backgroundColor: AppColors.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    context.pop(); // pop detail screen
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Color(0xFFE53935))),
            ),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dangerBorder),
        ),
        child: const Center(
          child: Text('Delete prescription',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.danger)),
        ),
      ),
    );
  }

}

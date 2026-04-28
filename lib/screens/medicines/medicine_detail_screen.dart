import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/medicine.dart';
import '../../services/data_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/forms/image_picker_widget.dart';
import 'components/badge_chip.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg = AppColors.surface;
const _kCard = AppColors.card;
const _kGreen = AppColors.primary;
const _kLabel = AppColors.textSecondary;

class MedicineDetailScreen extends StatefulWidget {
  final MedicineData medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late bool _isOpened;

  /// Current photo path — may be updated without leaving the detail screen.
  String? _photoPath;
  bool _photoSaving = false;

  @override
  void initState() {
    super.initState();
    _isOpened = widget.medicine.isOpened;
    _photoPath = widget.medicine.photoPath;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final med = widget.medicine;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed top header
            _buildTopBar(context),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoCard(),
                    const SizedBox(height: 20),
                    _buildNameAndBadges(med),
                    const SizedBox(height: 24),
                    _buildSectionLabel('MEDICINE INFO'),
                    const SizedBox(height: 10),
                    _buildInfoTable(med),
                    const SizedBox(height: 24),
                    _buildSectionLabel('DATES'),
                    const SizedBox(height: 10),
                    _buildDatesTable(med),
                    if (med.linkedPrescription != null) ...[
                      const SizedBox(height: 24),
                      _buildSectionLabel('LINKED PRESCRIPTION'),
                      const SizedBox(height: 10),
                      _buildLinkedPrescription(med),
                    ],
                    const SizedBox(height: 32),
                    _buildDeleteButton(),
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

  /// Back arrow + title + Edit action.
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ← Medicines
              GestureDetector(
                onTap: () => context.pop(),
                child: const Row(
                  children: [
                    Icon(Icons.chevron_left_rounded, color: _kGreen, size: 22),
                    Text(
                      'Medicines',
                      style: TextStyle(
                        fontSize: 14,
                        color: _kGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit
              GestureDetector(
                onTap: () async {
                  final saved = await context.push<bool>(
                    AppRoutes.medicinesAdd,
                    extra: widget.medicine,
                  );
                  // If the user saved changes, pop back to the list so it reloads
                  if (saved == true && mounted) context.pop();
                },
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 14,
                    color: _kGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'Medicine detail',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Photo card — shows the saved image or an add-photo placeholder.
  Widget _buildPhotoCard() {
    return Stack(
      children: [
        ImagePickerWidget(
          savedPath: _photoPath,
          onTap: () {
            final hasPhoto =
                _photoPath != null && File(_photoPath!).existsSync();
            if (hasPhoto) {
              _showPhotoSheet();
            } else {
              _showPickerSheet();
            }
          },
          height: 200,
        ),
        // Saving spinner overlay
        if (_photoSaving)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Photo sheet — shown when a photo already exists ───────────────────────────

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _sheetOption(
                icon: Icons.fullscreen_rounded,
                label: 'View full size',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _openFullScreen();
                },
              ),
              const SizedBox(height: 4),
              _sheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Replace with camera',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndSave(ImageSource.camera);
                },
              ),
              const SizedBox(height: 4),
              _sheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Replace from gallery',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndSave(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 4),
              _sheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove photo',
                color: AppColors.danger,
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _removePhoto();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Picker sheet — shown when no photo exists ─────────────────────────────────

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _sheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take a photo',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndSave(ImageSource.camera);
                },
              ),
              const SizedBox(height: 4),
              _sheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _pickAndSave(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: c,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pick → compress → persist → update Firestore ──────────────────────────────

  Future<void> _pickAndSave(ImageSource source) async {
    // Camera may not be available on iOS Simulator.
    if (source == ImageSource.camera &&
        !(await ImagePicker().supportsImageSource(ImageSource.camera))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera not available on this device. Use Gallery instead.'),
          ),
        );
      }
      return;
    }

    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null || !mounted) return;

    setState(() => _photoSaving = true);
    try {
      // Delete old photo file if one exists.
      if (_photoPath != null) {
        final old = File(_photoPath!);
        if (await old.exists()) await old.delete();
      }

      // Copy to app documents dir with a stable name.
      final docsDir  = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${docsDir.path}/medicine_photos');
      await photosDir.create(recursive: true);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final dest     = File('${photosDir.path}/$fileName');
      final bytes    = await ImageUtils.compressAndResize(File(file.path));
      await dest.writeAsBytes(bytes);

      // Persist to Firestore.
      final updated = widget.medicine.copyWith(photoPath: dest.path);
      await DataService.instance.updateMedicine(updated);

      if (mounted) setState(() { _photoPath = dest.path; _photoSaving = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _photoSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save photo: $e')),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _photoSaving = true);
    try {
      // Delete the local file.
      if (_photoPath != null) {
        final f = File(_photoPath!);
        if (await f.exists()) await f.delete();
      }
      // Clear in Firestore.
      final updated = widget.medicine.copyWith(photoPath: null);
      await DataService.instance.updateMedicine(updated);
      if (mounted) setState(() { _photoPath = null; _photoSaving = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _photoSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove photo: $e')),
        );
      }
    }
  }

  /// Push a full-screen image viewer (tap anywhere to close).
  void _openFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullScreenPhotoViewer(photoPath: _photoPath!),
      ),
    );
  }

  /// Medicine name + status badge chips.
  Widget _buildNameAndBadges(MedicineData med) {
    // Map topStatus to badge style
    BadgeStyle topBadgeStyle;
    switch (med.topStatus) {
      case 'Expiring':
        topBadgeStyle = BadgeStyle.expiring;
        break;
      case 'Opened':
        topBadgeStyle = BadgeStyle.opened;
        break;
      default:
        topBadgeStyle = BadgeStyle.available;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          med.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Status badge (filled)
            BadgeChip(
              label: med.topStatus,
              style: topBadgeStyle,
              filled: true,
            ),
            // Opened/Unopened badge
            BadgeChip(
              label: med.isOpened ? 'Opened' : 'Unopened',
              style: BadgeStyle.neutral,
            ),
            // Prescription badge (if any)
            if (med.linkedPrescription != null)
              BadgeChip(
                label:
                    '${med.linkedPrescription} · ${med.acquiredDateFull.substring(0, med.acquiredDateFull.lastIndexOf(' '))}',
                style: BadgeStyle.prescription,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: _kLabel,
      ),
    );
  }

  /// 5-row info table: Patient, Form, Dosage, Quantity, Notes.
  Widget _buildInfoTable(MedicineData med) {
    final rows = [
      ('Patient', null, med.patient, med.patientInitials, med.patientAvatarColor),
      ('Form', null, med.form, null, null),
      ('Dosage', null, med.dosage, null, null),
      ('Quantity', null, med.quantity, null, null),
      ('Notes', null, med.notes, null, null),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final r = rows[i];
          final label = r.$1 as String;
          final value = r.$3 as String;
          final initials = r.$4 as String?;
          final avatarColor = r.$5 as Color?;
          final isLast = i == rows.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kLabel,
                        ),
                      ),
                    ),
                    // Patient row: avatar + name
                    if (initials != null && avatarColor != null)
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: avatarColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      Expanded(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }

  /// 4-row dates table: purchased, expiry, opened on, opened status (toggle).
  Widget _buildDatesTable(MedicineData med) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _dateRow('Date purchased', med.acquiredDateFull, AppColors.textPrimary, false),
          _divider(),
          _dateRow('Expiry date', med.expiryDateFull, _kGreen, false),
          _divider(),
          _dateRow('Opened on', med.openedOn, AppColors.textPrimary, false),
          _divider(),
          // Opened status row with toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 110,
                  child: Text(
                    'Opened status',
                    style: TextStyle(fontSize: 13, color: _kLabel),
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _isOpened,
                    onChanged: (v) => setState(() => _isOpened = v),
                    activeColor: _kGreen,
                    inactiveTrackColor: AppColors.border,
                    inactiveThumbColor: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isOpened ? 'Opened' : 'Not opened',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isOpened ? _kGreen : _kLabel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateRow(String label, String value, Color valueColor, bool isLast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kLabel)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border,
        indent: 16,
        endIndent: 16,
      );

  /// Linked prescription card with document icon, title, meta, and chevron.
  Widget _buildLinkedPrescription(MedicineData med) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.rxBlueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: AppColors.rxBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.linkedPrescription!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  med.linkedPrescriptionMeta!,
                  style: const TextStyle(fontSize: 12, color: _kLabel),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: _kLabel,
            size: 20,
          ),
        ],
      ),
    );
  }

  /// Red outlined delete button.
  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text(
              'Delete medicine?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'This action cannot be undone.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel', style: TextStyle(color: _kLabel)),
              ),
              TextButton(
                onPressed: () async {
                  context.pop(); // close dialog
                  try {
                    await DataService.instance.deleteMedicine(
                      widget.medicine.id,
                      photoPath: _photoPath,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medicine deleted'),
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
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.dangerBorder,
          ),
        ),
        child: const Center(
          child: Text(
            'Delete medicine',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
            ),
          ),
        ),
      ),
    );
  }

}

// ── Full-screen photo viewer ───────────────────────────────────────────────────

class _FullScreenPhotoViewer extends StatelessWidget {
  final String photoPath;
  const _FullScreenPhotoViewer({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Pinch-to-zoom + pan via InteractiveViewer
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.white54, size: 60),
                  ),
                ),
              ),
            ),
            // Close button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
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

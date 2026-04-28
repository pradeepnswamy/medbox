import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../models/prescription.dart';
import '../../services/data_service.dart';
import '../../utils/date_utils.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kCard  = AppColors.card;
const _kGreen = AppColors.primary;
const _kBlue  = AppColors.rxBlue;
const _kGrey  = AppColors.textSecondary;

// ── Avatar palette (deterministic color from name hash) ───────────────────────
const _kPalette = AppColors.avatarPalette;
Color _avatarColor(String name) =>
    _kPalette[name.hashCode.abs() % _kPalette.length];

String _initials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  if (parts.isNotEmpty) return parts.first[0].toUpperCase();
  return '?';
}

class AddPrescriptionScreen extends StatefulWidget {
  /// When non-null the screen prefills with existing data (Edit mode).
  final PrescriptionData? existing;

  const AddPrescriptionScreen({super.key, this.existing});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late final TextEditingController _patientCtrl;
  late final TextEditingController _causeCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _doctorCtrl;
  late final TextEditingController _hospitalCtrl;
  late final TextEditingController _notesCtrl;

  bool   _isSaving = false;
  XFile? _pickedImage;

  // Existing patients loaded from Firestore for quick-select
  List<PrescriptionData>? _existingPrescriptions;

  List<String> get _knownPatients {
    final seen  = <String>{};
    final names = <String>[];
    for (final p in _existingPrescriptions ?? []) {
      if (seen.add(p.patientName)) names.add(p.patientName);
    }
    return names;
  }

  /// Inline medicine name list (editable rows).
  late final List<TextEditingController> _medicineCtrl;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final rx = widget.existing;
    _patientCtrl  = TextEditingController(text: rx?.patientName ?? '');
    _causeCtrl    = TextEditingController(text: rx?.cause ?? '');
    _dateCtrl     = TextEditingController(text: rx?.dateFull ?? '');
    _doctorCtrl   = TextEditingController(text: rx?.doctor ?? '');
    _hospitalCtrl = TextEditingController(text: rx?.hospitalFull ?? '');
    _notesCtrl    = TextEditingController(text: rx?.notes ?? '');
    _medicineCtrl = rx != null
        ? rx.medicines.map((m) => TextEditingController(text: m.name)).toList()
        : [TextEditingController()];

    DataService.instance.getPrescriptions().then((list) {
      if (mounted) setState(() => _existingPrescriptions = list);
    });
  }

  @override
  void dispose() {
    _patientCtrl.dispose();
    _causeCtrl.dispose();
    _dateCtrl.dispose();
    _doctorCtrl.dispose();
    _hospitalCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _medicineCtrl) c.dispose();
    super.dispose();
  }

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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotoCapture(),
                      const SizedBox(height: 14),
                      _buildPatientSection(),
                      const SizedBox(height: 14),
                      _buildVisitInfoSection(),
                      const SizedBox(height: 14),
                      _buildMedicinesSection(),
                      const SizedBox(height: 100), // space for pinned button
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildPinnedSaveButton(context),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────────

  /// Cancel | Add prescription | Save header bar.
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
          ),
          Text(
            _isEditMode ? 'Edit prescription' : 'Add prescription',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          GestureDetector(
            onTap: _isSaving ? null : _handleSave,
            child: Text('Save',
                style: TextStyle(
                    fontSize: 15,
                    color: _isSaving ? _kBlue.withOpacity(0.4) : _kBlue,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Photo picker ──────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    // Camera is not available on iOS Simulator — show a friendly message.
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
    final picker = ImagePicker();
    final file   = await picker.pickImage(
      source:       source,
      imageQuality: 85,
      maxWidth:     1400,
    );
    if (file != null && mounted) setState(() => _pickedImage = file);
  }

  /// Photo capture card with Camera + Gallery buttons.
  Widget _buildPhotoCapture() {
    final hasImage = _pickedImage != null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          // ── Picked image preview ───────────────────────────────────────────
          ? Stack(
              children: [
                Image.file(
                  File(_pickedImage!.path),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                // Action bar at bottom of preview
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _photoActionBtn(Icons.camera_alt_outlined, 'Retake',
                            () => _pickImage(ImageSource.camera)),
                        const SizedBox(width: 12),
                        _photoActionBtn(Icons.photo_library_outlined, 'Gallery',
                            () => _pickImage(ImageSource.gallery)),
                        const SizedBox(width: 12),
                        _photoActionBtn(Icons.delete_outline_rounded, 'Remove',
                            () => setState(() => _pickedImage = null),
                            color: AppColors.danger),
                      ],
                    ),
                  ),
                ),
              ],
            )
          // ── Placeholder ───────────────────────────────────────────────────
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFECEAE3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: _kGrey, size: 26),
                  ),
                  const SizedBox(height: 10),
                  const Text('Capture prescription',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text("Photo of the doctor's prescription slip",
                      style: TextStyle(fontSize: 12, color: _kGrey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _photoActionBtn(Icons.camera_alt_outlined, 'Camera',
                          () => _pickImage(ImageSource.camera)),
                      const SizedBox(width: 12),
                      _photoActionBtn(Icons.photo_library_outlined, 'Gallery',
                          () => _pickImage(ImageSource.gallery)),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _photoActionBtn(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? _kGrey;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFECEAE3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: c)),
          ],
        ),
      ),
    );
  }

  /// PATIENT * section — free-text field + quick-select from existing patients.
  Widget _buildPatientSection() {
    final known = _knownPatients;
    return _sectionCard(
      label: 'PATIENT',
      required: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Free-text input
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  color: _kGrey, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _patientCtrl,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: 'Enter patient name',
                    hintStyle:
                        TextStyle(fontSize: 14, color: Color(0xFFAFADA6)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          // Quick-select chips from existing Firestore patients
          if (known.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: known.map((name) {
                  final color    = _avatarColor(name);
                  final selected = _patientCtrl.text.trim() == name;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _patientCtrl.text = name),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.15)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? color : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: color,
                            child: Text(_initials(name),
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                          const SizedBox(width: 7),
                          Text(name.split(' ').first,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? color
                                      : AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// VISIT INFO section: cause, date, doctor, hospital, notes.
  Widget _buildVisitInfoSection() {
    return _sectionCard(
      label: 'VISIT INFO',
      child: Column(
        children: [
          _formField(
            label: 'Cause / diagnosis',
            required: true,
            controller: _causeCtrl,
            hint: 'e.g. Viral Fever',
          ),
          _fieldDivider(),
          _formField(
            label: 'Date of visit',
            required: true,
            controller: _dateCtrl,
            hint: 'e.g. 12 April 2025',
            trailing: const Icon(Icons.calendar_today_rounded,
                size: 16, color: _kGrey),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(primary: _kGreen),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() {
                  _dateCtrl.text =
                      '${picked.day} ${MedDateUtils.monthName(picked.month)} ${picked.year}';
                });
              }
            },
          ),
          _fieldDivider(),
          _formField(
            label: 'Doctor name',
            controller: _doctorCtrl,
            hint: 'e.g. Dr. Ramesh Kumar',
          ),
          _fieldDivider(),
          _formField(
            label: 'Hospital / clinic',
            controller: _hospitalCtrl,
            hint: 'e.g. City Hospital, Chennai',
          ),
          _fieldDivider(),
          _formField(
            label: 'Notes',
            controller: _notesCtrl,
            hint: 'Follow-up instructions, any remarks...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// MEDICINES IN THIS PRESCRIPTION section.
  Widget _buildMedicinesSection() {
    return _sectionCard(
      label: 'MEDICINES IN THIS PRESCRIPTION',
      child: Column(
        children: [
          // Existing medicine rows
          ...List.generate(_medicineCtrl.length, (i) {
            return Column(
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medication_rounded,
                          color: _kGreen, size: 18),
                    ),
                    const SizedBox(width: 12),
                    // Editable name
                    Expanded(
                      child: TextField(
                        controller: _medicineCtrl[i],
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    // Remove button
                    GestureDetector(
                      onTap: () => setState(() {
                        _medicineCtrl[i].dispose();
                        _medicineCtrl.removeAt(i);
                      }),
                      child: Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (i < _medicineCtrl.length - 1)
                  Divider(height: 16, thickness: 1,
                      color: AppColors.border),
              ],
            );
          }),

          // Add another medicine row
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () =>
                setState(() => _medicineCtrl.add(TextEditingController())),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: _kGreen),
                ),
                const SizedBox(width: 10),
                const Text('Add another medicine',
                    style: TextStyle(
                        fontSize: 13,
                        color: _kGreen,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Blue "Save prescription" button pinned at the bottom.
  Widget _buildPinnedSaveButton(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaving ? _kBlue.withOpacity(0.5) : _kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white70),
                    )
                  : const Text('Save prescription',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          const Text('* Required fields',
              style: TextStyle(fontSize: 11, color: _kGrey)),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Card with a grey uppercase label and padding.
  Widget _sectionCard({
    required String label,
    bool required = false,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _kGrey)),
                if (required)
                  const Text(' *',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }

  /// A single labelled form field.
  Widget _formField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    String hint = '',
    int maxLines = 1,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: _kGrey)),
            if (required)
              const Text(' *',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: AbsorbPointer(
                  absorbing: onTap != null,
                  child: TextFormField(
                    controller: controller,
                    maxLines: maxLines,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle:
                          const TextStyle(fontSize: 14, color: Color(0xFFAFADA6)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: required
                        ? (v) => (v == null || v.isEmpty) ? 'Required' : null
                        : null,
                  ),
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ],
    );
  }

  Widget _fieldDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border),
      );

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cause = _causeCtrl.text.trim();
    final dateText = _dateCtrl.text.trim();
    if (cause.isEmpty || dateText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the required fields')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ── Parse visit date ───────────────────────────────────────────────────
      final visitDate = _parsePickedDate(dateText);

      // Short display date e.g. "12 Apr 2025"
      final shortDate = visitDate != null
          ? MedDateUtils.formatDate(visitDate)
          : dateText;
      final year = visitDate?.year ?? DateTime.now().year;

      // ── Patient ────────────────────────────────────────────────────────────
      final patientName = _patientCtrl.text.trim();
      if (patientName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a patient name')),
        );
        setState(() => _isSaving = false);
        return;
      }

      // ── Medicines (names only from the form rows) ──────────────────────────
      final medicines = _medicineCtrl
          .map((c) => c.text.trim())
          .where((name) => name.isNotEmpty)
          .map((name) => RxMedicine(
                name:        name,
                dosage:      '',
                expiryLabel: '',
                status:      RxMedicineStatus.available,
              ))
          .toList();

      // ── Hospital fields ─────────────────────────────────────────────────────
      final hospitalFull = _hospitalCtrl.text.trim();
      // Trim everything from the first comma for the short name
      final hospital = hospitalFull.contains(',')
          ? hospitalFull.substring(0, hospitalFull.indexOf(',')).trim()
          : hospitalFull;

      final rx = PrescriptionData(
        id:                 '',   // Firestore generates the doc ID
        cause:              cause,
        date:               shortDate,
        dateFull:           dateText,
        year:               year,
        hospital:           hospital,
        hospitalFull:       hospitalFull,
        doctor:             _doctorCtrl.text.trim(),
        notes:              _notesCtrl.text.trim(),
        patientName:        patientName,
        patientInitials:    _initials(patientName),
        patientAvatarColor: _avatarColor(patientName),
        medicines:          medicines,
      );

      await DataService.instance.addPrescription(rx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription saved successfully'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  /// Parse "12 January 2025" → DateTime.
  DateTime? _parsePickedDate(String text) {
    const months = {
      'January': 1, 'February': 2, 'March': 3,     'April': 4,
      'May': 5,     'June': 6,     'July': 7,       'August': 8,
      'September': 9, 'October': 10, 'November': 11, 'December': 12,
    };
    final parts = text.trim().split(' ');
    if (parts.length != 3) return null;
    final day   = int.tryParse(parts[0]);
    final month = months[parts[1]];
    final year  = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

}

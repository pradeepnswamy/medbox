import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/medicine.dart';
import '../../models/patient.dart';
import '../../models/prescription.dart';
import '../../services/data_service.dart';
import '../../utils/date_utils.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kCard  = AppColors.card;
const _kGreen = AppColors.primary;
const _kBlue  = AppColors.rxBlue;
const _kGrey  = AppColors.textSecondary;

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
  late final TextEditingController _causeCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _doctorCtrl;
  late final TextEditingController _hospitalCtrl;
  late final TextEditingController _notesCtrl;

  bool   _isSaving = false;
  XFile? _pickedImage;

  // ── Patient picker ────────────────────────────────────────────────────────
  /// The patient selected for this prescription.
  PatientData? _selectedPatient;

  /// All patients loaded from Firestore for the picker.
  List<PatientData> _allPatients = [];

  /// Medicines selected for this prescription (picked from existing library).
  late List<MedicineData> _selectedMedicines;

  /// Full medicine library loaded from Firestore.
  List<MedicineData> _allMedicines = [];

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final rx = widget.existing;
    _causeCtrl    = TextEditingController(text: rx?.cause ?? '');
    _dateCtrl     = TextEditingController(text: rx?.dateFull ?? '');
    _doctorCtrl   = TextEditingController(text: rx?.doctor ?? '');
    _hospitalCtrl = TextEditingController(text: rx?.hospitalFull ?? '');
    _notesCtrl    = TextEditingController(text: rx?.notes ?? '');

    // Pre-select medicines from existing prescription (edit mode).
    _selectedMedicines = rx != null
        ? rx.medicines.map((m) => MedicineData.fromJson({
            'id': m.medicineId ?? '',
            'name': m.name,
            'acquiredDate': '',
            'acquiredDateFull': '',
            'expiryLabel': '',
            'expiryDateFull': '',
            'expiryColor': '#4CAF50',
            'attentionColor': null,
            'badges': <Map<String, dynamic>>[],
            'form': '',
            'dosage': m.dosage,
            'quantity': '',
            'notes': '',
            'linkedPrescription': null,
            'linkedPrescriptionMeta': null,
            'isOpened': false,
            'openedOn': '',
            'topStatus': 'Available',
            'expiryTimestamp': null,
            'openedTimestamp': null,
            'photoPath': null,
          })).toList()
        : [];

    // Load patients for the picker; in edit mode try to match by name.
    DataService.instance.getPatients().then((patients) {
      if (!mounted) return;
      PatientData? matched;
      if (rx != null) {
        final name = rx.patientName.toLowerCase();
        try {
          matched = patients.firstWhere(
            (p) => p.name.toLowerCase() == name,
          );
        } catch (_) {} // no match — user can select manually
      }
      setState(() {
        _allPatients      = patients;
        _selectedPatient  = matched;
      });
    });

    // Load full medicine library for the picker.
    DataService.instance.getMedicines().then((list) {
      if (!mounted) return;
      setState(() {
        _allMedicines = list;
        // Resolve stubs: match by name to get real IDs (edit mode).
        _selectedMedicines = _selectedMedicines.map((stub) {
          if (stub.id.isNotEmpty) return stub;
          final match = list.firstWhere(
            (m) => m.name.toLowerCase() == stub.name.toLowerCase(),
            orElse: () => stub,
          );
          return match;
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _causeCtrl.dispose();
    _dateCtrl.dispose();
    _doctorCtrl.dispose();
    _hospitalCtrl.dispose();
    _notesCtrl.dispose();
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

  /// PATIENT * section — chip picker from the patients collection.
  Widget _buildPatientSection() {
    return _sectionCard(
      label: 'PATIENT',
      required: true,
      child: _allPatients.isEmpty
          // ── No patients yet (or still loading) ──────────────────────────────
          ? GestureDetector(
              onTap: _goAddPatient,
              child: const Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded,
                      color: _kGreen, size: 18),
                  SizedBox(width: 10),
                  Text('Add a patient first',
                      style: TextStyle(color: _kGrey, fontSize: 14)),
                ],
              ),
            )
          // ── Patient chips ────────────────────────────────────────────────────
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._allPatients.map((p) {
                  final selected = _selectedPatient?.id == p.id;
                  return GestureDetector(
                    onTap: () => setState(
                        () => _selectedPatient = selected ? null : p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _kGreen : _kCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected ? _kGreen : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: selected
                                ? Colors.white.withOpacity(0.25)
                                : p.avatarColor.withOpacity(0.2),
                            child: Text(
                              p.initials,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.white
                                    : p.avatarColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            p.name.split(' ').first,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // "Add patient" chip
                GestureDetector(
                  onTap: _goAddPatient,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: _kGreen, size: 16),
                        SizedBox(width: 5),
                        Text(
                          'Add patient',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _goAddPatient() async {
    await context.push(AppRoutes.patientsAdd);
    final list = await DataService.instance.getPatients();
    if (mounted) setState(() => _allPatients = list);
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
  ///
  /// Shows selected medicines as removable chips and a button that opens a
  /// bottom-sheet picker.  The picker lists all medicines in the library;
  /// an "Add new medicine" option navigates to AddMedicineScreen and returns
  /// the freshly created medicine directly into the selection.
  Widget _buildMedicinesSection() {
    return _sectionCard(
      label: 'MEDICINES IN THIS PRESCRIPTION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Selected medicine chips ──────────────────────────────────────
          if (_selectedMedicines.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'No medicines selected yet.',
                style: TextStyle(fontSize: 13, color: _kGrey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedMedicines.map((med) {
                return Chip(
                  avatar: const Icon(Icons.medication_rounded,
                      size: 16, color: _kGreen),
                  label: Text(med.name,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary)),
                  deleteIcon:
                      const Icon(Icons.close, size: 14, color: _kGrey),
                  onDeleted: () =>
                      setState(() => _selectedMedicines.remove(med)),
                  backgroundColor: _kGreen.withOpacity(0.08),
                  side: BorderSide(color: _kGreen.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),

          const SizedBox(height: 12),

          // ── Add medicine button ──────────────────────────────────────────
          GestureDetector(
            onTap: _showMedicinePicker,
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
                Text(
                  _selectedMedicines.isEmpty
                      ? 'Select medicine'
                      : 'Add another medicine',
                  style: const TextStyle(
                      fontSize: 13,
                      color: _kGreen,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom-sheet medicine picker.
  /// Delegates to [_MedicinePickerSheet] so the search controller
  /// lifecycle is fully contained inside that widget's State.
  Future<void> _showMedicinePicker() async {
    final selectedIds = _selectedMedicines.map((m) => m.id).toSet();
    final available   = _allMedicines
        .where((m) => !selectedIds.contains(m.id))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicinePickerSheet(
        available: available,
        onSelected: (med) {
          if (mounted) setState(() => _selectedMedicines.add(med));
        },
        onAddNew: _goAddNewMedicine,
      ),
    );
  }

  /// Navigate to AddMedicineScreen, reload the library, and auto-select
  /// any newly created medicine.
  Future<void> _goAddNewMedicine() async {
    // Snapshot the current IDs before navigating away.
    final previousIds = _allMedicines.map((m) => m.id).toSet();

    await context.push(AppRoutes.medicinesAdd);
    if (!mounted) return;

    final updated = await DataService.instance.getMedicines();
    if (!mounted) return;

    // Find medicines whose IDs weren't in the library before — these are new.
    final newMeds = updated
        .where((m) => m.id.isNotEmpty && !previousIds.contains(m.id))
        .toList();

    setState(() {
      _allMedicines = updated;
      if (newMeds.isNotEmpty) _selectedMedicines.addAll(newMeds);
    });
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
    // ── Patient validation (before form.validate so it's the first error shown)
    final patient = _selectedPatient;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cause    = _causeCtrl.text.trim();
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

      // ── Medicines ──────────────────────────────────────────────────────────
      final medicines = _selectedMedicines
          .map((med) => RxMedicine(
                name:        med.name,
                dosage:      med.dosage,
                expiryLabel: med.expiryLabel,
                status:      RxMedicineStatus.available,
              ))
          .toList();

      // ── Hospital fields ────────────────────────────────────────────────────
      final hospitalFull = _hospitalCtrl.text.trim();
      final hospital = hospitalFull.contains(',')
          ? hospitalFull.substring(0, hospitalFull.indexOf(',')).trim()
          : hospitalFull;

      final rx = PrescriptionData(
        id:                 _isEditMode ? widget.existing!.id : '',
        cause:              cause,
        date:               shortDate,
        dateFull:           dateText,
        year:               year,
        hospital:           hospital,
        hospitalFull:       hospitalFull,
        doctor:             _doctorCtrl.text.trim(),
        notes:              _notesCtrl.text.trim(),
        patientName:        patient.name,
        patientInitials:    patient.initials,
        patientAvatarColor: patient.avatarColor,
        medicines:          medicines,
      );

      if (_isEditMode) {
        await DataService.instance.updatePrescription(rx);
      } else {
        await DataService.instance.addPrescription(rx);
      }
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

// ── Medicine picker bottom sheet ───────────────────────────────────────────────
//
// Extracted into its own StatefulWidget so the TextEditingController lifecycle
// is fully self-contained: created in initState(), disposed in dispose().
// This prevents the "controller used after disposal" crash that occurs when
// the controller is owned by the parent State and the sheet is torn down.

class _MedicinePickerSheet extends StatefulWidget {
  final List<MedicineData>        available;
  final ValueChanged<MedicineData> onSelected;
  final VoidCallback               onAddNew;

  const _MedicinePickerSheet({
    required this.available,
    required this.onSelected,
    required this.onAddNew,
  });

  @override
  State<_MedicinePickerSheet> createState() => _MedicinePickerSheetState();
}

class _MedicinePickerSheetState extends State<_MedicinePickerSheet> {
  late final TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      if (mounted) setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MedicineData> get _filtered {
    if (_query.isEmpty) return widget.available;
    return widget.available
        .where((m) => m.name.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize:     0.4,
      maxChildSize:     0.92,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Drag handle ────────────────────────────────────────────────
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Title ──────────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select medicine',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Search bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: false,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search medicines…',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Medicine list ──────────────────────────────────────────────
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'All medicines already added.'
                              : 'No medicines match "$_query".',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final med = _filtered[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.medication_rounded,
                                  size: 20, color: AppColors.primary),
                            ),
                            title: Text(med.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary)),
                            subtitle: med.dosage.isNotEmpty
                                ? Text(med.dosage,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary))
                                : null,
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onSelected(med);
                            },
                          );
                        },
                      ),
              ),

              // ── "Add new medicine" footer ──────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAddNew();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add new medicine',
                        style: TextStyle(fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

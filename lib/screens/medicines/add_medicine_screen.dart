import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/medicine.dart';
import '../../models/patient.dart';
import '../../services/data_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/image_utils.dart';
import '../../widgets/forms/image_picker_widget.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg       = AppColors.surface;
const _kCard     = AppColors.card;
const _kGreen    = AppColors.primary;
const _kGrey     = AppColors.textSecondary;
const _kBorder   = AppColors.border;

class AddMedicineScreen extends StatefulWidget {
  /// Pass an existing medicine to open the screen in edit mode.
  /// Leave null to open in add mode.
  final MedicineData? existing;

  /// Pre-selects a patient when opening in add mode.
  /// Ignored when [existing] is non-null (edit mode uses med.patientId).
  final String? initialPatientId;

  const AddMedicineScreen({super.key, this.existing, this.initialPatientId});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  // ── Form state ────────────────────────────────────────────────────────────────
  int    _selectedForm = 0;
  bool   _isOpened     = false;
  bool   _isSaving     = false;
  XFile? _pickedImage;

  /// The patient this medicine belongs to. Null = OTC / no patient.
  String? _selectedPatientId;

  /// All patients loaded from Firestore for the picker.
  List<PatientData> _allPatients = [];

  final _nameCtrl      = TextEditingController();
  final _dosageCtrl    = TextEditingController();
  final _quantityCtrl  = TextEditingController();
  final _notesCtrl     = TextEditingController();
  final _acquiredCtrl  = TextEditingController();
  final _expiryCtrl    = TextEditingController();
  final _openedCtrl    = TextEditingController();

  static const _forms = ['Tablet', 'Capsule', 'Syrup', 'Drops', 'Injection'];

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _prefillIfEditing();
    // Pre-select patient from parameter (add-mode only; edit-mode reads from med)
    if (!_isEditMode && widget.initialPatientId != null) {
      _selectedPatientId = widget.initialPatientId;
    }
    DataService.instance.getPatients().then((list) {
      if (mounted) setState(() => _allPatients = list);
    });
  }

  Future<void> _refreshPatients() async {
    final list = await DataService.instance.getPatients();
    if (mounted) setState(() => _allPatients = list);
  }

  /// Pre-fills all form fields from [widget.existing] when in edit mode.
  void _prefillIfEditing() {
    final med = widget.existing;
    if (med == null) return;

    _selectedPatientId = med.patientId;
    _nameCtrl.text     = med.name;
    _dosageCtrl.text   = med.dosage;
    _quantityCtrl.text = med.quantity;
    _notesCtrl.text    = med.notes;
    _isOpened          = med.isOpened;

    // Form chip — match stored form string
    final idx = _forms.indexOf(med.form);
    _selectedForm = idx >= 0 ? idx : 0;

    // Dates — prefer timestamps (precise); fall back to parsing stored strings
    _acquiredCtrl.text = _toPickerText(_parseDateField(
      timestamp: null,           // no acquired timestamp stored
      fallback:  med.acquiredDateFull, // "12 Apr 2025"
    ));
    _expiryCtrl.text = _toPickerText(_parseDateField(
      timestamp: med.expiryTimestamp,
      fallback:  med.expiryDateFull,   // "Apr 2025" (month-year only)
    ));
    if (med.isOpened && med.openedOn != 'Not opened yet') {
      _openedCtrl.text = _toPickerText(_parseDateField(
        timestamp: med.openedTimestamp,
        fallback:  med.openedOn,       // "12 Apr 2025"
      ));
    }
  }

  /// Resolves a [DateTime] from a timestamp or a fallback display string.
  /// Handles "12 Apr 2025" and "Apr 2025" formats.
  static DateTime? _parseDateField({int? timestamp, required String fallback}) {
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    // Try "12 Apr 2025" (day + abbreviated month + year)
    final parts = fallback.trim().split(' ');
    const abbrs = {
      'Jan': 1, 'Feb': 2, 'Mar': 3,  'Apr': 4,
      'May': 5, 'Jun': 6, 'Jul': 7,  'Aug': 8,
      'Sep': 9, 'Oct': 10,'Nov': 11, 'Dec': 12,
    };
    if (parts.length == 3) {
      final day   = int.tryParse(parts[0]);
      final month = abbrs[parts[1]];
      final year  = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    // Try "Apr 2025" (month-year only — use 1st of month)
    if (parts.length == 2) {
      final month = abbrs[parts[0]];
      final year  = int.tryParse(parts[1]);
      if (month != null && year != null) {
        return DateTime(year, month, 1);
      }
    }
    return null;
  }

  /// Converts a [DateTime] to the format expected by [_parsePickedDate]:
  /// "12 January 2025". Returns '' if dt is null.
  static String _toPickerText(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day} ${MedDateUtils.monthName(dt.month)} ${dt.year}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    _acquiredCtrl.dispose();
    _expiryCtrl.dispose();
    _openedCtrl.dispose();
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
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ImagePickerWidget(
                      pickedFile: _pickedImage,
                      savedPath:  widget.existing?.photoPath,
                      onTap:      _showPickerSheet,
                      height:     140,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionLabel('PATIENT'),
                    const SizedBox(height: 10),
                    _buildPatientPicker(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('MEDICINE DETAILS'),
                    const SizedBox(height: 12),
                    _buildField('Medicine name', _nameCtrl, hint: 'e.g. Paracetamol 500mg'),
                    const SizedBox(height: 12),
                    _buildSectionLabel('FORM'),
                    const SizedBox(height: 10),
                    _buildFormChips(),
                    const SizedBox(height: 12),
                    _buildField('Dosage / Strength', _dosageCtrl,
                        hint: 'e.g. 500mg · 1 tablet × 3/day'),
                    const SizedBox(height: 12),
                    _buildField('Quantity', _quantityCtrl,
                        hint: 'e.g. 10 tablets'),
                    const SizedBox(height: 24),
                    _buildSectionLabel('DATES'),
                    const SizedBox(height: 12),
                    _buildDateField('Acquired date', _acquiredCtrl),
                    const SizedBox(height: 12),
                    _buildDateField('Expiry date', _expiryCtrl, isFuture: true),
                    const SizedBox(height: 24),
                    _buildOpenedToggle(),
                    if (_isOpened) ...[
                      const SizedBox(height: 12),
                      _buildDateField('Date opened', _openedCtrl),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionLabel('NOTES'),
                    const SizedBox(height: 12),
                    _buildField('Notes', _notesCtrl,
                        hint: 'Any special instructions...', maxLines: 3),
                    const SizedBox(height: 12),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          Text(
            _isEditMode ? 'Edit Medicine' : 'Add Medicine',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 60), // balance
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
      maxWidth:     1200,
    );
    if (file != null && mounted) setState(() => _pickedImage = file);
  }

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
                icon:  Icons.camera_alt_outlined,
                label: 'Take a photo',
                onTap: () { Navigator.of(sheetCtx).pop(); _pickImage(ImageSource.camera); },
              ),
              const SizedBox(height: 4),
              _sheetOption(
                icon:  Icons.photo_library_outlined,
                label: 'Choose from gallery',
                onTap: () { Navigator.of(sheetCtx).pop(); _pickImage(ImageSource.gallery); },
              ),
              if (_pickedImage != null) ...[
                const SizedBox(height: 4),
                _sheetOption(
                  icon:  Icons.delete_outline_rounded,
                  label: 'Remove photo',
                  color: AppColors.danger,
                  onTap: () { Navigator.of(sheetCtx).pop(); setState(() => _pickedImage = null); },
                ),
              ],
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
            Text(label, style: TextStyle(fontSize: 15, color: c, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── Form type chips ───────────────────────────────────────────────────────────

  Widget _buildFormChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_forms.length, (i) {
          final selected = i == _selectedForm;
          return GestureDetector(
            onTap: () => setState(() => _selectedForm = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _kGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? _kGreen : AppColors.border),
              ),
              child: Text(
                _forms[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Opened toggle ─────────────────────────────────────────────────────────────

  Widget _buildOpenedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Medicine opened',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              SizedBox(height: 2),
              Text('Has the seal been broken?',
                  style: TextStyle(fontSize: 12, color: _kGrey)),
            ],
          ),
          Switch(
            value: _isOpened,
            onChanged: (v) => setState(() => _isOpened = v),
            activeColor: _kGreen,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }

  // ── Generic text field ────────────────────────────────────────────────────────

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Color(0xFFAFADA6), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ── Date picker field ─────────────────────────────────────────────────────────

  Widget _buildDateField(String label, TextEditingController ctrl,
      {bool isFuture = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: isFuture ? now.add(const Duration(days: 365)) : now,
              firstDate: isFuture ? now : DateTime(2020),
              lastDate:
                  isFuture ? DateTime(2035) : now,
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
            if (picked != null) {
              setState(() {
                ctrl.text =
                    '${picked.day} ${MedDateUtils.monthName(picked.month)} ${picked.year}';
              });
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ctrl.text.isEmpty ? 'Select date' : ctrl.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: ctrl.text.isEmpty
                          ? const Color(0xFFAFADA6)
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: _kGrey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _onSave,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isSaving ? _kGreen.withOpacity(0.5) : _kGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black54,
                  ),
                )
              : Text(
                  _isEditMode ? 'Save Changes' : 'Save Medicine',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the medicine name')),
      );
      return;
    }
    if (_acquiredCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an acquired date')),
      );
      return;
    }
    if (_expiryCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ── Persist photo to app documents dir ────────────────────────────────
      String? savedPhotoPath = widget.existing?.photoPath; // keep existing if no new pick
      if (_pickedImage != null) {
        final docsDir = await getApplicationDocumentsDirectory();
        final photosDir = Directory('${docsDir.path}/medicine_photos');
        await photosDir.create(recursive: true);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final dest = File('${photosDir.path}/$fileName');
        final bytes = await ImageUtils.compressAndResize(File(_pickedImage!.path));
        await dest.writeAsBytes(bytes);
        savedPhotoPath = dest.path;
        // Delete the old photo file if replacing
        if (widget.existing?.photoPath != null) {
          final old = File(widget.existing!.photoPath!);
          if (await old.exists()) await old.delete();
        }
      }

      // ── Parse dates from picker text ("12 January 2025") ──────────────────
      final acquired = _parsePickedDate(_acquiredCtrl.text);
      final expiry   = _parsePickedDate(_expiryCtrl.text);
      final opened   = _isOpened && _openedCtrl.text.isNotEmpty
          ? _parsePickedDate(_openedCtrl.text)
          : null;

      // ── Display strings ────────────────────────────────────────────────────
      final acquiredDate    = acquired != null
          ? 'Got ${MedDateUtils.formatShort(acquired)}, ${acquired.year}'
          : '';
      final acquiredDateFull = acquired != null
          ? MedDateUtils.formatDate(acquired)
          : '';
      final expiryLabel     = expiry != null ? _expiryLabel(expiry) : '';
      final expiryDateFull  = expiry != null
          ? MedDateUtils.formatMonthYear(expiry)
          : '';
      final openedOn = _isOpened && opened != null
          ? MedDateUtils.formatDate(opened)
          : 'Not opened yet';

      // ── Status + attention ─────────────────────────────────────────────────
      final daysLeft   = expiry != null ? MedDateUtils.daysUntilExpiry(expiry) : 999;
      final monthsOpen = opened != null ? MedDateUtils.monthsSinceOpened(opened) : 0;

      String topStatus = 'Available';
      if (daysLeft <= 30)               topStatus = 'Expiring';
      else if (_isOpened && monthsOpen >= 3) topStatus = 'Opened';

      // ── Colours ────────────────────────────────────────────────────────────
      Color expiryColor;
      Color? attentionColor;
      if (daysLeft <= 30) {
        expiryColor = AppColors.danger;
        attentionColor = AppColors.danger;
      } else if (daysLeft <= 90) {
        expiryColor = AppColors.warning;
        attentionColor = AppColors.warning;
      } else {
        expiryColor = AppColors.textSecondary;
        attentionColor = null;
      }

      // ── Badges ─────────────────────────────────────────────────────────────
      final badges = <(String, BadgeStyle)>[];
      if (topStatus == 'Expiring') {
        badges.add(('Expiring in $daysLeft day${daysLeft == 1 ? '' : 's'}',
            BadgeStyle.expiring));
      } else if (topStatus == 'Opened') {
        badges.add(('Opened $monthsOpen mo ago', BadgeStyle.opened));
      } else {
        badges.add(('Available', BadgeStyle.available));
      }
      if (!_isOpened) badges.add(('Unopened', BadgeStyle.neutral));

      // ── Build + save ───────────────────────────────────────────────────────
      final med = MedicineData(
        id:        _isEditMode ? widget.existing!.id : '',
        name:      name,
        patientId: _selectedPatientId,
        acquiredDate:         acquiredDate,
        acquiredDateFull:     acquiredDateFull,
        expiryLabel:          expiryLabel,
        expiryDateFull:       expiryDateFull,
        expiryColor:          expiryColor,
        attentionColor:       attentionColor,
        badges:               badges,
        form:                 _forms[_selectedForm],
        dosage:               _dosageCtrl.text.trim(),
        quantity:             _quantityCtrl.text.trim(),
        notes:                _notesCtrl.text.trim(),
        linkedPrescription:   null,
        linkedPrescriptionMeta: null,
        isOpened:             _isOpened,
        openedOn:             openedOn,
        topStatus:            topStatus,
        expiryTimestamp:      expiry?.millisecondsSinceEpoch,
        openedTimestamp:      opened?.millisecondsSinceEpoch,
        photoPath:            savedPhotoPath,
      );

      if (_isEditMode) {
        await DataService.instance.updateMedicine(med);
      } else {
        await DataService.instance.addMedicine(med);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Medicine updated successfully'
                : 'Medicine saved successfully'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Pop with true so callers know a save happened (used by detail screen)
        context.pop(true);
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

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Parse a date string produced by [showDatePicker] via [MedDateUtils.monthName],
  /// e.g. "12 January 2025" → DateTime(2025, 1, 12).
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

  /// Short expiry label: "Apr 20" for near-term (≤ 365 days), "Apr 2026" for later.
  String _expiryLabel(DateTime d) {
    final days = MedDateUtils.daysUntilExpiry(d);
    if (days <= 365) return MedDateUtils.formatShort(d);
    return MedDateUtils.formatMonthYear(d);
  }


  // ── Patient picker ────────────────────────────────────────────────────────────

  Widget _buildPatientPicker() {
    if (_allPatients.isEmpty) {
      // Still loading or genuinely empty
      return GestureDetector(
        onTap: _goAddPatient,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: _kGreen, size: 18),
              const SizedBox(width: 10),
              const Text(
                'Add a patient first',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // One chip per patient
        ..._allPatients.map((p) {
          final selected = _selectedPatientId == p.id;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedPatientId = selected ? null : p.id;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _kGreen : _kCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? _kGreen : _kBorder,
                  width: selected ? 0 : 1,
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
                        color: selected ? Colors.white : p.avatarColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    p.name.split(' ').first,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kBorder, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: _kGreen, size: 16),
                const SizedBox(width: 5),
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
    );
  }

  Future<void> _goAddPatient() async {
    await context.push(AppRoutes.patientsAdd);
    await _refreshPatients();
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
}

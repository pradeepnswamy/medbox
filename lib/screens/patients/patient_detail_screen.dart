import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/medicine.dart';
import '../../models/patient.dart';
import '../../services/data_service.dart';
import '../medicines/components/badge_chip.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kCard  = AppColors.card;
const _kGreen = AppColors.primary;
const _kGrey  = AppColors.textSecondary;

class PatientDetailScreen extends StatefulWidget {
  final PatientData patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late PatientData       _patient;
  List<MedicineData>?    _medicines;     // medicines linked to this patient
  List<MedicineData>     _allMedicines = []; // full library (for picker)

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _reload();
  }

  Future<void> _reload() async {
    // Load patient record, linked medicines, and the full library in parallel.
    final results = await Future.wait([
      DataService.instance.getPatients(),
      DataService.instance.getMedicinesByPatient(_patient.id),
      DataService.instance.getMedicines(),
    ]);
    if (!mounted) return;

    final patients    = results[0] as List<PatientData>;
    final linked      = results[1] as List<MedicineData>;
    final allMeds     = results[2] as List<MedicineData>;

    final updated = patients.firstWhere(
      (p) => p.id == _patient.id,
      orElse: () => _patient,
    );

    setState(() {
      _patient      = updated;
      _medicines    = linked;
      _allMedicines = allMeds;
    });
  }

  // ── Medicine picker ───────────────────────────────────────────────────────────

  /// Opens a bottom-sheet that lists every medicine in the library that is
  /// not yet linked to this patient.  Selecting one links it; the "Add new"
  /// button navigates to AddMedicineScreen with this patient pre-selected.
  Future<void> _showMedicinePicker() async {
    final linkedIds = (_medicines ?? []).map((m) => m.id).toSet();
    final available = _allMedicines
        .where((m) => !linkedIds.contains(m.id))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicinePickerSheet(
        available: available,
        onSelected: _linkMedicine,
        onAddNew: _goAddNewMedicine,
      ),
    );
  }

  Future<void> _linkMedicine(MedicineData med) async {
    await DataService.instance
        .updateMedicine(med.copyWith(patientId: _patient.id));
    if (mounted) _reload();
  }

  Future<void> _goAddNewMedicine() async {
    await context.push(AppRoutes.medicinesAdd, extra: _patient.id);
    if (mounted) _reload();
  }

  // ── Medicine removal ──────────────────────────────────────────────────────────

  /// Shows a dialog offering Unlink or Delete, executes the chosen action,
  /// and returns [true] so the Dismissible removes the tile (the reload
  /// also refreshes the list).  Returns [false] on Cancel so it bounces back.
  Future<bool?> _confirmRemoveMedicine(MedicineData med) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dlg) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          med.name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'What would you like to do with this medicine?',
          style: TextStyle(fontSize: 14, color: _kGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(null),
            child: const Text('Cancel', style: TextStyle(color: _kGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dlg).pop('unlink'),
            child: const Text(
              'Unlink from patient',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dlg).pop('delete'),
            child: const Text(
              'Delete medicine',
              style: TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (action == null || !mounted) return false; // Cancel → bounce back

    if (action == 'unlink') {
      await DataService.instance
          .updateMedicine(med.copyWith(patientId: null));
    } else if (action == 'delete') {
      await DataService.instance
          .deleteMedicine(med.id, photoPath: med.photoPath);
    }

    if (mounted) _reload();
    return true; // Let Dismissible complete the slide-out animation
  }

  // ── Patient deletion ──────────────────────────────────────────────────────────

  Future<void> _onDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete patient?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This removes ${_patient.name} from your patient list. '
          'Their medicines will not be deleted.',
          style: const TextStyle(fontSize: 14, color: _kGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(false),
            child: const Text('Cancel', style: TextStyle(color: _kGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    if (_patient.id.isNotEmpty) {
      await DataService.instance.deletePatient(_patient.id);
    }

    if (mounted) context.pop(true);
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
              child: RefreshIndicator(
                color: _kGreen,
                onRefresh: _reload,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 28),
                      _buildMedicinesSection(),
                      if (_patient.isExplicit) ...[
                        const SizedBox(height: 40),
                        _buildDeleteButton(),
                      ],
                    ],
                  ),
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
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.chevron_left_rounded, color: _kGreen, size: 24),
                Text(
                  'Patients',
                  style: TextStyle(
                    fontSize: 14,
                    color: _kGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Patient',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 72),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _patient.avatarColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _patient.avatarColor.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _patient.initials,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _patient.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (_patient.relationship.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _patient.relationship,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Medicines section ─────────────────────────────────────────────────────────

  Widget _buildMedicinesSection() {
    final meds = _medicines;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              meds == null
                  ? 'MEDICINES'
                  : 'MEDICINES (${meds.length})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: _kGrey,
              ),
            ),
            GestureDetector(
              onTap: _showMedicinePicker,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, color: _kGreen, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Add medicine',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (meds == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: _kGreen),
            ),
          )
        else if (meds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medication_outlined,
                        color: _kGreen, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No medicines yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap "Add medicine" above to link or create one.',
                    style: TextStyle(fontSize: 13, color: _kGrey),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: meds.map(_buildMedicineTile).toList(),
          ),
      ],
    );
  }

  Widget _buildMedicineTile(MedicineData med) {
    BadgeStyle badgeStyle;
    Color iconColor;
    String statusLabel;
    switch (med.topStatus) {
      case 'Expiring':
        badgeStyle  = BadgeStyle.expiring;
        iconColor   = AppColors.danger;
        statusLabel = 'Expiring';
        break;
      case 'Opened':
        badgeStyle  = BadgeStyle.opened;
        iconColor   = AppColors.warning;
        statusLabel = 'Opened';
        break;
      default:
        badgeStyle  = BadgeStyle.available;
        iconColor   = _kGreen;
        statusLabel = 'Available';
    }

    return Dismissible(
      key: ValueKey(med.id),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) => _confirmRemoveMedicine(med),
      onDismissed: (_) {
        // Item already removed by _confirmRemoveMedicine which calls _reload()
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await context.push(AppRoutes.medicineDetail, extra: med);
          _reload();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.medication_rounded,
                    color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(med.acquiredDate,
                        style:
                            const TextStyle(fontSize: 12, color: _kGrey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BadgeChip(label: statusLabel, style: badgeStyle),
                  const SizedBox(height: 4),
                  Text('Exp ${med.expiryLabel}',
                      style:
                          const TextStyle(fontSize: 11, color: _kGrey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete button ─────────────────────────────────────────────────────────────

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _onDelete,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dangerBorder),
        ),
        child: const Center(
          child: Text(
            'Delete patient',
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

// ── Medicine picker bottom sheet ───────────────────────────────────────────────

class _MedicinePickerSheet extends StatefulWidget {
  final List<MedicineData>         available;
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
              // Drag handle
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

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add medicine',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: false,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search medicines…',
                    hintStyle: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: AppColors.textSecondary),
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

              // Medicine list
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _query.isEmpty
                                ? 'All medicines are already linked to this patient.\nTap "Add new medicine" below to create one.'
                                : 'No medicines match "$_query".',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary),
                          ),
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

              // "Add new medicine" footer
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
                      side: BorderSide(
                          color: AppColors.primary.withOpacity(0.5)),
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

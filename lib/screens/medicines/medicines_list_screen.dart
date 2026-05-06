import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/medicine.dart';
import '../../models/patient.dart';
import '../../services/data_service.dart';
import '../../widgets/offline_retry_widget.dart';
import 'components/badge_chip.dart';
import 'components/medicine_list_card.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg           = AppColors.surface;
const _kGreen        = AppColors.primary;
const _kSectionLabel = AppColors.textSecondary;

// ── Screen ────────────────────────────────────────────────────────────────────

class MedicinesListScreen extends StatefulWidget {
  const MedicinesListScreen({super.key});

  @override
  State<MedicinesListScreen> createState() => _MedicinesListScreenState();
}

class _MedicinesListScreenState extends State<MedicinesListScreen> {
  // ── Async data ────────────────────────────────────────────────────────────
  List<MedicineData>?     _medicines; // null = still loading
  Map<String, PatientData> _patientMap = {};
  String? _error;

  // ── Sort / filter / search ────────────────────────────────────────────────
  int    _selectedSort = 0;
  String _filterKey    = 'all';   // 'all' | 'expiring' | 'opened'
  final _searchController = TextEditingController();

  final List<String> _sortOptions = ['Date added', 'Expiry', 'Name A–Z'];

  /// Filter chips derived live from loaded medicines.
  List<(String, Color, String)> get _filterChips {
    final all      = _medicines ?? [];
    final expiring = all.where((m) => m.topStatus == 'Expiring').length;
    final opened   = all.where((m) => m.topStatus == 'Opened').length;

    return [
      ('All (${all.length})', _kGreen, 'all'),
      if (expiring > 0) ('Expiring ($expiring)', AppColors.danger, 'expiring'),
      if (opened   > 0) ('Opened ($opened)',     AppColors.warning, 'opened'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) setState(() { _error = null; _medicines = null; });
    try {
      // Load medicines and patients in parallel for speed
      final results = await Future.wait([
        DataService.instance.getMedicines(),
        DataService.instance.getPatients(),
      ]);
      final medicines = results[0] as List<MedicineData>;
      final patients  = results[1] as List<PatientData>;
      if (mounted) {
        setState(() {
          _medicines  = medicines;
          _patientMap = {for (final p in patients) p.id: p};
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _medicines = [];
        _error = 'Could not load medicines. Check your connection and retry.';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Computed list (filter + search + sort applied) ────────────────────────

  List<MedicineData> get _filtered {
    List<MedicineData> list = List.from(_medicines ?? []);

    // Filter chip
    if (_filterKey == 'expiring') {
      list = list.where((m) => m.topStatus == 'Expiring').toList();
    } else if (_filterKey == 'opened') {
      list = list.where((m) => m.topStatus == 'Opened').toList();
    }

    // Search
    final q = _searchController.text.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((m) => m.name.toLowerCase().contains(q)).toList();
    }

    // Sort
    switch (_selectedSort) {
      case 1: // Expiry
        list.sort((a, b) => a.expiryLabel.compareTo(b.expiryLabel));
        break;
      case 2: // Name A–Z
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      default: // Date added — preserve original order
        break;
    }

    return list;
  }

  bool get _isFiltered =>
      _filterKey != 'all' || _searchController.text.trim().isNotEmpty;

  List<MedicineData> get _attentionMeds =>
      _filtered.where((m) => m.attentionColor != null).toList();

  List<MedicineData> get _availableMeds =>
      _filtered.where((m) => m.attentionColor == null).toList();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Fixed top chrome ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildSortRow(),
                  const SizedBox(height: 10),
                  _buildFilterRow(),
                  const SizedBox(height: 6),
                ],
              ),
            ),

            // ── Scrollable list ────────────────────────────────────────────
            Expanded(
              child: _error != null
                  ? OfflineRetryWidget(onRetry: _reload, message: _error)
                  : _medicines == null
                      ? const Center(child: CircularProgressIndicator(color: _kGreen))
                      : RefreshIndicator(
                          onRefresh: _reload,
                          color: _kGreen,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            child: _isFiltered
                                ? _buildFlatList()
                                : _buildSectionedList(),
                          ),
                        ),
            ),
          ],
        ),
      ),

      // Green FAB → Add Medicine screen
      floatingActionButton: FloatingActionButton(
        heroTag: 'medicines-fab',
        onPressed: () async {
          await context.push(AppRoutes.medicinesAdd);
          _reload();
        },
        backgroundColor: _kGreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Medicines',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Row(
          children: [
            _iconBtn(Icons.format_list_bulleted_rounded, () {}),
            const SizedBox(width: 8),
            _iconBtn(Icons.tune_rounded, () {}),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0xFFECEAE3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search medicines...',
                hintStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SORT BY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _kSectionLabel,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_sortOptions.length, (i) {
              final selected = i == _selectedSort;
              return GestureDetector(
                onTap: () => setState(() => _selectedSort = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? _kGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          selected ? _kGreen : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _sortOptions[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded,
                            size: 16, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    final chips = _filterChips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FILTER',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _kSectionLabel,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips.map((chip) {
              final label    = chip.$1;
              final color    = chip.$2;
              final key      = chip.$3;
              final selected = key == _filterKey;
              return GestureDetector(
                onTap: () => setState(() => _filterKey = key),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? color : AppColors.border,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
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
        color: _kSectionLabel,
      ),
    );
  }

  // ── List layouts ───────────────────────────────────────────────────────────

  Widget _buildSectionedList() {
    final attention = _attentionMeds;
    final available = _availableMeds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attention.isNotEmpty) ...[
          _buildSectionLabel('NEEDS ATTENTION'),
          const SizedBox(height: 10),
          ...attention.map(_buildCard),
          const SizedBox(height: 16),
        ],
        if (available.isNotEmpty) ...[
          _buildSectionLabel('AVAILABLE'),
          const SizedBox(height: 10),
          ...available.map(_buildCard),
        ],
        if (attention.isEmpty && available.isEmpty)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildFlatList() {
    final results = _filtered;
    if (results.isEmpty) return _buildEmptyState();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
            '${results.length} RESULT${results.length == 1 ? '' : 'S'}'),
        const SizedBox(height: 10),
        ...results.map(_buildCard),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppColors.border, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No medicines found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try a different search or filter',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(MedicineData med) {
    final patientName = med.patientId != null
        ? _patientMap[med.patientId]?.name
        : null;
    return Dismissible(
      key: ValueKey(med.id),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: _deleteBg(),
      confirmDismiss: (_) => _confirmDelete(
        title: med.name,
        message: 'Delete this medicine from the cabinet? This cannot be undone.',
      ),
      onDismissed: (_) async {
        await DataService.instance.deleteMedicine(med.id, photoPath: med.photoPath);
        _reload();
      },
      child: MedicineListCard(
        name:           med.name,
        patientName:    patientName,
        acquiredDate:   med.acquiredDate,
        expiryLabel:    med.expiryLabel,
        expiryColor:    med.expiryColor,
        badges:         med.badges,
        attentionColor: med.attentionColor,
        onTap: () async {
          await context.push(AppRoutes.medicineDetail, extra: med);
          _reload();
        },
      ),
    );
  }

  // ── Shared swipe-delete helpers ────────────────────────────────────────────

  Widget _deleteBg() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline_rounded,
          color: Colors.white, size: 22),
    );
  }

  Future<bool?> _confirmDelete({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        content: Text(message,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
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
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../models/prescription.dart';
import '../../services/data_service.dart';
import '../../widgets/offline_retry_widget.dart';
import 'components/prescription_list_card.dart';
import 'prescription_detail_screen.dart';
import 'add_prescription_screen.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kGreen = AppColors.primary;
const _kGrey  = AppColors.textSecondary;

class PrescriptionsListScreen extends StatefulWidget {
  const PrescriptionsListScreen({super.key});

  @override
  State<PrescriptionsListScreen> createState() =>
      _PrescriptionsListScreenState();
}

class _PrescriptionsListScreenState extends State<PrescriptionsListScreen> {
  // ── Async data ────────────────────────────────────────────────────────────
  List<PrescriptionData>? _prescriptions; // null = loading
  String? _error;

  int    _selectedSort = 0;
  String _filterKey    = 'all';   // 'all' | 'patient:<full name>'

  final _searchController = TextEditingController();

  final List<String> _sortOptions = ['Newest first', 'Oldest first', 'Patient'];

  /// Filter chips derived live from loaded prescriptions.
  /// Each chip is (display label, accent color, filter key).
  List<(String, Color, String)> get _filterChips {
    final all = _prescriptions ?? [];

    final seen         = <String>{};
    final patientChips = <(String, Color, String)>[];
    for (final p in all) {
      if (seen.add(p.patientName)) {
        final count = all.where((x) => x.patientName == p.patientName).length;
        patientChips.add((
          '${p.patientName.split(' ').first} ($count)',
          p.patientAvatarColor,
          'patient:${p.patientName}',
        ));
      }
    }

    return [
      ('All (${all.length})', _kGreen, 'all'),
      ...patientChips,
    ];
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) setState(() { _error = null; _prescriptions = null; });
    try {
      final list = await DataService.instance.getPrescriptions();
      if (mounted) setState(() => _prescriptions = list);
    } catch (_) {
      if (mounted) setState(() {
        _prescriptions = [];
        _error = 'Could not load prescriptions. Check your connection and retry.';
      });
    }
  }

  // ── Filtered + sorted data ────────────────────────────────────────────────────

  List<PrescriptionData> get _filtered {
    List<PrescriptionData> list = List.from(_prescriptions ?? []);

    // Apply patient filter
    if (_filterKey.startsWith('patient:')) {
      final name = _filterKey.substring(8);
      list = list.where((p) => p.patientName == name).toList();
    }

    // Apply search
    final q = _searchController.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.cause.toLowerCase().contains(q) ||
                p.patientName.toLowerCase().contains(q) ||
                p.doctor.toLowerCase().contains(q) ||
                p.hospital.toLowerCase().contains(q),
          )
          .toList();
    }

    // Apply sort
    switch (_selectedSort) {
      case 0: // Newest first — already sorted newest-first in sample data
        break;
      case 1: // Oldest first
        list = list.reversed.toList();
        break;
      case 2: // Patient A–Z
        list.sort((a, b) => a.patientName.compareTo(b.patientName));
        break;
    }

    return list;
  }

  /// Group filtered prescriptions by year → { 2025: [...], 2024: [...] }
  Map<int, List<PrescriptionData>> get _groupedByYear {
    final Map<int, List<PrescriptionData>> map = {};
    for (final p in _filtered) {
      map.putIfAbsent(p.year, () => []).add(p);
    }
    return map;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedByYear;
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed chrome
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 14),
                  _buildSortRow(),
                  const SizedBox(height: 10),
                  _buildFilterRow(),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // Scrollable list grouped by year
            Expanded(
              child: _error != null
                  ? OfflineRetryWidget(onRetry: _reload, message: _error)
                  : _prescriptions == null
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : RefreshIndicator(
                          onRefresh: _reload,
                          color: AppColors.primary,
                          child: _filtered.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [_buildEmptyState()],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                                  itemCount: years.length,
                                  itemBuilder: (context, idx) {
                                    final year = years[idx];
                                    final prescriptions = grouped[year]!;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Year header
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Text(
                                            '$year',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        // Cards for this year
                                        ...prescriptions.map(
                                          (p) => Dismissible(
                                            key: ValueKey(p.id),
                                            direction: DismissDirection.endToStart,
                                            background: const SizedBox.shrink(),
                                            secondaryBackground: _deleteBg(),
                                            confirmDismiss: (_) => showDialog<bool>(
                                              context: context,
                                              builder: (dlg) => AlertDialog(
                                                backgroundColor: AppColors.card,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16)),
                                                title: Text(p.cause,
                                                    style: const TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textPrimary)),
                                                content: const Text(
                                                  'Delete this prescription? This cannot be undone.',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: AppColors.textSecondary),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(dlg).pop(false),
                                                    child: const Text('Cancel',
                                                        style: TextStyle(
                                                            color: AppColors.textSecondary)),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.of(dlg).pop(true),
                                                    child: const Text('Delete',
                                                        style: TextStyle(
                                                            color: AppColors.danger,
                                                            fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            onDismissed: (_) async {
                                              await DataService.instance.deletePrescription(p.id);
                                              _reload();
                                            },
                                            child: PrescriptionListCard(
                                              cause: p.cause,
                                              date: p.date,
                                              hospital: p.hospital,
                                              doctor: p.doctor,
                                              patientName: p.patientName,
                                              patientInitials: p.patientInitials,
                                              patientAvatarColor: p.patientAvatarColor,
                                              medicineCount: p.medicines.length,
                                              onTap: () async {
                                                await context.push(AppRoutes.prescriptionDetail, extra: p);
                                                _reload();
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),

      // Green FAB → Add Prescription
      floatingActionButton: FloatingActionButton(
        heroTag: 'prescriptions-fab',
        onPressed: () async {
          await context.push(AppRoutes.prescriptionsAdd);
          _reload();
        },
        backgroundColor: _kGreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

    );
  }

  // ── Swipe-delete background ───────────────────────────────────────────────────

  Widget _deleteBg() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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

  // ── Empty state ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isFiltered = _filterKey != 'all' || _searchController.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 34,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No prescriptions found' : 'No prescriptions yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'Try adjusting your search or filter.'
                  : 'Tap + to add your first prescription.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chrome builders ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Prescriptions',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        _iconBtn(Icons.tune_rounded, () {}),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
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
          const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search by cause, patient, doctor...',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
    return _labeledChipRow(
      label: 'SORT BY',
      options: _sortOptions,
      selectedIndex: _selectedSort,
      onSelect: (i) => setState(() => _selectedSort = i),
      selectedColor: _kGreen,
      selectedTextColor: Colors.black87,
      showArrow: true,
    );
  }

  Widget _buildFilterRow() {
    final chips = _filterChips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FILTER BY PATIENT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _kGrey,
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
                    horizontal: 14,
                    vertical: 7,
                  ),
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

  Widget _labeledChipRow({
    required String label,
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
    required Color selectedColor,
    required Color selectedTextColor,
    bool showArrow = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _kGrey,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(options.length, (i) {
              final selected = i == selectedIndex;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? selectedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? selectedColor : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        options[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? selectedTextColor
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (showArrow && selected) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: selectedTextColor,
                        ),
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

}

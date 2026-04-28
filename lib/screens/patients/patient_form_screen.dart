import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/patient.dart';
import '../../services/data_service.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg    = AppColors.surface;
const _kCard  = AppColors.card;
const _kGreen = AppColors.primary;
const _kGrey  = AppColors.textSecondary;
const _kBorder = AppColors.border;

class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({super.key});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _nameCtrl = TextEditingController();
  bool  _isSaving = false;

  static const _relationships = ['Self', 'Spouse', 'Child', 'Parent', 'Other'];
  String _selectedRelationship = '';

  // Avatar color — auto-picked from name hash; user can override.
  static const _palette = AppColors.avatarPalette;
  int _selectedColorIndex = 0;

  Color get _selectedColor => _palette[_selectedColorIndex];

  String get _initials {
    final parts = _nameCtrl.text.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    // Auto-select a color based on the name so the preview feels live.
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _selectedColorIndex = name.hashCode.abs() % _palette.length;
      });
    } else {
      setState(() {}); // rebuild to update initials preview
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarPreview(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('PATIENT NAME'),
                    const SizedBox(height: 10),
                    _buildNameField(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('RELATIONSHIP'),
                    const SizedBox(height: 10),
                    _buildRelationshipChips(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('AVATAR COLOR'),
                    const SizedBox(height: 10),
                    _buildColorPicker(),
                    const SizedBox(height: 32),
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

  // ── Top bar ───────────────────────────────────────────────────────────────

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
                  'Patients',
                  style: TextStyle(
                    fontSize: 14,
                    color: _kGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Add Patient',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 72), // mirror back button for centering
        ],
      ),
    );
  }

  // ── Avatar preview ────────────────────────────────────────────────────────

  Widget _buildAvatarPreview() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _selectedColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _selectedColor.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _nameCtrl.text.trim().isEmpty
                ? 'Enter a name below'
                : _nameCtrl.text.trim(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (_selectedRelationship.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _selectedRelationship,
              style: const TextStyle(fontSize: 13, color: _kGrey),
            ),
          ],
        ],
      ),
    );
  }

  // ── Name field ────────────────────────────────────────────────────────────

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: _nameCtrl,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'e.g. Ravi Kumar',
          hintStyle: TextStyle(color: Color(0xFFAFADA6), fontSize: 15),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          prefixIcon: Icon(Icons.person_outline_rounded,
              color: Color(0xFFAFADA6), size: 20),
        ),
      ),
    );
  }

  // ── Relationship chips ────────────────────────────────────────────────────

  Widget _buildRelationshipChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _relationships.map((rel) {
        final selected = rel == _selectedRelationship;
        return GestureDetector(
          onTap: () => setState(
            () => _selectedRelationship = selected ? '' : rel,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? _kGreen.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _kGreen : _kBorder,
              ),
            ),
            child: Text(
              rel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? _kGreen : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Color picker ──────────────────────────────────────────────────────────

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(_palette.length, (i) {
        final selected = i == _selectedColorIndex;
        final color = _palette[i];
        return GestureDetector(
          onTap: () => setState(() => _selectedColorIndex = i),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: AppColors.textPrimary, width: 2.5)
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18)
                : null,
          ),
        );
      }),
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────

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
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Save Patient',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Save logic ────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the patient name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final patient = PatientData(
        name:         name,
        initials:     _initials,
        avatarColor:  _selectedColor,
        relationship: _selectedRelationship,
        medicines:    [],
      );

      await DataService.instance.addPatient(patient);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient added'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop(true); // signal success to caller
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

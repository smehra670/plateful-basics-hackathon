import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/pantry_photo.dart';
import 'pantry_import_screen.dart';

const _places = ['Fridge', 'Freezer', 'Cupboard', 'Counter'];

class PantryConfirmScreen extends StatefulWidget {
  const PantryConfirmScreen({super.key, required this.drafts});

  final List<PantryDraft> drafts;

  @override
  State<PantryConfirmScreen> createState() => _PantryConfirmScreenState();
}

class _PantryConfirmScreenState extends State<PantryConfirmScreen> {
  late List<PantryDraft> _drafts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _drafts = List.of(widget.drafts);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    for (final draft in _drafts) {
      final name = draft.name.trim();
      if (name.isEmpty) continue;
      await state.addIngredient(
        name: name,
        quantity: draft.quantity <= 0 ? 1 : draft.quantity,
        unit: draft.unit.trim().isEmpty ? 'pcs' : draft.unit.trim(),
        expiry: draft.expiry,
        imageUrl: draft.photoPath,
        storagePlace: draft.storagePlace,
        estimatedUnitValueGbp: draft.estimatedPriceGbp,
      );
    }
    if (!mounted) return;
    state.setShellTab(2);
    Navigator.of(context).pop();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_drafts.length} item(s) to your pantry'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('Confirm details', style: AppText.title(fontSize: 18)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Check each photo is the right food, then add. Nothing goes in the pantry until you confirm.',
                style: AppText.body(),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _drafts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final draft = _drafts[index];
                  return _DraftCard(
                    key: ObjectKey(draft),
                    draft: draft,
                    onChanged: () => setState(() {}),
                    onRemove: () => setState(() => _drafts.removeAt(index)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving || _drafts.isEmpty ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _saving ? 'Adding to pantry…' : 'Add to pantry',
                    style: AppText.button(),
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

class _DraftCard extends StatefulWidget {
  const _DraftCard({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final PantryDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<_DraftCard> {
  late final TextEditingController _name;
  late final TextEditingController _qty;
  late final TextEditingController _unit;

  @override
  void initState() {
    super.initState();
    final q = widget.draft.quantity;
    _name = TextEditingController(text: widget.draft.name);
    _qty = TextEditingController(
      text: q == q.roundToDouble() ? q.toInt().toString() : q.toString(),
    );
    _unit = TextEditingController(text: widget.draft.unit);
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _previewPhoto(String? path) {
    if (path == null || path.trim().isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: AppColors.ink,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: PantryPhoto(path: path, name: widget.draft.name),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDate:
          widget.draft.expiry ?? DateTime.now().add(const Duration(days: 7)),
    );
    if (picked == null) return;
    setState(() => widget.draft.expiry = picked);
    widget.onChanged();
  }

  void _quickExpiry(int days) {
    setState(() {
      widget.draft.expiry = DateTime.now().add(Duration(days: days));
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _previewPhoto(draft.photoPath),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: PantryPhoto(path: draft.photoPath, name: draft.name),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  onChanged: (v) => draft.name = v,
                  decoration: const InputDecoration(
                    labelText: 'Ingredient',
                    border: InputBorder.none,
                  ),
                  style: AppText.title(fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qty,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) =>
                      draft.quantity = double.tryParse(v) ?? draft.quantity,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _unit,
                  onChanged: (v) => draft.unit = v,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Expiry', style: AppText.label(fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Tomorrow', () => _quickExpiry(1)),
              _chip('3 days', () => _quickExpiry(3)),
              _chip('1 week', () => _quickExpiry(7)),
              _chip('2 weeks', () => _quickExpiry(14)),
              _chip(
                draft.expiry == null
                    ? 'Pick date'
                    : DateFormat.MMMd().format(draft.expiry!),
                _pickExpiry,
                selected: draft.expiry != null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Stored in', style: AppText.label(fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _places
                .map(
                  (place) => _chip(
                    place,
                    () {
                      setState(() => draft.storagePlace = place);
                      widget.onChanged();
                    },
                    selected: draft.storagePlace == place,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap, {bool selected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageMuted : AppColors.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppText.label(
            fontSize: 12,
            color: selected ? AppColors.green : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

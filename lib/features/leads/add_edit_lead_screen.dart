import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../core/models/lead_status.dart';
import '../../core/utils/secure_flag.dart';
import '../../features/parser/phone_normalizer.dart';
import 'duplicate_detection_dialog.dart';
import 'lead_draft.dart';
import 'merge_lead_screen.dart';
import 'sections_crud_widget.dart';
import 'status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AddEditLeadScreen
// ─────────────────────────────────────────────────────────────────────────────

class AddEditLeadScreen extends ConsumerStatefulWidget {
  const AddEditLeadScreen({
    super.key,
    this.editLeadId,
    this.prefillPhone,
    this.initialDraft,
  });

  /// null → Add mode; non-null → Edit mode.
  final String? editLeadId;

  /// Pre-fill first phone (from native overlay intent).
  final String? prefillPhone;

  /// Pre-filled draft from paste preview.
  final LeadDraft? initialDraft;

  bool get isEdit => editLeadId != null;

  @override
  ConsumerState<AddEditLeadScreen> createState() => _AddEditLeadScreenState();
}

class _AddEditLeadScreenState extends ConsumerState<AddEditLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _normalizer = const PhoneNormalizer();
  final _picker = ImagePicker();

  late LeadDraft _draft;
  late TextEditingController _nameCtrl;
  late TextEditingController _businessTypeCtrl;
  late TextEditingController _notesCtrl;
  final List<TextEditingController> _phoneCtrlList = [];
  final List<File> _newImages = [];
  bool _loading = false;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft ??
        LeadDraft(
          phones: widget.prefillPhone != null
              ? [PhoneEntry(raw: widget.prefillPhone!, isPrimary: true)]
              : [],
        );
    _nameCtrl = TextEditingController(text: _draft.name);
    _businessTypeCtrl =
        TextEditingController(text: _draft.businessType ?? '');
    _notesCtrl = TextEditingController(text: _draft.notes ?? '');
    _rebuildPhoneControllers();
  }

  void _rebuildPhoneControllers() {
    for (final c in _phoneCtrlList) {
      c.dispose();
    }
    _phoneCtrlList.clear();
    for (final ph in _draft.phones) {
      _phoneCtrlList.add(TextEditingController(text: ph.raw));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessTypeCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _phoneCtrlList) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingLead(String id) async {
    if (_initialised) return;
    _initialised = true;
    final repo = ref.read(leadsRepositoryProvider);
    final lead = await repo.getLeadById(id);
    if (lead == null || !mounted) return;

    final phones = await repo.getPhonesForLead(id);
    final sections = await repo.getSectionsForLead(id);
    final images = await repo.getImagesForLead(id);

    setState(() {
      _draft = LeadDraft(
        name: lead.name,
        businessType: lead.businessType,
        status: LeadStatus.fromDb(lead.status),
        notes: lead.notes,
        phones: phones
            .map((p) => PhoneEntry(
                  raw: p.e164,
                  label: p.label,
                  isPrimary: p.isPrimary,
                ))
            .toList(),
        sections: sections
            .map((s) => SectionEntry(title: s.title, body: s.body))
            .toList(),
        existingImagePaths: images.map((i) => i.filePath).toList(),
      );
      _nameCtrl.text = _draft.name;
      _businessTypeCtrl.text = _draft.businessType ?? '';
      _notesCtrl.text = _draft.notes ?? '';
      _rebuildPhoneControllers();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit && !_initialised) {
      _loadExistingLead(widget.editLeadId!);
    }

    final businessTypesAsync = ref.watch(businessTypesProvider);
    final flagSecure = ref.watch(appSettingsProvider).flagSecureEnabled;

    return SecureFlagScope(
      enabled: flagSecure,
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Lead' : 'Add Lead'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),

            // Business type autocomplete
            _BusinessTypeField(
              controller: _businessTypeCtrl,
              businessTypesAsync: businessTypesAsync,
            ),
            const SizedBox(height: 12),

            // Status picker
            InkWell(
              onTap: () async {
                final picked = await StatusPickerBottomSheet.show(
                    context, _draft.status);
                if (picked != null) setState(() => _draft.status = picked);
              },
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusChip(status: _draft.status),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Phones
            _PhonesField(
              phones: _draft.phones,
              controllers: _phoneCtrlList,
              onAdd: () {
                setState(() {
                  _draft.phones.add(PhoneEntry(raw: ''));
                  _phoneCtrlList.add(TextEditingController());
                });
              },
              onRemove: (i) {
                setState(() {
                  _draft.phones.removeAt(i);
                  _phoneCtrlList[i].dispose();
                  _phoneCtrlList.removeAt(i);
                });
              },
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Images
            _ImagesField(
              existingPaths: _draft.existingImagePaths,
              newImages: _newImages,
              onPick: _pickImage,
              onRemoveExisting: (i) =>
                  setState(() => _draft.existingImagePaths.removeAt(i)),
              onRemoveNew: (i) => setState(() => _newImages.removeAt(i)),
            ),
            const SizedBox(height: 12),

            // Sections
            SectionsCrudWidget(
              sections: _draft.sections,
              onChange: (s) => setState(() => _draft.sections = s),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    ), // Scaffold
    ); // SecureFlagScope
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final total = _draft.existingImagePaths.length + _newImages.length;
    if (total >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 images per lead')),
      );
      return;
    }
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newImages.add(File(picked.path)));
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Sync phone controllers → draft.
    for (var i = 0; i < _phoneCtrlList.length; i++) {
      if (i < _draft.phones.length) {
        _draft.phones[i].raw = _phoneCtrlList[i].text;
      }
    }

    // Validate phone formats.
    bool phoneError = false;
    for (final ph in _draft.phones) {
      if (ph.raw.trim().isEmpty) continue;
      final e164 = _normalizer.tryNormalize(ph.raw);
      if (e164 == null) {
        ph.errorText = 'Invalid number';
        phoneError = true;
      } else {
        ph.errorText = null;
      }
    }
    if (phoneError) {
      setState(() {});
      return;
    }

    setState(() => _loading = true);
    try {
      await _doSave();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doSave() async {
    final repo = ref.read(leadsRepositoryProvider);
    final imageService = ref.read(imageServiceProvider);
    final lookupService = ref.read(lookupIndexServiceProvider);

    final name = _nameCtrl.text.trim();
    final businessType = _businessTypeCtrl.text.trim().isEmpty
        ? null
        : _businessTypeCtrl.text.trim();
    final notes =
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    // Sync + normalize phones.
    for (var i = 0; i < _phoneCtrlList.length; i++) {
      if (i < _draft.phones.length) {
        _draft.phones[i].raw = _phoneCtrlList[i].text;
      }
    }
    final validPhones = _draft.phones
        .where((p) => p.raw.trim().isNotEmpty)
        .map((p) {
          final e164 = _normalizer.tryNormalize(p.raw) ?? p.raw;
          return (e164: e164, label: p.label, isPrimary: p.isPrimary);
        })
        .toList();

    final sections = _draft.sections
        .map((s) => (title: s.title, body: s.body))
        .toList();

    // ── Duplicate detection (Add mode only; Edit mode skips own phones) ──
    final e164s = validPhones.map((p) => p.e164).toList();
    final duplicates = await repo.findDuplicatesByPhones(
      e164s,
      excludeLeadId: widget.editLeadId, // null on add → no exclusion
    );

    if (duplicates.isNotEmpty && mounted) {
      // Determine if "Save as separate" is valid:
      // It's valid only when every conflicting phone has been removed from
      // the draft (i.e., no overlap).
      final allExistingE164s = <String>{};
      for (final dup in duplicates) {
        final phones = await repo.getPhonesForLead(dup.id);
        allExistingE164s.addAll(phones.map((p) => p.e164));
      }
      final draftE164s = e164s.toSet();
      final canSaveAsSeparate = draftE164s.intersection(allExistingE164s).isEmpty;

      if (!mounted) return;
      final result = await DuplicateDetectionDialog.show(
        context,
        draft: _draft,
        duplicates: duplicates,
        canSaveAsSeparate: canSaveAsSeparate,
      );

      switch (result.action) {
        case DuplicateAction.cancel:
          // Return to editor — do nothing.
          return;

        case DuplicateAction.keepExisting:
          // Discard draft and go back.
          if (mounted) context.pop();
          return;

        case DuplicateAction.saveAsSeparate:
          // Fall through to normal save below — phones no longer conflict.
          break;

        case DuplicateAction.reviewAndMerge:
          // Navigate to MergeLeadScreen.
          final targetId = result.chosenTargetLeadId!;
          final targetLead = await repo.getLeadById(targetId);
          if (targetLead == null || !mounted) return;

          final existingPhones = await repo.getPhonesForLead(targetId);
          final existingSections = await repo.getSectionsForLead(targetId);

          // Sync draft one more time.
          _draft.name = name;
          _draft.businessType = businessType;
          _draft.notes = notes;

          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MergeLeadScreen(
                targetLead: targetLead,
                existingPhones: existingPhones,
                existingSections: existingSections,
                draft: _draft,
                draftPhones: validPhones,
                draftSections: sections,
              ),
            ),
          );
          // MergeLeadScreen pops all the way to the list on save.
          // If the user cancels, they're back here — just return.
          return;
      }
    }

    // ── No conflict (or user chose Save as separate) → persist normally ──
    // Determine source.
    final source = widget.initialDraft != null ? 'PASTE' : 'MANUAL';

    String leadId;
    if (widget.isEdit) {
      final saved = await repo.updateLead(
        widget.editLeadId!,
        name: Value(name),
        businessType: Value(businessType),
        status: Value(_draft.status.dbValue),
        notes: Value(notes),
      );
      await repo.replaceAllPhones(widget.editLeadId!, validPhones);
      await repo.replaceAllSections(widget.editLeadId!, sections);
      leadId = saved.id;
    } else {
      final saved = await repo.createLead(
        name: name,
        businessType: businessType,
        status: _draft.status.dbValue,
        source: source,
        notes: notes,
        phones: validPhones,
        sections: sections,
      );
      leadId = saved.id;
    }

    // Process new images (compress + store).
    final existingCount = _draft.existingImagePaths.length;
    for (final (i, file) in _newImages.indexed) {
      try {
        final path = await imageService.processAndStore(
          sourceFile: file,
          leadId: leadId,
          position: existingCount + i,
        );
        await repo.addImage(leadId, path);
      } catch (e) {
        debugPrint('Image processing error: $e');
      }
    }

    // Upsert native lookup index.
    final lead = await repo.getLeadById(leadId);
    final phones = await repo.getPhonesForLead(leadId);
    if (lead != null) {
      await lookupService.upsertLead(lead: lead, phones: phones);
    }

    if (mounted) context.pop();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BusinessTypeField extends StatelessWidget {
  const _BusinessTypeField({
    required this.controller,
    required this.businessTypesAsync,
  });

  final TextEditingController controller;
  final AsyncValue<List<String>> businessTypesAsync;

  @override
  Widget build(BuildContext context) {
    final suggestions = businessTypesAsync.valueOrNull ?? [];
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (value) {
        if (value.text.isEmpty) return suggestions;
        final q = value.text.toLowerCase();
        return suggestions.where((t) => t.toLowerCase().contains(q));
      },
      onSelected: (v) => controller.text = v,
      fieldViewBuilder: (_, fieldCtrl, focusNode, onSubmit) {
        // Keep our controller synced.
        fieldCtrl.text = controller.text;
        fieldCtrl.addListener(() => controller.text = fieldCtrl.text);
        return TextFormField(
          controller: fieldCtrl,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Business Type',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        );
      },
    );
  }
}

class _PhonesField extends StatelessWidget {
  const _PhonesField({
    required this.phones,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
  });

  final List<PhoneEntry> phones;
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Phones',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: onAdd,
            ),
          ],
        ),
        ...phones.asMap().entries.map((e) {
          final i = e.key;
          final ph = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: i < controllers.length ? controllers[i] : null,
              decoration: InputDecoration(
                labelText: i == 0 ? 'Primary phone' : 'Phone ${i + 1}',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  i == 0 ? Icons.star_outline : Icons.phone_outlined,
                  size: 20,
                ),
                errorText: ph.errorText,
                suffixIcon: phones.length > 1
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: theme.colorScheme.error,
                        onPressed: () => onRemove(i),
                      )
                    : null,
              ),
              keyboardType: TextInputType.phone,
            ),
          );
        }),
      ],
    );
  }
}

class _ImagesField extends StatelessWidget {
  const _ImagesField({
    required this.existingPaths,
    required this.newImages,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  final List<String> existingPaths;
  final List<File> newImages;
  final VoidCallback onPick;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = existingPaths.length + newImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Images',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (total > 0)
              Text(' ($total/3)',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            const Spacer(),
            if (total < 3)
              TextButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined,
                    size: 18),
                label: const Text('Add'),
                onPressed: onPick,
              ),
          ],
        ),
        if (total > 0)
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...existingPaths.asMap().entries.map((e) => _ImgThumb(
                      child: Image.file(File(e.value),
                          width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) =>
                              const Icon(Icons.broken_image_outlined)),
                      onRemove: () => onRemoveExisting(e.key),
                    )),
                ...newImages.asMap().entries.map((e) => _ImgThumb(
                      child: Image.file(e.value,
                          width: 80, height: 80, fit: BoxFit.cover),
                      onRemove: () => onRemoveNew(e.key),
                    )),
              ],
            ),
          ),
      ],
    );
  }
}

class _ImgThumb extends StatelessWidget {
  const _ImgThumb({required this.child, required this.onRemove});
  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: child,
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

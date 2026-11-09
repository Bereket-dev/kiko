import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/lead_status.dart';
import '../../features/parser/lead_text_parser.dart';
import 'add_edit_lead_screen.dart';
import 'lead_draft.dart';
import 'sections_crud_widget.dart';
import 'status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PastePreviewScreen
// ─────────────────────────────────────────────────────────────────────────────
//
// Spec requirement: parse pasted text, show editable preview.
// NOTHING is persisted until the user taps "Continue" → AddEditLeadScreen → Save.
// ─────────────────────────────────────────────────────────────────────────────

class PastePreviewScreen extends ConsumerStatefulWidget {
  const PastePreviewScreen({super.key});

  @override
  ConsumerState<PastePreviewScreen> createState() =>
      _PastePreviewScreenState();
}

class _PastePreviewScreenState extends ConsumerState<PastePreviewScreen> {
  final _parser = LeadTextParser();
  final _textCtrl = TextEditingController();

  bool _showPreview = false;

  // Editable preview controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _businessTypeCtrl;
  late TextEditingController _notesCtrl;
  LeadStatus _status = LeadStatus.newLead;
  List<_EditablePhone> _phones = [];
  List<SectionEntry> _sections = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _businessTypeCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _tryPasteFromClipboard());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _nameCtrl.dispose();
    _businessTypeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Clipboard ──────────────────────────────────────────────────────────────

  Future<void> _tryPasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _textCtrl.text = data.text!;
      _parseText();
    }
  }

  // ── Parse ──────────────────────────────────────────────────────────────────

  void _parseText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final parsed = _parser.parse(text);
    setState(() {
      _showPreview = true;
      _nameCtrl.text = parsed.name ?? '';
      _businessTypeCtrl.text = parsed.businessType ?? '';
      _notesCtrl.text = parsed.remainingBody;
      _phones = parsed.phones
          .map((p) => _EditablePhone(e164: p.e164, raw: p.raw))
          .toList();
      _sections = parsed.sections
          .map((s) => SectionEntry(title: s.title, body: s.body))
          .toList();
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _proceedToSave() {
    final draft = LeadDraft(
      name: _nameCtrl.text.trim(),
      businessType: _businessTypeCtrl.text.trim().isEmpty
          ? null
          : _businessTypeCtrl.text.trim(),
      status: _status,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      phones: _phones
          .map((p) => PhoneEntry(
                raw: p.e164,
                isPrimary: _phones.indexOf(p) == 0,
              ))
          .toList(),
      sections: List.from(_sections),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditLeadScreen(initialDraft: draft),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paste Lead'),
        actions: [
          if (_showPreview)
            TextButton(
              onPressed: _proceedToSave,
              child: const Text('Continue'),
            ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildPasteInput(),
    );
  }

  // ── Paste input ───────────────────────────────────────────────────────────

  Widget _buildPasteInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Paste contact info below',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Include name, phone numbers, business type, and notes.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText:
                    'e.g.\nAbebe Kebede\n0911 234 567\nBusiness: Retailer\n\nMerkato, Addis Ababa',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.content_paste_outlined),
                  label: const Text('From clipboard'),
                  onPressed: _tryPasteFromClipboard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Parse'),
                  onPressed: _parseText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Preview ───────────────────────────────────────────────────────────────

  Widget _buildPreview() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: theme.colorScheme.secondaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Review and edit before saving. Nothing stored yet.',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _showPreview = false),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Name
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // Business type
              TextField(
                controller: _businessTypeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Business Type',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // Status
              InkWell(
                onTap: () async {
                  final picked = await StatusPickerBottomSheet.show(
                      context, _status);
                  if (picked != null) setState(() => _status = picked);
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
                      StatusChip(status: _status),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Phones
              if (_phones.isNotEmpty) ...[
                Text('Phones',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ..._phones.asMap().entries.map((e) {
                  final i = e.key;
                  final ph = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          i == 0 ? Icons.star : Icons.phone_outlined,
                          size: 18,
                          color: i == 0
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: ph.e164,
                            decoration: InputDecoration(
                              labelText: i == 0
                                  ? 'Primary'
                                  : 'Phone ${i + 1}',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => ph.e164 = v,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: theme.colorScheme.error,
                          onPressed: () =>
                              setState(() => _phones.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // Sections
              if (_sections.isNotEmpty) ...[
                SectionsCrudWidget(
                  sections: _sections,
                  onChange: (s) => setState(() => _sections = s),
                ),
                const SizedBox(height: 12),
              ],

              // Remaining notes
              if (_notesCtrl.text.isNotEmpty) ...[
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
              ],

              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue to Save'),
                onPressed: _proceedToSave,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditablePhone  (local mutable wrapper)
// ─────────────────────────────────────────────────────────────────────────────

class _EditablePhone {
  _EditablePhone({required this.e164, required this.raw});
  String e164;
  String raw;
}

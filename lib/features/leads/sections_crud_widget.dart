import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SectionEntry  (in-memory model used while editing)
// ─────────────────────────────────────────────────────────────────────────────

class SectionEntry {
  SectionEntry({required this.title, required this.body, String? id})
      : id = id ?? UniqueKey().toString();

  final String id; // stable key for ReorderableListView
  String title;
  String body;

  SectionEntry copyWith({String? title, String? body}) => SectionEntry(
        title: title ?? this.title,
        body: body ?? this.body,
        id: id,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SectionsCrudWidget
// ─────────────────────────────────────────────────────────────────────────────
//
// Displays a list of sections that can be added, edited, reordered, and
// deleted inline.  The parent form owns the state via [sections] + [onChange].
// ─────────────────────────────────────────────────────────────────────────────

class SectionsCrudWidget extends StatelessWidget {
  const SectionsCrudWidget({
    super.key,
    required this.sections,
    required this.onChange,
  });

  final List<SectionEntry> sections;
  final ValueChanged<List<SectionEntry>> onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Text('Sections',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: () => _addSection(context),
            ),
          ],
        ),

        if (sections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No sections yet',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sections.length,
            onReorderItem: _onReorder,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 4,
              child: child,
            ),
            itemBuilder: (context, index) {
              final s = sections[index];
              return _SectionTile(
                key: ValueKey(s.id),
                section: s,
                onEdit: () => _editSection(context, index),
                onDelete: () => _deleteSection(index),
              );
            },
          ),
      ],
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    final updated = List<SectionEntry>.from(sections);
    if (newIndex > oldIndex) newIndex--;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    onChange(updated);
  }

  Future<void> _addSection(BuildContext context) async {
    final result = await _SectionEditDialog.show(context, null);
    if (result != null) {
      onChange([...sections, result]);
    }
  }

  Future<void> _editSection(BuildContext context, int index) async {
    final result = await _SectionEditDialog.show(context, sections[index]);
    if (result != null) {
      final updated = List<SectionEntry>.from(sections);
      updated[index] = result;
      onChange(updated);
    }
  }

  void _deleteSection(int index) {
    final updated = List<SectionEntry>.from(sections)..removeAt(index);
    onChange(updated);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionTile
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    super.key,
    required this.section,
    required this.onEdit,
    required this.onDelete,
  });

  final SectionEntry section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: section.title.isNotEmpty
            ? Text(section.title, style: theme.textTheme.titleSmall)
            : Text('(no title)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
        subtitle: section.body.isNotEmpty
            ? Text(
                section.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Edit section',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
              onPressed: onDelete,
              tooltip: 'Delete section',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionEditDialog
// ─────────────────────────────────────────────────────────────────────────────

class _SectionEditDialog extends StatefulWidget {
  const _SectionEditDialog({this.existing});

  final SectionEntry? existing;

  static Future<SectionEntry?> show(
      BuildContext context, SectionEntry? existing) {
    return showDialog<SectionEntry>(
      context: context,
      builder: (_) => _SectionEditDialog(existing: existing),
    );
  }

  @override
  State<_SectionEditDialog> createState() => _SectionEditDialogState();
}

class _SectionEditDialogState extends State<_SectionEditDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Section' : 'Add Section'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty && _titleCtrl.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final entry = SectionEntry(
      title: _titleCtrl.text.trim(),
      body: body,
      id: widget.existing?.id,
    );
    Navigator.of(context).pop(entry);
  }
}

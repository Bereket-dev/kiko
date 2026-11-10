import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/models/lead_status.dart';
import '../../core/utils/secure_flag.dart';
import '../reminders/set_reminder_widget.dart';
import 'status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LeadDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class LeadDetailScreen extends ConsumerWidget {
  const LeadDetailScreen({super.key, required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsync = ref.watch(leadDetailProvider(leadId));
    final phonesAsync = ref.watch(leadPhonesProvider(leadId));
    final sectionsAsync = ref.watch(leadSectionsProvider(leadId));
    final imagesAsync = ref.watch(leadImagesProvider(leadId));
    final flagSecure = ref.watch(appSettingsProvider).flagSecureEnabled;

    return SecureFlagScope(
      enabled: flagSecure,
      child: leadAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error: $e')),
        ),
        data: (lead) {
          if (lead == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Lead not found')),
            );
          }
          return _LeadDetailView(
            lead: lead,
            phonesAsync: phonesAsync,
            sectionsAsync: sectionsAsync,
            imagesAsync: imagesAsync,
            onEdit: () => context.push('/leads/${lead.id}/edit'),
            onDelete: () => _confirmDelete(context, ref, lead),
            onReminder: () => _openReminderSheet(context, ref, lead),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Lead lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lead?'),
        content: Text('Delete "${lead.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(leadsRepositoryProvider).deleteLead(lead.id);
      if (context.mounted) context.pop();
    }
  }

  Future<void> _openReminderSheet(
      BuildContext context, WidgetRef ref, Lead lead) async {
    final existing = await ref
        .read(remindersRepositoryProvider)
        .getPendingReminderForLead(lead.id);
    if (!context.mounted) return;
    await showSetReminderSheet(
      context: context,
      ref: ref,
      leadId: lead.id,
      leadName: lead.name,
      existing: existing,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LeadDetailView
// ─────────────────────────────────────────────────────────────────────────────

class _LeadDetailView extends StatelessWidget {
  const _LeadDetailView({
    required this.lead,
    required this.phonesAsync,
    required this.sectionsAsync,
    required this.imagesAsync,
    required this.onEdit,
    required this.onDelete,
    required this.onReminder,
  });

  final Lead lead;
  final AsyncValue<List<LeadPhone>> phonesAsync;
  final AsyncValue<List<LeadSection>> sectionsAsync;
  final AsyncValue<List<LeadImage>> imagesAsync;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    final status = LeadStatus.fromDb(lead.status);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lead.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') onDelete();
              if (v == 'reminder') onReminder();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'reminder',
                child: ListTile(
                  leading: Icon(Icons.alarm_add_outlined),
                  title: Text('Set Reminder'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status + business type row ──────────────────────────────────
          Row(
            children: [
              StatusChip(status: status),
              if (lead.businessType != null) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(lead.businessType!),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ── Phones ────────────────────────────────────────────────────
          _Section(
            title: 'Phones',
            child: phonesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (phones) {
                if (phones.isEmpty) {
                  return Text('No phones',
                      style: TextStyle(color: theme.colorScheme.outline));
                }
                return Column(
                  children: phones
                      .map((p) => _PhoneTile(phone: p))
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Notes ─────────────────────────────────────────────────────
          if (lead.notes != null && lead.notes!.isNotEmpty) ...[
            _Section(
              title: 'Notes',
              child: Text(lead.notes!),
            ),
            const SizedBox(height: 12),
          ],

          // ── Images ────────────────────────────────────────────────────
          imagesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, st) => const SizedBox.shrink(),
            data: (images) {
              if (images.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: 'Images'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                      itemBuilder: (_, i) =>
                          _ImageThumb(image: images[i]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // ── Sections ──────────────────────────────────────────────────
          sectionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, st) => const SizedBox.shrink(),
            data: (sections) {
              if (sections.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sections.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _Section(
                      title: s.title.isNotEmpty ? s.title : null,
                      child: Text(s.body),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneTile extends StatelessWidget {
  const _PhoneTile({required this.phone});

  final LeadPhone phone;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        phone.isPrimary ? Icons.star : Icons.phone_outlined,
        size: 20,
        color: phone.isPrimary
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
      title: Text(phone.e164),
      subtitle: phone.label != null ? Text(phone.label!) : null,
      trailing: IconButton(
        icon: const Icon(Icons.call_outlined),
        tooltip: 'Call',
        onPressed: () async {
          final uri = Uri(scheme: 'tel', path: phone.e164);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) _SectionHeader(title: title!),
        if (title != null) const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.image});

  final LeadImage image;

  @override
  Widget build(BuildContext context) {
    final file = File(image.filePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FutureBuilder<bool>(
        future: file.exists(),
        builder: (_, snap) {
          if (snap.data == true) {
            return Image.file(file,
                width: 100, height: 100, fit: BoxFit.cover);
          }
          return Container(
            width: 100,
            height: 100,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined),
          );
        },
      ),
    );
  }
}

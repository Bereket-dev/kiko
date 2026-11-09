import 'package:flutter/material.dart';
import '../../core/models/lead_status.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StatusChip  (read-only display)
// ─────────────────────────────────────────────────────────────────────────────

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final LeadStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label),
      labelStyle: TextStyle(
        color: status.color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: status.backgroundColor,
      side: BorderSide(color: status.color.withValues(alpha: 0.4)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusPickerBottomSheet  (for Add/Edit form)
// ─────────────────────────────────────────────────────────────────────────────

class StatusPickerBottomSheet extends StatelessWidget {
  const StatusPickerBottomSheet({super.key, required this.current});

  final LeadStatus current;

  static Future<LeadStatus?> show(BuildContext context, LeadStatus current) {
    return showModalBottomSheet<LeadStatus>(
      context: context,
      builder: (_) => StatusPickerBottomSheet(current: current),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Set Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          ...LeadStatus.values.map((status) {
            final selected = status == current;
            return ListTile(
              leading: CircleAvatar(
                radius: 8,
                backgroundColor: status.color,
              ),
              title: Text(status.label),
              trailing: selected
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(status),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

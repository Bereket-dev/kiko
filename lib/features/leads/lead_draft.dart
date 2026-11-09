import '../../core/models/lead_status.dart';
import 'sections_crud_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared in-memory draft types used by AddEditLeadScreen and PastePreviewScreen
// ─────────────────────────────────────────────────────────────────────────────

class PhoneEntry {
  PhoneEntry({required this.raw, this.label, this.isPrimary = false});

  String raw;
  String? label;
  bool isPrimary;
  String? errorText;
}

class LeadDraft {
  LeadDraft({
    this.name = '',
    this.businessType,
    this.status = LeadStatus.newLead,
    this.notes,
    List<PhoneEntry>? phones,
    List<SectionEntry>? sections,
    List<String>? existingImagePaths,
  })  : phones = phones ?? [],
        sections = sections ?? [],
        existingImagePaths = existingImagePaths ?? [];

  String name;
  String? businessType;
  LeadStatus status;
  String? notes;
  List<PhoneEntry> phones;
  List<SectionEntry> sections;
  List<String> existingImagePaths;
}

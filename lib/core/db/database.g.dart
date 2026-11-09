// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LeadsTable extends Leads with TableInfo<$LeadsTable, Lead> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LeadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessTypeMeta = const VerificationMeta(
    'businessType',
  );
  @override
  late final GeneratedColumn<String> businessType = GeneratedColumn<String>(
    'business_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('NEW'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MANUAL'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastContactAtMeta = const VerificationMeta(
    'lastContactAt',
  );
  @override
  late final GeneratedColumn<int> lastContactAt = GeneratedColumn<int>(
    'last_contact_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    businessType,
    status,
    source,
    notes,
    archived,
    createdAt,
    updatedAt,
    lastContactAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'leads';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lead> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('business_type')) {
      context.handle(
        _businessTypeMeta,
        businessType.isAcceptableOrUnknown(
          data['business_type']!,
          _businessTypeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_contact_at')) {
      context.handle(
        _lastContactAtMeta,
        lastContactAt.isAcceptableOrUnknown(
          data['last_contact_at']!,
          _lastContactAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lead map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lead(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      businessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_type'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lastContactAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_contact_at'],
      ),
    );
  }

  @override
  $LeadsTable createAlias(String alias) {
    return $LeadsTable(attachedDatabase, alias);
  }
}

class Lead extends DataClass implements Insertable<Lead> {
  final String id;
  final String name;
  final String? businessType;
  final String status;
  final String source;
  final String? notes;
  final bool archived;
  final int createdAt;
  final int updatedAt;
  final int? lastContactAt;
  const Lead({
    required this.id,
    required this.name,
    this.businessType,
    required this.status,
    required this.source,
    this.notes,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
    this.lastContactAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || businessType != null) {
      map['business_type'] = Variable<String>(businessType);
    }
    map['status'] = Variable<String>(status);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || lastContactAt != null) {
      map['last_contact_at'] = Variable<int>(lastContactAt);
    }
    return map;
  }

  LeadsCompanion toCompanion(bool nullToAbsent) {
    return LeadsCompanion(
      id: Value(id),
      name: Value(name),
      businessType: businessType == null && nullToAbsent
          ? const Value.absent()
          : Value(businessType),
      status: Value(status),
      source: Value(source),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastContactAt: lastContactAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastContactAt),
    );
  }

  factory Lead.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lead(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      businessType: serializer.fromJson<String?>(json['businessType']),
      status: serializer.fromJson<String>(json['status']),
      source: serializer.fromJson<String>(json['source']),
      notes: serializer.fromJson<String?>(json['notes']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastContactAt: serializer.fromJson<int?>(json['lastContactAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'businessType': serializer.toJson<String?>(businessType),
      'status': serializer.toJson<String>(status),
      'source': serializer.toJson<String>(source),
      'notes': serializer.toJson<String?>(notes),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastContactAt': serializer.toJson<int?>(lastContactAt),
    };
  }

  Lead copyWith({
    String? id,
    String? name,
    Value<String?> businessType = const Value.absent(),
    String? status,
    String? source,
    Value<String?> notes = const Value.absent(),
    bool? archived,
    int? createdAt,
    int? updatedAt,
    Value<int?> lastContactAt = const Value.absent(),
  }) => Lead(
    id: id ?? this.id,
    name: name ?? this.name,
    businessType: businessType.present ? businessType.value : this.businessType,
    status: status ?? this.status,
    source: source ?? this.source,
    notes: notes.present ? notes.value : this.notes,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastContactAt: lastContactAt.present
        ? lastContactAt.value
        : this.lastContactAt,
  );
  Lead copyWithCompanion(LeadsCompanion data) {
    return Lead(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      businessType: data.businessType.present
          ? data.businessType.value
          : this.businessType,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      notes: data.notes.present ? data.notes.value : this.notes,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastContactAt: data.lastContactAt.present
          ? data.lastContactAt.value
          : this.lastContactAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lead(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('businessType: $businessType, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('notes: $notes, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastContactAt: $lastContactAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    businessType,
    status,
    source,
    notes,
    archived,
    createdAt,
    updatedAt,
    lastContactAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lead &&
          other.id == this.id &&
          other.name == this.name &&
          other.businessType == this.businessType &&
          other.status == this.status &&
          other.source == this.source &&
          other.notes == this.notes &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastContactAt == this.lastContactAt);
}

class LeadsCompanion extends UpdateCompanion<Lead> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> businessType;
  final Value<String> status;
  final Value<String> source;
  final Value<String?> notes;
  final Value<bool> archived;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> lastContactAt;
  final Value<int> rowid;
  const LeadsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.businessType = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.notes = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastContactAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LeadsCompanion.insert({
    required String id,
    required String name,
    this.businessType = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.notes = const Value.absent(),
    this.archived = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.lastContactAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Lead> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? businessType,
    Expression<String>? status,
    Expression<String>? source,
    Expression<String>? notes,
    Expression<bool>? archived,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? lastContactAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (businessType != null) 'business_type': businessType,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (notes != null) 'notes': notes,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastContactAt != null) 'last_contact_at': lastContactAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LeadsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? businessType,
    Value<String>? status,
    Value<String>? source,
    Value<String?>? notes,
    Value<bool>? archived,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? lastContactAt,
    Value<int>? rowid,
  }) {
    return LeadsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      status: status ?? this.status,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastContactAt: lastContactAt ?? this.lastContactAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (businessType.present) {
      map['business_type'] = Variable<String>(businessType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastContactAt.present) {
      map['last_contact_at'] = Variable<int>(lastContactAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LeadsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('businessType: $businessType, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('notes: $notes, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastContactAt: $lastContactAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LeadPhonesTable extends LeadPhones
    with TableInfo<$LeadPhonesTable, LeadPhone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LeadPhonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _leadIdMeta = const VerificationMeta('leadId');
  @override
  late final GeneratedColumn<String> leadId = GeneratedColumn<String>(
    'lead_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES leads (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _e164Meta = const VerificationMeta('e164');
  @override
  late final GeneratedColumn<String> e164 = GeneratedColumn<String>(
    'e164',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, leadId, e164, label, isPrimary];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lead_phones';
  @override
  VerificationContext validateIntegrity(
    Insertable<LeadPhone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lead_id')) {
      context.handle(
        _leadIdMeta,
        leadId.isAcceptableOrUnknown(data['lead_id']!, _leadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_leadIdMeta);
    }
    if (data.containsKey('e164')) {
      context.handle(
        _e164Meta,
        e164.isAcceptableOrUnknown(data['e164']!, _e164Meta),
      );
    } else if (isInserting) {
      context.missing(_e164Meta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LeadPhone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LeadPhone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      leadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lead_id'],
      )!,
      e164: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}e164'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
    );
  }

  @override
  $LeadPhonesTable createAlias(String alias) {
    return $LeadPhonesTable(attachedDatabase, alias);
  }
}

class LeadPhone extends DataClass implements Insertable<LeadPhone> {
  final int id;
  final String leadId;
  final String e164;
  final String? label;
  final bool isPrimary;
  const LeadPhone({
    required this.id,
    required this.leadId,
    required this.e164,
    this.label,
    required this.isPrimary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lead_id'] = Variable<String>(leadId);
    map['e164'] = Variable<String>(e164);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    return map;
  }

  LeadPhonesCompanion toCompanion(bool nullToAbsent) {
    return LeadPhonesCompanion(
      id: Value(id),
      leadId: Value(leadId),
      e164: Value(e164),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      isPrimary: Value(isPrimary),
    );
  }

  factory LeadPhone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LeadPhone(
      id: serializer.fromJson<int>(json['id']),
      leadId: serializer.fromJson<String>(json['leadId']),
      e164: serializer.fromJson<String>(json['e164']),
      label: serializer.fromJson<String?>(json['label']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'leadId': serializer.toJson<String>(leadId),
      'e164': serializer.toJson<String>(e164),
      'label': serializer.toJson<String?>(label),
      'isPrimary': serializer.toJson<bool>(isPrimary),
    };
  }

  LeadPhone copyWith({
    int? id,
    String? leadId,
    String? e164,
    Value<String?> label = const Value.absent(),
    bool? isPrimary,
  }) => LeadPhone(
    id: id ?? this.id,
    leadId: leadId ?? this.leadId,
    e164: e164 ?? this.e164,
    label: label.present ? label.value : this.label,
    isPrimary: isPrimary ?? this.isPrimary,
  );
  LeadPhone copyWithCompanion(LeadPhonesCompanion data) {
    return LeadPhone(
      id: data.id.present ? data.id.value : this.id,
      leadId: data.leadId.present ? data.leadId.value : this.leadId,
      e164: data.e164.present ? data.e164.value : this.e164,
      label: data.label.present ? data.label.value : this.label,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LeadPhone(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('e164: $e164, ')
          ..write('label: $label, ')
          ..write('isPrimary: $isPrimary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, leadId, e164, label, isPrimary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LeadPhone &&
          other.id == this.id &&
          other.leadId == this.leadId &&
          other.e164 == this.e164 &&
          other.label == this.label &&
          other.isPrimary == this.isPrimary);
}

class LeadPhonesCompanion extends UpdateCompanion<LeadPhone> {
  final Value<int> id;
  final Value<String> leadId;
  final Value<String> e164;
  final Value<String?> label;
  final Value<bool> isPrimary;
  const LeadPhonesCompanion({
    this.id = const Value.absent(),
    this.leadId = const Value.absent(),
    this.e164 = const Value.absent(),
    this.label = const Value.absent(),
    this.isPrimary = const Value.absent(),
  });
  LeadPhonesCompanion.insert({
    this.id = const Value.absent(),
    required String leadId,
    required String e164,
    this.label = const Value.absent(),
    this.isPrimary = const Value.absent(),
  }) : leadId = Value(leadId),
       e164 = Value(e164);
  static Insertable<LeadPhone> custom({
    Expression<int>? id,
    Expression<String>? leadId,
    Expression<String>? e164,
    Expression<String>? label,
    Expression<bool>? isPrimary,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (leadId != null) 'lead_id': leadId,
      if (e164 != null) 'e164': e164,
      if (label != null) 'label': label,
      if (isPrimary != null) 'is_primary': isPrimary,
    });
  }

  LeadPhonesCompanion copyWith({
    Value<int>? id,
    Value<String>? leadId,
    Value<String>? e164,
    Value<String?>? label,
    Value<bool>? isPrimary,
  }) {
    return LeadPhonesCompanion(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      e164: e164 ?? this.e164,
      label: label ?? this.label,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (leadId.present) {
      map['lead_id'] = Variable<String>(leadId.value);
    }
    if (e164.present) {
      map['e164'] = Variable<String>(e164.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LeadPhonesCompanion(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('e164: $e164, ')
          ..write('label: $label, ')
          ..write('isPrimary: $isPrimary')
          ..write(')'))
        .toString();
  }
}

class $LeadSectionsTable extends LeadSections
    with TableInfo<$LeadSectionsTable, LeadSection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LeadSectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _leadIdMeta = const VerificationMeta('leadId');
  @override
  late final GeneratedColumn<String> leadId = GeneratedColumn<String>(
    'lead_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES leads (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, leadId, title, body, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lead_sections';
  @override
  VerificationContext validateIntegrity(
    Insertable<LeadSection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lead_id')) {
      context.handle(
        _leadIdMeta,
        leadId.isAcceptableOrUnknown(data['lead_id']!, _leadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_leadIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LeadSection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LeadSection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      leadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lead_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $LeadSectionsTable createAlias(String alias) {
    return $LeadSectionsTable(attachedDatabase, alias);
  }
}

class LeadSection extends DataClass implements Insertable<LeadSection> {
  final int id;
  final String leadId;
  final String title;
  final String body;
  final int position;
  const LeadSection({
    required this.id,
    required this.leadId,
    required this.title,
    required this.body,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lead_id'] = Variable<String>(leadId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['position'] = Variable<int>(position);
    return map;
  }

  LeadSectionsCompanion toCompanion(bool nullToAbsent) {
    return LeadSectionsCompanion(
      id: Value(id),
      leadId: Value(leadId),
      title: Value(title),
      body: Value(body),
      position: Value(position),
    );
  }

  factory LeadSection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LeadSection(
      id: serializer.fromJson<int>(json['id']),
      leadId: serializer.fromJson<String>(json['leadId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'leadId': serializer.toJson<String>(leadId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'position': serializer.toJson<int>(position),
    };
  }

  LeadSection copyWith({
    int? id,
    String? leadId,
    String? title,
    String? body,
    int? position,
  }) => LeadSection(
    id: id ?? this.id,
    leadId: leadId ?? this.leadId,
    title: title ?? this.title,
    body: body ?? this.body,
    position: position ?? this.position,
  );
  LeadSection copyWithCompanion(LeadSectionsCompanion data) {
    return LeadSection(
      id: data.id.present ? data.id.value : this.id,
      leadId: data.leadId.present ? data.leadId.value : this.leadId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LeadSection(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, leadId, title, body, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LeadSection &&
          other.id == this.id &&
          other.leadId == this.leadId &&
          other.title == this.title &&
          other.body == this.body &&
          other.position == this.position);
}

class LeadSectionsCompanion extends UpdateCompanion<LeadSection> {
  final Value<int> id;
  final Value<String> leadId;
  final Value<String> title;
  final Value<String> body;
  final Value<int> position;
  const LeadSectionsCompanion({
    this.id = const Value.absent(),
    this.leadId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.position = const Value.absent(),
  });
  LeadSectionsCompanion.insert({
    this.id = const Value.absent(),
    required String leadId,
    required String title,
    required String body,
    this.position = const Value.absent(),
  }) : leadId = Value(leadId),
       title = Value(title),
       body = Value(body);
  static Insertable<LeadSection> custom({
    Expression<int>? id,
    Expression<String>? leadId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (leadId != null) 'lead_id': leadId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (position != null) 'position': position,
    });
  }

  LeadSectionsCompanion copyWith({
    Value<int>? id,
    Value<String>? leadId,
    Value<String>? title,
    Value<String>? body,
    Value<int>? position,
  }) {
    return LeadSectionsCompanion(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      title: title ?? this.title,
      body: body ?? this.body,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (leadId.present) {
      map['lead_id'] = Variable<String>(leadId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LeadSectionsCompanion(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $LeadImagesTable extends LeadImages
    with TableInfo<$LeadImagesTable, LeadImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LeadImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _leadIdMeta = const VerificationMeta('leadId');
  @override
  late final GeneratedColumn<String> leadId = GeneratedColumn<String>(
    'lead_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES leads (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    leadId,
    filePath,
    position,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lead_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<LeadImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lead_id')) {
      context.handle(
        _leadIdMeta,
        leadId.isAcceptableOrUnknown(data['lead_id']!, _leadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_leadIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LeadImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LeadImage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      leadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lead_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LeadImagesTable createAlias(String alias) {
    return $LeadImagesTable(attachedDatabase, alias);
  }
}

class LeadImage extends DataClass implements Insertable<LeadImage> {
  final int id;
  final String leadId;
  final String filePath;
  final int position;
  final int createdAt;
  const LeadImage({
    required this.id,
    required this.leadId,
    required this.filePath,
    required this.position,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lead_id'] = Variable<String>(leadId);
    map['file_path'] = Variable<String>(filePath);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  LeadImagesCompanion toCompanion(bool nullToAbsent) {
    return LeadImagesCompanion(
      id: Value(id),
      leadId: Value(leadId),
      filePath: Value(filePath),
      position: Value(position),
      createdAt: Value(createdAt),
    );
  }

  factory LeadImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LeadImage(
      id: serializer.fromJson<int>(json['id']),
      leadId: serializer.fromJson<String>(json['leadId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'leadId': serializer.toJson<String>(leadId),
      'filePath': serializer.toJson<String>(filePath),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  LeadImage copyWith({
    int? id,
    String? leadId,
    String? filePath,
    int? position,
    int? createdAt,
  }) => LeadImage(
    id: id ?? this.id,
    leadId: leadId ?? this.leadId,
    filePath: filePath ?? this.filePath,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );
  LeadImage copyWithCompanion(LeadImagesCompanion data) {
    return LeadImage(
      id: data.id.present ? data.id.value : this.id,
      leadId: data.leadId.present ? data.leadId.value : this.leadId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LeadImage(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('filePath: $filePath, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, leadId, filePath, position, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LeadImage &&
          other.id == this.id &&
          other.leadId == this.leadId &&
          other.filePath == this.filePath &&
          other.position == this.position &&
          other.createdAt == this.createdAt);
}

class LeadImagesCompanion extends UpdateCompanion<LeadImage> {
  final Value<int> id;
  final Value<String> leadId;
  final Value<String> filePath;
  final Value<int> position;
  final Value<int> createdAt;
  const LeadImagesCompanion({
    this.id = const Value.absent(),
    this.leadId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LeadImagesCompanion.insert({
    this.id = const Value.absent(),
    required String leadId,
    required String filePath,
    this.position = const Value.absent(),
    required int createdAt,
  }) : leadId = Value(leadId),
       filePath = Value(filePath),
       createdAt = Value(createdAt);
  static Insertable<LeadImage> custom({
    Expression<int>? id,
    Expression<String>? leadId,
    Expression<String>? filePath,
    Expression<int>? position,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (leadId != null) 'lead_id': leadId,
      if (filePath != null) 'file_path': filePath,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LeadImagesCompanion copyWith({
    Value<int>? id,
    Value<String>? leadId,
    Value<String>? filePath,
    Value<int>? position,
    Value<int>? createdAt,
  }) {
    return LeadImagesCompanion(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      filePath: filePath ?? this.filePath,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (leadId.present) {
      map['lead_id'] = Variable<String>(leadId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LeadImagesCompanion(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('filePath: $filePath, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CallEventsTable extends CallEvents
    with TableInfo<$CallEventsTable, CallEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _leadIdMeta = const VerificationMeta('leadId');
  @override
  late final GeneratedColumn<String> leadId = GeneratedColumn<String>(
    'lead_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES leads (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _e164Meta = const VerificationMeta('e164');
  @override
  late final GeneratedColumn<String> e164 = GeneratedColumn<String>(
    'e164',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _callTypeMeta = const VerificationMeta(
    'callType',
  );
  @override
  late final GeneratedColumn<String> callType = GeneratedColumn<String>(
    'call_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    leadId,
    e164,
    callType,
    startedAt,
    durationSec,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'call_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CallEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lead_id')) {
      context.handle(
        _leadIdMeta,
        leadId.isAcceptableOrUnknown(data['lead_id']!, _leadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_leadIdMeta);
    }
    if (data.containsKey('e164')) {
      context.handle(
        _e164Meta,
        e164.isAcceptableOrUnknown(data['e164']!, _e164Meta),
      );
    } else if (isInserting) {
      context.missing(_e164Meta);
    }
    if (data.containsKey('call_type')) {
      context.handle(
        _callTypeMeta,
        callType.isAcceptableOrUnknown(data['call_type']!, _callTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_callTypeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CallEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      leadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lead_id'],
      )!,
      e164: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}e164'],
      )!,
      callType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}call_type'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CallEventsTable createAlias(String alias) {
    return $CallEventsTable(attachedDatabase, alias);
  }
}

class CallEvent extends DataClass implements Insertable<CallEvent> {
  final int id;
  final String leadId;
  final String e164;
  final String callType;
  final int startedAt;
  final int durationSec;
  final String? notes;
  final int createdAt;
  const CallEvent({
    required this.id,
    required this.leadId,
    required this.e164,
    required this.callType,
    required this.startedAt,
    required this.durationSec,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lead_id'] = Variable<String>(leadId);
    map['e164'] = Variable<String>(e164);
    map['call_type'] = Variable<String>(callType);
    map['started_at'] = Variable<int>(startedAt);
    map['duration_sec'] = Variable<int>(durationSec);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CallEventsCompanion toCompanion(bool nullToAbsent) {
    return CallEventsCompanion(
      id: Value(id),
      leadId: Value(leadId),
      e164: Value(e164),
      callType: Value(callType),
      startedAt: Value(startedAt),
      durationSec: Value(durationSec),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory CallEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallEvent(
      id: serializer.fromJson<int>(json['id']),
      leadId: serializer.fromJson<String>(json['leadId']),
      e164: serializer.fromJson<String>(json['e164']),
      callType: serializer.fromJson<String>(json['callType']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'leadId': serializer.toJson<String>(leadId),
      'e164': serializer.toJson<String>(e164),
      'callType': serializer.toJson<String>(callType),
      'startedAt': serializer.toJson<int>(startedAt),
      'durationSec': serializer.toJson<int>(durationSec),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CallEvent copyWith({
    int? id,
    String? leadId,
    String? e164,
    String? callType,
    int? startedAt,
    int? durationSec,
    Value<String?> notes = const Value.absent(),
    int? createdAt,
  }) => CallEvent(
    id: id ?? this.id,
    leadId: leadId ?? this.leadId,
    e164: e164 ?? this.e164,
    callType: callType ?? this.callType,
    startedAt: startedAt ?? this.startedAt,
    durationSec: durationSec ?? this.durationSec,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  CallEvent copyWithCompanion(CallEventsCompanion data) {
    return CallEvent(
      id: data.id.present ? data.id.value : this.id,
      leadId: data.leadId.present ? data.leadId.value : this.leadId,
      e164: data.e164.present ? data.e164.value : this.e164,
      callType: data.callType.present ? data.callType.value : this.callType,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallEvent(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('e164: $e164, ')
          ..write('callType: $callType, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    leadId,
    e164,
    callType,
    startedAt,
    durationSec,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallEvent &&
          other.id == this.id &&
          other.leadId == this.leadId &&
          other.e164 == this.e164 &&
          other.callType == this.callType &&
          other.startedAt == this.startedAt &&
          other.durationSec == this.durationSec &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class CallEventsCompanion extends UpdateCompanion<CallEvent> {
  final Value<int> id;
  final Value<String> leadId;
  final Value<String> e164;
  final Value<String> callType;
  final Value<int> startedAt;
  final Value<int> durationSec;
  final Value<String?> notes;
  final Value<int> createdAt;
  const CallEventsCompanion({
    this.id = const Value.absent(),
    this.leadId = const Value.absent(),
    this.e164 = const Value.absent(),
    this.callType = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CallEventsCompanion.insert({
    this.id = const Value.absent(),
    required String leadId,
    required String e164,
    required String callType,
    required int startedAt,
    this.durationSec = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
  }) : leadId = Value(leadId),
       e164 = Value(e164),
       callType = Value(callType),
       startedAt = Value(startedAt),
       createdAt = Value(createdAt);
  static Insertable<CallEvent> custom({
    Expression<int>? id,
    Expression<String>? leadId,
    Expression<String>? e164,
    Expression<String>? callType,
    Expression<int>? startedAt,
    Expression<int>? durationSec,
    Expression<String>? notes,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (leadId != null) 'lead_id': leadId,
      if (e164 != null) 'e164': e164,
      if (callType != null) 'call_type': callType,
      if (startedAt != null) 'started_at': startedAt,
      if (durationSec != null) 'duration_sec': durationSec,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CallEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? leadId,
    Value<String>? e164,
    Value<String>? callType,
    Value<int>? startedAt,
    Value<int>? durationSec,
    Value<String?>? notes,
    Value<int>? createdAt,
  }) {
    return CallEventsCompanion(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      e164: e164 ?? this.e164,
      callType: callType ?? this.callType,
      startedAt: startedAt ?? this.startedAt,
      durationSec: durationSec ?? this.durationSec,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (leadId.present) {
      map['lead_id'] = Variable<String>(leadId.value);
    }
    if (e164.present) {
      map['e164'] = Variable<String>(e164.value);
    }
    if (callType.present) {
      map['call_type'] = Variable<String>(callType.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallEventsCompanion(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('e164: $e164, ')
          ..write('callType: $callType, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _leadIdMeta = const VerificationMeta('leadId');
  @override
  late final GeneratedColumn<String> leadId = GeneratedColumn<String>(
    'lead_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES leads (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _alarmIdMeta = const VerificationMeta(
    'alarmId',
  );
  @override
  late final GeneratedColumn<String> alarmId = GeneratedColumn<String>(
    'alarm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    leadId,
    alarmId,
    dueAt,
    state,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lead_id')) {
      context.handle(
        _leadIdMeta,
        leadId.isAcceptableOrUnknown(data['lead_id']!, _leadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_leadIdMeta);
    }
    if (data.containsKey('alarm_id')) {
      context.handle(
        _alarmIdMeta,
        alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alarmIdMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      leadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lead_id'],
      )!,
      alarmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_id'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final String leadId;
  final String alarmId;
  final int dueAt;
  final String state;
  final String? notes;
  final int createdAt;
  const Reminder({
    required this.id,
    required this.leadId,
    required this.alarmId,
    required this.dueAt,
    required this.state,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lead_id'] = Variable<String>(leadId);
    map['alarm_id'] = Variable<String>(alarmId);
    map['due_at'] = Variable<int>(dueAt);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      leadId: Value(leadId),
      alarmId: Value(alarmId),
      dueAt: Value(dueAt),
      state: Value(state),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      leadId: serializer.fromJson<String>(json['leadId']),
      alarmId: serializer.fromJson<String>(json['alarmId']),
      dueAt: serializer.fromJson<int>(json['dueAt']),
      state: serializer.fromJson<String>(json['state']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'leadId': serializer.toJson<String>(leadId),
      'alarmId': serializer.toJson<String>(alarmId),
      'dueAt': serializer.toJson<int>(dueAt),
      'state': serializer.toJson<String>(state),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Reminder copyWith({
    int? id,
    String? leadId,
    String? alarmId,
    int? dueAt,
    String? state,
    Value<String?> notes = const Value.absent(),
    int? createdAt,
  }) => Reminder(
    id: id ?? this.id,
    leadId: leadId ?? this.leadId,
    alarmId: alarmId ?? this.alarmId,
    dueAt: dueAt ?? this.dueAt,
    state: state ?? this.state,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      leadId: data.leadId.present ? data.leadId.value : this.leadId,
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      state: data.state.present ? data.state.value : this.state,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('alarmId: $alarmId, ')
          ..write('dueAt: $dueAt, ')
          ..write('state: $state, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, leadId, alarmId, dueAt, state, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.leadId == this.leadId &&
          other.alarmId == this.alarmId &&
          other.dueAt == this.dueAt &&
          other.state == this.state &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<String> leadId;
  final Value<String> alarmId;
  final Value<int> dueAt;
  final Value<String> state;
  final Value<String?> notes;
  final Value<int> createdAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.leadId = const Value.absent(),
    this.alarmId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.state = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required String leadId,
    required String alarmId,
    required int dueAt,
    this.state = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
  }) : leadId = Value(leadId),
       alarmId = Value(alarmId),
       dueAt = Value(dueAt),
       createdAt = Value(createdAt);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<String>? leadId,
    Expression<String>? alarmId,
    Expression<int>? dueAt,
    Expression<String>? state,
    Expression<String>? notes,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (leadId != null) 'lead_id': leadId,
      if (alarmId != null) 'alarm_id': alarmId,
      if (dueAt != null) 'due_at': dueAt,
      if (state != null) 'state': state,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<String>? leadId,
    Value<String>? alarmId,
    Value<int>? dueAt,
    Value<String>? state,
    Value<String?>? notes,
    Value<int>? createdAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      alarmId: alarmId ?? this.alarmId,
      dueAt: dueAt ?? this.dueAt,
      state: state ?? this.state,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (leadId.present) {
      map['lead_id'] = Variable<String>(leadId.value);
    }
    if (alarmId.present) {
      map['alarm_id'] = Variable<String>(alarmId.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('leadId: $leadId, ')
          ..write('alarmId: $alarmId, ')
          ..write('dueAt: $dueAt, ')
          ..write('state: $state, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CallPlanSchedulesTable extends CallPlanSchedules
    with TableInfo<$CallPlanSchedulesTable, CallPlanSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallPlanSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alarmIdMeta = const VerificationMeta(
    'alarmId',
  );
  @override
  late final GeneratedColumn<String> alarmId = GeneratedColumn<String>(
    'alarm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerAtMeta = const VerificationMeta(
    'triggerAt',
  );
  @override
  late final GeneratedColumn<int> triggerAt = GeneratedColumn<int>(
    'trigger_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _filterBusinessTypeMeta =
      const VerificationMeta('filterBusinessType');
  @override
  late final GeneratedColumn<String> filterBusinessType =
      GeneratedColumn<String>(
        'filter_business_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    alarmId,
    triggerAt,
    state,
    filterBusinessType,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'call_plan_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<CallPlanSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('alarm_id')) {
      context.handle(
        _alarmIdMeta,
        alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_alarmIdMeta);
    }
    if (data.containsKey('trigger_at')) {
      context.handle(
        _triggerAtMeta,
        triggerAt.isAcceptableOrUnknown(data['trigger_at']!, _triggerAtMeta),
      );
    } else if (isInserting) {
      context.missing(_triggerAtMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('filter_business_type')) {
      context.handle(
        _filterBusinessTypeMeta,
        filterBusinessType.isAcceptableOrUnknown(
          data['filter_business_type']!,
          _filterBusinessTypeMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CallPlanSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallPlanSchedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      alarmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_id'],
      )!,
      triggerAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trigger_at'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      filterBusinessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_business_type'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CallPlanSchedulesTable createAlias(String alias) {
    return $CallPlanSchedulesTable(attachedDatabase, alias);
  }
}

class CallPlanSchedule extends DataClass
    implements Insertable<CallPlanSchedule> {
  final String id;
  final String alarmId;
  final int triggerAt;
  final String state;
  final String? filterBusinessType;
  final String? notes;
  final int createdAt;
  const CallPlanSchedule({
    required this.id,
    required this.alarmId,
    required this.triggerAt,
    required this.state,
    this.filterBusinessType,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['alarm_id'] = Variable<String>(alarmId);
    map['trigger_at'] = Variable<int>(triggerAt);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || filterBusinessType != null) {
      map['filter_business_type'] = Variable<String>(filterBusinessType);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CallPlanSchedulesCompanion toCompanion(bool nullToAbsent) {
    return CallPlanSchedulesCompanion(
      id: Value(id),
      alarmId: Value(alarmId),
      triggerAt: Value(triggerAt),
      state: Value(state),
      filterBusinessType: filterBusinessType == null && nullToAbsent
          ? const Value.absent()
          : Value(filterBusinessType),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory CallPlanSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallPlanSchedule(
      id: serializer.fromJson<String>(json['id']),
      alarmId: serializer.fromJson<String>(json['alarmId']),
      triggerAt: serializer.fromJson<int>(json['triggerAt']),
      state: serializer.fromJson<String>(json['state']),
      filterBusinessType: serializer.fromJson<String?>(
        json['filterBusinessType'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'alarmId': serializer.toJson<String>(alarmId),
      'triggerAt': serializer.toJson<int>(triggerAt),
      'state': serializer.toJson<String>(state),
      'filterBusinessType': serializer.toJson<String?>(filterBusinessType),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CallPlanSchedule copyWith({
    String? id,
    String? alarmId,
    int? triggerAt,
    String? state,
    Value<String?> filterBusinessType = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? createdAt,
  }) => CallPlanSchedule(
    id: id ?? this.id,
    alarmId: alarmId ?? this.alarmId,
    triggerAt: triggerAt ?? this.triggerAt,
    state: state ?? this.state,
    filterBusinessType: filterBusinessType.present
        ? filterBusinessType.value
        : this.filterBusinessType,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  CallPlanSchedule copyWithCompanion(CallPlanSchedulesCompanion data) {
    return CallPlanSchedule(
      id: data.id.present ? data.id.value : this.id,
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      triggerAt: data.triggerAt.present ? data.triggerAt.value : this.triggerAt,
      state: data.state.present ? data.state.value : this.state,
      filterBusinessType: data.filterBusinessType.present
          ? data.filterBusinessType.value
          : this.filterBusinessType,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallPlanSchedule(')
          ..write('id: $id, ')
          ..write('alarmId: $alarmId, ')
          ..write('triggerAt: $triggerAt, ')
          ..write('state: $state, ')
          ..write('filterBusinessType: $filterBusinessType, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    alarmId,
    triggerAt,
    state,
    filterBusinessType,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallPlanSchedule &&
          other.id == this.id &&
          other.alarmId == this.alarmId &&
          other.triggerAt == this.triggerAt &&
          other.state == this.state &&
          other.filterBusinessType == this.filterBusinessType &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class CallPlanSchedulesCompanion extends UpdateCompanion<CallPlanSchedule> {
  final Value<String> id;
  final Value<String> alarmId;
  final Value<int> triggerAt;
  final Value<String> state;
  final Value<String?> filterBusinessType;
  final Value<String?> notes;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CallPlanSchedulesCompanion({
    this.id = const Value.absent(),
    this.alarmId = const Value.absent(),
    this.triggerAt = const Value.absent(),
    this.state = const Value.absent(),
    this.filterBusinessType = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CallPlanSchedulesCompanion.insert({
    required String id,
    required String alarmId,
    required int triggerAt,
    this.state = const Value.absent(),
    this.filterBusinessType = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       alarmId = Value(alarmId),
       triggerAt = Value(triggerAt),
       createdAt = Value(createdAt);
  static Insertable<CallPlanSchedule> custom({
    Expression<String>? id,
    Expression<String>? alarmId,
    Expression<int>? triggerAt,
    Expression<String>? state,
    Expression<String>? filterBusinessType,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alarmId != null) 'alarm_id': alarmId,
      if (triggerAt != null) 'trigger_at': triggerAt,
      if (state != null) 'state': state,
      if (filterBusinessType != null)
        'filter_business_type': filterBusinessType,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CallPlanSchedulesCompanion copyWith({
    Value<String>? id,
    Value<String>? alarmId,
    Value<int>? triggerAt,
    Value<String>? state,
    Value<String?>? filterBusinessType,
    Value<String?>? notes,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CallPlanSchedulesCompanion(
      id: id ?? this.id,
      alarmId: alarmId ?? this.alarmId,
      triggerAt: triggerAt ?? this.triggerAt,
      state: state ?? this.state,
      filterBusinessType: filterBusinessType ?? this.filterBusinessType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (alarmId.present) {
      map['alarm_id'] = Variable<String>(alarmId.value);
    }
    if (triggerAt.present) {
      map['trigger_at'] = Variable<int>(triggerAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (filterBusinessType.present) {
      map['filter_business_type'] = Variable<String>(filterBusinessType.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallPlanSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('alarmId: $alarmId, ')
          ..write('triggerAt: $triggerAt, ')
          ..write('state: $state, ')
          ..write('filterBusinessType: $filterBusinessType, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CallPlanLeadsTable extends CallPlanLeads
    with TableInfo<$CallPlanLeadsTable, CallPlanLead> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallPlanLeadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES call_plan_schedules (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _leadIdMeta = const VerificationMeta('leadId');
  @override
  late final GeneratedColumn<String> leadId = GeneratedColumn<String>(
    'lead_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES leads (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scheduleId,
    leadId,
    position,
    done,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'call_plan_leads';
  @override
  VerificationContext validateIntegrity(
    Insertable<CallPlanLead> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('lead_id')) {
      context.handle(
        _leadIdMeta,
        leadId.isAcceptableOrUnknown(data['lead_id']!, _leadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_leadIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CallPlanLead map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallPlanLead(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      leadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lead_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
    );
  }

  @override
  $CallPlanLeadsTable createAlias(String alias) {
    return $CallPlanLeadsTable(attachedDatabase, alias);
  }
}

class CallPlanLead extends DataClass implements Insertable<CallPlanLead> {
  final int id;
  final String scheduleId;
  final String leadId;
  final int position;
  final bool done;
  const CallPlanLead({
    required this.id,
    required this.scheduleId,
    required this.leadId,
    required this.position,
    required this.done,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['schedule_id'] = Variable<String>(scheduleId);
    map['lead_id'] = Variable<String>(leadId);
    map['position'] = Variable<int>(position);
    map['done'] = Variable<bool>(done);
    return map;
  }

  CallPlanLeadsCompanion toCompanion(bool nullToAbsent) {
    return CallPlanLeadsCompanion(
      id: Value(id),
      scheduleId: Value(scheduleId),
      leadId: Value(leadId),
      position: Value(position),
      done: Value(done),
    );
  }

  factory CallPlanLead.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallPlanLead(
      id: serializer.fromJson<int>(json['id']),
      scheduleId: serializer.fromJson<String>(json['scheduleId']),
      leadId: serializer.fromJson<String>(json['leadId']),
      position: serializer.fromJson<int>(json['position']),
      done: serializer.fromJson<bool>(json['done']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scheduleId': serializer.toJson<String>(scheduleId),
      'leadId': serializer.toJson<String>(leadId),
      'position': serializer.toJson<int>(position),
      'done': serializer.toJson<bool>(done),
    };
  }

  CallPlanLead copyWith({
    int? id,
    String? scheduleId,
    String? leadId,
    int? position,
    bool? done,
  }) => CallPlanLead(
    id: id ?? this.id,
    scheduleId: scheduleId ?? this.scheduleId,
    leadId: leadId ?? this.leadId,
    position: position ?? this.position,
    done: done ?? this.done,
  );
  CallPlanLead copyWithCompanion(CallPlanLeadsCompanion data) {
    return CallPlanLead(
      id: data.id.present ? data.id.value : this.id,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      leadId: data.leadId.present ? data.leadId.value : this.leadId,
      position: data.position.present ? data.position.value : this.position,
      done: data.done.present ? data.done.value : this.done,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallPlanLead(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('leadId: $leadId, ')
          ..write('position: $position, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scheduleId, leadId, position, done);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallPlanLead &&
          other.id == this.id &&
          other.scheduleId == this.scheduleId &&
          other.leadId == this.leadId &&
          other.position == this.position &&
          other.done == this.done);
}

class CallPlanLeadsCompanion extends UpdateCompanion<CallPlanLead> {
  final Value<int> id;
  final Value<String> scheduleId;
  final Value<String> leadId;
  final Value<int> position;
  final Value<bool> done;
  const CallPlanLeadsCompanion({
    this.id = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.leadId = const Value.absent(),
    this.position = const Value.absent(),
    this.done = const Value.absent(),
  });
  CallPlanLeadsCompanion.insert({
    this.id = const Value.absent(),
    required String scheduleId,
    required String leadId,
    this.position = const Value.absent(),
    this.done = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       leadId = Value(leadId);
  static Insertable<CallPlanLead> custom({
    Expression<int>? id,
    Expression<String>? scheduleId,
    Expression<String>? leadId,
    Expression<int>? position,
    Expression<bool>? done,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (leadId != null) 'lead_id': leadId,
      if (position != null) 'position': position,
      if (done != null) 'done': done,
    });
  }

  CallPlanLeadsCompanion copyWith({
    Value<int>? id,
    Value<String>? scheduleId,
    Value<String>? leadId,
    Value<int>? position,
    Value<bool>? done,
  }) {
    return CallPlanLeadsCompanion(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      leadId: leadId ?? this.leadId,
      position: position ?? this.position,
      done: done ?? this.done,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (leadId.present) {
      map['lead_id'] = Variable<String>(leadId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallPlanLeadsCompanion(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('leadId: $leadId, ')
          ..write('position: $position, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }
}

class $DismissedNumbersTable extends DismissedNumbers
    with TableInfo<$DismissedNumbersTable, DismissedNumber> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DismissedNumbersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _e164Meta = const VerificationMeta('e164');
  @override
  late final GeneratedColumn<String> e164 = GeneratedColumn<String>(
    'e164',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dismissedAtMeta = const VerificationMeta(
    'dismissedAt',
  );
  @override
  late final GeneratedColumn<int> dismissedAt = GeneratedColumn<int>(
    'dismissed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [e164, dismissedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dismissed_numbers';
  @override
  VerificationContext validateIntegrity(
    Insertable<DismissedNumber> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('e164')) {
      context.handle(
        _e164Meta,
        e164.isAcceptableOrUnknown(data['e164']!, _e164Meta),
      );
    } else if (isInserting) {
      context.missing(_e164Meta);
    }
    if (data.containsKey('dismissed_at')) {
      context.handle(
        _dismissedAtMeta,
        dismissedAt.isAcceptableOrUnknown(
          data['dismissed_at']!,
          _dismissedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dismissedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {e164};
  @override
  DismissedNumber map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DismissedNumber(
      e164: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}e164'],
      )!,
      dismissedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dismissed_at'],
      )!,
    );
  }

  @override
  $DismissedNumbersTable createAlias(String alias) {
    return $DismissedNumbersTable(attachedDatabase, alias);
  }
}

class DismissedNumber extends DataClass implements Insertable<DismissedNumber> {
  final String e164;
  final int dismissedAt;
  const DismissedNumber({required this.e164, required this.dismissedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['e164'] = Variable<String>(e164);
    map['dismissed_at'] = Variable<int>(dismissedAt);
    return map;
  }

  DismissedNumbersCompanion toCompanion(bool nullToAbsent) {
    return DismissedNumbersCompanion(
      e164: Value(e164),
      dismissedAt: Value(dismissedAt),
    );
  }

  factory DismissedNumber.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DismissedNumber(
      e164: serializer.fromJson<String>(json['e164']),
      dismissedAt: serializer.fromJson<int>(json['dismissedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'e164': serializer.toJson<String>(e164),
      'dismissedAt': serializer.toJson<int>(dismissedAt),
    };
  }

  DismissedNumber copyWith({String? e164, int? dismissedAt}) => DismissedNumber(
    e164: e164 ?? this.e164,
    dismissedAt: dismissedAt ?? this.dismissedAt,
  );
  DismissedNumber copyWithCompanion(DismissedNumbersCompanion data) {
    return DismissedNumber(
      e164: data.e164.present ? data.e164.value : this.e164,
      dismissedAt: data.dismissedAt.present
          ? data.dismissedAt.value
          : this.dismissedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DismissedNumber(')
          ..write('e164: $e164, ')
          ..write('dismissedAt: $dismissedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(e164, dismissedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DismissedNumber &&
          other.e164 == this.e164 &&
          other.dismissedAt == this.dismissedAt);
}

class DismissedNumbersCompanion extends UpdateCompanion<DismissedNumber> {
  final Value<String> e164;
  final Value<int> dismissedAt;
  final Value<int> rowid;
  const DismissedNumbersCompanion({
    this.e164 = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DismissedNumbersCompanion.insert({
    required String e164,
    required int dismissedAt,
    this.rowid = const Value.absent(),
  }) : e164 = Value(e164),
       dismissedAt = Value(dismissedAt);
  static Insertable<DismissedNumber> custom({
    Expression<String>? e164,
    Expression<int>? dismissedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (e164 != null) 'e164': e164,
      if (dismissedAt != null) 'dismissed_at': dismissedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DismissedNumbersCompanion copyWith({
    Value<String>? e164,
    Value<int>? dismissedAt,
    Value<int>? rowid,
  }) {
    return DismissedNumbersCompanion(
      e164: e164 ?? this.e164,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (e164.present) {
      map['e164'] = Variable<String>(e164.value);
    }
    if (dismissedAt.present) {
      map['dismissed_at'] = Variable<int>(dismissedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DismissedNumbersCompanion(')
          ..write('e164: $e164, ')
          ..write('dismissedAt: $dismissedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CallRecordingsTable extends CallRecordings
    with TableInfo<$CallRecordingsTable, CallRecording> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallRecordingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _callEventIdMeta = const VerificationMeta(
    'callEventId',
  );
  @override
  late final GeneratedColumn<int> callEventId = GeneratedColumn<int>(
    'call_event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES call_events (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isManuallyAttachedMeta =
      const VerificationMeta('isManuallyAttached');
  @override
  late final GeneratedColumn<bool> isManuallyAttached = GeneratedColumn<bool>(
    'is_manually_attached',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manually_attached" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    callEventId,
    uri,
    displayName,
    durationMs,
    sizeBytes,
    isManuallyAttached,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'call_recordings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CallRecording> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('call_event_id')) {
      context.handle(
        _callEventIdMeta,
        callEventId.isAcceptableOrUnknown(
          data['call_event_id']!,
          _callEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_callEventIdMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('is_manually_attached')) {
      context.handle(
        _isManuallyAttachedMeta,
        isManuallyAttached.isAcceptableOrUnknown(
          data['is_manually_attached']!,
          _isManuallyAttachedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CallRecording map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallRecording(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      callEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}call_event_id'],
      )!,
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      isManuallyAttached: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_manually_attached'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CallRecordingsTable createAlias(String alias) {
    return $CallRecordingsTable(attachedDatabase, alias);
  }
}

class CallRecording extends DataClass implements Insertable<CallRecording> {
  final int id;
  final int callEventId;
  final String uri;
  final String displayName;
  final int durationMs;
  final int sizeBytes;
  final bool isManuallyAttached;
  final int createdAt;
  const CallRecording({
    required this.id,
    required this.callEventId,
    required this.uri,
    required this.displayName,
    required this.durationMs,
    required this.sizeBytes,
    required this.isManuallyAttached,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['call_event_id'] = Variable<int>(callEventId);
    map['uri'] = Variable<String>(uri);
    map['display_name'] = Variable<String>(displayName);
    map['duration_ms'] = Variable<int>(durationMs);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['is_manually_attached'] = Variable<bool>(isManuallyAttached);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CallRecordingsCompanion toCompanion(bool nullToAbsent) {
    return CallRecordingsCompanion(
      id: Value(id),
      callEventId: Value(callEventId),
      uri: Value(uri),
      displayName: Value(displayName),
      durationMs: Value(durationMs),
      sizeBytes: Value(sizeBytes),
      isManuallyAttached: Value(isManuallyAttached),
      createdAt: Value(createdAt),
    );
  }

  factory CallRecording.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallRecording(
      id: serializer.fromJson<int>(json['id']),
      callEventId: serializer.fromJson<int>(json['callEventId']),
      uri: serializer.fromJson<String>(json['uri']),
      displayName: serializer.fromJson<String>(json['displayName']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      isManuallyAttached: serializer.fromJson<bool>(json['isManuallyAttached']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'callEventId': serializer.toJson<int>(callEventId),
      'uri': serializer.toJson<String>(uri),
      'displayName': serializer.toJson<String>(displayName),
      'durationMs': serializer.toJson<int>(durationMs),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'isManuallyAttached': serializer.toJson<bool>(isManuallyAttached),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CallRecording copyWith({
    int? id,
    int? callEventId,
    String? uri,
    String? displayName,
    int? durationMs,
    int? sizeBytes,
    bool? isManuallyAttached,
    int? createdAt,
  }) => CallRecording(
    id: id ?? this.id,
    callEventId: callEventId ?? this.callEventId,
    uri: uri ?? this.uri,
    displayName: displayName ?? this.displayName,
    durationMs: durationMs ?? this.durationMs,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    isManuallyAttached: isManuallyAttached ?? this.isManuallyAttached,
    createdAt: createdAt ?? this.createdAt,
  );
  CallRecording copyWithCompanion(CallRecordingsCompanion data) {
    return CallRecording(
      id: data.id.present ? data.id.value : this.id,
      callEventId: data.callEventId.present
          ? data.callEventId.value
          : this.callEventId,
      uri: data.uri.present ? data.uri.value : this.uri,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      isManuallyAttached: data.isManuallyAttached.present
          ? data.isManuallyAttached.value
          : this.isManuallyAttached,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallRecording(')
          ..write('id: $id, ')
          ..write('callEventId: $callEventId, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isManuallyAttached: $isManuallyAttached, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    callEventId,
    uri,
    displayName,
    durationMs,
    sizeBytes,
    isManuallyAttached,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallRecording &&
          other.id == this.id &&
          other.callEventId == this.callEventId &&
          other.uri == this.uri &&
          other.displayName == this.displayName &&
          other.durationMs == this.durationMs &&
          other.sizeBytes == this.sizeBytes &&
          other.isManuallyAttached == this.isManuallyAttached &&
          other.createdAt == this.createdAt);
}

class CallRecordingsCompanion extends UpdateCompanion<CallRecording> {
  final Value<int> id;
  final Value<int> callEventId;
  final Value<String> uri;
  final Value<String> displayName;
  final Value<int> durationMs;
  final Value<int> sizeBytes;
  final Value<bool> isManuallyAttached;
  final Value<int> createdAt;
  const CallRecordingsCompanion({
    this.id = const Value.absent(),
    this.callEventId = const Value.absent(),
    this.uri = const Value.absent(),
    this.displayName = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.isManuallyAttached = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CallRecordingsCompanion.insert({
    this.id = const Value.absent(),
    required int callEventId,
    required String uri,
    required String displayName,
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.isManuallyAttached = const Value.absent(),
    required int createdAt,
  }) : callEventId = Value(callEventId),
       uri = Value(uri),
       displayName = Value(displayName),
       createdAt = Value(createdAt);
  static Insertable<CallRecording> custom({
    Expression<int>? id,
    Expression<int>? callEventId,
    Expression<String>? uri,
    Expression<String>? displayName,
    Expression<int>? durationMs,
    Expression<int>? sizeBytes,
    Expression<bool>? isManuallyAttached,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (callEventId != null) 'call_event_id': callEventId,
      if (uri != null) 'uri': uri,
      if (displayName != null) 'display_name': displayName,
      if (durationMs != null) 'duration_ms': durationMs,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (isManuallyAttached != null)
        'is_manually_attached': isManuallyAttached,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CallRecordingsCompanion copyWith({
    Value<int>? id,
    Value<int>? callEventId,
    Value<String>? uri,
    Value<String>? displayName,
    Value<int>? durationMs,
    Value<int>? sizeBytes,
    Value<bool>? isManuallyAttached,
    Value<int>? createdAt,
  }) {
    return CallRecordingsCompanion(
      id: id ?? this.id,
      callEventId: callEventId ?? this.callEventId,
      uri: uri ?? this.uri,
      displayName: displayName ?? this.displayName,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isManuallyAttached: isManuallyAttached ?? this.isManuallyAttached,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (callEventId.present) {
      map['call_event_id'] = Variable<int>(callEventId.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (isManuallyAttached.present) {
      map['is_manually_attached'] = Variable<bool>(isManuallyAttached.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallRecordingsCompanion(')
          ..write('id: $id, ')
          ..write('callEventId: $callEventId, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isManuallyAttached: $isManuallyAttached, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LeadsTable leads = $LeadsTable(this);
  late final $LeadPhonesTable leadPhones = $LeadPhonesTable(this);
  late final $LeadSectionsTable leadSections = $LeadSectionsTable(this);
  late final $LeadImagesTable leadImages = $LeadImagesTable(this);
  late final $CallEventsTable callEvents = $CallEventsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $CallPlanSchedulesTable callPlanSchedules =
      $CallPlanSchedulesTable(this);
  late final $CallPlanLeadsTable callPlanLeads = $CallPlanLeadsTable(this);
  late final $DismissedNumbersTable dismissedNumbers = $DismissedNumbersTable(
    this,
  );
  late final $CallRecordingsTable callRecordings = $CallRecordingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    leads,
    leadPhones,
    leadSections,
    leadImages,
    callEvents,
    reminders,
    callPlanSchedules,
    callPlanLeads,
    dismissedNumbers,
    callRecordings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'leads',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lead_phones', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'leads',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lead_sections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'leads',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lead_images', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'leads',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('call_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'leads',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reminders', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'call_plan_schedules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('call_plan_leads', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'leads',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('call_plan_leads', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'call_events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('call_recordings', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LeadsTableCreateCompanionBuilder =
    LeadsCompanion Function({
      required String id,
      required String name,
      Value<String?> businessType,
      Value<String> status,
      Value<String> source,
      Value<String?> notes,
      Value<bool> archived,
      required int createdAt,
      required int updatedAt,
      Value<int?> lastContactAt,
      Value<int> rowid,
    });
typedef $$LeadsTableUpdateCompanionBuilder =
    LeadsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> businessType,
      Value<String> status,
      Value<String> source,
      Value<String?> notes,
      Value<bool> archived,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> lastContactAt,
      Value<int> rowid,
    });

final class $$LeadsTableReferences
    extends BaseReferences<_$AppDatabase, $LeadsTable, Lead> {
  $$LeadsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LeadPhonesTable, List<LeadPhone>>
  _leadPhonesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.leadPhones,
    aliasName: $_aliasNameGenerator(db.leads.id, db.leadPhones.leadId),
  );

  $$LeadPhonesTableProcessedTableManager get leadPhonesRefs {
    final manager = $$LeadPhonesTableTableManager(
      $_db,
      $_db.leadPhones,
    ).filter((f) => f.leadId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_leadPhonesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LeadSectionsTable, List<LeadSection>>
  _leadSectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.leadSections,
    aliasName: $_aliasNameGenerator(db.leads.id, db.leadSections.leadId),
  );

  $$LeadSectionsTableProcessedTableManager get leadSectionsRefs {
    final manager = $$LeadSectionsTableTableManager(
      $_db,
      $_db.leadSections,
    ).filter((f) => f.leadId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_leadSectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LeadImagesTable, List<LeadImage>>
  _leadImagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.leadImages,
    aliasName: $_aliasNameGenerator(db.leads.id, db.leadImages.leadId),
  );

  $$LeadImagesTableProcessedTableManager get leadImagesRefs {
    final manager = $$LeadImagesTableTableManager(
      $_db,
      $_db.leadImages,
    ).filter((f) => f.leadId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_leadImagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CallEventsTable, List<CallEvent>>
  _callEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.callEvents,
    aliasName: $_aliasNameGenerator(db.leads.id, db.callEvents.leadId),
  );

  $$CallEventsTableProcessedTableManager get callEventsRefs {
    final manager = $$CallEventsTableTableManager(
      $_db,
      $_db.callEvents,
    ).filter((f) => f.leadId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_callEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: $_aliasNameGenerator(db.leads.id, db.reminders.leadId),
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.leadId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CallPlanLeadsTable, List<CallPlanLead>>
  _callPlanLeadsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.callPlanLeads,
    aliasName: $_aliasNameGenerator(db.leads.id, db.callPlanLeads.leadId),
  );

  $$CallPlanLeadsTableProcessedTableManager get callPlanLeadsRefs {
    final manager = $$CallPlanLeadsTableTableManager(
      $_db,
      $_db.callPlanLeads,
    ).filter((f) => f.leadId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_callPlanLeadsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LeadsTableFilterComposer extends Composer<_$AppDatabase, $LeadsTable> {
  $$LeadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastContactAt => $composableBuilder(
    column: $table.lastContactAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> leadPhonesRefs(
    Expression<bool> Function($$LeadPhonesTableFilterComposer f) f,
  ) {
    final $$LeadPhonesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.leadPhones,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadPhonesTableFilterComposer(
            $db: $db,
            $table: $db.leadPhones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> leadSectionsRefs(
    Expression<bool> Function($$LeadSectionsTableFilterComposer f) f,
  ) {
    final $$LeadSectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.leadSections,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadSectionsTableFilterComposer(
            $db: $db,
            $table: $db.leadSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> leadImagesRefs(
    Expression<bool> Function($$LeadImagesTableFilterComposer f) f,
  ) {
    final $$LeadImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.leadImages,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadImagesTableFilterComposer(
            $db: $db,
            $table: $db.leadImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> callEventsRefs(
    Expression<bool> Function($$CallEventsTableFilterComposer f) f,
  ) {
    final $$CallEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callEvents,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallEventsTableFilterComposer(
            $db: $db,
            $table: $db.callEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> callPlanLeadsRefs(
    Expression<bool> Function($$CallPlanLeadsTableFilterComposer f) f,
  ) {
    final $$CallPlanLeadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callPlanLeads,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallPlanLeadsTableFilterComposer(
            $db: $db,
            $table: $db.callPlanLeads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LeadsTableOrderingComposer
    extends Composer<_$AppDatabase, $LeadsTable> {
  $$LeadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastContactAt => $composableBuilder(
    column: $table.lastContactAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LeadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LeadsTable> {
  $$LeadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastContactAt => $composableBuilder(
    column: $table.lastContactAt,
    builder: (column) => column,
  );

  Expression<T> leadPhonesRefs<T extends Object>(
    Expression<T> Function($$LeadPhonesTableAnnotationComposer a) f,
  ) {
    final $$LeadPhonesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.leadPhones,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadPhonesTableAnnotationComposer(
            $db: $db,
            $table: $db.leadPhones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> leadSectionsRefs<T extends Object>(
    Expression<T> Function($$LeadSectionsTableAnnotationComposer a) f,
  ) {
    final $$LeadSectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.leadSections,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadSectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.leadSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> leadImagesRefs<T extends Object>(
    Expression<T> Function($$LeadImagesTableAnnotationComposer a) f,
  ) {
    final $$LeadImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.leadImages,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.leadImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> callEventsRefs<T extends Object>(
    Expression<T> Function($$CallEventsTableAnnotationComposer a) f,
  ) {
    final $$CallEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callEvents,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.callEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> callPlanLeadsRefs<T extends Object>(
    Expression<T> Function($$CallPlanLeadsTableAnnotationComposer a) f,
  ) {
    final $$CallPlanLeadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callPlanLeads,
      getReferencedColumn: (t) => t.leadId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallPlanLeadsTableAnnotationComposer(
            $db: $db,
            $table: $db.callPlanLeads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LeadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LeadsTable,
          Lead,
          $$LeadsTableFilterComposer,
          $$LeadsTableOrderingComposer,
          $$LeadsTableAnnotationComposer,
          $$LeadsTableCreateCompanionBuilder,
          $$LeadsTableUpdateCompanionBuilder,
          (Lead, $$LeadsTableReferences),
          Lead,
          PrefetchHooks Function({
            bool leadPhonesRefs,
            bool leadSectionsRefs,
            bool leadImagesRefs,
            bool callEventsRefs,
            bool remindersRefs,
            bool callPlanLeadsRefs,
          })
        > {
  $$LeadsTableTableManager(_$AppDatabase db, $LeadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LeadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LeadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LeadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> businessType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> lastContactAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LeadsCompanion(
                id: id,
                name: name,
                businessType: businessType,
                status: status,
                source: source,
                notes: notes,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastContactAt: lastContactAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> businessType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> lastContactAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LeadsCompanion.insert(
                id: id,
                name: name,
                businessType: businessType,
                status: status,
                source: source,
                notes: notes,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastContactAt: lastContactAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$LeadsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                leadPhonesRefs = false,
                leadSectionsRefs = false,
                leadImagesRefs = false,
                callEventsRefs = false,
                remindersRefs = false,
                callPlanLeadsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (leadPhonesRefs) db.leadPhones,
                    if (leadSectionsRefs) db.leadSections,
                    if (leadImagesRefs) db.leadImages,
                    if (callEventsRefs) db.callEvents,
                    if (remindersRefs) db.reminders,
                    if (callPlanLeadsRefs) db.callPlanLeads,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (leadPhonesRefs)
                        await $_getPrefetchedData<Lead, $LeadsTable, LeadPhone>(
                          currentTable: table,
                          referencedTable: $$LeadsTableReferences
                              ._leadPhonesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LeadsTableReferences(
                                db,
                                table,
                                p0,
                              ).leadPhonesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.leadId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (leadSectionsRefs)
                        await $_getPrefetchedData<
                          Lead,
                          $LeadsTable,
                          LeadSection
                        >(
                          currentTable: table,
                          referencedTable: $$LeadsTableReferences
                              ._leadSectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LeadsTableReferences(
                                db,
                                table,
                                p0,
                              ).leadSectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.leadId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (leadImagesRefs)
                        await $_getPrefetchedData<Lead, $LeadsTable, LeadImage>(
                          currentTable: table,
                          referencedTable: $$LeadsTableReferences
                              ._leadImagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LeadsTableReferences(
                                db,
                                table,
                                p0,
                              ).leadImagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.leadId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (callEventsRefs)
                        await $_getPrefetchedData<Lead, $LeadsTable, CallEvent>(
                          currentTable: table,
                          referencedTable: $$LeadsTableReferences
                              ._callEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LeadsTableReferences(
                                db,
                                table,
                                p0,
                              ).callEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.leadId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (remindersRefs)
                        await $_getPrefetchedData<Lead, $LeadsTable, Reminder>(
                          currentTable: table,
                          referencedTable: $$LeadsTableReferences
                              ._remindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LeadsTableReferences(
                                db,
                                table,
                                p0,
                              ).remindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.leadId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (callPlanLeadsRefs)
                        await $_getPrefetchedData<
                          Lead,
                          $LeadsTable,
                          CallPlanLead
                        >(
                          currentTable: table,
                          referencedTable: $$LeadsTableReferences
                              ._callPlanLeadsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LeadsTableReferences(
                                db,
                                table,
                                p0,
                              ).callPlanLeadsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.leadId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LeadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LeadsTable,
      Lead,
      $$LeadsTableFilterComposer,
      $$LeadsTableOrderingComposer,
      $$LeadsTableAnnotationComposer,
      $$LeadsTableCreateCompanionBuilder,
      $$LeadsTableUpdateCompanionBuilder,
      (Lead, $$LeadsTableReferences),
      Lead,
      PrefetchHooks Function({
        bool leadPhonesRefs,
        bool leadSectionsRefs,
        bool leadImagesRefs,
        bool callEventsRefs,
        bool remindersRefs,
        bool callPlanLeadsRefs,
      })
    >;
typedef $$LeadPhonesTableCreateCompanionBuilder =
    LeadPhonesCompanion Function({
      Value<int> id,
      required String leadId,
      required String e164,
      Value<String?> label,
      Value<bool> isPrimary,
    });
typedef $$LeadPhonesTableUpdateCompanionBuilder =
    LeadPhonesCompanion Function({
      Value<int> id,
      Value<String> leadId,
      Value<String> e164,
      Value<String?> label,
      Value<bool> isPrimary,
    });

final class $$LeadPhonesTableReferences
    extends BaseReferences<_$AppDatabase, $LeadPhonesTable, LeadPhone> {
  $$LeadPhonesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LeadsTable _leadIdTable(_$AppDatabase db) => db.leads.createAlias(
    $_aliasNameGenerator(db.leadPhones.leadId, db.leads.id),
  );

  $$LeadsTableProcessedTableManager get leadId {
    final $_column = $_itemColumn<String>('lead_id')!;

    final manager = $$LeadsTableTableManager(
      $_db,
      $_db.leads,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_leadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LeadPhonesTableFilterComposer
    extends Composer<_$AppDatabase, $LeadPhonesTable> {
  $$LeadPhonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get e164 => $composableBuilder(
    column: $table.e164,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  $$LeadsTableFilterComposer get leadId {
    final $$LeadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableFilterComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeadPhonesTableOrderingComposer
    extends Composer<_$AppDatabase, $LeadPhonesTable> {
  $$LeadPhonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get e164 => $composableBuilder(
    column: $table.e164,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  $$LeadsTableOrderingComposer get leadId {
    final $$LeadsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableOrderingComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeadPhonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LeadPhonesTable> {
  $$LeadPhonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get e164 =>
      $composableBuilder(column: $table.e164, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  $$LeadsTableAnnotationComposer get leadId {
    final $$LeadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableAnnotationComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeadPhonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LeadPhonesTable,
          LeadPhone,
          $$LeadPhonesTableFilterComposer,
          $$LeadPhonesTableOrderingComposer,
          $$LeadPhonesTableAnnotationComposer,
          $$LeadPhonesTableCreateCompanionBuilder,
          $$LeadPhonesTableUpdateCompanionBuilder,
          (LeadPhone, $$LeadPhonesTableReferences),
          LeadPhone,
          PrefetchHooks Function({bool leadId})
        > {
  $$LeadPhonesTableTableManager(_$AppDatabase db, $LeadPhonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LeadPhonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LeadPhonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LeadPhonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> leadId = const Value.absent(),
                Value<String> e164 = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
              }) => LeadPhonesCompanion(
                id: id,
                leadId: leadId,
                e164: e164,
                label: label,
                isPrimary: isPrimary,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String leadId,
                required String e164,
                Value<String?> label = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
              }) => LeadPhonesCompanion.insert(
                id: id,
                leadId: leadId,
                e164: e164,
                label: label,
                isPrimary: isPrimary,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LeadPhonesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({leadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (leadId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.leadId,
                                referencedTable: $$LeadPhonesTableReferences
                                    ._leadIdTable(db),
                                referencedColumn: $$LeadPhonesTableReferences
                                    ._leadIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LeadPhonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LeadPhonesTable,
      LeadPhone,
      $$LeadPhonesTableFilterComposer,
      $$LeadPhonesTableOrderingComposer,
      $$LeadPhonesTableAnnotationComposer,
      $$LeadPhonesTableCreateCompanionBuilder,
      $$LeadPhonesTableUpdateCompanionBuilder,
      (LeadPhone, $$LeadPhonesTableReferences),
      LeadPhone,
      PrefetchHooks Function({bool leadId})
    >;
typedef $$LeadSectionsTableCreateCompanionBuilder =
    LeadSectionsCompanion Function({
      Value<int> id,
      required String leadId,
      required String title,
      required String body,
      Value<int> position,
    });
typedef $$LeadSectionsTableUpdateCompanionBuilder =
    LeadSectionsCompanion Function({
      Value<int> id,
      Value<String> leadId,
      Value<String> title,
      Value<String> body,
      Value<int> position,
    });

final class $$LeadSectionsTableReferences
    extends BaseReferences<_$AppDatabase, $LeadSectionsTable, LeadSection> {
  $$LeadSectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LeadsTable _leadIdTable(_$AppDatabase db) => db.leads.createAlias(
    $_aliasNameGenerator(db.leadSections.leadId, db.leads.id),
  );

  $$LeadsTableProcessedTableManager get leadId {
    final $_column = $_itemColumn<String>('lead_id')!;

    final manager = $$LeadsTableTableManager(
      $_db,
      $_db.leads,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_leadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LeadSectionsTableFilterComposer
    extends Composer<_$AppDatabase, $LeadSectionsTable> {
  $$LeadSectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$LeadsTableFilterComposer get leadId {
    final $$LeadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableFilterComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeadSectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LeadSectionsTable> {
  $$LeadSectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$LeadsTableOrderingComposer get leadId {
    final $$LeadsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableOrderingComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeadSectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LeadSectionsTable> {
  $$LeadSectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$LeadsTableAnnotationComposer get leadId {
    final $$LeadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableAnnotationComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeadSectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LeadSectionsTable,
          LeadSection,
          $$LeadSectionsTableFilterComposer,
          $$LeadSectionsTableOrderingComposer,
          $$LeadSectionsTableAnnotationComposer,
          $$LeadSectionsTableCreateCompanionBuilder,
          $$LeadSectionsTableUpdateCompanionBuilder,
          (LeadSection, $$LeadSectionsTableReferences),
          LeadSection,
          PrefetchHooks Function({bool leadId})
        > {
  $$LeadSectionsTableTableManager(_$AppDatabase db, $LeadSectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LeadSectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LeadSectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LeadSectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> leadId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => LeadSectionsCompanion(
                id: id,
                leadId: leadId,
                title: title,
                body: body,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String leadId,
                required String title,
                required String body,
                Value<int> position = const Value.absent(),
              }) => LeadSectionsCompanion.insert(
                id: id,
                leadId: leadId,
                title: title,
                body: body,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LeadSectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({leadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (leadId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.leadId,
                                referencedTable: $$LeadSectionsTableReferences
                                    ._leadIdTable(db),
                                referencedColumn: $$LeadSectionsTableReferences
                                    ._leadIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LeadSectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LeadSectionsTable,
      LeadSection,
      $$LeadSectionsTableFilterComposer,
      $$LeadSectionsTableOrderingComposer,
      $$LeadSectionsTableAnnotationComposer,
      $$LeadSectionsTableCreateCompanionBuilder,
      $$LeadSectionsTableUpdateCompanionBuilder,
      (LeadSection, $$LeadSectionsTableReferences),
      LeadSection,
      PrefetchHooks Function({bool leadId})
    >;
typedef $$LeadImagesTableCreateCompanionBuilder =
    LeadImagesCompanion Function({
      Value<int> id,
      required String leadId,
      required String filePath,
      Value<int> position,
      required int createdAt,
    });
typedef $$LeadImagesTableUpdateCompanionBuilder =
    LeadImagesCompanion Function({
      Value<int> id,
      Value<String> leadId,
      Value<String> filePath,
      Value<int> position,
      Value<int> createdAt,
    });

final class $$LeadImagesTableReferences
    extends BaseReferences<_$AppDatabase, $LeadImagesTable, LeadImage> {
  $$LeadImagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LeadsTable _leadIdTable(_$AppDatabase db) => db.leads.createAlias(
    $_aliasNameGenerator(db.leadImages.leadId, db.leads.id),
  );

  $$LeadsTableProcessedTableManager get leadId {
    final $_column = $_itemColumn<String>('lead_id')!;

    final manager = $$LeadsTableTableManager(
      $_db,
      $_db.leads,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_leadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LeadImagesTableFilterComposer
    extends Composer<_$AppDatabase, $LeadImagesTable> {
  $$LeadImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LeadsTableFilterComposer get leadId {
    final $$LeadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableFilterComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeadImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $LeadImagesTable> {
  $$LeadImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LeadsTableOrderingComposer get leadId {
    final $$LeadsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableOrderingComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeadImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LeadImagesTable> {
  $$LeadImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LeadsTableAnnotationComposer get leadId {
    final $$LeadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableAnnotationComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeadImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LeadImagesTable,
          LeadImage,
          $$LeadImagesTableFilterComposer,
          $$LeadImagesTableOrderingComposer,
          $$LeadImagesTableAnnotationComposer,
          $$LeadImagesTableCreateCompanionBuilder,
          $$LeadImagesTableUpdateCompanionBuilder,
          (LeadImage, $$LeadImagesTableReferences),
          LeadImage,
          PrefetchHooks Function({bool leadId})
        > {
  $$LeadImagesTableTableManager(_$AppDatabase db, $LeadImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LeadImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LeadImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LeadImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> leadId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => LeadImagesCompanion(
                id: id,
                leadId: leadId,
                filePath: filePath,
                position: position,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String leadId,
                required String filePath,
                Value<int> position = const Value.absent(),
                required int createdAt,
              }) => LeadImagesCompanion.insert(
                id: id,
                leadId: leadId,
                filePath: filePath,
                position: position,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LeadImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({leadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (leadId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.leadId,
                                referencedTable: $$LeadImagesTableReferences
                                    ._leadIdTable(db),
                                referencedColumn: $$LeadImagesTableReferences
                                    ._leadIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LeadImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LeadImagesTable,
      LeadImage,
      $$LeadImagesTableFilterComposer,
      $$LeadImagesTableOrderingComposer,
      $$LeadImagesTableAnnotationComposer,
      $$LeadImagesTableCreateCompanionBuilder,
      $$LeadImagesTableUpdateCompanionBuilder,
      (LeadImage, $$LeadImagesTableReferences),
      LeadImage,
      PrefetchHooks Function({bool leadId})
    >;
typedef $$CallEventsTableCreateCompanionBuilder =
    CallEventsCompanion Function({
      Value<int> id,
      required String leadId,
      required String e164,
      required String callType,
      required int startedAt,
      Value<int> durationSec,
      Value<String?> notes,
      required int createdAt,
    });
typedef $$CallEventsTableUpdateCompanionBuilder =
    CallEventsCompanion Function({
      Value<int> id,
      Value<String> leadId,
      Value<String> e164,
      Value<String> callType,
      Value<int> startedAt,
      Value<int> durationSec,
      Value<String?> notes,
      Value<int> createdAt,
    });

final class $$CallEventsTableReferences
    extends BaseReferences<_$AppDatabase, $CallEventsTable, CallEvent> {
  $$CallEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LeadsTable _leadIdTable(_$AppDatabase db) => db.leads.createAlias(
    $_aliasNameGenerator(db.callEvents.leadId, db.leads.id),
  );

  $$LeadsTableProcessedTableManager get leadId {
    final $_column = $_itemColumn<String>('lead_id')!;

    final manager = $$LeadsTableTableManager(
      $_db,
      $_db.leads,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_leadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CallRecordingsTable, List<CallRecording>>
  _callRecordingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.callRecordings,
    aliasName: $_aliasNameGenerator(
      db.callEvents.id,
      db.callRecordings.callEventId,
    ),
  );

  $$CallRecordingsTableProcessedTableManager get callRecordingsRefs {
    final manager = $$CallRecordingsTableTableManager(
      $_db,
      $_db.callRecordings,
    ).filter((f) => f.callEventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_callRecordingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CallEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CallEventsTable> {
  $$CallEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get e164 => $composableBuilder(
    column: $table.e164,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get callType => $composableBuilder(
    column: $table.callType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LeadsTableFilterComposer get leadId {
    final $$LeadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableFilterComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> callRecordingsRefs(
    Expression<bool> Function($$CallRecordingsTableFilterComposer f) f,
  ) {
    final $$CallRecordingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callRecordings,
      getReferencedColumn: (t) => t.callEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallRecordingsTableFilterComposer(
            $db: $db,
            $table: $db.callRecordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CallEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CallEventsTable> {
  $$CallEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get e164 => $composableBuilder(
    column: $table.e164,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get callType => $composableBuilder(
    column: $table.callType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LeadsTableOrderingComposer get leadId {
    final $$LeadsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableOrderingComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallEventsTable> {
  $$CallEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get e164 =>
      $composableBuilder(column: $table.e164, builder: (column) => column);

  GeneratedColumn<String> get callType =>
      $composableBuilder(column: $table.callType, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LeadsTableAnnotationComposer get leadId {
    final $$LeadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableAnnotationComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> callRecordingsRefs<T extends Object>(
    Expression<T> Function($$CallRecordingsTableAnnotationComposer a) f,
  ) {
    final $$CallRecordingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callRecordings,
      getReferencedColumn: (t) => t.callEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallRecordingsTableAnnotationComposer(
            $db: $db,
            $table: $db.callRecordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CallEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CallEventsTable,
          CallEvent,
          $$CallEventsTableFilterComposer,
          $$CallEventsTableOrderingComposer,
          $$CallEventsTableAnnotationComposer,
          $$CallEventsTableCreateCompanionBuilder,
          $$CallEventsTableUpdateCompanionBuilder,
          (CallEvent, $$CallEventsTableReferences),
          CallEvent,
          PrefetchHooks Function({bool leadId, bool callRecordingsRefs})
        > {
  $$CallEventsTableTableManager(_$AppDatabase db, $CallEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> leadId = const Value.absent(),
                Value<String> e164 = const Value.absent(),
                Value<String> callType = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => CallEventsCompanion(
                id: id,
                leadId: leadId,
                e164: e164,
                callType: callType,
                startedAt: startedAt,
                durationSec: durationSec,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String leadId,
                required String e164,
                required String callType,
                required int startedAt,
                Value<int> durationSec = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int createdAt,
              }) => CallEventsCompanion.insert(
                id: id,
                leadId: leadId,
                e164: e164,
                callType: callType,
                startedAt: startedAt,
                durationSec: durationSec,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CallEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({leadId = false, callRecordingsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (callRecordingsRefs) db.callRecordings,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (leadId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.leadId,
                                    referencedTable: $$CallEventsTableReferences
                                        ._leadIdTable(db),
                                    referencedColumn:
                                        $$CallEventsTableReferences
                                            ._leadIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (callRecordingsRefs)
                        await $_getPrefetchedData<
                          CallEvent,
                          $CallEventsTable,
                          CallRecording
                        >(
                          currentTable: table,
                          referencedTable: $$CallEventsTableReferences
                              ._callRecordingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CallEventsTableReferences(
                                db,
                                table,
                                p0,
                              ).callRecordingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.callEventId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CallEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CallEventsTable,
      CallEvent,
      $$CallEventsTableFilterComposer,
      $$CallEventsTableOrderingComposer,
      $$CallEventsTableAnnotationComposer,
      $$CallEventsTableCreateCompanionBuilder,
      $$CallEventsTableUpdateCompanionBuilder,
      (CallEvent, $$CallEventsTableReferences),
      CallEvent,
      PrefetchHooks Function({bool leadId, bool callRecordingsRefs})
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      required String leadId,
      required String alarmId,
      required int dueAt,
      Value<String> state,
      Value<String?> notes,
      required int createdAt,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<String> leadId,
      Value<String> alarmId,
      Value<int> dueAt,
      Value<String> state,
      Value<String?> notes,
      Value<int> createdAt,
    });

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LeadsTable _leadIdTable(_$AppDatabase db) => db.leads.createAlias(
    $_aliasNameGenerator(db.reminders.leadId, db.leads.id),
  );

  $$LeadsTableProcessedTableManager get leadId {
    final $_column = $_itemColumn<String>('lead_id')!;

    final manager = $$LeadsTableTableManager(
      $_db,
      $_db.leads,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_leadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmId => $composableBuilder(
    column: $table.alarmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LeadsTableFilterComposer get leadId {
    final $$LeadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableFilterComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmId => $composableBuilder(
    column: $table.alarmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LeadsTableOrderingComposer get leadId {
    final $$LeadsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableOrderingComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alarmId =>
      $composableBuilder(column: $table.alarmId, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LeadsTableAnnotationComposer get leadId {
    final $$LeadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableAnnotationComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, $$RemindersTableReferences),
          Reminder,
          PrefetchHooks Function({bool leadId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> leadId = const Value.absent(),
                Value<String> alarmId = const Value.absent(),
                Value<int> dueAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                leadId: leadId,
                alarmId: alarmId,
                dueAt: dueAt,
                state: state,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String leadId,
                required String alarmId,
                required int dueAt,
                Value<String> state = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int createdAt,
              }) => RemindersCompanion.insert(
                id: id,
                leadId: leadId,
                alarmId: alarmId,
                dueAt: dueAt,
                state: state,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({leadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (leadId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.leadId,
                                referencedTable: $$RemindersTableReferences
                                    ._leadIdTable(db),
                                referencedColumn: $$RemindersTableReferences
                                    ._leadIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, $$RemindersTableReferences),
      Reminder,
      PrefetchHooks Function({bool leadId})
    >;
typedef $$CallPlanSchedulesTableCreateCompanionBuilder =
    CallPlanSchedulesCompanion Function({
      required String id,
      required String alarmId,
      required int triggerAt,
      Value<String> state,
      Value<String?> filterBusinessType,
      Value<String?> notes,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CallPlanSchedulesTableUpdateCompanionBuilder =
    CallPlanSchedulesCompanion Function({
      Value<String> id,
      Value<String> alarmId,
      Value<int> triggerAt,
      Value<String> state,
      Value<String?> filterBusinessType,
      Value<String?> notes,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$CallPlanSchedulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CallPlanSchedulesTable,
          CallPlanSchedule
        > {
  $$CallPlanSchedulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CallPlanLeadsTable, List<CallPlanLead>>
  _callPlanLeadsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.callPlanLeads,
    aliasName: $_aliasNameGenerator(
      db.callPlanSchedules.id,
      db.callPlanLeads.scheduleId,
    ),
  );

  $$CallPlanLeadsTableProcessedTableManager get callPlanLeadsRefs {
    final manager = $$CallPlanLeadsTableTableManager(
      $_db,
      $_db.callPlanLeads,
    ).filter((f) => f.scheduleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_callPlanLeadsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CallPlanSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $CallPlanSchedulesTable> {
  $$CallPlanSchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmId => $composableBuilder(
    column: $table.alarmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get triggerAt => $composableBuilder(
    column: $table.triggerAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterBusinessType => $composableBuilder(
    column: $table.filterBusinessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> callPlanLeadsRefs(
    Expression<bool> Function($$CallPlanLeadsTableFilterComposer f) f,
  ) {
    final $$CallPlanLeadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callPlanLeads,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallPlanLeadsTableFilterComposer(
            $db: $db,
            $table: $db.callPlanLeads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CallPlanSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $CallPlanSchedulesTable> {
  $$CallPlanSchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmId => $composableBuilder(
    column: $table.alarmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get triggerAt => $composableBuilder(
    column: $table.triggerAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterBusinessType => $composableBuilder(
    column: $table.filterBusinessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CallPlanSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallPlanSchedulesTable> {
  $$CallPlanSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alarmId =>
      $composableBuilder(column: $table.alarmId, builder: (column) => column);

  GeneratedColumn<int> get triggerAt =>
      $composableBuilder(column: $table.triggerAt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get filterBusinessType => $composableBuilder(
    column: $table.filterBusinessType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> callPlanLeadsRefs<T extends Object>(
    Expression<T> Function($$CallPlanLeadsTableAnnotationComposer a) f,
  ) {
    final $$CallPlanLeadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.callPlanLeads,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallPlanLeadsTableAnnotationComposer(
            $db: $db,
            $table: $db.callPlanLeads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CallPlanSchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CallPlanSchedulesTable,
          CallPlanSchedule,
          $$CallPlanSchedulesTableFilterComposer,
          $$CallPlanSchedulesTableOrderingComposer,
          $$CallPlanSchedulesTableAnnotationComposer,
          $$CallPlanSchedulesTableCreateCompanionBuilder,
          $$CallPlanSchedulesTableUpdateCompanionBuilder,
          (CallPlanSchedule, $$CallPlanSchedulesTableReferences),
          CallPlanSchedule,
          PrefetchHooks Function({bool callPlanLeadsRefs})
        > {
  $$CallPlanSchedulesTableTableManager(
    _$AppDatabase db,
    $CallPlanSchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallPlanSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallPlanSchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallPlanSchedulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> alarmId = const Value.absent(),
                Value<int> triggerAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> filterBusinessType = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CallPlanSchedulesCompanion(
                id: id,
                alarmId: alarmId,
                triggerAt: triggerAt,
                state: state,
                filterBusinessType: filterBusinessType,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String alarmId,
                required int triggerAt,
                Value<String> state = const Value.absent(),
                Value<String?> filterBusinessType = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CallPlanSchedulesCompanion.insert(
                id: id,
                alarmId: alarmId,
                triggerAt: triggerAt,
                state: state,
                filterBusinessType: filterBusinessType,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CallPlanSchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({callPlanLeadsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (callPlanLeadsRefs) db.callPlanLeads,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (callPlanLeadsRefs)
                    await $_getPrefetchedData<
                      CallPlanSchedule,
                      $CallPlanSchedulesTable,
                      CallPlanLead
                    >(
                      currentTable: table,
                      referencedTable: $$CallPlanSchedulesTableReferences
                          ._callPlanLeadsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CallPlanSchedulesTableReferences(
                            db,
                            table,
                            p0,
                          ).callPlanLeadsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.scheduleId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CallPlanSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CallPlanSchedulesTable,
      CallPlanSchedule,
      $$CallPlanSchedulesTableFilterComposer,
      $$CallPlanSchedulesTableOrderingComposer,
      $$CallPlanSchedulesTableAnnotationComposer,
      $$CallPlanSchedulesTableCreateCompanionBuilder,
      $$CallPlanSchedulesTableUpdateCompanionBuilder,
      (CallPlanSchedule, $$CallPlanSchedulesTableReferences),
      CallPlanSchedule,
      PrefetchHooks Function({bool callPlanLeadsRefs})
    >;
typedef $$CallPlanLeadsTableCreateCompanionBuilder =
    CallPlanLeadsCompanion Function({
      Value<int> id,
      required String scheduleId,
      required String leadId,
      Value<int> position,
      Value<bool> done,
    });
typedef $$CallPlanLeadsTableUpdateCompanionBuilder =
    CallPlanLeadsCompanion Function({
      Value<int> id,
      Value<String> scheduleId,
      Value<String> leadId,
      Value<int> position,
      Value<bool> done,
    });

final class $$CallPlanLeadsTableReferences
    extends BaseReferences<_$AppDatabase, $CallPlanLeadsTable, CallPlanLead> {
  $$CallPlanLeadsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CallPlanSchedulesTable _scheduleIdTable(_$AppDatabase db) =>
      db.callPlanSchedules.createAlias(
        $_aliasNameGenerator(
          db.callPlanLeads.scheduleId,
          db.callPlanSchedules.id,
        ),
      );

  $$CallPlanSchedulesTableProcessedTableManager get scheduleId {
    final $_column = $_itemColumn<String>('schedule_id')!;

    final manager = $$CallPlanSchedulesTableTableManager(
      $_db,
      $_db.callPlanSchedules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scheduleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LeadsTable _leadIdTable(_$AppDatabase db) => db.leads.createAlias(
    $_aliasNameGenerator(db.callPlanLeads.leadId, db.leads.id),
  );

  $$LeadsTableProcessedTableManager get leadId {
    final $_column = $_itemColumn<String>('lead_id')!;

    final manager = $$LeadsTableTableManager(
      $_db,
      $_db.leads,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_leadIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CallPlanLeadsTableFilterComposer
    extends Composer<_$AppDatabase, $CallPlanLeadsTable> {
  $$CallPlanLeadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  $$CallPlanSchedulesTableFilterComposer get scheduleId {
    final $$CallPlanSchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.callPlanSchedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallPlanSchedulesTableFilterComposer(
            $db: $db,
            $table: $db.callPlanSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LeadsTableFilterComposer get leadId {
    final $$LeadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableFilterComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallPlanLeadsTableOrderingComposer
    extends Composer<_$AppDatabase, $CallPlanLeadsTable> {
  $$CallPlanLeadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  $$CallPlanSchedulesTableOrderingComposer get scheduleId {
    final $$CallPlanSchedulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.callPlanSchedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallPlanSchedulesTableOrderingComposer(
            $db: $db,
            $table: $db.callPlanSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LeadsTableOrderingComposer get leadId {
    final $$LeadsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableOrderingComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallPlanLeadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallPlanLeadsTable> {
  $$CallPlanLeadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  $$CallPlanSchedulesTableAnnotationComposer get scheduleId {
    final $$CallPlanSchedulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.scheduleId,
          referencedTable: $db.callPlanSchedules,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CallPlanSchedulesTableAnnotationComposer(
                $db: $db,
                $table: $db.callPlanSchedules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$LeadsTableAnnotationComposer get leadId {
    final $$LeadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.leadId,
      referencedTable: $db.leads,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeadsTableAnnotationComposer(
            $db: $db,
            $table: $db.leads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallPlanLeadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CallPlanLeadsTable,
          CallPlanLead,
          $$CallPlanLeadsTableFilterComposer,
          $$CallPlanLeadsTableOrderingComposer,
          $$CallPlanLeadsTableAnnotationComposer,
          $$CallPlanLeadsTableCreateCompanionBuilder,
          $$CallPlanLeadsTableUpdateCompanionBuilder,
          (CallPlanLead, $$CallPlanLeadsTableReferences),
          CallPlanLead,
          PrefetchHooks Function({bool scheduleId, bool leadId})
        > {
  $$CallPlanLeadsTableTableManager(_$AppDatabase db, $CallPlanLeadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallPlanLeadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallPlanLeadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallPlanLeadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> scheduleId = const Value.absent(),
                Value<String> leadId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> done = const Value.absent(),
              }) => CallPlanLeadsCompanion(
                id: id,
                scheduleId: scheduleId,
                leadId: leadId,
                position: position,
                done: done,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String scheduleId,
                required String leadId,
                Value<int> position = const Value.absent(),
                Value<bool> done = const Value.absent(),
              }) => CallPlanLeadsCompanion.insert(
                id: id,
                scheduleId: scheduleId,
                leadId: leadId,
                position: position,
                done: done,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CallPlanLeadsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scheduleId = false, leadId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scheduleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scheduleId,
                                referencedTable: $$CallPlanLeadsTableReferences
                                    ._scheduleIdTable(db),
                                referencedColumn: $$CallPlanLeadsTableReferences
                                    ._scheduleIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (leadId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.leadId,
                                referencedTable: $$CallPlanLeadsTableReferences
                                    ._leadIdTable(db),
                                referencedColumn: $$CallPlanLeadsTableReferences
                                    ._leadIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CallPlanLeadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CallPlanLeadsTable,
      CallPlanLead,
      $$CallPlanLeadsTableFilterComposer,
      $$CallPlanLeadsTableOrderingComposer,
      $$CallPlanLeadsTableAnnotationComposer,
      $$CallPlanLeadsTableCreateCompanionBuilder,
      $$CallPlanLeadsTableUpdateCompanionBuilder,
      (CallPlanLead, $$CallPlanLeadsTableReferences),
      CallPlanLead,
      PrefetchHooks Function({bool scheduleId, bool leadId})
    >;
typedef $$DismissedNumbersTableCreateCompanionBuilder =
    DismissedNumbersCompanion Function({
      required String e164,
      required int dismissedAt,
      Value<int> rowid,
    });
typedef $$DismissedNumbersTableUpdateCompanionBuilder =
    DismissedNumbersCompanion Function({
      Value<String> e164,
      Value<int> dismissedAt,
      Value<int> rowid,
    });

class $$DismissedNumbersTableFilterComposer
    extends Composer<_$AppDatabase, $DismissedNumbersTable> {
  $$DismissedNumbersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get e164 => $composableBuilder(
    column: $table.e164,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DismissedNumbersTableOrderingComposer
    extends Composer<_$AppDatabase, $DismissedNumbersTable> {
  $$DismissedNumbersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get e164 => $composableBuilder(
    column: $table.e164,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DismissedNumbersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DismissedNumbersTable> {
  $$DismissedNumbersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get e164 =>
      $composableBuilder(column: $table.e164, builder: (column) => column);

  GeneratedColumn<int> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => column,
  );
}

class $$DismissedNumbersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DismissedNumbersTable,
          DismissedNumber,
          $$DismissedNumbersTableFilterComposer,
          $$DismissedNumbersTableOrderingComposer,
          $$DismissedNumbersTableAnnotationComposer,
          $$DismissedNumbersTableCreateCompanionBuilder,
          $$DismissedNumbersTableUpdateCompanionBuilder,
          (
            DismissedNumber,
            BaseReferences<
              _$AppDatabase,
              $DismissedNumbersTable,
              DismissedNumber
            >,
          ),
          DismissedNumber,
          PrefetchHooks Function()
        > {
  $$DismissedNumbersTableTableManager(
    _$AppDatabase db,
    $DismissedNumbersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DismissedNumbersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DismissedNumbersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DismissedNumbersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> e164 = const Value.absent(),
                Value<int> dismissedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DismissedNumbersCompanion(
                e164: e164,
                dismissedAt: dismissedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String e164,
                required int dismissedAt,
                Value<int> rowid = const Value.absent(),
              }) => DismissedNumbersCompanion.insert(
                e164: e164,
                dismissedAt: dismissedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DismissedNumbersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DismissedNumbersTable,
      DismissedNumber,
      $$DismissedNumbersTableFilterComposer,
      $$DismissedNumbersTableOrderingComposer,
      $$DismissedNumbersTableAnnotationComposer,
      $$DismissedNumbersTableCreateCompanionBuilder,
      $$DismissedNumbersTableUpdateCompanionBuilder,
      (
        DismissedNumber,
        BaseReferences<_$AppDatabase, $DismissedNumbersTable, DismissedNumber>,
      ),
      DismissedNumber,
      PrefetchHooks Function()
    >;
typedef $$CallRecordingsTableCreateCompanionBuilder =
    CallRecordingsCompanion Function({
      Value<int> id,
      required int callEventId,
      required String uri,
      required String displayName,
      Value<int> durationMs,
      Value<int> sizeBytes,
      Value<bool> isManuallyAttached,
      required int createdAt,
    });
typedef $$CallRecordingsTableUpdateCompanionBuilder =
    CallRecordingsCompanion Function({
      Value<int> id,
      Value<int> callEventId,
      Value<String> uri,
      Value<String> displayName,
      Value<int> durationMs,
      Value<int> sizeBytes,
      Value<bool> isManuallyAttached,
      Value<int> createdAt,
    });

final class $$CallRecordingsTableReferences
    extends BaseReferences<_$AppDatabase, $CallRecordingsTable, CallRecording> {
  $$CallRecordingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CallEventsTable _callEventIdTable(_$AppDatabase db) =>
      db.callEvents.createAlias(
        $_aliasNameGenerator(db.callRecordings.callEventId, db.callEvents.id),
      );

  $$CallEventsTableProcessedTableManager get callEventId {
    final $_column = $_itemColumn<int>('call_event_id')!;

    final manager = $$CallEventsTableTableManager(
      $_db,
      $_db.callEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_callEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CallRecordingsTableFilterComposer
    extends Composer<_$AppDatabase, $CallRecordingsTable> {
  $$CallRecordingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManuallyAttached => $composableBuilder(
    column: $table.isManuallyAttached,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CallEventsTableFilterComposer get callEventId {
    final $$CallEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callEventId,
      referencedTable: $db.callEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallEventsTableFilterComposer(
            $db: $db,
            $table: $db.callEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallRecordingsTableOrderingComposer
    extends Composer<_$AppDatabase, $CallRecordingsTable> {
  $$CallRecordingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManuallyAttached => $composableBuilder(
    column: $table.isManuallyAttached,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CallEventsTableOrderingComposer get callEventId {
    final $$CallEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callEventId,
      referencedTable: $db.callEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallEventsTableOrderingComposer(
            $db: $db,
            $table: $db.callEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallRecordingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallRecordingsTable> {
  $$CallRecordingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<bool> get isManuallyAttached => $composableBuilder(
    column: $table.isManuallyAttached,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CallEventsTableAnnotationComposer get callEventId {
    final $$CallEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.callEventId,
      referencedTable: $db.callEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CallEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.callEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CallRecordingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CallRecordingsTable,
          CallRecording,
          $$CallRecordingsTableFilterComposer,
          $$CallRecordingsTableOrderingComposer,
          $$CallRecordingsTableAnnotationComposer,
          $$CallRecordingsTableCreateCompanionBuilder,
          $$CallRecordingsTableUpdateCompanionBuilder,
          (CallRecording, $$CallRecordingsTableReferences),
          CallRecording,
          PrefetchHooks Function({bool callEventId})
        > {
  $$CallRecordingsTableTableManager(
    _$AppDatabase db,
    $CallRecordingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallRecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallRecordingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallRecordingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> callEventId = const Value.absent(),
                Value<String> uri = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<bool> isManuallyAttached = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => CallRecordingsCompanion(
                id: id,
                callEventId: callEventId,
                uri: uri,
                displayName: displayName,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                isManuallyAttached: isManuallyAttached,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int callEventId,
                required String uri,
                required String displayName,
                Value<int> durationMs = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<bool> isManuallyAttached = const Value.absent(),
                required int createdAt,
              }) => CallRecordingsCompanion.insert(
                id: id,
                callEventId: callEventId,
                uri: uri,
                displayName: displayName,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                isManuallyAttached: isManuallyAttached,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CallRecordingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({callEventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (callEventId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.callEventId,
                                referencedTable: $$CallRecordingsTableReferences
                                    ._callEventIdTable(db),
                                referencedColumn:
                                    $$CallRecordingsTableReferences
                                        ._callEventIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CallRecordingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CallRecordingsTable,
      CallRecording,
      $$CallRecordingsTableFilterComposer,
      $$CallRecordingsTableOrderingComposer,
      $$CallRecordingsTableAnnotationComposer,
      $$CallRecordingsTableCreateCompanionBuilder,
      $$CallRecordingsTableUpdateCompanionBuilder,
      (CallRecording, $$CallRecordingsTableReferences),
      CallRecording,
      PrefetchHooks Function({bool callEventId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LeadsTableTableManager get leads =>
      $$LeadsTableTableManager(_db, _db.leads);
  $$LeadPhonesTableTableManager get leadPhones =>
      $$LeadPhonesTableTableManager(_db, _db.leadPhones);
  $$LeadSectionsTableTableManager get leadSections =>
      $$LeadSectionsTableTableManager(_db, _db.leadSections);
  $$LeadImagesTableTableManager get leadImages =>
      $$LeadImagesTableTableManager(_db, _db.leadImages);
  $$CallEventsTableTableManager get callEvents =>
      $$CallEventsTableTableManager(_db, _db.callEvents);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$CallPlanSchedulesTableTableManager get callPlanSchedules =>
      $$CallPlanSchedulesTableTableManager(_db, _db.callPlanSchedules);
  $$CallPlanLeadsTableTableManager get callPlanLeads =>
      $$CallPlanLeadsTableTableManager(_db, _db.callPlanLeads);
  $$DismissedNumbersTableTableManager get dismissedNumbers =>
      $$DismissedNumbersTableTableManager(_db, _db.dismissedNumbers);
  $$CallRecordingsTableTableManager get callRecordings =>
      $$CallRecordingsTableTableManager(_db, _db.callRecordings);
}

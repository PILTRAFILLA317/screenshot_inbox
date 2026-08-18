// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ScreenshotsTable extends Screenshots
    with TableInfo<$ScreenshotsTable, ScreenshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScreenshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processingStatusMeta = const VerificationMeta(
    'processingStatus',
  );
  @override
  late final GeneratedColumn<String> processingStatus = GeneratedColumn<String>(
    'processing_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primaryTypeMeta = const VerificationMeta(
    'primaryType',
  );
  @override
  late final GeneratedColumn<String> primaryType = GeneratedColumn<String>(
    'primary_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _primarySubtypeMeta = const VerificationMeta(
    'primarySubtype',
  );
  @override
  late final GeneratedColumn<String> primarySubtype = GeneratedColumn<String>(
    'primary_subtype',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _classificationConfidenceMeta =
      const VerificationMeta('classificationConfidence');
  @override
  late final GeneratedColumn<double> classificationConfidence =
      GeneratedColumn<double>(
        'classification_confidence',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _currentLifecycleStateMeta =
      const VerificationMeta('currentLifecycleState');
  @override
  late final GeneratedColumn<String> currentLifecycleState =
      GeneratedColumn<String>(
        'current_lifecycle_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastProcessedAtMeta = const VerificationMeta(
    'lastProcessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastProcessedAt =
      GeneratedColumn<DateTime>(
        'last_processed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _processingVersionMeta = const VerificationMeta(
    'processingVersion',
  );
  @override
  late final GeneratedColumn<int> processingVersion = GeneratedColumn<int>(
    'processing_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    createdAt,
    indexedAt,
    width,
    height,
    sizeBytes,
    processingStatus,
    ocrText,
    primaryType,
    primarySubtype,
    classificationConfidence,
    currentLifecycleState,
    lastProcessedAt,
    processingVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'screenshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScreenshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_indexedAtMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('processing_status')) {
      context.handle(
        _processingStatusMeta,
        processingStatus.isAcceptableOrUnknown(
          data['processing_status']!,
          _processingStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processingStatusMeta);
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    }
    if (data.containsKey('primary_type')) {
      context.handle(
        _primaryTypeMeta,
        primaryType.isAcceptableOrUnknown(
          data['primary_type']!,
          _primaryTypeMeta,
        ),
      );
    }
    if (data.containsKey('primary_subtype')) {
      context.handle(
        _primarySubtypeMeta,
        primarySubtype.isAcceptableOrUnknown(
          data['primary_subtype']!,
          _primarySubtypeMeta,
        ),
      );
    }
    if (data.containsKey('classification_confidence')) {
      context.handle(
        _classificationConfidenceMeta,
        classificationConfidence.isAcceptableOrUnknown(
          data['classification_confidence']!,
          _classificationConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('current_lifecycle_state')) {
      context.handle(
        _currentLifecycleStateMeta,
        currentLifecycleState.isAcceptableOrUnknown(
          data['current_lifecycle_state']!,
          _currentLifecycleStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentLifecycleStateMeta);
    }
    if (data.containsKey('last_processed_at')) {
      context.handle(
        _lastProcessedAtMeta,
        lastProcessedAt.isAcceptableOrUnknown(
          data['last_processed_at']!,
          _lastProcessedAtMeta,
        ),
      );
    }
    if (data.containsKey('processing_version')) {
      context.handle(
        _processingVersionMeta,
        processingVersion.isAcceptableOrUnknown(
          data['processing_version']!,
          _processingVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScreenshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScreenshotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      processingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processing_status'],
      )!,
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      ),
      primaryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_type'],
      ),
      primarySubtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_subtype'],
      ),
      classificationConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}classification_confidence'],
      ),
      currentLifecycleState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_lifecycle_state'],
      )!,
      lastProcessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_processed_at'],
      ),
      processingVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processing_version'],
      )!,
    );
  }

  @override
  $ScreenshotsTable createAlias(String alias) {
    return $ScreenshotsTable(attachedDatabase, alias);
  }
}

class ScreenshotRow extends DataClass implements Insertable<ScreenshotRow> {
  final String id;
  final String assetId;
  final DateTime createdAt;
  final DateTime indexedAt;
  final int width;
  final int height;
  final int? sizeBytes;
  final String processingStatus;
  final String? ocrText;
  final String? primaryType;
  final String? primarySubtype;
  final double? classificationConfidence;
  final String currentLifecycleState;
  final DateTime? lastProcessedAt;
  final int processingVersion;
  const ScreenshotRow({
    required this.id,
    required this.assetId,
    required this.createdAt,
    required this.indexedAt,
    required this.width,
    required this.height,
    this.sizeBytes,
    required this.processingStatus,
    this.ocrText,
    this.primaryType,
    this.primarySubtype,
    this.classificationConfidence,
    required this.currentLifecycleState,
    this.lastProcessedAt,
    required this.processingVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['asset_id'] = Variable<String>(assetId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['processing_status'] = Variable<String>(processingStatus);
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    if (!nullToAbsent || primaryType != null) {
      map['primary_type'] = Variable<String>(primaryType);
    }
    if (!nullToAbsent || primarySubtype != null) {
      map['primary_subtype'] = Variable<String>(primarySubtype);
    }
    if (!nullToAbsent || classificationConfidence != null) {
      map['classification_confidence'] = Variable<double>(
        classificationConfidence,
      );
    }
    map['current_lifecycle_state'] = Variable<String>(currentLifecycleState);
    if (!nullToAbsent || lastProcessedAt != null) {
      map['last_processed_at'] = Variable<DateTime>(lastProcessedAt);
    }
    map['processing_version'] = Variable<int>(processingVersion);
    return map;
  }

  ScreenshotsCompanion toCompanion(bool nullToAbsent) {
    return ScreenshotsCompanion(
      id: Value(id),
      assetId: Value(assetId),
      createdAt: Value(createdAt),
      indexedAt: Value(indexedAt),
      width: Value(width),
      height: Value(height),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      processingStatus: Value(processingStatus),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      primaryType: primaryType == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryType),
      primarySubtype: primarySubtype == null && nullToAbsent
          ? const Value.absent()
          : Value(primarySubtype),
      classificationConfidence: classificationConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(classificationConfidence),
      currentLifecycleState: Value(currentLifecycleState),
      lastProcessedAt: lastProcessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastProcessedAt),
      processingVersion: Value(processingVersion),
    );
  }

  factory ScreenshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScreenshotRow(
      id: serializer.fromJson<String>(json['id']),
      assetId: serializer.fromJson<String>(json['assetId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      processingStatus: serializer.fromJson<String>(json['processingStatus']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      primaryType: serializer.fromJson<String?>(json['primaryType']),
      primarySubtype: serializer.fromJson<String?>(json['primarySubtype']),
      classificationConfidence: serializer.fromJson<double?>(
        json['classificationConfidence'],
      ),
      currentLifecycleState: serializer.fromJson<String>(
        json['currentLifecycleState'],
      ),
      lastProcessedAt: serializer.fromJson<DateTime?>(json['lastProcessedAt']),
      processingVersion: serializer.fromJson<int>(json['processingVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'assetId': serializer.toJson<String>(assetId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'processingStatus': serializer.toJson<String>(processingStatus),
      'ocrText': serializer.toJson<String?>(ocrText),
      'primaryType': serializer.toJson<String?>(primaryType),
      'primarySubtype': serializer.toJson<String?>(primarySubtype),
      'classificationConfidence': serializer.toJson<double?>(
        classificationConfidence,
      ),
      'currentLifecycleState': serializer.toJson<String>(currentLifecycleState),
      'lastProcessedAt': serializer.toJson<DateTime?>(lastProcessedAt),
      'processingVersion': serializer.toJson<int>(processingVersion),
    };
  }

  ScreenshotRow copyWith({
    String? id,
    String? assetId,
    DateTime? createdAt,
    DateTime? indexedAt,
    int? width,
    int? height,
    Value<int?> sizeBytes = const Value.absent(),
    String? processingStatus,
    Value<String?> ocrText = const Value.absent(),
    Value<String?> primaryType = const Value.absent(),
    Value<String?> primarySubtype = const Value.absent(),
    Value<double?> classificationConfidence = const Value.absent(),
    String? currentLifecycleState,
    Value<DateTime?> lastProcessedAt = const Value.absent(),
    int? processingVersion,
  }) => ScreenshotRow(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    createdAt: createdAt ?? this.createdAt,
    indexedAt: indexedAt ?? this.indexedAt,
    width: width ?? this.width,
    height: height ?? this.height,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    processingStatus: processingStatus ?? this.processingStatus,
    ocrText: ocrText.present ? ocrText.value : this.ocrText,
    primaryType: primaryType.present ? primaryType.value : this.primaryType,
    primarySubtype: primarySubtype.present
        ? primarySubtype.value
        : this.primarySubtype,
    classificationConfidence: classificationConfidence.present
        ? classificationConfidence.value
        : this.classificationConfidence,
    currentLifecycleState: currentLifecycleState ?? this.currentLifecycleState,
    lastProcessedAt: lastProcessedAt.present
        ? lastProcessedAt.value
        : this.lastProcessedAt,
    processingVersion: processingVersion ?? this.processingVersion,
  );
  ScreenshotRow copyWithCompanion(ScreenshotsCompanion data) {
    return ScreenshotRow(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      processingStatus: data.processingStatus.present
          ? data.processingStatus.value
          : this.processingStatus,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      primaryType: data.primaryType.present
          ? data.primaryType.value
          : this.primaryType,
      primarySubtype: data.primarySubtype.present
          ? data.primarySubtype.value
          : this.primarySubtype,
      classificationConfidence: data.classificationConfidence.present
          ? data.classificationConfidence.value
          : this.classificationConfidence,
      currentLifecycleState: data.currentLifecycleState.present
          ? data.currentLifecycleState.value
          : this.currentLifecycleState,
      lastProcessedAt: data.lastProcessedAt.present
          ? data.lastProcessedAt.value
          : this.lastProcessedAt,
      processingVersion: data.processingVersion.present
          ? data.processingVersion.value
          : this.processingVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScreenshotRow(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('ocrText: $ocrText, ')
          ..write('primaryType: $primaryType, ')
          ..write('primarySubtype: $primarySubtype, ')
          ..write('classificationConfidence: $classificationConfidence, ')
          ..write('currentLifecycleState: $currentLifecycleState, ')
          ..write('lastProcessedAt: $lastProcessedAt, ')
          ..write('processingVersion: $processingVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    createdAt,
    indexedAt,
    width,
    height,
    sizeBytes,
    processingStatus,
    ocrText,
    primaryType,
    primarySubtype,
    classificationConfidence,
    currentLifecycleState,
    lastProcessedAt,
    processingVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScreenshotRow &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.createdAt == this.createdAt &&
          other.indexedAt == this.indexedAt &&
          other.width == this.width &&
          other.height == this.height &&
          other.sizeBytes == this.sizeBytes &&
          other.processingStatus == this.processingStatus &&
          other.ocrText == this.ocrText &&
          other.primaryType == this.primaryType &&
          other.primarySubtype == this.primarySubtype &&
          other.classificationConfidence == this.classificationConfidence &&
          other.currentLifecycleState == this.currentLifecycleState &&
          other.lastProcessedAt == this.lastProcessedAt &&
          other.processingVersion == this.processingVersion);
}

class ScreenshotsCompanion extends UpdateCompanion<ScreenshotRow> {
  final Value<String> id;
  final Value<String> assetId;
  final Value<DateTime> createdAt;
  final Value<DateTime> indexedAt;
  final Value<int> width;
  final Value<int> height;
  final Value<int?> sizeBytes;
  final Value<String> processingStatus;
  final Value<String?> ocrText;
  final Value<String?> primaryType;
  final Value<String?> primarySubtype;
  final Value<double?> classificationConfidence;
  final Value<String> currentLifecycleState;
  final Value<DateTime?> lastProcessedAt;
  final Value<int> processingVersion;
  final Value<int> rowid;
  const ScreenshotsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.processingStatus = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.primaryType = const Value.absent(),
    this.primarySubtype = const Value.absent(),
    this.classificationConfidence = const Value.absent(),
    this.currentLifecycleState = const Value.absent(),
    this.lastProcessedAt = const Value.absent(),
    this.processingVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScreenshotsCompanion.insert({
    required String id,
    required String assetId,
    required DateTime createdAt,
    required DateTime indexedAt,
    required int width,
    required int height,
    this.sizeBytes = const Value.absent(),
    required String processingStatus,
    this.ocrText = const Value.absent(),
    this.primaryType = const Value.absent(),
    this.primarySubtype = const Value.absent(),
    this.classificationConfidence = const Value.absent(),
    required String currentLifecycleState,
    this.lastProcessedAt = const Value.absent(),
    this.processingVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       assetId = Value(assetId),
       createdAt = Value(createdAt),
       indexedAt = Value(indexedAt),
       width = Value(width),
       height = Value(height),
       processingStatus = Value(processingStatus),
       currentLifecycleState = Value(currentLifecycleState);
  static Insertable<ScreenshotRow> custom({
    Expression<String>? id,
    Expression<String>? assetId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? indexedAt,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? sizeBytes,
    Expression<String>? processingStatus,
    Expression<String>? ocrText,
    Expression<String>? primaryType,
    Expression<String>? primarySubtype,
    Expression<double>? classificationConfidence,
    Expression<String>? currentLifecycleState,
    Expression<DateTime>? lastProcessedAt,
    Expression<int>? processingVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (createdAt != null) 'created_at': createdAt,
      if (indexedAt != null) 'indexed_at': indexedAt,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (processingStatus != null) 'processing_status': processingStatus,
      if (ocrText != null) 'ocr_text': ocrText,
      if (primaryType != null) 'primary_type': primaryType,
      if (primarySubtype != null) 'primary_subtype': primarySubtype,
      if (classificationConfidence != null)
        'classification_confidence': classificationConfidence,
      if (currentLifecycleState != null)
        'current_lifecycle_state': currentLifecycleState,
      if (lastProcessedAt != null) 'last_processed_at': lastProcessedAt,
      if (processingVersion != null) 'processing_version': processingVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScreenshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? assetId,
    Value<DateTime>? createdAt,
    Value<DateTime>? indexedAt,
    Value<int>? width,
    Value<int>? height,
    Value<int?>? sizeBytes,
    Value<String>? processingStatus,
    Value<String?>? ocrText,
    Value<String?>? primaryType,
    Value<String?>? primarySubtype,
    Value<double?>? classificationConfidence,
    Value<String>? currentLifecycleState,
    Value<DateTime?>? lastProcessedAt,
    Value<int>? processingVersion,
    Value<int>? rowid,
  }) {
    return ScreenshotsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      createdAt: createdAt ?? this.createdAt,
      indexedAt: indexedAt ?? this.indexedAt,
      width: width ?? this.width,
      height: height ?? this.height,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      processingStatus: processingStatus ?? this.processingStatus,
      ocrText: ocrText ?? this.ocrText,
      primaryType: primaryType ?? this.primaryType,
      primarySubtype: primarySubtype ?? this.primarySubtype,
      classificationConfidence:
          classificationConfidence ?? this.classificationConfidence,
      currentLifecycleState:
          currentLifecycleState ?? this.currentLifecycleState,
      lastProcessedAt: lastProcessedAt ?? this.lastProcessedAt,
      processingVersion: processingVersion ?? this.processingVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (processingStatus.present) {
      map['processing_status'] = Variable<String>(processingStatus.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (primaryType.present) {
      map['primary_type'] = Variable<String>(primaryType.value);
    }
    if (primarySubtype.present) {
      map['primary_subtype'] = Variable<String>(primarySubtype.value);
    }
    if (classificationConfidence.present) {
      map['classification_confidence'] = Variable<double>(
        classificationConfidence.value,
      );
    }
    if (currentLifecycleState.present) {
      map['current_lifecycle_state'] = Variable<String>(
        currentLifecycleState.value,
      );
    }
    if (lastProcessedAt.present) {
      map['last_processed_at'] = Variable<DateTime>(lastProcessedAt.value);
    }
    if (processingVersion.present) {
      map['processing_version'] = Variable<int>(processingVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScreenshotsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('ocrText: $ocrText, ')
          ..write('primaryType: $primaryType, ')
          ..write('primarySubtype: $primarySubtype, ')
          ..write('classificationConfidence: $classificationConfidence, ')
          ..write('currentLifecycleState: $currentLifecycleState, ')
          ..write('lastProcessedAt: $lastProcessedAt, ')
          ..write('processingVersion: $processingVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntitiesTable extends Entities
    with TableInfo<$EntitiesTable, EntityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _screenshotIdMeta = const VerificationMeta(
    'screenshotId',
  );
  @override
  late final GeneratedColumn<String> screenshotId = GeneratedColumn<String>(
    'screenshot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES screenshots (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawValueMeta = const VerificationMeta(
    'rawValue',
  );
  @override
  late final GeneratedColumn<String> rawValue = GeneratedColumn<String>(
    'raw_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedValueMeta = const VerificationMeta(
    'normalizedValue',
  );
  @override
  late final GeneratedColumn<String> normalizedValue = GeneratedColumn<String>(
    'normalized_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    screenshotId,
    type,
    rawValue,
    normalizedValue,
    confidence,
    metadataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('screenshot_id')) {
      context.handle(
        _screenshotIdMeta,
        screenshotId.isAcceptableOrUnknown(
          data['screenshot_id']!,
          _screenshotIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_screenshotIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('raw_value')) {
      context.handle(
        _rawValueMeta,
        rawValue.isAcceptableOrUnknown(data['raw_value']!, _rawValueMeta),
      );
    } else if (isInserting) {
      context.missing(_rawValueMeta);
    }
    if (data.containsKey('normalized_value')) {
      context.handle(
        _normalizedValueMeta,
        normalizedValue.isAcceptableOrUnknown(
          data['normalized_value']!,
          _normalizedValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedValueMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      screenshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screenshot_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      rawValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_value'],
      )!,
      normalizedValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_value'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
    );
  }

  @override
  $EntitiesTable createAlias(String alias) {
    return $EntitiesTable(attachedDatabase, alias);
  }
}

class EntityRow extends DataClass implements Insertable<EntityRow> {
  final String id;
  final String screenshotId;
  final String type;
  final String rawValue;
  final String normalizedValue;
  final double confidence;
  final String metadataJson;
  const EntityRow({
    required this.id,
    required this.screenshotId,
    required this.type,
    required this.rawValue,
    required this.normalizedValue,
    required this.confidence,
    required this.metadataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['screenshot_id'] = Variable<String>(screenshotId);
    map['type'] = Variable<String>(type);
    map['raw_value'] = Variable<String>(rawValue);
    map['normalized_value'] = Variable<String>(normalizedValue);
    map['confidence'] = Variable<double>(confidence);
    map['metadata_json'] = Variable<String>(metadataJson);
    return map;
  }

  EntitiesCompanion toCompanion(bool nullToAbsent) {
    return EntitiesCompanion(
      id: Value(id),
      screenshotId: Value(screenshotId),
      type: Value(type),
      rawValue: Value(rawValue),
      normalizedValue: Value(normalizedValue),
      confidence: Value(confidence),
      metadataJson: Value(metadataJson),
    );
  }

  factory EntityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntityRow(
      id: serializer.fromJson<String>(json['id']),
      screenshotId: serializer.fromJson<String>(json['screenshotId']),
      type: serializer.fromJson<String>(json['type']),
      rawValue: serializer.fromJson<String>(json['rawValue']),
      normalizedValue: serializer.fromJson<String>(json['normalizedValue']),
      confidence: serializer.fromJson<double>(json['confidence']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'screenshotId': serializer.toJson<String>(screenshotId),
      'type': serializer.toJson<String>(type),
      'rawValue': serializer.toJson<String>(rawValue),
      'normalizedValue': serializer.toJson<String>(normalizedValue),
      'confidence': serializer.toJson<double>(confidence),
      'metadataJson': serializer.toJson<String>(metadataJson),
    };
  }

  EntityRow copyWith({
    String? id,
    String? screenshotId,
    String? type,
    String? rawValue,
    String? normalizedValue,
    double? confidence,
    String? metadataJson,
  }) => EntityRow(
    id: id ?? this.id,
    screenshotId: screenshotId ?? this.screenshotId,
    type: type ?? this.type,
    rawValue: rawValue ?? this.rawValue,
    normalizedValue: normalizedValue ?? this.normalizedValue,
    confidence: confidence ?? this.confidence,
    metadataJson: metadataJson ?? this.metadataJson,
  );
  EntityRow copyWithCompanion(EntitiesCompanion data) {
    return EntityRow(
      id: data.id.present ? data.id.value : this.id,
      screenshotId: data.screenshotId.present
          ? data.screenshotId.value
          : this.screenshotId,
      type: data.type.present ? data.type.value : this.type,
      rawValue: data.rawValue.present ? data.rawValue.value : this.rawValue,
      normalizedValue: data.normalizedValue.present
          ? data.normalizedValue.value
          : this.normalizedValue,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntityRow(')
          ..write('id: $id, ')
          ..write('screenshotId: $screenshotId, ')
          ..write('type: $type, ')
          ..write('rawValue: $rawValue, ')
          ..write('normalizedValue: $normalizedValue, ')
          ..write('confidence: $confidence, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    screenshotId,
    type,
    rawValue,
    normalizedValue,
    confidence,
    metadataJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityRow &&
          other.id == this.id &&
          other.screenshotId == this.screenshotId &&
          other.type == this.type &&
          other.rawValue == this.rawValue &&
          other.normalizedValue == this.normalizedValue &&
          other.confidence == this.confidence &&
          other.metadataJson == this.metadataJson);
}

class EntitiesCompanion extends UpdateCompanion<EntityRow> {
  final Value<String> id;
  final Value<String> screenshotId;
  final Value<String> type;
  final Value<String> rawValue;
  final Value<String> normalizedValue;
  final Value<double> confidence;
  final Value<String> metadataJson;
  final Value<int> rowid;
  const EntitiesCompanion({
    this.id = const Value.absent(),
    this.screenshotId = const Value.absent(),
    this.type = const Value.absent(),
    this.rawValue = const Value.absent(),
    this.normalizedValue = const Value.absent(),
    this.confidence = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitiesCompanion.insert({
    required String id,
    required String screenshotId,
    required String type,
    required String rawValue,
    required String normalizedValue,
    required double confidence,
    required String metadataJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       screenshotId = Value(screenshotId),
       type = Value(type),
       rawValue = Value(rawValue),
       normalizedValue = Value(normalizedValue),
       confidence = Value(confidence),
       metadataJson = Value(metadataJson);
  static Insertable<EntityRow> custom({
    Expression<String>? id,
    Expression<String>? screenshotId,
    Expression<String>? type,
    Expression<String>? rawValue,
    Expression<String>? normalizedValue,
    Expression<double>? confidence,
    Expression<String>? metadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (screenshotId != null) 'screenshot_id': screenshotId,
      if (type != null) 'type': type,
      if (rawValue != null) 'raw_value': rawValue,
      if (normalizedValue != null) 'normalized_value': normalizedValue,
      if (confidence != null) 'confidence': confidence,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? screenshotId,
    Value<String>? type,
    Value<String>? rawValue,
    Value<String>? normalizedValue,
    Value<double>? confidence,
    Value<String>? metadataJson,
    Value<int>? rowid,
  }) {
    return EntitiesCompanion(
      id: id ?? this.id,
      screenshotId: screenshotId ?? this.screenshotId,
      type: type ?? this.type,
      rawValue: rawValue ?? this.rawValue,
      normalizedValue: normalizedValue ?? this.normalizedValue,
      confidence: confidence ?? this.confidence,
      metadataJson: metadataJson ?? this.metadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (screenshotId.present) {
      map['screenshot_id'] = Variable<String>(screenshotId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rawValue.present) {
      map['raw_value'] = Variable<String>(rawValue.value);
    }
    if (normalizedValue.present) {
      map['normalized_value'] = Variable<String>(normalizedValue.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitiesCompanion(')
          ..write('id: $id, ')
          ..write('screenshotId: $screenshotId, ')
          ..write('type: $type, ')
          ..write('rawValue: $rawValue, ')
          ..write('normalizedValue: $normalizedValue, ')
          ..write('confidence: $confidence, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExtractedObjectsTable extends ExtractedObjects
    with TableInfo<$ExtractedObjectsTable, ExtractedObjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtractedObjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _screenshotIdMeta = const VerificationMeta(
    'screenshotId',
  );
  @override
  late final GeneratedColumn<String> screenshotId = GeneratedColumn<String>(
    'screenshot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES screenshots (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtypeMeta = const VerificationMeta(
    'subtype',
  );
  @override
  late final GeneratedColumn<String> subtype = GeneratedColumn<String>(
    'subtype',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _structuredDataJsonMeta =
      const VerificationMeta('structuredDataJson');
  @override
  late final GeneratedColumn<String> structuredDataJson =
      GeneratedColumn<String>(
        'structured_data_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedMeta = const VerificationMeta('saved');
  @override
  late final GeneratedColumn<bool> saved = GeneratedColumn<bool>(
    'saved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("saved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _handledMeta = const VerificationMeta(
    'handled',
  );
  @override
  late final GeneratedColumn<bool> handled = GeneratedColumn<bool>(
    'handled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("handled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    screenshotId,
    type,
    subtype,
    title,
    subtitle,
    structuredDataJson,
    confidence,
    saved,
    handled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extracted_objects';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtractedObjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('screenshot_id')) {
      context.handle(
        _screenshotIdMeta,
        screenshotId.isAcceptableOrUnknown(
          data['screenshot_id']!,
          _screenshotIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_screenshotIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('subtype')) {
      context.handle(
        _subtypeMeta,
        subtype.isAcceptableOrUnknown(data['subtype']!, _subtypeMeta),
      );
    } else if (isInserting) {
      context.missing(_subtypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('structured_data_json')) {
      context.handle(
        _structuredDataJsonMeta,
        structuredDataJson.isAcceptableOrUnknown(
          data['structured_data_json']!,
          _structuredDataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_structuredDataJsonMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('saved')) {
      context.handle(
        _savedMeta,
        saved.isAcceptableOrUnknown(data['saved']!, _savedMeta),
      );
    }
    if (data.containsKey('handled')) {
      context.handle(
        _handledMeta,
        handled.isAcceptableOrUnknown(data['handled']!, _handledMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExtractedObjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtractedObjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      screenshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screenshot_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      subtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtype'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      structuredDataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}structured_data_json'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      saved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}saved'],
      )!,
      handled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}handled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExtractedObjectsTable createAlias(String alias) {
    return $ExtractedObjectsTable(attachedDatabase, alias);
  }
}

class ExtractedObjectRow extends DataClass
    implements Insertable<ExtractedObjectRow> {
  final String id;
  final String screenshotId;
  final String type;
  final String subtype;
  final String title;
  final String? subtitle;
  final String structuredDataJson;
  final double confidence;
  final bool saved;
  final bool handled;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExtractedObjectRow({
    required this.id,
    required this.screenshotId,
    required this.type,
    required this.subtype,
    required this.title,
    this.subtitle,
    required this.structuredDataJson,
    required this.confidence,
    required this.saved,
    required this.handled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['screenshot_id'] = Variable<String>(screenshotId);
    map['type'] = Variable<String>(type);
    map['subtype'] = Variable<String>(subtype);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    map['structured_data_json'] = Variable<String>(structuredDataJson);
    map['confidence'] = Variable<double>(confidence);
    map['saved'] = Variable<bool>(saved);
    map['handled'] = Variable<bool>(handled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExtractedObjectsCompanion toCompanion(bool nullToAbsent) {
    return ExtractedObjectsCompanion(
      id: Value(id),
      screenshotId: Value(screenshotId),
      type: Value(type),
      subtype: Value(subtype),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      structuredDataJson: Value(structuredDataJson),
      confidence: Value(confidence),
      saved: Value(saved),
      handled: Value(handled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExtractedObjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtractedObjectRow(
      id: serializer.fromJson<String>(json['id']),
      screenshotId: serializer.fromJson<String>(json['screenshotId']),
      type: serializer.fromJson<String>(json['type']),
      subtype: serializer.fromJson<String>(json['subtype']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      structuredDataJson: serializer.fromJson<String>(
        json['structuredDataJson'],
      ),
      confidence: serializer.fromJson<double>(json['confidence']),
      saved: serializer.fromJson<bool>(json['saved']),
      handled: serializer.fromJson<bool>(json['handled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'screenshotId': serializer.toJson<String>(screenshotId),
      'type': serializer.toJson<String>(type),
      'subtype': serializer.toJson<String>(subtype),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'structuredDataJson': serializer.toJson<String>(structuredDataJson),
      'confidence': serializer.toJson<double>(confidence),
      'saved': serializer.toJson<bool>(saved),
      'handled': serializer.toJson<bool>(handled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExtractedObjectRow copyWith({
    String? id,
    String? screenshotId,
    String? type,
    String? subtype,
    String? title,
    Value<String?> subtitle = const Value.absent(),
    String? structuredDataJson,
    double? confidence,
    bool? saved,
    bool? handled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExtractedObjectRow(
    id: id ?? this.id,
    screenshotId: screenshotId ?? this.screenshotId,
    type: type ?? this.type,
    subtype: subtype ?? this.subtype,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    structuredDataJson: structuredDataJson ?? this.structuredDataJson,
    confidence: confidence ?? this.confidence,
    saved: saved ?? this.saved,
    handled: handled ?? this.handled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExtractedObjectRow copyWithCompanion(ExtractedObjectsCompanion data) {
    return ExtractedObjectRow(
      id: data.id.present ? data.id.value : this.id,
      screenshotId: data.screenshotId.present
          ? data.screenshotId.value
          : this.screenshotId,
      type: data.type.present ? data.type.value : this.type,
      subtype: data.subtype.present ? data.subtype.value : this.subtype,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      structuredDataJson: data.structuredDataJson.present
          ? data.structuredDataJson.value
          : this.structuredDataJson,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      saved: data.saved.present ? data.saved.value : this.saved,
      handled: data.handled.present ? data.handled.value : this.handled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtractedObjectRow(')
          ..write('id: $id, ')
          ..write('screenshotId: $screenshotId, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('structuredDataJson: $structuredDataJson, ')
          ..write('confidence: $confidence, ')
          ..write('saved: $saved, ')
          ..write('handled: $handled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    screenshotId,
    type,
    subtype,
    title,
    subtitle,
    structuredDataJson,
    confidence,
    saved,
    handled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtractedObjectRow &&
          other.id == this.id &&
          other.screenshotId == this.screenshotId &&
          other.type == this.type &&
          other.subtype == this.subtype &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.structuredDataJson == this.structuredDataJson &&
          other.confidence == this.confidence &&
          other.saved == this.saved &&
          other.handled == this.handled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExtractedObjectsCompanion extends UpdateCompanion<ExtractedObjectRow> {
  final Value<String> id;
  final Value<String> screenshotId;
  final Value<String> type;
  final Value<String> subtype;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<String> structuredDataJson;
  final Value<double> confidence;
  final Value<bool> saved;
  final Value<bool> handled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExtractedObjectsCompanion({
    this.id = const Value.absent(),
    this.screenshotId = const Value.absent(),
    this.type = const Value.absent(),
    this.subtype = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.structuredDataJson = const Value.absent(),
    this.confidence = const Value.absent(),
    this.saved = const Value.absent(),
    this.handled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExtractedObjectsCompanion.insert({
    required String id,
    required String screenshotId,
    required String type,
    required String subtype,
    required String title,
    this.subtitle = const Value.absent(),
    required String structuredDataJson,
    required double confidence,
    this.saved = const Value.absent(),
    this.handled = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       screenshotId = Value(screenshotId),
       type = Value(type),
       subtype = Value(subtype),
       title = Value(title),
       structuredDataJson = Value(structuredDataJson),
       confidence = Value(confidence),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExtractedObjectRow> custom({
    Expression<String>? id,
    Expression<String>? screenshotId,
    Expression<String>? type,
    Expression<String>? subtype,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? structuredDataJson,
    Expression<double>? confidence,
    Expression<bool>? saved,
    Expression<bool>? handled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (screenshotId != null) 'screenshot_id': screenshotId,
      if (type != null) 'type': type,
      if (subtype != null) 'subtype': subtype,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (structuredDataJson != null)
        'structured_data_json': structuredDataJson,
      if (confidence != null) 'confidence': confidence,
      if (saved != null) 'saved': saved,
      if (handled != null) 'handled': handled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExtractedObjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? screenshotId,
    Value<String>? type,
    Value<String>? subtype,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<String>? structuredDataJson,
    Value<double>? confidence,
    Value<bool>? saved,
    Value<bool>? handled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ExtractedObjectsCompanion(
      id: id ?? this.id,
      screenshotId: screenshotId ?? this.screenshotId,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      structuredDataJson: structuredDataJson ?? this.structuredDataJson,
      confidence: confidence ?? this.confidence,
      saved: saved ?? this.saved,
      handled: handled ?? this.handled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (screenshotId.present) {
      map['screenshot_id'] = Variable<String>(screenshotId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (subtype.present) {
      map['subtype'] = Variable<String>(subtype.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (structuredDataJson.present) {
      map['structured_data_json'] = Variable<String>(structuredDataJson.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (saved.present) {
      map['saved'] = Variable<bool>(saved.value);
    }
    if (handled.present) {
      map['handled'] = Variable<bool>(handled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtractedObjectsCompanion(')
          ..write('id: $id, ')
          ..write('screenshotId: $screenshotId, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('structuredDataJson: $structuredDataJson, ')
          ..write('confidence: $confidence, ')
          ..write('saved: $saved, ')
          ..write('handled: $handled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SuggestedActionsTable extends SuggestedActions
    with TableInfo<$SuggestedActionsTable, SuggestedActionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuggestedActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _screenshotIdMeta = const VerificationMeta(
    'screenshotId',
  );
  @override
  late final GeneratedColumn<String> screenshotId = GeneratedColumn<String>(
    'screenshot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES screenshots (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _extractedObjectIdMeta = const VerificationMeta(
    'extractedObjectId',
  );
  @override
  late final GeneratedColumn<String> extractedObjectId =
      GeneratedColumn<String>(
        'extracted_object_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES extracted_objects (id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dismissedAtMeta = const VerificationMeta(
    'dismissedAt',
  );
  @override
  late final GeneratedColumn<DateTime> dismissedAt = GeneratedColumn<DateTime>(
    'dismissed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    screenshotId,
    extractedObjectId,
    type,
    payloadJson,
    confidence,
    status,
    createdAt,
    completedAt,
    dismissedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suggested_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SuggestedActionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('screenshot_id')) {
      context.handle(
        _screenshotIdMeta,
        screenshotId.isAcceptableOrUnknown(
          data['screenshot_id']!,
          _screenshotIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_screenshotIdMeta);
    }
    if (data.containsKey('extracted_object_id')) {
      context.handle(
        _extractedObjectIdMeta,
        extractedObjectId.isAcceptableOrUnknown(
          data['extracted_object_id']!,
          _extractedObjectIdMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('dismissed_at')) {
      context.handle(
        _dismissedAtMeta,
        dismissedAt.isAcceptableOrUnknown(
          data['dismissed_at']!,
          _dismissedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SuggestedActionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SuggestedActionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      screenshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screenshot_id'],
      )!,
      extractedObjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_object_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      dismissedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dismissed_at'],
      ),
    );
  }

  @override
  $SuggestedActionsTable createAlias(String alias) {
    return $SuggestedActionsTable(attachedDatabase, alias);
  }
}

class SuggestedActionRow extends DataClass
    implements Insertable<SuggestedActionRow> {
  final String id;
  final String screenshotId;
  final String? extractedObjectId;
  final String type;
  final String payloadJson;
  final double confidence;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dismissedAt;
  const SuggestedActionRow({
    required this.id,
    required this.screenshotId,
    this.extractedObjectId,
    required this.type,
    required this.payloadJson,
    required this.confidence,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.dismissedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['screenshot_id'] = Variable<String>(screenshotId);
    if (!nullToAbsent || extractedObjectId != null) {
      map['extracted_object_id'] = Variable<String>(extractedObjectId);
    }
    map['type'] = Variable<String>(type);
    map['payload_json'] = Variable<String>(payloadJson);
    map['confidence'] = Variable<double>(confidence);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || dismissedAt != null) {
      map['dismissed_at'] = Variable<DateTime>(dismissedAt);
    }
    return map;
  }

  SuggestedActionsCompanion toCompanion(bool nullToAbsent) {
    return SuggestedActionsCompanion(
      id: Value(id),
      screenshotId: Value(screenshotId),
      extractedObjectId: extractedObjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedObjectId),
      type: Value(type),
      payloadJson: Value(payloadJson),
      confidence: Value(confidence),
      status: Value(status),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      dismissedAt: dismissedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dismissedAt),
    );
  }

  factory SuggestedActionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SuggestedActionRow(
      id: serializer.fromJson<String>(json['id']),
      screenshotId: serializer.fromJson<String>(json['screenshotId']),
      extractedObjectId: serializer.fromJson<String?>(
        json['extractedObjectId'],
      ),
      type: serializer.fromJson<String>(json['type']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      confidence: serializer.fromJson<double>(json['confidence']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      dismissedAt: serializer.fromJson<DateTime?>(json['dismissedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'screenshotId': serializer.toJson<String>(screenshotId),
      'extractedObjectId': serializer.toJson<String?>(extractedObjectId),
      'type': serializer.toJson<String>(type),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'confidence': serializer.toJson<double>(confidence),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'dismissedAt': serializer.toJson<DateTime?>(dismissedAt),
    };
  }

  SuggestedActionRow copyWith({
    String? id,
    String? screenshotId,
    Value<String?> extractedObjectId = const Value.absent(),
    String? type,
    String? payloadJson,
    double? confidence,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> dismissedAt = const Value.absent(),
  }) => SuggestedActionRow(
    id: id ?? this.id,
    screenshotId: screenshotId ?? this.screenshotId,
    extractedObjectId: extractedObjectId.present
        ? extractedObjectId.value
        : this.extractedObjectId,
    type: type ?? this.type,
    payloadJson: payloadJson ?? this.payloadJson,
    confidence: confidence ?? this.confidence,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    dismissedAt: dismissedAt.present ? dismissedAt.value : this.dismissedAt,
  );
  SuggestedActionRow copyWithCompanion(SuggestedActionsCompanion data) {
    return SuggestedActionRow(
      id: data.id.present ? data.id.value : this.id,
      screenshotId: data.screenshotId.present
          ? data.screenshotId.value
          : this.screenshotId,
      extractedObjectId: data.extractedObjectId.present
          ? data.extractedObjectId.value
          : this.extractedObjectId,
      type: data.type.present ? data.type.value : this.type,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      dismissedAt: data.dismissedAt.present
          ? data.dismissedAt.value
          : this.dismissedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SuggestedActionRow(')
          ..write('id: $id, ')
          ..write('screenshotId: $screenshotId, ')
          ..write('extractedObjectId: $extractedObjectId, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('dismissedAt: $dismissedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    screenshotId,
    extractedObjectId,
    type,
    payloadJson,
    confidence,
    status,
    createdAt,
    completedAt,
    dismissedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SuggestedActionRow &&
          other.id == this.id &&
          other.screenshotId == this.screenshotId &&
          other.extractedObjectId == this.extractedObjectId &&
          other.type == this.type &&
          other.payloadJson == this.payloadJson &&
          other.confidence == this.confidence &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.dismissedAt == this.dismissedAt);
}

class SuggestedActionsCompanion extends UpdateCompanion<SuggestedActionRow> {
  final Value<String> id;
  final Value<String> screenshotId;
  final Value<String?> extractedObjectId;
  final Value<String> type;
  final Value<String> payloadJson;
  final Value<double> confidence;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> dismissedAt;
  final Value<int> rowid;
  const SuggestedActionsCompanion({
    this.id = const Value.absent(),
    this.screenshotId = const Value.absent(),
    this.extractedObjectId = const Value.absent(),
    this.type = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.confidence = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SuggestedActionsCompanion.insert({
    required String id,
    required String screenshotId,
    this.extractedObjectId = const Value.absent(),
    required String type,
    required String payloadJson,
    required double confidence,
    required String status,
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       screenshotId = Value(screenshotId),
       type = Value(type),
       payloadJson = Value(payloadJson),
       confidence = Value(confidence),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<SuggestedActionRow> custom({
    Expression<String>? id,
    Expression<String>? screenshotId,
    Expression<String>? extractedObjectId,
    Expression<String>? type,
    Expression<String>? payloadJson,
    Expression<double>? confidence,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? dismissedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (screenshotId != null) 'screenshot_id': screenshotId,
      if (extractedObjectId != null) 'extracted_object_id': extractedObjectId,
      if (type != null) 'type': type,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (confidence != null) 'confidence': confidence,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (dismissedAt != null) 'dismissed_at': dismissedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SuggestedActionsCompanion copyWith({
    Value<String>? id,
    Value<String>? screenshotId,
    Value<String?>? extractedObjectId,
    Value<String>? type,
    Value<String>? payloadJson,
    Value<double>? confidence,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? dismissedAt,
    Value<int>? rowid,
  }) {
    return SuggestedActionsCompanion(
      id: id ?? this.id,
      screenshotId: screenshotId ?? this.screenshotId,
      extractedObjectId: extractedObjectId ?? this.extractedObjectId,
      type: type ?? this.type,
      payloadJson: payloadJson ?? this.payloadJson,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (screenshotId.present) {
      map['screenshot_id'] = Variable<String>(screenshotId.value);
    }
    if (extractedObjectId.present) {
      map['extracted_object_id'] = Variable<String>(extractedObjectId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (dismissedAt.present) {
      map['dismissed_at'] = Variable<DateTime>(dismissedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuggestedActionsCompanion(')
          ..write('id: $id, ')
          ..write('screenshotId: $screenshotId, ')
          ..write('extractedObjectId: $extractedObjectId, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('dismissedAt: $dismissedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifecycleEventsTable extends LifecycleEvents
    with TableInfo<$LifecycleEventsTable, LifecycleEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifecycleEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _screenshotIdMeta = const VerificationMeta(
    'screenshotId',
  );
  @override
  late final GeneratedColumn<String> screenshotId = GeneratedColumn<String>(
    'screenshot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES screenshots (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    screenshotId,
    type,
    timestamp,
    reason,
    metadataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lifecycle_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<LifecycleEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('screenshot_id')) {
      context.handle(
        _screenshotIdMeta,
        screenshotId.isAcceptableOrUnknown(
          data['screenshot_id']!,
          _screenshotIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_screenshotIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LifecycleEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifecycleEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      screenshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screenshot_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
    );
  }

  @override
  $LifecycleEventsTable createAlias(String alias) {
    return $LifecycleEventsTable(attachedDatabase, alias);
  }
}

class LifecycleEventRow extends DataClass
    implements Insertable<LifecycleEventRow> {
  final String id;
  final String screenshotId;
  final String type;
  final DateTime timestamp;
  final String reason;
  final String metadataJson;
  const LifecycleEventRow({
    required this.id,
    required this.screenshotId,
    required this.type,
    required this.timestamp,
    required this.reason,
    required this.metadataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['screenshot_id'] = Variable<String>(screenshotId);
    map['type'] = Variable<String>(type);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['reason'] = Variable<String>(reason);
    map['metadata_json'] = Variable<String>(metadataJson);
    return map;
  }

  LifecycleEventsCompanion toCompanion(bool nullToAbsent) {
    return LifecycleEventsCompanion(
      id: Value(id),
      screenshotId: Value(screenshotId),
      type: Value(type),
      timestamp: Value(timestamp),
      reason: Value(reason),
      metadataJson: Value(metadataJson),
    );
  }

  factory LifecycleEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifecycleEventRow(
      id: serializer.fromJson<String>(json['id']),
      screenshotId: serializer.fromJson<String>(json['screenshotId']),
      type: serializer.fromJson<String>(json['type']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      reason: serializer.fromJson<String>(json['reason']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'screenshotId': serializer.toJson<String>(screenshotId),
      'type': serializer.toJson<String>(type),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'reason': serializer.toJson<String>(reason),
      'metadataJson': serializer.toJson<String>(metadataJson),
    };
  }

  LifecycleEventRow copyWith({
    String? id,
    String? screenshotId,
    String? type,
    DateTime? timestamp,
    String? reason,
    String? metadataJson,
  }) => LifecycleEventRow(
    id: id ?? this.id,
    screenshotId: screenshotId ?? this.screenshotId,
    type: type ?? this.type,
    timestamp: timestamp ?? this.timestamp,
    reason: reason ?? this.reason,
    metadataJson: metadataJson ?? this.metadataJson,
  );
  LifecycleEventRow copyWithCompanion(LifecycleEventsCompanion data) {
    return LifecycleEventRow(
      id: data.id.present ? data.id.value : this.id,
      screenshotId: data.screenshotId.present
          ? data.screenshotId.value
          : this.screenshotId,
      type: data.type.present ? data.type.value : this.type,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      reason: data.reason.present ? data.reason.value : this.reason,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifecycleEventRow(')
          ..write('id: $id, ')
          ..write('screenshotId: $screenshotId, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('reason: $reason, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, screenshotId, type, timestamp, reason, metadataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifecycleEventRow &&
          other.id == this.id &&
          other.screenshotId == this.screenshotId &&
          other.type == this.type &&
          other.timestamp == this.timestamp &&
          other.reason == this.reason &&
          other.metadataJson == this.metadataJson);
}

class LifecycleEventsCompanion extends UpdateCompanion<LifecycleEventRow> {
  final Value<String> id;
  final Value<String> screenshotId;
  final Value<String> type;
  final Value<DateTime> timestamp;
  final Value<String> reason;
  final Value<String> metadataJson;
  final Value<int> rowid;
  const LifecycleEventsCompanion({
    this.id = const Value.absent(),
    this.screenshotId = const Value.absent(),
    this.type = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.reason = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LifecycleEventsCompanion.insert({
    required String id,
    required String screenshotId,
    required String type,
    required DateTime timestamp,
    required String reason,
    required String metadataJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       screenshotId = Value(screenshotId),
       type = Value(type),
       timestamp = Value(timestamp),
       reason = Value(reason),
       metadataJson = Value(metadataJson);
  static Insertable<LifecycleEventRow> custom({
    Expression<String>? id,
    Expression<String>? screenshotId,
    Expression<String>? type,
    Expression<DateTime>? timestamp,
    Expression<String>? reason,
    Expression<String>? metadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (screenshotId != null) 'screenshot_id': screenshotId,
      if (type != null) 'type': type,
      if (timestamp != null) 'timestamp': timestamp,
      if (reason != null) 'reason': reason,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LifecycleEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? screenshotId,
    Value<String>? type,
    Value<DateTime>? timestamp,
    Value<String>? reason,
    Value<String>? metadataJson,
    Value<int>? rowid,
  }) {
    return LifecycleEventsCompanion(
      id: id ?? this.id,
      screenshotId: screenshotId ?? this.screenshotId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      reason: reason ?? this.reason,
      metadataJson: metadataJson ?? this.metadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (screenshotId.present) {
      map['screenshot_id'] = Variable<String>(screenshotId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifecycleEventsCompanion(')
          ..write('id: $id, ')
          ..write('screenshotId: $screenshotId, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('reason: $reason, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScreenshotsTable screenshots = $ScreenshotsTable(this);
  late final $EntitiesTable entities = $EntitiesTable(this);
  late final $ExtractedObjectsTable extractedObjects = $ExtractedObjectsTable(
    this,
  );
  late final $SuggestedActionsTable suggestedActions = $SuggestedActionsTable(
    this,
  );
  late final $LifecycleEventsTable lifecycleEvents = $LifecycleEventsTable(
    this,
  );
  late final Index screenshotsAssetIdIdx = Index(
    'screenshots_asset_id_idx',
    'CREATE UNIQUE INDEX screenshots_asset_id_idx ON screenshots (asset_id)',
  );
  late final Index screenshotsLifecycleIdx = Index(
    'screenshots_lifecycle_idx',
    'CREATE INDEX screenshots_lifecycle_idx ON screenshots (current_lifecycle_state)',
  );
  late final Index screenshotsCreatedAtIdx = Index(
    'screenshots_created_at_idx',
    'CREATE INDEX screenshots_created_at_idx ON screenshots (created_at)',
  );
  late final Index entitiesScreenshotIdx = Index(
    'entities_screenshot_idx',
    'CREATE INDEX entities_screenshot_idx ON entities (screenshot_id)',
  );
  late final Index entitiesTypeIdx = Index(
    'entities_type_idx',
    'CREATE INDEX entities_type_idx ON entities (type)',
  );
  late final Index objectsScreenshotIdx = Index(
    'objects_screenshot_idx',
    'CREATE INDEX objects_screenshot_idx ON extracted_objects (screenshot_id)',
  );
  late final Index objectsTypeSubtypeIdx = Index(
    'objects_type_subtype_idx',
    'CREATE INDEX objects_type_subtype_idx ON extracted_objects (type, subtype)',
  );
  late final Index actionsScreenshotStatusIdx = Index(
    'actions_screenshot_status_idx',
    'CREATE INDEX actions_screenshot_status_idx ON suggested_actions (screenshot_id, status)',
  );
  late final Index actionsObjectIdx = Index(
    'actions_object_idx',
    'CREATE INDEX actions_object_idx ON suggested_actions (extracted_object_id)',
  );
  late final Index lifecycleScreenshotTimeIdx = Index(
    'lifecycle_screenshot_time_idx',
    'CREATE INDEX lifecycle_screenshot_time_idx ON lifecycle_events (screenshot_id, timestamp)',
  );
  late final Index lifecycleTypeIdx = Index(
    'lifecycle_type_idx',
    'CREATE INDEX lifecycle_type_idx ON lifecycle_events (type)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    screenshots,
    entities,
    extractedObjects,
    suggestedActions,
    lifecycleEvents,
    screenshotsAssetIdIdx,
    screenshotsLifecycleIdx,
    screenshotsCreatedAtIdx,
    entitiesScreenshotIdx,
    entitiesTypeIdx,
    objectsScreenshotIdx,
    objectsTypeSubtypeIdx,
    actionsScreenshotStatusIdx,
    actionsObjectIdx,
    lifecycleScreenshotTimeIdx,
    lifecycleTypeIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'screenshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entities', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'screenshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('extracted_objects', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'screenshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('suggested_actions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'extracted_objects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('suggested_actions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'screenshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lifecycle_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ScreenshotsTableCreateCompanionBuilder =
    ScreenshotsCompanion Function({
      required String id,
      required String assetId,
      required DateTime createdAt,
      required DateTime indexedAt,
      required int width,
      required int height,
      Value<int?> sizeBytes,
      required String processingStatus,
      Value<String?> ocrText,
      Value<String?> primaryType,
      Value<String?> primarySubtype,
      Value<double?> classificationConfidence,
      required String currentLifecycleState,
      Value<DateTime?> lastProcessedAt,
      Value<int> processingVersion,
      Value<int> rowid,
    });
typedef $$ScreenshotsTableUpdateCompanionBuilder =
    ScreenshotsCompanion Function({
      Value<String> id,
      Value<String> assetId,
      Value<DateTime> createdAt,
      Value<DateTime> indexedAt,
      Value<int> width,
      Value<int> height,
      Value<int?> sizeBytes,
      Value<String> processingStatus,
      Value<String?> ocrText,
      Value<String?> primaryType,
      Value<String?> primarySubtype,
      Value<double?> classificationConfidence,
      Value<String> currentLifecycleState,
      Value<DateTime?> lastProcessedAt,
      Value<int> processingVersion,
      Value<int> rowid,
    });

final class $$ScreenshotsTableReferences
    extends BaseReferences<_$AppDatabase, $ScreenshotsTable, ScreenshotRow> {
  $$ScreenshotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntitiesTable, List<EntityRow>>
  _entitiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entities,
    aliasName: 'screenshots__id__entities__screenshot_id',
  );

  $$EntitiesTableProcessedTableManager get entitiesRefs {
    final manager = $$EntitiesTableTableManager(
      $_db,
      $_db.entities,
    ).filter((f) => f.screenshotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_entitiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExtractedObjectsTable, List<ExtractedObjectRow>>
  _extractedObjectsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.extractedObjects,
    aliasName: 'screenshots__id__extracted_objects__screenshot_id',
  );

  $$ExtractedObjectsTableProcessedTableManager get extractedObjectsRefs {
    final manager = $$ExtractedObjectsTableTableManager(
      $_db,
      $_db.extractedObjects,
    ).filter((f) => f.screenshotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _extractedObjectsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SuggestedActionsTable, List<SuggestedActionRow>>
  _suggestedActionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.suggestedActions,
    aliasName: 'screenshots__id__suggested_actions__screenshot_id',
  );

  $$SuggestedActionsTableProcessedTableManager get suggestedActionsRefs {
    final manager = $$SuggestedActionsTableTableManager(
      $_db,
      $_db.suggestedActions,
    ).filter((f) => f.screenshotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _suggestedActionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LifecycleEventsTable, List<LifecycleEventRow>>
  _lifecycleEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lifecycleEvents,
    aliasName: 'screenshots__id__lifecycle_events__screenshot_id',
  );

  $$LifecycleEventsTableProcessedTableManager get lifecycleEventsRefs {
    final manager = $$LifecycleEventsTableTableManager(
      $_db,
      $_db.lifecycleEvents,
    ).filter((f) => f.screenshotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _lifecycleEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScreenshotsTableFilterComposer
    extends Composer<_$AppDatabase, $ScreenshotsTable> {
  $$ScreenshotsTableFilterComposer({
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

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryType => $composableBuilder(
    column: $table.primaryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primarySubtype => $composableBuilder(
    column: $table.primarySubtype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get classificationConfidence => $composableBuilder(
    column: $table.classificationConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentLifecycleState => $composableBuilder(
    column: $table.currentLifecycleState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastProcessedAt => $composableBuilder(
    column: $table.lastProcessedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processingVersion => $composableBuilder(
    column: $table.processingVersion,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entitiesRefs(
    Expression<bool> Function($$EntitiesTableFilterComposer f) f,
  ) {
    final $$EntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.screenshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableFilterComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> extractedObjectsRefs(
    Expression<bool> Function($$ExtractedObjectsTableFilterComposer f) f,
  ) {
    final $$ExtractedObjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extractedObjects,
      getReferencedColumn: (t) => t.screenshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedObjectsTableFilterComposer(
            $db: $db,
            $table: $db.extractedObjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> suggestedActionsRefs(
    Expression<bool> Function($$SuggestedActionsTableFilterComposer f) f,
  ) {
    final $$SuggestedActionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.suggestedActions,
      getReferencedColumn: (t) => t.screenshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuggestedActionsTableFilterComposer(
            $db: $db,
            $table: $db.suggestedActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lifecycleEventsRefs(
    Expression<bool> Function($$LifecycleEventsTableFilterComposer f) f,
  ) {
    final $$LifecycleEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifecycleEvents,
      getReferencedColumn: (t) => t.screenshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifecycleEventsTableFilterComposer(
            $db: $db,
            $table: $db.lifecycleEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScreenshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScreenshotsTable> {
  $$ScreenshotsTableOrderingComposer({
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

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryType => $composableBuilder(
    column: $table.primaryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primarySubtype => $composableBuilder(
    column: $table.primarySubtype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get classificationConfidence => $composableBuilder(
    column: $table.classificationConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentLifecycleState => $composableBuilder(
    column: $table.currentLifecycleState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastProcessedAt => $composableBuilder(
    column: $table.lastProcessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processingVersion => $composableBuilder(
    column: $table.processingVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScreenshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScreenshotsTable> {
  $$ScreenshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<String> get primaryType => $composableBuilder(
    column: $table.primaryType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primarySubtype => $composableBuilder(
    column: $table.primarySubtype,
    builder: (column) => column,
  );

  GeneratedColumn<double> get classificationConfidence => $composableBuilder(
    column: $table.classificationConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentLifecycleState => $composableBuilder(
    column: $table.currentLifecycleState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastProcessedAt => $composableBuilder(
    column: $table.lastProcessedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get processingVersion => $composableBuilder(
    column: $table.processingVersion,
    builder: (column) => column,
  );

  Expression<T> entitiesRefs<T extends Object>(
    Expression<T> Function($$EntitiesTableAnnotationComposer a) f,
  ) {
    final $$EntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.screenshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> extractedObjectsRefs<T extends Object>(
    Expression<T> Function($$ExtractedObjectsTableAnnotationComposer a) f,
  ) {
    final $$ExtractedObjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extractedObjects,
      getReferencedColumn: (t) => t.screenshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedObjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.extractedObjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> suggestedActionsRefs<T extends Object>(
    Expression<T> Function($$SuggestedActionsTableAnnotationComposer a) f,
  ) {
    final $$SuggestedActionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.suggestedActions,
      getReferencedColumn: (t) => t.screenshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuggestedActionsTableAnnotationComposer(
            $db: $db,
            $table: $db.suggestedActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lifecycleEventsRefs<T extends Object>(
    Expression<T> Function($$LifecycleEventsTableAnnotationComposer a) f,
  ) {
    final $$LifecycleEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lifecycleEvents,
      getReferencedColumn: (t) => t.screenshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LifecycleEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.lifecycleEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScreenshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScreenshotsTable,
          ScreenshotRow,
          $$ScreenshotsTableFilterComposer,
          $$ScreenshotsTableOrderingComposer,
          $$ScreenshotsTableAnnotationComposer,
          $$ScreenshotsTableCreateCompanionBuilder,
          $$ScreenshotsTableUpdateCompanionBuilder,
          (ScreenshotRow, $$ScreenshotsTableReferences),
          ScreenshotRow,
          PrefetchHooks Function({
            bool entitiesRefs,
            bool extractedObjectsRefs,
            bool suggestedActionsRefs,
            bool lifecycleEventsRefs,
          })
        > {
  $$ScreenshotsTableTableManager(_$AppDatabase db, $ScreenshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScreenshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScreenshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScreenshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<String> processingStatus = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String?> primaryType = const Value.absent(),
                Value<String?> primarySubtype = const Value.absent(),
                Value<double?> classificationConfidence = const Value.absent(),
                Value<String> currentLifecycleState = const Value.absent(),
                Value<DateTime?> lastProcessedAt = const Value.absent(),
                Value<int> processingVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScreenshotsCompanion(
                id: id,
                assetId: assetId,
                createdAt: createdAt,
                indexedAt: indexedAt,
                width: width,
                height: height,
                sizeBytes: sizeBytes,
                processingStatus: processingStatus,
                ocrText: ocrText,
                primaryType: primaryType,
                primarySubtype: primarySubtype,
                classificationConfidence: classificationConfidence,
                currentLifecycleState: currentLifecycleState,
                lastProcessedAt: lastProcessedAt,
                processingVersion: processingVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String assetId,
                required DateTime createdAt,
                required DateTime indexedAt,
                required int width,
                required int height,
                Value<int?> sizeBytes = const Value.absent(),
                required String processingStatus,
                Value<String?> ocrText = const Value.absent(),
                Value<String?> primaryType = const Value.absent(),
                Value<String?> primarySubtype = const Value.absent(),
                Value<double?> classificationConfidence = const Value.absent(),
                required String currentLifecycleState,
                Value<DateTime?> lastProcessedAt = const Value.absent(),
                Value<int> processingVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScreenshotsCompanion.insert(
                id: id,
                assetId: assetId,
                createdAt: createdAt,
                indexedAt: indexedAt,
                width: width,
                height: height,
                sizeBytes: sizeBytes,
                processingStatus: processingStatus,
                ocrText: ocrText,
                primaryType: primaryType,
                primarySubtype: primarySubtype,
                classificationConfidence: classificationConfidence,
                currentLifecycleState: currentLifecycleState,
                lastProcessedAt: lastProcessedAt,
                processingVersion: processingVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScreenshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                entitiesRefs = false,
                extractedObjectsRefs = false,
                suggestedActionsRefs = false,
                lifecycleEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entitiesRefs) db.entities,
                    if (extractedObjectsRefs) db.extractedObjects,
                    if (suggestedActionsRefs) db.suggestedActions,
                    if (lifecycleEventsRefs) db.lifecycleEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entitiesRefs)
                        await $_getPrefetchedData<
                          ScreenshotRow,
                          $ScreenshotsTable,
                          EntityRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScreenshotsTableReferences
                              ._entitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScreenshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).entitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.screenshotId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (extractedObjectsRefs)
                        await $_getPrefetchedData<
                          ScreenshotRow,
                          $ScreenshotsTable,
                          ExtractedObjectRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScreenshotsTableReferences
                              ._extractedObjectsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScreenshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).extractedObjectsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.screenshotId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (suggestedActionsRefs)
                        await $_getPrefetchedData<
                          ScreenshotRow,
                          $ScreenshotsTable,
                          SuggestedActionRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScreenshotsTableReferences
                              ._suggestedActionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScreenshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).suggestedActionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.screenshotId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lifecycleEventsRefs)
                        await $_getPrefetchedData<
                          ScreenshotRow,
                          $ScreenshotsTable,
                          LifecycleEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$ScreenshotsTableReferences
                              ._lifecycleEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScreenshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).lifecycleEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.screenshotId == item.id,
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

typedef $$ScreenshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScreenshotsTable,
      ScreenshotRow,
      $$ScreenshotsTableFilterComposer,
      $$ScreenshotsTableOrderingComposer,
      $$ScreenshotsTableAnnotationComposer,
      $$ScreenshotsTableCreateCompanionBuilder,
      $$ScreenshotsTableUpdateCompanionBuilder,
      (ScreenshotRow, $$ScreenshotsTableReferences),
      ScreenshotRow,
      PrefetchHooks Function({
        bool entitiesRefs,
        bool extractedObjectsRefs,
        bool suggestedActionsRefs,
        bool lifecycleEventsRefs,
      })
    >;
typedef $$EntitiesTableCreateCompanionBuilder = EntitiesCompanion Function({
  required String id,
  required String screenshotId,
  required String type,
  required String rawValue,
  required String normalizedValue,
  required double confidence,
  required String metadataJson,
  Value<int> rowid,
});
typedef $$EntitiesTableUpdateCompanionBuilder = EntitiesCompanion Function({
  Value<String> id,
  Value<String> screenshotId,
  Value<String> type,
  Value<String> rawValue,
  Value<String> normalizedValue,
  Value<double> confidence,
  Value<String> metadataJson,
  Value<int> rowid,
});

final class $$EntitiesTableReferences
    extends BaseReferences<_$AppDatabase, $EntitiesTable, EntityRow> {
  $$EntitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScreenshotsTable _screenshotIdTable(_$AppDatabase db) =>
      db.screenshots.createAlias('entities__screenshot_id__screenshots__id');

  $$ScreenshotsTableProcessedTableManager get screenshotId {
    final $_column = $_itemColumn<String>('screenshot_id')!;

    final manager = $$ScreenshotsTableTableManager(
      $_db,
      $_db.screenshots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_screenshotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawValue => $composableBuilder(
    column: $table.rawValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedValue => $composableBuilder(
    column: $table.normalizedValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ScreenshotsTableFilterComposer get screenshotId {
    final $$ScreenshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableFilterComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawValue => $composableBuilder(
    column: $table.rawValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedValue => $composableBuilder(
    column: $table.normalizedValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScreenshotsTableOrderingComposer get screenshotId {
    final $$ScreenshotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableOrderingComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get rawValue =>
      $composableBuilder(column: $table.rawValue, builder: (column) => column);

  GeneratedColumn<String> get normalizedValue => $composableBuilder(
    column: $table.normalizedValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  $$ScreenshotsTableAnnotationComposer get screenshotId {
    final $$ScreenshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntitiesTable,
          EntityRow,
          $$EntitiesTableFilterComposer,
          $$EntitiesTableOrderingComposer,
          $$EntitiesTableAnnotationComposer,
          $$EntitiesTableCreateCompanionBuilder,
          $$EntitiesTableUpdateCompanionBuilder,
          (EntityRow, $$EntitiesTableReferences),
          EntityRow,
          PrefetchHooks Function({bool screenshotId})
        > {
  $$EntitiesTableTableManager(_$AppDatabase db, $EntitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> screenshotId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> rawValue = const Value.absent(),
                Value<String> normalizedValue = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitiesCompanion(
                id: id,
                screenshotId: screenshotId,
                type: type,
                rawValue: rawValue,
                normalizedValue: normalizedValue,
                confidence: confidence,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String screenshotId,
                required String type,
                required String rawValue,
                required String normalizedValue,
                required double confidence,
                required String metadataJson,
                Value<int> rowid = const Value.absent(),
              }) => EntitiesCompanion.insert(
                id: id,
                screenshotId: screenshotId,
                type: type,
                rawValue: rawValue,
                normalizedValue: normalizedValue,
                confidence: confidence,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({screenshotId = false}) {
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
                    if (screenshotId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.screenshotId,
                        referencedTable: $$EntitiesTableReferences
                            ._screenshotIdTable(db),
                        referencedColumn: $$EntitiesTableReferences
                            ._screenshotIdTable(db)
                            .id,
                      ) as T;
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

typedef $$EntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntitiesTable,
      EntityRow,
      $$EntitiesTableFilterComposer,
      $$EntitiesTableOrderingComposer,
      $$EntitiesTableAnnotationComposer,
      $$EntitiesTableCreateCompanionBuilder,
      $$EntitiesTableUpdateCompanionBuilder,
      (EntityRow, $$EntitiesTableReferences),
      EntityRow,
      PrefetchHooks Function({bool screenshotId})
    >;
typedef $$ExtractedObjectsTableCreateCompanionBuilder =
    ExtractedObjectsCompanion Function({
      required String id,
      required String screenshotId,
      required String type,
      required String subtype,
      required String title,
      Value<String?> subtitle,
      required String structuredDataJson,
      required double confidence,
      Value<bool> saved,
      Value<bool> handled,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ExtractedObjectsTableUpdateCompanionBuilder =
    ExtractedObjectsCompanion Function({
      Value<String> id,
      Value<String> screenshotId,
      Value<String> type,
      Value<String> subtype,
      Value<String> title,
      Value<String?> subtitle,
      Value<String> structuredDataJson,
      Value<double> confidence,
      Value<bool> saved,
      Value<bool> handled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ExtractedObjectsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExtractedObjectsTable,
          ExtractedObjectRow
        > {
  $$ExtractedObjectsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScreenshotsTable _screenshotIdTable(_$AppDatabase db) => db
      .screenshots
      .createAlias('extracted_objects__screenshot_id__screenshots__id');

  $$ScreenshotsTableProcessedTableManager get screenshotId {
    final $_column = $_itemColumn<String>('screenshot_id')!;

    final manager = $$ScreenshotsTableTableManager(
      $_db,
      $_db.screenshots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_screenshotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SuggestedActionsTable, List<SuggestedActionRow>>
  _suggestedActionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.suggestedActions,
    aliasName: 'extracted_objects__id__suggested_actions__extracted_object_id',
  );

  $$SuggestedActionsTableProcessedTableManager get suggestedActionsRefs {
    final manager =
        $$SuggestedActionsTableTableManager($_db, $_db.suggestedActions).filter(
          (f) => f.extractedObjectId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _suggestedActionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExtractedObjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ExtractedObjectsTable> {
  $$ExtractedObjectsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtype => $composableBuilder(
    column: $table.subtype,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get structuredDataJson => $composableBuilder(
    column: $table.structuredDataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saved => $composableBuilder(
    column: $table.saved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get handled => $composableBuilder(
    column: $table.handled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScreenshotsTableFilterComposer get screenshotId {
    final $$ScreenshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableFilterComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> suggestedActionsRefs(
    Expression<bool> Function($$SuggestedActionsTableFilterComposer f) f,
  ) {
    final $$SuggestedActionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.suggestedActions,
      getReferencedColumn: (t) => t.extractedObjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuggestedActionsTableFilterComposer(
            $db: $db,
            $table: $db.suggestedActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExtractedObjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExtractedObjectsTable> {
  $$ExtractedObjectsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtype => $composableBuilder(
    column: $table.subtype,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get structuredDataJson => $composableBuilder(
    column: $table.structuredDataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saved => $composableBuilder(
    column: $table.saved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get handled => $composableBuilder(
    column: $table.handled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScreenshotsTableOrderingComposer get screenshotId {
    final $$ScreenshotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableOrderingComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtractedObjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExtractedObjectsTable> {
  $$ExtractedObjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get subtype =>
      $composableBuilder(column: $table.subtype, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get structuredDataJson => $composableBuilder(
    column: $table.structuredDataJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get saved =>
      $composableBuilder(column: $table.saved, builder: (column) => column);

  GeneratedColumn<bool> get handled =>
      $composableBuilder(column: $table.handled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ScreenshotsTableAnnotationComposer get screenshotId {
    final $$ScreenshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> suggestedActionsRefs<T extends Object>(
    Expression<T> Function($$SuggestedActionsTableAnnotationComposer a) f,
  ) {
    final $$SuggestedActionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.suggestedActions,
      getReferencedColumn: (t) => t.extractedObjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuggestedActionsTableAnnotationComposer(
            $db: $db,
            $table: $db.suggestedActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExtractedObjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExtractedObjectsTable,
          ExtractedObjectRow,
          $$ExtractedObjectsTableFilterComposer,
          $$ExtractedObjectsTableOrderingComposer,
          $$ExtractedObjectsTableAnnotationComposer,
          $$ExtractedObjectsTableCreateCompanionBuilder,
          $$ExtractedObjectsTableUpdateCompanionBuilder,
          (ExtractedObjectRow, $$ExtractedObjectsTableReferences),
          ExtractedObjectRow,
          PrefetchHooks Function({bool screenshotId, bool suggestedActionsRefs})
        > {
  $$ExtractedObjectsTableTableManager(
    _$AppDatabase db,
    $ExtractedObjectsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtractedObjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtractedObjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExtractedObjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> screenshotId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> subtype = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String> structuredDataJson = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<bool> saved = const Value.absent(),
                Value<bool> handled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExtractedObjectsCompanion(
                id: id,
                screenshotId: screenshotId,
                type: type,
                subtype: subtype,
                title: title,
                subtitle: subtitle,
                structuredDataJson: structuredDataJson,
                confidence: confidence,
                saved: saved,
                handled: handled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String screenshotId,
                required String type,
                required String subtype,
                required String title,
                Value<String?> subtitle = const Value.absent(),
                required String structuredDataJson,
                required double confidence,
                Value<bool> saved = const Value.absent(),
                Value<bool> handled = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExtractedObjectsCompanion.insert(
                id: id,
                screenshotId: screenshotId,
                type: type,
                subtype: subtype,
                title: title,
                subtitle: subtitle,
                structuredDataJson: structuredDataJson,
                confidence: confidence,
                saved: saved,
                handled: handled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExtractedObjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({screenshotId = false, suggestedActionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (suggestedActionsRefs) db.suggestedActions,
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
                        if (screenshotId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.screenshotId,
                            referencedTable: $$ExtractedObjectsTableReferences
                                ._screenshotIdTable(db),
                            referencedColumn: $$ExtractedObjectsTableReferences
                                ._screenshotIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (suggestedActionsRefs)
                        await $_getPrefetchedData<
                          ExtractedObjectRow,
                          $ExtractedObjectsTable,
                          SuggestedActionRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExtractedObjectsTableReferences
                              ._suggestedActionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExtractedObjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).suggestedActionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.extractedObjectId == item.id,
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

typedef $$ExtractedObjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExtractedObjectsTable,
      ExtractedObjectRow,
      $$ExtractedObjectsTableFilterComposer,
      $$ExtractedObjectsTableOrderingComposer,
      $$ExtractedObjectsTableAnnotationComposer,
      $$ExtractedObjectsTableCreateCompanionBuilder,
      $$ExtractedObjectsTableUpdateCompanionBuilder,
      (ExtractedObjectRow, $$ExtractedObjectsTableReferences),
      ExtractedObjectRow,
      PrefetchHooks Function({bool screenshotId, bool suggestedActionsRefs})
    >;
typedef $$SuggestedActionsTableCreateCompanionBuilder =
    SuggestedActionsCompanion Function({
      required String id,
      required String screenshotId,
      Value<String?> extractedObjectId,
      required String type,
      required String payloadJson,
      required double confidence,
      required String status,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> dismissedAt,
      Value<int> rowid,
    });
typedef $$SuggestedActionsTableUpdateCompanionBuilder =
    SuggestedActionsCompanion Function({
      Value<String> id,
      Value<String> screenshotId,
      Value<String?> extractedObjectId,
      Value<String> type,
      Value<String> payloadJson,
      Value<double> confidence,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> dismissedAt,
      Value<int> rowid,
    });

final class $$SuggestedActionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SuggestedActionsTable,
          SuggestedActionRow
        > {
  $$SuggestedActionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScreenshotsTable _screenshotIdTable(_$AppDatabase db) => db
      .screenshots
      .createAlias('suggested_actions__screenshot_id__screenshots__id');

  $$ScreenshotsTableProcessedTableManager get screenshotId {
    final $_column = $_itemColumn<String>('screenshot_id')!;

    final manager = $$ScreenshotsTableTableManager(
      $_db,
      $_db.screenshots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_screenshotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExtractedObjectsTable _extractedObjectIdTable(_$AppDatabase db) =>
      db.extractedObjects.createAlias(
        'suggested_actions__extracted_object_id__extracted_objects__id',
      );

  $$ExtractedObjectsTableProcessedTableManager? get extractedObjectId {
    final $_column = $_itemColumn<String>('extracted_object_id');
    if ($_column == null) return null;
    final manager = $$ExtractedObjectsTableTableManager(
      $_db,
      $_db.extractedObjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_extractedObjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SuggestedActionsTableFilterComposer
    extends Composer<_$AppDatabase, $SuggestedActionsTable> {
  $$SuggestedActionsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScreenshotsTableFilterComposer get screenshotId {
    final $$ScreenshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableFilterComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedObjectsTableFilterComposer get extractedObjectId {
    final $$ExtractedObjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.extractedObjectId,
      referencedTable: $db.extractedObjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedObjectsTableFilterComposer(
            $db: $db,
            $table: $db.extractedObjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SuggestedActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SuggestedActionsTable> {
  $$SuggestedActionsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScreenshotsTableOrderingComposer get screenshotId {
    final $$ScreenshotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableOrderingComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedObjectsTableOrderingComposer get extractedObjectId {
    final $$ExtractedObjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.extractedObjectId,
      referencedTable: $db.extractedObjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedObjectsTableOrderingComposer(
            $db: $db,
            $table: $db.extractedObjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SuggestedActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuggestedActionsTable> {
  $$SuggestedActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dismissedAt => $composableBuilder(
    column: $table.dismissedAt,
    builder: (column) => column,
  );

  $$ScreenshotsTableAnnotationComposer get screenshotId {
    final $$ScreenshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExtractedObjectsTableAnnotationComposer get extractedObjectId {
    final $$ExtractedObjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.extractedObjectId,
      referencedTable: $db.extractedObjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedObjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.extractedObjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SuggestedActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SuggestedActionsTable,
          SuggestedActionRow,
          $$SuggestedActionsTableFilterComposer,
          $$SuggestedActionsTableOrderingComposer,
          $$SuggestedActionsTableAnnotationComposer,
          $$SuggestedActionsTableCreateCompanionBuilder,
          $$SuggestedActionsTableUpdateCompanionBuilder,
          (SuggestedActionRow, $$SuggestedActionsTableReferences),
          SuggestedActionRow,
          PrefetchHooks Function({bool screenshotId, bool extractedObjectId})
        > {
  $$SuggestedActionsTableTableManager(
    _$AppDatabase db,
    $SuggestedActionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuggestedActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuggestedActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuggestedActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> screenshotId = const Value.absent(),
                Value<String?> extractedObjectId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> dismissedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuggestedActionsCompanion(
                id: id,
                screenshotId: screenshotId,
                extractedObjectId: extractedObjectId,
                type: type,
                payloadJson: payloadJson,
                confidence: confidence,
                status: status,
                createdAt: createdAt,
                completedAt: completedAt,
                dismissedAt: dismissedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String screenshotId,
                Value<String?> extractedObjectId = const Value.absent(),
                required String type,
                required String payloadJson,
                required double confidence,
                required String status,
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> dismissedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuggestedActionsCompanion.insert(
                id: id,
                screenshotId: screenshotId,
                extractedObjectId: extractedObjectId,
                type: type,
                payloadJson: payloadJson,
                confidence: confidence,
                status: status,
                createdAt: createdAt,
                completedAt: completedAt,
                dismissedAt: dismissedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SuggestedActionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({screenshotId = false, extractedObjectId = false}) {
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
                        if (screenshotId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.screenshotId,
                            referencedTable: $$SuggestedActionsTableReferences
                                ._screenshotIdTable(db),
                            referencedColumn: $$SuggestedActionsTableReferences
                                ._screenshotIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (extractedObjectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.extractedObjectId,
                            referencedTable: $$SuggestedActionsTableReferences
                                ._extractedObjectIdTable(db),
                            referencedColumn: $$SuggestedActionsTableReferences
                                ._extractedObjectIdTable(db)
                                .id,
                          ) as T;
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

typedef $$SuggestedActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SuggestedActionsTable,
      SuggestedActionRow,
      $$SuggestedActionsTableFilterComposer,
      $$SuggestedActionsTableOrderingComposer,
      $$SuggestedActionsTableAnnotationComposer,
      $$SuggestedActionsTableCreateCompanionBuilder,
      $$SuggestedActionsTableUpdateCompanionBuilder,
      (SuggestedActionRow, $$SuggestedActionsTableReferences),
      SuggestedActionRow,
      PrefetchHooks Function({bool screenshotId, bool extractedObjectId})
    >;
typedef $$LifecycleEventsTableCreateCompanionBuilder =
    LifecycleEventsCompanion Function({
      required String id,
      required String screenshotId,
      required String type,
      required DateTime timestamp,
      required String reason,
      required String metadataJson,
      Value<int> rowid,
    });
typedef $$LifecycleEventsTableUpdateCompanionBuilder =
    LifecycleEventsCompanion Function({
      Value<String> id,
      Value<String> screenshotId,
      Value<String> type,
      Value<DateTime> timestamp,
      Value<String> reason,
      Value<String> metadataJson,
      Value<int> rowid,
    });

final class $$LifecycleEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LifecycleEventsTable,
          LifecycleEventRow
        > {
  $$LifecycleEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScreenshotsTable _screenshotIdTable(_$AppDatabase db) => db
      .screenshots
      .createAlias('lifecycle_events__screenshot_id__screenshots__id');

  $$ScreenshotsTableProcessedTableManager get screenshotId {
    final $_column = $_itemColumn<String>('screenshot_id')!;

    final manager = $$ScreenshotsTableTableManager(
      $_db,
      $_db.screenshots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_screenshotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LifecycleEventsTableFilterComposer
    extends Composer<_$AppDatabase, $LifecycleEventsTable> {
  $$LifecycleEventsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ScreenshotsTableFilterComposer get screenshotId {
    final $$ScreenshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableFilterComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LifecycleEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $LifecycleEventsTable> {
  $$LifecycleEventsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScreenshotsTableOrderingComposer get screenshotId {
    final $$ScreenshotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableOrderingComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LifecycleEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LifecycleEventsTable> {
  $$LifecycleEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  $$ScreenshotsTableAnnotationComposer get screenshotId {
    final $$ScreenshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.screenshotId,
      referencedTable: $db.screenshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScreenshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.screenshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LifecycleEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LifecycleEventsTable,
          LifecycleEventRow,
          $$LifecycleEventsTableFilterComposer,
          $$LifecycleEventsTableOrderingComposer,
          $$LifecycleEventsTableAnnotationComposer,
          $$LifecycleEventsTableCreateCompanionBuilder,
          $$LifecycleEventsTableUpdateCompanionBuilder,
          (LifecycleEventRow, $$LifecycleEventsTableReferences),
          LifecycleEventRow,
          PrefetchHooks Function({bool screenshotId})
        > {
  $$LifecycleEventsTableTableManager(
    _$AppDatabase db,
    $LifecycleEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifecycleEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LifecycleEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LifecycleEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> screenshotId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LifecycleEventsCompanion(
                id: id,
                screenshotId: screenshotId,
                type: type,
                timestamp: timestamp,
                reason: reason,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String screenshotId,
                required String type,
                required DateTime timestamp,
                required String reason,
                required String metadataJson,
                Value<int> rowid = const Value.absent(),
              }) => LifecycleEventsCompanion.insert(
                id: id,
                screenshotId: screenshotId,
                type: type,
                timestamp: timestamp,
                reason: reason,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LifecycleEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({screenshotId = false}) {
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
                    if (screenshotId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.screenshotId,
                        referencedTable: $$LifecycleEventsTableReferences
                            ._screenshotIdTable(db),
                        referencedColumn: $$LifecycleEventsTableReferences
                            ._screenshotIdTable(db)
                            .id,
                      ) as T;
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

typedef $$LifecycleEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LifecycleEventsTable,
      LifecycleEventRow,
      $$LifecycleEventsTableFilterComposer,
      $$LifecycleEventsTableOrderingComposer,
      $$LifecycleEventsTableAnnotationComposer,
      $$LifecycleEventsTableCreateCompanionBuilder,
      $$LifecycleEventsTableUpdateCompanionBuilder,
      (LifecycleEventRow, $$LifecycleEventsTableReferences),
      LifecycleEventRow,
      PrefetchHooks Function({bool screenshotId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScreenshotsTableTableManager get screenshots =>
      $$ScreenshotsTableTableManager(_db, _db.screenshots);
  $$EntitiesTableTableManager get entities =>
      $$EntitiesTableTableManager(_db, _db.entities);
  $$ExtractedObjectsTableTableManager get extractedObjects =>
      $$ExtractedObjectsTableTableManager(_db, _db.extractedObjects);
  $$SuggestedActionsTableTableManager get suggestedActions =>
      $$SuggestedActionsTableTableManager(_db, _db.suggestedActions);
  $$LifecycleEventsTableTableManager get lifecycleEvents =>
      $$LifecycleEventsTableTableManager(_db, _db.lifecycleEvents);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedIncidentsTable extends CachedIncidents
    with TableInfo<$CachedIncidentsTable, CachedIncident> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedIncidentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _locationAddressMeta = const VerificationMeta(
    'locationAddress',
  );
  @override
  late final GeneratedColumn<String> locationAddress = GeneratedColumn<String>(
    'location_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlsJsonMeta = const VerificationMeta(
    'imageUrlsJson',
  );
  @override
  late final GeneratedColumn<String> imageUrlsJson = GeneratedColumn<String>(
    'image_urls_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _upvoteCountMeta = const VerificationMeta(
    'upvoteCount',
  );
  @override
  late final GeneratedColumn<int> upvoteCount = GeneratedColumn<int>(
    'upvote_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hasUpvotedMeta = const VerificationMeta(
    'hasUpvoted',
  );
  @override
  late final GeneratedColumn<bool> hasUpvoted = GeneratedColumn<bool>(
    'has_upvoted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_upvoted" IN (0, 1))',
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
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    category,
    status,
    locationAddress,
    latitude,
    longitude,
    imageUrlsJson,
    upvoteCount,
    hasUpvoted,
    createdAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_incidents';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedIncident> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('location_address')) {
      context.handle(
        _locationAddressMeta,
        locationAddress.isAcceptableOrUnknown(
          data['location_address']!,
          _locationAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationAddressMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('image_urls_json')) {
      context.handle(
        _imageUrlsJsonMeta,
        imageUrlsJson.isAcceptableOrUnknown(
          data['image_urls_json']!,
          _imageUrlsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_imageUrlsJsonMeta);
    }
    if (data.containsKey('upvote_count')) {
      context.handle(
        _upvoteCountMeta,
        upvoteCount.isAcceptableOrUnknown(
          data['upvote_count']!,
          _upvoteCountMeta,
        ),
      );
    }
    if (data.containsKey('has_upvoted')) {
      context.handle(
        _hasUpvotedMeta,
        hasUpvoted.isAcceptableOrUnknown(data['has_upvoted']!, _hasUpvotedMeta),
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
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedIncident map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedIncident(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      locationAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_address'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      imageUrlsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_urls_json'],
      )!,
      upvoteCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upvote_count'],
      )!,
      hasUpvoted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_upvoted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedIncidentsTable createAlias(String alias) {
    return $CachedIncidentsTable(attachedDatabase, alias);
  }
}

class CachedIncident extends DataClass implements Insertable<CachedIncident> {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final String imageUrlsJson;
  final int upvoteCount;
  final bool hasUpvoted;
  final DateTime createdAt;
  final DateTime cachedAt;
  const CachedIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.imageUrlsJson,
    required this.upvoteCount,
    required this.hasUpvoted,
    required this.createdAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['status'] = Variable<String>(status);
    map['location_address'] = Variable<String>(locationAddress);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['image_urls_json'] = Variable<String>(imageUrlsJson);
    map['upvote_count'] = Variable<int>(upvoteCount);
    map['has_upvoted'] = Variable<bool>(hasUpvoted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedIncidentsCompanion toCompanion(bool nullToAbsent) {
    return CachedIncidentsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      category: Value(category),
      status: Value(status),
      locationAddress: Value(locationAddress),
      latitude: Value(latitude),
      longitude: Value(longitude),
      imageUrlsJson: Value(imageUrlsJson),
      upvoteCount: Value(upvoteCount),
      hasUpvoted: Value(hasUpvoted),
      createdAt: Value(createdAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedIncident.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedIncident(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      status: serializer.fromJson<String>(json['status']),
      locationAddress: serializer.fromJson<String>(json['locationAddress']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      imageUrlsJson: serializer.fromJson<String>(json['imageUrlsJson']),
      upvoteCount: serializer.fromJson<int>(json['upvoteCount']),
      hasUpvoted: serializer.fromJson<bool>(json['hasUpvoted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'status': serializer.toJson<String>(status),
      'locationAddress': serializer.toJson<String>(locationAddress),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'imageUrlsJson': serializer.toJson<String>(imageUrlsJson),
      'upvoteCount': serializer.toJson<int>(upvoteCount),
      'hasUpvoted': serializer.toJson<bool>(hasUpvoted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedIncident copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? status,
    String? locationAddress,
    double? latitude,
    double? longitude,
    String? imageUrlsJson,
    int? upvoteCount,
    bool? hasUpvoted,
    DateTime? createdAt,
    DateTime? cachedAt,
  }) => CachedIncident(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    status: status ?? this.status,
    locationAddress: locationAddress ?? this.locationAddress,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    imageUrlsJson: imageUrlsJson ?? this.imageUrlsJson,
    upvoteCount: upvoteCount ?? this.upvoteCount,
    hasUpvoted: hasUpvoted ?? this.hasUpvoted,
    createdAt: createdAt ?? this.createdAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedIncident copyWithCompanion(CachedIncidentsCompanion data) {
    return CachedIncident(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
      locationAddress: data.locationAddress.present
          ? data.locationAddress.value
          : this.locationAddress,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      imageUrlsJson: data.imageUrlsJson.present
          ? data.imageUrlsJson.value
          : this.imageUrlsJson,
      upvoteCount: data.upvoteCount.present
          ? data.upvoteCount.value
          : this.upvoteCount,
      hasUpvoted: data.hasUpvoted.present
          ? data.hasUpvoted.value
          : this.hasUpvoted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedIncident(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('locationAddress: $locationAddress, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('imageUrlsJson: $imageUrlsJson, ')
          ..write('upvoteCount: $upvoteCount, ')
          ..write('hasUpvoted: $hasUpvoted, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    category,
    status,
    locationAddress,
    latitude,
    longitude,
    imageUrlsJson,
    upvoteCount,
    hasUpvoted,
    createdAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedIncident &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.status == this.status &&
          other.locationAddress == this.locationAddress &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.imageUrlsJson == this.imageUrlsJson &&
          other.upvoteCount == this.upvoteCount &&
          other.hasUpvoted == this.hasUpvoted &&
          other.createdAt == this.createdAt &&
          other.cachedAt == this.cachedAt);
}

class CachedIncidentsCompanion extends UpdateCompanion<CachedIncident> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<String> category;
  final Value<String> status;
  final Value<String> locationAddress;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> imageUrlsJson;
  final Value<int> upvoteCount;
  final Value<bool> hasUpvoted;
  final Value<DateTime> createdAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedIncidentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.locationAddress = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.imageUrlsJson = const Value.absent(),
    this.upvoteCount = const Value.absent(),
    this.hasUpvoted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedIncidentsCompanion.insert({
    required String id,
    required String title,
    required String description,
    required String category,
    required String status,
    required String locationAddress,
    required double latitude,
    required double longitude,
    required String imageUrlsJson,
    this.upvoteCount = const Value.absent(),
    this.hasUpvoted = const Value.absent(),
    required DateTime createdAt,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       description = Value(description),
       category = Value(category),
       status = Value(status),
       locationAddress = Value(locationAddress),
       latitude = Value(latitude),
       longitude = Value(longitude),
       imageUrlsJson = Value(imageUrlsJson),
       createdAt = Value(createdAt);
  static Insertable<CachedIncident> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? status,
    Expression<String>? locationAddress,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? imageUrlsJson,
    Expression<int>? upvoteCount,
    Expression<bool>? hasUpvoted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (locationAddress != null) 'location_address': locationAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (imageUrlsJson != null) 'image_urls_json': imageUrlsJson,
      if (upvoteCount != null) 'upvote_count': upvoteCount,
      if (hasUpvoted != null) 'has_upvoted': hasUpvoted,
      if (createdAt != null) 'created_at': createdAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedIncidentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<String>? category,
    Value<String>? status,
    Value<String>? locationAddress,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String>? imageUrlsJson,
    Value<int>? upvoteCount,
    Value<bool>? hasUpvoted,
    Value<DateTime>? createdAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedIncidentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrlsJson: imageUrlsJson ?? this.imageUrlsJson,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
      createdAt: createdAt ?? this.createdAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (locationAddress.present) {
      map['location_address'] = Variable<String>(locationAddress.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (imageUrlsJson.present) {
      map['image_urls_json'] = Variable<String>(imageUrlsJson.value);
    }
    if (upvoteCount.present) {
      map['upvote_count'] = Variable<int>(upvoteCount.value);
    }
    if (hasUpvoted.present) {
      map['has_upvoted'] = Variable<bool>(hasUpvoted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedIncidentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('locationAddress: $locationAddress, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('imageUrlsJson: $imageUrlsJson, ')
          ..write('upvoteCount: $upvoteCount, ')
          ..write('hasUpvoted: $hasUpvoted, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedIncidentsTable cachedIncidents = $CachedIncidentsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cachedIncidents];
}

typedef $$CachedIncidentsTableCreateCompanionBuilder =
    CachedIncidentsCompanion Function({
      required String id,
      required String title,
      required String description,
      required String category,
      required String status,
      required String locationAddress,
      required double latitude,
      required double longitude,
      required String imageUrlsJson,
      Value<int> upvoteCount,
      Value<bool> hasUpvoted,
      required DateTime createdAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedIncidentsTableUpdateCompanionBuilder =
    CachedIncidentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> description,
      Value<String> category,
      Value<String> status,
      Value<String> locationAddress,
      Value<double> latitude,
      Value<double> longitude,
      Value<String> imageUrlsJson,
      Value<int> upvoteCount,
      Value<bool> hasUpvoted,
      Value<DateTime> createdAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedIncidentsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedIncidentsTable> {
  $$CachedIncidentsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationAddress => $composableBuilder(
    column: $table.locationAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrlsJson => $composableBuilder(
    column: $table.imageUrlsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get upvoteCount => $composableBuilder(
    column: $table.upvoteCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasUpvoted => $composableBuilder(
    column: $table.hasUpvoted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedIncidentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedIncidentsTable> {
  $$CachedIncidentsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationAddress => $composableBuilder(
    column: $table.locationAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrlsJson => $composableBuilder(
    column: $table.imageUrlsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get upvoteCount => $composableBuilder(
    column: $table.upvoteCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasUpvoted => $composableBuilder(
    column: $table.hasUpvoted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedIncidentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedIncidentsTable> {
  $$CachedIncidentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get locationAddress => $composableBuilder(
    column: $table.locationAddress,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get imageUrlsJson => $composableBuilder(
    column: $table.imageUrlsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get upvoteCount => $composableBuilder(
    column: $table.upvoteCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasUpvoted => $composableBuilder(
    column: $table.hasUpvoted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedIncidentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedIncidentsTable,
          CachedIncident,
          $$CachedIncidentsTableFilterComposer,
          $$CachedIncidentsTableOrderingComposer,
          $$CachedIncidentsTableAnnotationComposer,
          $$CachedIncidentsTableCreateCompanionBuilder,
          $$CachedIncidentsTableUpdateCompanionBuilder,
          (
            CachedIncident,
            BaseReferences<
              _$AppDatabase,
              $CachedIncidentsTable,
              CachedIncident
            >,
          ),
          CachedIncident,
          PrefetchHooks Function()
        > {
  $$CachedIncidentsTableTableManager(
    _$AppDatabase db,
    $CachedIncidentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedIncidentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedIncidentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedIncidentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> locationAddress = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String> imageUrlsJson = const Value.absent(),
                Value<int> upvoteCount = const Value.absent(),
                Value<bool> hasUpvoted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedIncidentsCompanion(
                id: id,
                title: title,
                description: description,
                category: category,
                status: status,
                locationAddress: locationAddress,
                latitude: latitude,
                longitude: longitude,
                imageUrlsJson: imageUrlsJson,
                upvoteCount: upvoteCount,
                hasUpvoted: hasUpvoted,
                createdAt: createdAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String description,
                required String category,
                required String status,
                required String locationAddress,
                required double latitude,
                required double longitude,
                required String imageUrlsJson,
                Value<int> upvoteCount = const Value.absent(),
                Value<bool> hasUpvoted = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedIncidentsCompanion.insert(
                id: id,
                title: title,
                description: description,
                category: category,
                status: status,
                locationAddress: locationAddress,
                latitude: latitude,
                longitude: longitude,
                imageUrlsJson: imageUrlsJson,
                upvoteCount: upvoteCount,
                hasUpvoted: hasUpvoted,
                createdAt: createdAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedIncidentsTable, CachedIncident>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedIncidentsTable,
                    CachedIncident
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedIncidentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedIncidentsTable,
      CachedIncident,
      $$CachedIncidentsTableFilterComposer,
      $$CachedIncidentsTableOrderingComposer,
      $$CachedIncidentsTableAnnotationComposer,
      $$CachedIncidentsTableCreateCompanionBuilder,
      $$CachedIncidentsTableUpdateCompanionBuilder,
      (
        CachedIncident,
        BaseReferences<_$AppDatabase, $CachedIncidentsTable, CachedIncident>,
      ),
      CachedIncident,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedIncidentsTableTableManager get cachedIncidents =>
      $$CachedIncidentsTableTableManager(_db, _db.cachedIncidents);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, Document> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionCountMeta = const VerificationMeta(
    'sectionCount',
  );
  @override
  late final GeneratedColumn<int> sectionCount = GeneratedColumn<int>(
    'section_count',
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
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    year,
    sectionCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<Document> instance, {
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
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('section_count')) {
      context.handle(
        _sectionCountMeta,
        sectionCount.isAcceptableOrUnknown(
          data['section_count']!,
          _sectionCountMeta,
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
  Document map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Document(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      sectionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class Document extends DataClass implements Insertable<Document> {
  final String id;
  final String title;
  final int year;
  final int sectionCount;
  final DateTime createdAt;
  const Document({
    required this.id,
    required this.title,
    required this.year,
    required this.sectionCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['year'] = Variable<int>(year);
    map['section_count'] = Variable<int>(sectionCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      title: Value(title),
      year: Value(year),
      sectionCount: Value(sectionCount),
      createdAt: Value(createdAt),
    );
  }

  factory Document.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Document(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      year: serializer.fromJson<int>(json['year']),
      sectionCount: serializer.fromJson<int>(json['sectionCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'year': serializer.toJson<int>(year),
      'sectionCount': serializer.toJson<int>(sectionCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Document copyWith({
    String? id,
    String? title,
    int? year,
    int? sectionCount,
    DateTime? createdAt,
  }) => Document(
    id: id ?? this.id,
    title: title ?? this.title,
    year: year ?? this.year,
    sectionCount: sectionCount ?? this.sectionCount,
    createdAt: createdAt ?? this.createdAt,
  );
  Document copyWithCompanion(DocumentsCompanion data) {
    return Document(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      year: data.year.present ? data.year.value : this.year,
      sectionCount: data.sectionCount.present
          ? data.sectionCount.value
          : this.sectionCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Document(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('sectionCount: $sectionCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, year, sectionCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Document &&
          other.id == this.id &&
          other.title == this.title &&
          other.year == this.year &&
          other.sectionCount == this.sectionCount &&
          other.createdAt == this.createdAt);
}

class DocumentsCompanion extends UpdateCompanion<Document> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> year;
  final Value<int> sectionCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.sectionCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required String title,
    required int year,
    this.sectionCount = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       year = Value(year),
       createdAt = Value(createdAt);
  static Insertable<Document> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? year,
    Expression<int>? sectionCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (year != null) 'year': year,
      if (sectionCount != null) 'section_count': sectionCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? year,
    Value<int>? sectionCount,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      sectionCount: sectionCount ?? this.sectionCount,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (sectionCount.present) {
      map['section_count'] = Variable<int>(sectionCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('sectionCount: $sectionCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChunksTable extends Chunks with TableInfo<$ChunksTable, Chunk> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChunksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id)',
    ),
  );
  static const VerificationMeta _documentTitleMeta = const VerificationMeta(
    'documentTitle',
  );
  @override
  late final GeneratedColumn<String> documentTitle = GeneratedColumn<String>(
    'document_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<String> embedding = GeneratedColumn<String>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    documentTitle,
    year,
    section,
    content,
    embedding,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chunks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chunk> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('document_title')) {
      context.handle(
        _documentTitleMeta,
        documentTitle.isAcceptableOrUnknown(
          data['document_title']!,
          _documentTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentTitleMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chunk map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chunk(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      documentTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_title'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding'],
      ),
    );
  }

  @override
  $ChunksTable createAlias(String alias) {
    return $ChunksTable(attachedDatabase, alias);
  }
}

class Chunk extends DataClass implements Insertable<Chunk> {
  final String id;
  final String documentId;
  final String documentTitle;
  final int year;
  final String section;
  final String content;
  final String? embedding;
  const Chunk({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    required this.year,
    required this.section,
    required this.content,
    this.embedding,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['document_title'] = Variable<String>(documentTitle);
    map['year'] = Variable<int>(year);
    map['section'] = Variable<String>(section);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<String>(embedding);
    }
    return map;
  }

  ChunksCompanion toCompanion(bool nullToAbsent) {
    return ChunksCompanion(
      id: Value(id),
      documentId: Value(documentId),
      documentTitle: Value(documentTitle),
      year: Value(year),
      section: Value(section),
      content: Value(content),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
    );
  }

  factory Chunk.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chunk(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      documentTitle: serializer.fromJson<String>(json['documentTitle']),
      year: serializer.fromJson<int>(json['year']),
      section: serializer.fromJson<String>(json['section']),
      content: serializer.fromJson<String>(json['content']),
      embedding: serializer.fromJson<String?>(json['embedding']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'documentTitle': serializer.toJson<String>(documentTitle),
      'year': serializer.toJson<int>(year),
      'section': serializer.toJson<String>(section),
      'content': serializer.toJson<String>(content),
      'embedding': serializer.toJson<String?>(embedding),
    };
  }

  Chunk copyWith({
    String? id,
    String? documentId,
    String? documentTitle,
    int? year,
    String? section,
    String? content,
    Value<String?> embedding = const Value.absent(),
  }) => Chunk(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    documentTitle: documentTitle ?? this.documentTitle,
    year: year ?? this.year,
    section: section ?? this.section,
    content: content ?? this.content,
    embedding: embedding.present ? embedding.value : this.embedding,
  );
  Chunk copyWithCompanion(ChunksCompanion data) {
    return Chunk(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      documentTitle: data.documentTitle.present
          ? data.documentTitle.value
          : this.documentTitle,
      year: data.year.present ? data.year.value : this.year,
      section: data.section.present ? data.section.value : this.section,
      content: data.content.present ? data.content.value : this.content,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chunk(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('documentTitle: $documentTitle, ')
          ..write('year: $year, ')
          ..write('section: $section, ')
          ..write('content: $content, ')
          ..write('embedding: $embedding')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    documentTitle,
    year,
    section,
    content,
    embedding,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chunk &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.documentTitle == this.documentTitle &&
          other.year == this.year &&
          other.section == this.section &&
          other.content == this.content &&
          other.embedding == this.embedding);
}

class ChunksCompanion extends UpdateCompanion<Chunk> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<String> documentTitle;
  final Value<int> year;
  final Value<String> section;
  final Value<String> content;
  final Value<String?> embedding;
  final Value<int> rowid;
  const ChunksCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.documentTitle = const Value.absent(),
    this.year = const Value.absent(),
    this.section = const Value.absent(),
    this.content = const Value.absent(),
    this.embedding = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChunksCompanion.insert({
    required String id,
    required String documentId,
    required String documentTitle,
    required int year,
    required String section,
    required String content,
    this.embedding = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       documentTitle = Value(documentTitle),
       year = Value(year),
       section = Value(section),
       content = Value(content);
  static Insertable<Chunk> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<String>? documentTitle,
    Expression<int>? year,
    Expression<String>? section,
    Expression<String>? content,
    Expression<String>? embedding,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (documentTitle != null) 'document_title': documentTitle,
      if (year != null) 'year': year,
      if (section != null) 'section': section,
      if (content != null) 'content': content,
      if (embedding != null) 'embedding': embedding,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChunksCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<String>? documentTitle,
    Value<int>? year,
    Value<String>? section,
    Value<String>? content,
    Value<String?>? embedding,
    Value<int>? rowid,
  }) {
    return ChunksCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      documentTitle: documentTitle ?? this.documentTitle,
      year: year ?? this.year,
      section: section ?? this.section,
      content: content ?? this.content,
      embedding: embedding ?? this.embedding,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (documentTitle.present) {
      map['document_title'] = Variable<String>(documentTitle.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<String>(embedding.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChunksCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('documentTitle: $documentTitle, ')
          ..write('year: $year, ')
          ..write('section: $section, ')
          ..write('content: $content, ')
          ..write('embedding: $embedding, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAnswersTable extends CachedAnswers
    with TableInfo<$CachedAnswersTable, CachedAnswer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionMeta = const VerificationMeta(
    'question',
  );
  @override
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
    'question',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _citationsJsonMeta = const VerificationMeta(
    'citationsJson',
  );
  @override
  late final GeneratedColumn<String> citationsJson = GeneratedColumn<String>(
    'citations_json',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    question,
    answer,
    citationsJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAnswer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question')) {
      context.handle(
        _questionMeta,
        question.isAcceptableOrUnknown(data['question']!, _questionMeta),
      );
    } else if (isInserting) {
      context.missing(_questionMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('citations_json')) {
      context.handle(
        _citationsJsonMeta,
        citationsJson.isAcceptableOrUnknown(
          data['citations_json']!,
          _citationsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_citationsJsonMeta);
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
  CachedAnswer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAnswer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      question: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      citationsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}citations_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CachedAnswersTable createAlias(String alias) {
    return $CachedAnswersTable(attachedDatabase, alias);
  }
}

class CachedAnswer extends DataClass implements Insertable<CachedAnswer> {
  final String id;
  final String question;
  final String answer;
  final String citationsJson;
  final DateTime createdAt;
  const CachedAnswer({
    required this.id,
    required this.question,
    required this.answer,
    required this.citationsJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question'] = Variable<String>(question);
    map['answer'] = Variable<String>(answer);
    map['citations_json'] = Variable<String>(citationsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CachedAnswersCompanion toCompanion(bool nullToAbsent) {
    return CachedAnswersCompanion(
      id: Value(id),
      question: Value(question),
      answer: Value(answer),
      citationsJson: Value(citationsJson),
      createdAt: Value(createdAt),
    );
  }

  factory CachedAnswer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAnswer(
      id: serializer.fromJson<String>(json['id']),
      question: serializer.fromJson<String>(json['question']),
      answer: serializer.fromJson<String>(json['answer']),
      citationsJson: serializer.fromJson<String>(json['citationsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'question': serializer.toJson<String>(question),
      'answer': serializer.toJson<String>(answer),
      'citationsJson': serializer.toJson<String>(citationsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CachedAnswer copyWith({
    String? id,
    String? question,
    String? answer,
    String? citationsJson,
    DateTime? createdAt,
  }) => CachedAnswer(
    id: id ?? this.id,
    question: question ?? this.question,
    answer: answer ?? this.answer,
    citationsJson: citationsJson ?? this.citationsJson,
    createdAt: createdAt ?? this.createdAt,
  );
  CachedAnswer copyWithCompanion(CachedAnswersCompanion data) {
    return CachedAnswer(
      id: data.id.present ? data.id.value : this.id,
      question: data.question.present ? data.question.value : this.question,
      answer: data.answer.present ? data.answer.value : this.answer,
      citationsJson: data.citationsJson.present
          ? data.citationsJson.value
          : this.citationsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAnswer(')
          ..write('id: $id, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('citationsJson: $citationsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, question, answer, citationsJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAnswer &&
          other.id == this.id &&
          other.question == this.question &&
          other.answer == this.answer &&
          other.citationsJson == this.citationsJson &&
          other.createdAt == this.createdAt);
}

class CachedAnswersCompanion extends UpdateCompanion<CachedAnswer> {
  final Value<String> id;
  final Value<String> question;
  final Value<String> answer;
  final Value<String> citationsJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CachedAnswersCompanion({
    this.id = const Value.absent(),
    this.question = const Value.absent(),
    this.answer = const Value.absent(),
    this.citationsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAnswersCompanion.insert({
    required String id,
    required String question,
    required String answer,
    required String citationsJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       question = Value(question),
       answer = Value(answer),
       citationsJson = Value(citationsJson),
       createdAt = Value(createdAt);
  static Insertable<CachedAnswer> custom({
    Expression<String>? id,
    Expression<String>? question,
    Expression<String>? answer,
    Expression<String>? citationsJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (question != null) 'question': question,
      if (answer != null) 'answer': answer,
      if (citationsJson != null) 'citations_json': citationsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAnswersCompanion copyWith({
    Value<String>? id,
    Value<String>? question,
    Value<String>? answer,
    Value<String>? citationsJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CachedAnswersCompanion(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      citationsJson: citationsJson ?? this.citationsJson,
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
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (citationsJson.present) {
      map['citations_json'] = Variable<String>(citationsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAnswersCompanion(')
          ..write('id: $id, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('citationsJson: $citationsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $ChunksTable chunks = $ChunksTable(this);
  late final $CachedAnswersTable cachedAnswers = $CachedAnswersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    documents,
    chunks,
    cachedAnswers,
  ];
}

typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String id,
      required String title,
      required int year,
      Value<int> sectionCount,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> year,
      Value<int> sectionCount,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$DocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentsTable, Document> {
  $$DocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChunksTable, List<Chunk>> _chunksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.chunks,
    aliasName: $_aliasNameGenerator(db.documents.id, db.chunks.documentId),
  );

  $$ChunksTableProcessedTableManager get chunksRefs {
    final manager = $$ChunksTableTableManager(
      $_db,
      $_db.chunks,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chunksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
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

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sectionCount => $composableBuilder(
    column: $table.sectionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> chunksRefs(
    Expression<bool> Function($$ChunksTableFilterComposer f) f,
  ) {
    final $$ChunksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chunks,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChunksTableFilterComposer(
            $db: $db,
            $table: $db.chunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
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

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sectionCount => $composableBuilder(
    column: $table.sectionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
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

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get sectionCount => $composableBuilder(
    column: $table.sectionCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> chunksRefs<T extends Object>(
    Expression<T> Function($$ChunksTableAnnotationComposer a) f,
  ) {
    final $$ChunksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chunks,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChunksTableAnnotationComposer(
            $db: $db,
            $table: $db.chunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          Document,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (Document, $$DocumentsTableReferences),
          Document,
          PrefetchHooks Function({bool chunksRefs})
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> sectionCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                title: title,
                year: year,
                sectionCount: sectionCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int year,
                Value<int> sectionCount = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                title: title,
                year: year,
                sectionCount: sectionCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chunksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chunksRefs) db.chunks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chunksRefs)
                    await $_getPrefetchedData<Document, $DocumentsTable, Chunk>(
                      currentTable: table,
                      referencedTable: $$DocumentsTableReferences
                          ._chunksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DocumentsTableReferences(db, table, p0).chunksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.documentId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      Document,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (Document, $$DocumentsTableReferences),
      Document,
      PrefetchHooks Function({bool chunksRefs})
    >;
typedef $$ChunksTableCreateCompanionBuilder =
    ChunksCompanion Function({
      required String id,
      required String documentId,
      required String documentTitle,
      required int year,
      required String section,
      required String content,
      Value<String?> embedding,
      Value<int> rowid,
    });
typedef $$ChunksTableUpdateCompanionBuilder =
    ChunksCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<String> documentTitle,
      Value<int> year,
      Value<String> section,
      Value<String> content,
      Value<String?> embedding,
      Value<int> rowid,
    });

final class $$ChunksTableReferences
    extends BaseReferences<_$AppDatabase, $ChunksTable, Chunk> {
  $$ChunksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentsTable _documentIdTable(_$AppDatabase db) => db.documents
      .createAlias($_aliasNameGenerator(db.chunks.documentId, db.documents.id));

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChunksTableFilterComposer
    extends Composer<_$AppDatabase, $ChunksTable> {
  $$ChunksTableFilterComposer({
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

  ColumnFilters<String> get documentTitle => $composableBuilder(
    column: $table.documentTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChunksTableOrderingComposer
    extends Composer<_$AppDatabase, $ChunksTable> {
  $$ChunksTableOrderingComposer({
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

  ColumnOrderings<String> get documentTitle => $composableBuilder(
    column: $table.documentTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChunksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChunksTable> {
  $$ChunksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get documentTitle => $composableBuilder(
    column: $table.documentTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChunksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChunksTable,
          Chunk,
          $$ChunksTableFilterComposer,
          $$ChunksTableOrderingComposer,
          $$ChunksTableAnnotationComposer,
          $$ChunksTableCreateCompanionBuilder,
          $$ChunksTableUpdateCompanionBuilder,
          (Chunk, $$ChunksTableReferences),
          Chunk,
          PrefetchHooks Function({bool documentId})
        > {
  $$ChunksTableTableManager(_$AppDatabase db, $ChunksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChunksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChunksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChunksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<String> documentTitle = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<String> section = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> embedding = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChunksCompanion(
                id: id,
                documentId: documentId,
                documentTitle: documentTitle,
                year: year,
                section: section,
                content: content,
                embedding: embedding,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required String documentTitle,
                required int year,
                required String section,
                required String content,
                Value<String?> embedding = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChunksCompanion.insert(
                id: id,
                documentId: documentId,
                documentTitle: documentTitle,
                year: year,
                section: section,
                content: content,
                embedding: embedding,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ChunksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
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
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable: $$ChunksTableReferences
                                    ._documentIdTable(db),
                                referencedColumn: $$ChunksTableReferences
                                    ._documentIdTable(db)
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

typedef $$ChunksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChunksTable,
      Chunk,
      $$ChunksTableFilterComposer,
      $$ChunksTableOrderingComposer,
      $$ChunksTableAnnotationComposer,
      $$ChunksTableCreateCompanionBuilder,
      $$ChunksTableUpdateCompanionBuilder,
      (Chunk, $$ChunksTableReferences),
      Chunk,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$CachedAnswersTableCreateCompanionBuilder =
    CachedAnswersCompanion Function({
      required String id,
      required String question,
      required String answer,
      required String citationsJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CachedAnswersTableUpdateCompanionBuilder =
    CachedAnswersCompanion Function({
      Value<String> id,
      Value<String> question,
      Value<String> answer,
      Value<String> citationsJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CachedAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAnswersTable> {
  $$CachedAnswersTableFilterComposer({
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

  ColumnFilters<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get citationsJson => $composableBuilder(
    column: $table.citationsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAnswersTable> {
  $$CachedAnswersTableOrderingComposer({
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

  ColumnOrderings<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get citationsJson => $composableBuilder(
    column: $table.citationsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAnswersTable> {
  $$CachedAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get citationsJson => $composableBuilder(
    column: $table.citationsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CachedAnswersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedAnswersTable,
          CachedAnswer,
          $$CachedAnswersTableFilterComposer,
          $$CachedAnswersTableOrderingComposer,
          $$CachedAnswersTableAnnotationComposer,
          $$CachedAnswersTableCreateCompanionBuilder,
          $$CachedAnswersTableUpdateCompanionBuilder,
          (
            CachedAnswer,
            BaseReferences<_$AppDatabase, $CachedAnswersTable, CachedAnswer>,
          ),
          CachedAnswer,
          PrefetchHooks Function()
        > {
  $$CachedAnswersTableTableManager(_$AppDatabase db, $CachedAnswersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> question = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<String> citationsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAnswersCompanion(
                id: id,
                question: question,
                answer: answer,
                citationsJson: citationsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String question,
                required String answer,
                required String citationsJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedAnswersCompanion.insert(
                id: id,
                question: question,
                answer: answer,
                citationsJson: citationsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedAnswersTable,
      CachedAnswer,
      $$CachedAnswersTableFilterComposer,
      $$CachedAnswersTableOrderingComposer,
      $$CachedAnswersTableAnnotationComposer,
      $$CachedAnswersTableCreateCompanionBuilder,
      $$CachedAnswersTableUpdateCompanionBuilder,
      (
        CachedAnswer,
        BaseReferences<_$AppDatabase, $CachedAnswersTable, CachedAnswer>,
      ),
      CachedAnswer,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$ChunksTableTableManager get chunks =>
      $$ChunksTableTableManager(_db, _db.chunks);
  $$CachedAnswersTableTableManager get cachedAnswers =>
      $$CachedAnswersTableTableManager(_db, _db.cachedAnswers);
}

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

class Documents extends Table {
  TextColumn get id => text()(); // UUID stored as text
  TextColumn get title => text()();
  IntColumn get year => integer()();
  IntColumn get sectionCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Chunks extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id)();
  TextColumn get documentTitle => text()();
  IntColumn get year => integer()();
  TextColumn get section => text()();
  TextColumn get content => text()();
  TextColumn get embedding => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedAnswers extends Table {
  TextColumn get id => text()();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  TextColumn get citationsJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Database class
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Documents, Chunks, CachedAnswers])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
  );

  Future<List<Document>> getAllDocuments() => (select(
    documents,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<Document?> getDocumentById(String id) =>
      (select(documents)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertDocument(DocumentsCompanion doc) =>
      into(documents).insert(doc);

  Future<void> deleteDocument(String id) async {
    await (delete(chunks)..where((t) => t.documentId.equals(id))).go();
    await (delete(documents)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateDocumentSectionCount(String id, int count) =>
      (update(documents)..where((t) => t.id.equals(id))).write(
        DocumentsCompanion(sectionCount: Value(count)),
      );

  Future<void> insertChunk(ChunksCompanion chunk) => into(chunks).insert(chunk);

  Future<void> insertChunks(List<ChunksCompanion> chunkList) =>
      batch((b) => b.insertAll(chunks, chunkList));

  Future<List<Chunk>> getChunksByDocumentId(String documentId) =>
      (select(chunks)..where((t) => t.documentId.equals(documentId))).get();

  Future<List<Chunk>> getAllChunksWithEmbeddings() =>
      (select(chunks)..where((t) => t.embedding.isNotNull())).get();

  Future<List<Chunk>> getAllChunks() => select(chunks).get();

  Future<int> getTotalChunkCount() async {
    final countExpression = chunks.id.count();
    final query = selectOnly(chunks)..addColumns([countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<void> updateChunkEmbedding(String chunkId, String embeddingCsv) =>
      (update(chunks)..where((t) => t.id.equals(chunkId))).write(
        ChunksCompanion(embedding: Value(embeddingCsv)),
      );

  Future<void> insertCachedAnswer(CachedAnswersCompanion answer) =>
      into(cachedAnswers).insert(answer, mode: InsertMode.insertOrReplace);

  Future<List<CachedAnswer>> getAllCachedAnswers() => (select(
    cachedAnswers,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<CachedAnswer?> findCachedAnswer(String question) => (select(
    cachedAnswers,
  )..where((t) => t.question.equals(question))).getSingleOrNull();
}

// ---------------------------------------------------------------------------
// Connection factory
// ---------------------------------------------------------------------------

QueryExecutor _openConnection() {
  return driftDatabase(name: 'athena_local');
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});

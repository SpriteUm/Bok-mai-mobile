import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// ตารางแคชปัญหาในเครื่อง (Local Database สำหรับโหมด Offline-first)
class CachedIncidents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get category => text()();
  TextColumn get status => text()();
  TextColumn get locationAddress => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get imageUrlsJson => text()(); // เก็บเป็น JSON string
  IntColumn get upvoteCount => integer().withDefault(const Constant(0))();
  BoolColumn get hasUpvoted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [CachedIncidents])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(DatabaseConnection connection) : super(connection);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'bok_mai_local_db');
  }

  // ดึงรายการปัญหาที่แคชไว้ทั้งหมด
  Future<List<CachedIncident>> getAllCachedIncidents() =>
      select(cachedIncidents).get();

  // Watch รายการปัญหาแบบ Stream
  Stream<List<CachedIncident>> watchAllCachedIncidents() =>
      (select(cachedIncidents)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  // บันทึกหรืออัปเดตปัญหาลงแคช
  Future<void> upsertIncident(CachedIncidentsCompanion entry) =>
      into(cachedIncidents).insertOnConflictUpdate(entry);

  // บันทึกทีละหลายรายการ (Batch Cache)
  Future<void> cacheIncidentsBatch(List<CachedIncidentsCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(cachedIncidents, entries);
    });
  }

  // ล้างแคชทั้งหมด
  Future<int> clearCache() => delete(cachedIncidents).go();
}


import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/seed_data.dart';
import '../models/job_application.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'job_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE applications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company TEXT NOT NULL,
        position TEXT,
        status TEXT NOT NULL,
        source TEXT,
        location TEXT,
        priority INTEGER,
        link TEXT,
        dateApplied TEXT,
        followUpDate TEXT,
        notes TEXT,
        contactPerson TEXT
      )
    ''');
  }

  Future<int> insert(JobApplication application) async {
    final db = await database;
    final map = application.toMap()..remove('id');
    return db.insert('applications', map);
  }

  Future<int> update(JobApplication application) async {
    final db = await database;
    return db.update(
      'applications',
      application.toMap(),
      where: 'id = ?',
      whereArgs: [application.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('applications', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<JobApplication>> getAll({
    JobStatus? statusFilter,
    String? searchQuery,
    String orderBy = 'dateApplied DESC',
  }) async {
    final db = await database;

    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (statusFilter != null) {
      whereClauses.add('status = ?');
      whereArgs.add(statusFilter.name);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(company LIKE ? OR position LIKE ?)');
      final pattern = '%${searchQuery.trim()}%';
      whereArgs.add(pattern);
      whereArgs.add(pattern);
    }

    final result = await db.query(
      'applications',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return result.map((map) => JobApplication.fromMap(map)).toList();
  }

  Future<Map<JobStatus, int>> getStatusCounts() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT status, COUNT(*) as count FROM applications GROUP BY status',
    );

    final counts = <JobStatus, int>{
      for (final status in JobStatus.values) status: 0,
    };

    for (final row in result) {
      final status = JobStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => JobStatus.wishlist,
      );
      counts[status] = row['count'] as int;
    }

    return counts;
  }

  /// Returns a list of [weeks] entries (oldest first), each the count of
  /// applications with a dateApplied falling in that week (Mon-Sun).
  Future<void> seedIfEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM applications'),
    );
    if (count != null && count > 0) return;

    final batch = db.batch();
    for (final app in getSeedApplications()) {
      final map = app.toMap()..remove('id');
      batch.insert('applications', map);
    }
    await batch.commit(noResult: true);
  }

  Future<List<int>> getWeeklyApplicationCounts(int weeks) async {
    final db = await database;
    final result = await db.query(
      'applications',
      columns: ['dateApplied'],
      where: 'dateApplied IS NOT NULL',
    );

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    // Start of the current week (Monday).
    final currentWeekStart =
        todayMidnight.subtract(Duration(days: todayMidnight.weekday - 1));

    final weekStarts = List.generate(
      weeks,
      (i) => currentWeekStart.subtract(Duration(days: 7 * (weeks - 1 - i))),
    );

    final counts = List<int>.filled(weeks, 0);

    for (final row in result) {
      final raw = row['dateApplied'] as String?;
      if (raw == null) continue;
      final date = DateTime.parse(raw);
      final dateMidnight = DateTime(date.year, date.month, date.day);

      for (var i = 0; i < weeks; i++) {
        final weekStart = weekStarts[i];
        final weekEnd = weekStart.add(const Duration(days: 7));
        if (!dateMidnight.isBefore(weekStart) &&
            dateMidnight.isBefore(weekEnd)) {
          counts[i]++;
          break;
        }
      }
    }

    return counts;
  }
}

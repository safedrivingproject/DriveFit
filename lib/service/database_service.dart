import 'dart:async';
import 'dart:io' as io;
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService.internal();
  factory DatabaseService() => _instance;
  static Database? _db;
  static const _databaseVersion = 2;

  Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  DatabaseService.internal();

  Future<Database> initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "driving_sessions.db");
    var db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return db;
  }

  void _onCreate(Database db, int version) async {
    await db.execute(
        "CREATE TABLE sessions(id INTEGER PRIMARY KEY, start_time TEXT NOT NULL, end_time TEXT NOT NULL, duration INTEGER NOT NULL, distance DOUBLE NOT NULL, drowsy_alerts INTEGER NOT NULL, inattentive_alerts INTEGER NOT NULL, score INTEGER NOT NULL)");
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db
          .execute("ALTER TABLE sessions ADD COLUMN distance DOUBLE NOT NULL");
    }
  }

  Future<int> saveSessionData(SessionData session) async {
    var dbClient = await db;
    if (dbClient == null) return 0;
    int id = await dbClient.insert("sessions", session.toMap());
    return id;
  }

  Future<int> getRowCount() async {
    var dbClient = await db;
    if (dbClient == null) return 0;
    int count = Sqflite.firstIntValue(
            await dbClient.rawQuery('SELECT COUNT(*) FROM sessions')) ??
        0;
    return count;
  }

  Future<int> getTotalAlertCount() async {
    var dbClient = await db;
    if (dbClient == null) return 0;
    int count = Sqflite.firstIntValue(await dbClient.rawQuery(
            'SELECT SUM(drowsy_alerts + inattentive_alerts) FROM sessions')) ??
        0;
    return count;
  }

  Future<double> getOverallAverageScore() async {
    var dbClient = await db;
    if (dbClient == null) return 0.0;
    var result =
        await dbClient.rawQuery('SELECT ROUND(AVG(score), 1) FROM sessions');
    double average =
        result.isNotEmpty ? (result.first.values.first as num).toDouble() : 0.0;
    return average;
  }

  Future<double> getRecentAverageScore() async {
    var dbClient = await db;
    if (dbClient == null) return 0.0;
    var result = await dbClient
        .rawQuery('SELECT score FROM sessions ORDER BY id DESC LIMIT 7');
    List<int> scoreList = [];
    for (int i = 0; i < result.length; i++) {
      scoreList.add(result[i]['score'] as int);
    }
    double average =
        scoreList.average;
    return average;
  }

  Future<List<SessionData>> getRecentSessions() async {
    var dbClient = await db;
    List<Map> list = await dbClient!
        .rawQuery('SELECT * FROM sessions ORDER BY id DESC LIMIT 14');
    List<SessionData> sessions = [];
    for (int i = 0; i < list.length; i++) {
      sessions.add(SessionData.fromMap(list[i] as Map<String, dynamic>));
    }
    return sessions;
  }

  Future<void> deleteData() async {
    var dbClient = await db;
    await dbClient?.delete("sessions");
  }
}

class SessionData {
  int id = 0;
  String startTime = '';
  String endTime = '';
  int duration = 0;
  double distance = 0.0;
  int drowsyAlertCount = 0;
  int inattentiveAlertCount = 0;
  int score = 0;

  SessionData({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distance,
    required this.drowsyAlertCount,
    required this.inattentiveAlertCount,
    required this.score,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'distance': distance,
      'drowsy_alerts': drowsyAlertCount,
      'inattentive_alerts': inattentiveAlertCount,
      'score': score,
    };
    return map;
  }

  SessionData.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    startTime = map['start_time'];
    endTime = map['end_time'];
    duration = map['duration'];
    distance = map['distance'];
    drowsyAlertCount = map['drowsy_alerts'];
    inattentiveAlertCount = map['inattentive_alerts'];
    score = map['score'];
  }

  @override
  String toString() {
    return 'Session{id: $id, startTime: $startTime, endTime: $endTime, duration: $duration, distance: $distance, drowsyAlertCount: $drowsyAlertCount, inattentiveAlertCount: $inattentiveAlertCount, score: $score}';
  }
}

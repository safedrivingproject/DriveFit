import 'dart:async';
import 'dart:io' as io;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService.internal();
  factory DatabaseService() => _instance;
  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  DatabaseService.internal();

  Future<Database> initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "driving_sessions.db");
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  void _onCreate(Database db, int version) async {
    await db.execute(
        "CREATE TABLE sessions(id INTEGER PRIMARY KEY, start_time TEXT NOT NULL, end_time TEXT NOT NULL, duration INTEGER NOT NULL, drowsy_alerts INTEGER NOT NULL, inattentive_alerts INTEGER NOT NULL, score INTEGER NOT NULL)");
  }

  Future<int> saveSession(SessionData session) async {
    var dbClient = await db;
    if (dbClient == null) return 0;
    int res = await dbClient.insert("sessions", session.toMap());
    return res;
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
  int drowsyAlerts = 0;
  int inattentiveAlerts = 0;
  int score = 0;

  SessionData({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distance,
    required this.drowsyAlerts,
    required this.inattentiveAlerts,
    required this.score,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'distance': distance,
      'drowsy_alerts': drowsyAlerts,
      'inattentive_alerts': inattentiveAlerts,
      'score': score,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  SessionData.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    startTime = map['start_time'];
    endTime = map['end_time'];
    duration = map['duration'];
    distance = map['distance'];
    drowsyAlerts = map['drowsy_alerts'];
    inattentiveAlerts = map['inattentive_alerts'];
    score = map['score'];
  }
}

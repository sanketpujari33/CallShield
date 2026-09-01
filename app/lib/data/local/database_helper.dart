import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/rule_models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('callshield.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spam_numbers (
        number TEXT PRIMARY KEY,
        type TEXT,
        reports INTEGER DEFAULT 1,
        description TEXT,
        first_seen TEXT,
        last_seen TEXT,
        sources TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_spam_numbers_number ON spam_numbers(number)');

    await db.execute('''
      CREATE TABLE blocklist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT UNIQUE,
        note TEXT,
        created_at TEXT,
        expires_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE whitelist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT UNIQUE,
        note TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE wildcard_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pattern TEXT,
        is_regex INTEGER DEFAULT 0,
        note TEXT,
        enabled INTEGER DEFAULT 1,
        days_mask INTEGER DEFAULT 0,
        start_hour INTEGER DEFAULT 0,
        start_minute INTEGER DEFAULT 0,
        end_hour INTEGER DEFAULT 23,
        end_minute INTEGER DEFAULT 59
      )
    ''');

    await db.execute('''
      CREATE TABLE range_patterns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pattern TEXT,
        note TEXT,
        enabled INTEGER DEFAULT 1,
        days_mask INTEGER DEFAULT 0,
        start_hour INTEGER DEFAULT 0,
        start_minute INTEGER DEFAULT 0,
        end_hour INTEGER DEFAULT 23,
        end_minute INTEGER DEFAULT 59
      )
    ''');

    await db.execute('''
      CREATE TABLE sms_keywords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        keyword TEXT,
        case_sensitive INTEGER DEFAULT 0,
        note TEXT,
        enabled INTEGER DEFAULT 1,
        days_mask INTEGER DEFAULT 0,
        start_hour INTEGER DEFAULT 0,
        start_minute INTEGER DEFAULT 0,
        end_hour INTEGER DEFAULT 23,
        end_minute INTEGER DEFAULT 59
      )
    ''');

    await db.execute('''
      CREATE TABLE call_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT,
        caller_name TEXT,
        timestamp TEXT,
        is_blocked INTEGER,
        reason_code TEXT,
        match_source TEXT,
        description TEXT,
        confidence INTEGER,
        score REAL,
        category TEXT,
        is_sms INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_call_logs_timestamp ON call_logs(timestamp DESC)');

    await db.execute('''
      CREATE TABLE campaign_observations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        npa_nxx TEXT,
        timestamp TEXT,
        number TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_campaign_npanxx ON campaign_observations(npa_nxx, timestamp)');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // ── Spam Numbers Operations ──
  Future<Map<String, dynamic>?> lookupSpamNumber(String number) async {
    final db = await database;
    final res = await db.query(
      'spam_numbers',
      where: 'number = ?',
      whereArgs: [number],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> batchInsertSpamNumbers(List<Map<String, dynamic>> rows) async {
    final db = await database;
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(
        'spam_numbers',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> getSpamNumberCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM spam_numbers');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // ── Blocklist Operations ──
  Future<List<BlocklistEntry>> getBlocklist() async {
    final db = await database;
    final res = await db.query('blocklist', orderBy: 'id DESC');
    return res.map((m) => BlocklistEntry.fromMap(m)).toList();
  }

  Future<int> addBlocklistEntry(BlocklistEntry entry) async {
    final db = await database;
    return await db.insert('blocklist', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> removeBlocklistEntry(int id) async {
    final db = await database;
    return await db.delete('blocklist', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isNumberInBlocklist(String number) async {
    final db = await database;
    final res = await db.query(
      'blocklist',
      where: 'number = ?',
      whereArgs: [number],
      limit: 1,
    );
    if (res.isEmpty) return false;
    final entry = BlocklistEntry.fromMap(res.first);
    if (entry.isExpired) {
      await removeBlocklistEntry(entry.id!);
      return false;
    }
    return true;
  }

  // ── Whitelist Operations ──
  Future<List<WhitelistEntry>> getWhitelist() async {
    final db = await database;
    final res = await db.query('whitelist', orderBy: 'id DESC');
    return res.map((m) => WhitelistEntry.fromMap(m)).toList();
  }

  Future<int> addWhitelistEntry(WhitelistEntry entry) async {
    final db = await database;
    return await db.insert('whitelist', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> removeWhitelistEntry(int id) async {
    final db = await database;
    return await db.delete('whitelist', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isNumberInWhitelist(String number) async {
    final db = await database;
    final res = await db.query(
      'whitelist',
      where: 'number = ?',
      whereArgs: [number],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  // ── Wildcard Rules Operations ──
  Future<List<WildcardRule>> getWildcardRules() async {
    final db = await database;
    final res = await db.query('wildcard_rules', orderBy: 'id DESC');
    return res.map((m) => WildcardRule.fromMap(m)).toList();
  }

  Future<int> addWildcardRule(WildcardRule rule) async {
    final db = await database;
    return await db.insert('wildcard_rules', rule.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateWildcardRule(WildcardRule rule) async {
    final db = await database;
    return await db.update('wildcard_rules', rule.toMap(), where: 'id = ?', whereArgs: [rule.id]);
  }

  Future<int> removeWildcardRule(int id) async {
    final db = await database;
    return await db.delete('wildcard_rules', where: 'id = ?', whereArgs: [id]);
  }

  // ── Range Patterns Operations ──
  Future<List<RangePattern>> getRangePatterns() async {
    final db = await database;
    final res = await db.query('range_patterns', orderBy: 'id DESC');
    return res.map((m) => RangePattern.fromMap(m)).toList();
  }

  Future<int> addRangePattern(RangePattern pattern) async {
    final db = await database;
    return await db.insert('range_patterns', pattern.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateRangePattern(RangePattern pattern) async {
    final db = await database;
    return await db.update('range_patterns', pattern.toMap(), where: 'id = ?', whereArgs: [pattern.id]);
  }

  Future<int> removeRangePattern(int id) async {
    final db = await database;
    return await db.delete('range_patterns', where: 'id = ?', whereArgs: [id]);
  }

  // ── SMS Keyword Rules Operations ──
  Future<List<SmsKeywordRule>> getSmsKeywords() async {
    final db = await database;
    final res = await db.query('sms_keywords', orderBy: 'id DESC');
    return res.map((m) => SmsKeywordRule.fromMap(m)).toList();
  }

  Future<int> addSmsKeyword(SmsKeywordRule rule) async {
    final db = await database;
    return await db.insert('sms_keywords', rule.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSmsKeyword(SmsKeywordRule rule) async {
    final db = await database;
    return await db.update('sms_keywords', rule.toMap(), where: 'id = ?', whereArgs: [rule.id]);
  }

  Future<int> removeSmsKeyword(int id) async {
    final db = await database;
    return await db.delete('sms_keywords', where: 'id = ?', whereArgs: [id]);
  }

  // ── Call Logs Operations ──
  Future<List<CallLogRecord>> getCallLogs({int limit = 100, bool? blockedOnly, bool? isSms}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (blockedOnly != null || isSms != null) {
      final conditions = <String>[];
      final args = <dynamic>[];
      if (blockedOnly != null) {
        conditions.add('is_blocked = ?');
        args.add(blockedOnly ? 1 : 0);
      }
      if (isSms != null) {
        conditions.add('is_sms = ?');
        args.add(isSms ? 1 : 0);
      }
      where = conditions.join(' AND ');
      whereArgs = args;
    }

    final res = await db.query(
      'call_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return res.map((m) => CallLogRecord.fromMap(m)).toList();
  }

  Future<int> addCallLog(CallLogRecord record) async {
    final db = await database;
    return await db.insert('call_logs', record.toMap());
  }

  Future<int> getWeeklyBlockedCount() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM call_logs WHERE is_blocked = 1 AND timestamp >= ?',
      [sevenDaysAgo],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getWeeklyTextBlockedCount() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM call_logs WHERE is_blocked = 1 AND is_sms = 1 AND timestamp >= ?',
      [sevenDaysAgo],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> clearAllLogs() async {
    final db = await database;
    await db.delete('call_logs');
  }

  // ── Settings KV ──
  Future<String?> getSetting(String key) async {
    final db = await database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    return res.isNotEmpty ? res.first['value'] as String? : null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

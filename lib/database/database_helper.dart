import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finance.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        date INTEGER NOT NULL,
        type INTEGER NOT NULL
      )
    ''');

    // Insert sample data for demo
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Sample income data
    await db.insert('transactions', {
      'id': '1',
      'amount': 5000000.0,
      'category': 'Gaji',
      'description': 'Gaji bulan Januari',
      'date': DateTime.now().subtract(Duration(days: 2)).millisecondsSinceEpoch,
      'type': 1,
    });

    // Sample expense data
    await db.insert('transactions', {
      'id': '2',
      'amount': 150000.0,
      'category': 'Makanan',
      'description': 'Makan siang',
      'date': DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch,
      'type': 0,
    });

    await db.insert('transactions', {
      'id': '3',
      'amount': 200000.0,
      'category': 'Transportasi',
      'description': 'Bensin motor',
      'date': DateTime.now().millisecondsSinceEpoch,
      'type': 0,
    });

    await db.insert('transactions', {
      'id': '4',
      'amount': 1000000.0,
      'category': 'Bonus',
      'description': 'Bonus project',
      'date': DateTime.now().subtract(Duration(days: 3)).millisecondsSinceEpoch,
      'type': 1,
    });
  }

  // Insert transaction
  Future<void> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all transactions
  Future<List<model.Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update transaction
  Future<void> updateTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Get transactions by date range
  Future<List<model.Transaction>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  // Get total income/expense for a period
  Future<double> getTotalByType(model.TransactionType type, DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM transactions 
      WHERE type = ? AND date BETWEEN ? AND ?
    ''', [type == model.TransactionType.income ? 1 : 0, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);

    final total = result.first['total'];
    if (total != null) {
      return (total as num).toDouble();
    }
    return 0.0;
  }
}
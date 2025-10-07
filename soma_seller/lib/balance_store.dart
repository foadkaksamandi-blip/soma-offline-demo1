import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/transaction.dart';
import 'package:uuid/uuid.dart';

class BalanceStore {
  static Database? _database;
  final encrypt.Encrypter _encrypter;
  final encrypt.IV _iv;

  BalanceStore() : _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromLength(32))), // کلید 256-bit (تست، واقعی امن‌تر کن)
        _iv = encrypt.IV.fromLength(16);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'soma_balance.db');
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE balance(id INTEGER PRIMARY KEY, amount REAL)
    ''');
    await db.execute('''
      CREATE TABLE transactions(id INTEGER PRIMARY KEY, txnId TEXT, amount REAL, timestamp TEXT, type TEXT, counterpart TEXT)
    ''');
    // موجودی اولیه: 1000
    await db.insert('balance', {'amount': 1000.0});
  }

  Future<double> getBalance() async {
    final db = await database;
    final result = await db.query('balance');
    return result.first['amount'] as double;
  }

  Future<void> updateBalance(double newBalance) async {
    final db = await database;
    await db.update('balance', {'amount': newBalance});
  }

  Future<void> addTransaction(Transaction txn) async {
    final db = await database;
    final encryptedData = _encrypt(jsonEncode(txn.toMap()));
    await db.insert('transactions', {
      'txnId': txn.txnId,
      'amount': txn.amount,
      'timestamp': txn.timestamp.toIso8601String(),
      'type': txn.type,
      'counterpart': txn.counterpart,
    });
  }

  Future<List<Transaction>> getHistory() async {
    final db = await database;
    final maps = await db.query('transactions');
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  String _encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String _decrypt(String encryptedText) {
    final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}

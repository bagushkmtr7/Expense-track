import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aurelia_expense_pro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        pin TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0,
        color_hex INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_hex INTEGER NOT NULL,
        budget_limit REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        wallet TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        created_by TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        detail TEXT NOT NULL,
        actor TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // Default Users (Admin PIN: 1234, Staff PIN: 0000)
    await db.insert('users', {
      'username': 'Admin Utama',
      'pin': '1234',
      'role': 'admin',
      'is_active': 1,
    });
    await db.insert('users', {
      'username': 'Staff Operasional',
      'pin': '0000',
      'role': 'staff',
      'is_active': 1,
    });

    // Default Wallets
    await db.insert('wallets', {
      'name': 'Dompet Tunai',
      'initial_balance': 750000.0,
      'color_hex': 0xFF10B981,
    });
    await db.insert('wallets', {
      'name': 'Rekening BCA',
      'initial_balance': 5500000.0,
      'color_hex': 0xFF3B82F6,
    });
    await db.insert('wallets', {
      'name': 'E-Wallet (GoPay/OVO)',
      'initial_balance': 1250000.0,
      'color_hex': 0xFF8B5CF6,
    });

    // Default Categories
    final defaultCategories = [
      {'name': 'Makan & Minum', 'type': 'expense', 'icon_code': 1, 'color_hex': 0xFFF59E0B, 'budget_limit': 2500000.0},
      {'name': 'Transportasi & BBM', 'type': 'expense', 'icon_code': 2, 'color_hex': 0xFF3B82F6, 'budget_limit': 1200000.0},
      {'name': 'Belanja & Kebutuhan', 'type': 'expense', 'icon_code': 3, 'color_hex': 0xFFEC4899, 'budget_limit': 2000000.0},
      {'name': 'Tagihan & Internet', 'type': 'expense', 'icon_code': 4, 'color_hex': 0xFFF43F5E, 'budget_limit': 1500000.0},
      {'name': 'Hiburan & Langganan', 'type': 'expense', 'icon_code': 5, 'color_hex': 0xFF8B5CF6, 'budget_limit': 800000.0},
      {'name': 'Gaji & Pendapatan', 'type': 'income', 'icon_code': 6, 'color_hex': 0xFF10B981, 'budget_limit': 0.0},
      {'name': 'Bonus & Proyek', 'type': 'income', 'icon_code': 7, 'color_hex': 0xFFF59E0B, 'budget_limit': 0.0},
      {'name': 'Investasi & Dividen', 'type': 'income', 'icon_code': 8, 'color_hex': 0xFF06B6D4, 'budget_limit': 0.0},
    ];
    for (final cat in defaultCategories) {
      await db.insert('categories', cat);
    }

    final now = DateTime.now();
    await db.insert('transactions', {
      'title': 'Gaji Bulanan Utama',
      'amount': 8500000.0,
      'type': 'income',
      'category': 'Gaji & Pendapatan',
      'wallet': 'Rekening BCA',
      'note': 'Transfer payroll bulanan',
      'date': now.subtract(const Duration(days: 2)).toIso8601String(),
      'created_by': 'Admin Utama',
    });
    await db.insert('transactions', {
      'title': 'Makan Siang & Kopi',
      'amount': 85000.0,
      'type': 'expense',
      'category': 'Makan & Minum',
      'wallet': 'E-Wallet (GoPay/OVO)',
      'note': 'Meeting klien siang',
      'date': now.subtract(const Duration(hours: 5)).toIso8601String(),
      'created_by': 'Admin Utama',
    });
    await db.insert('transactions', {
      'title': 'Isi BBM Full Tank',
      'amount': 150000.0,
      'type': 'expense',
      'category': 'Transportasi & BBM',
      'wallet': 'Dompet Tunai',
      'note': 'Pertamax',
      'date': now.subtract(const Duration(hours: 2)).toIso8601String(),
      'created_by': 'Admin Utama',
    });

    await db.insert('audit_logs', {
      'action': 'INIT_SYSTEM',
      'detail': 'Database SQLite diinisialisasi dengan konfigurasi default',
      'actor': 'SYSTEM',
      'timestamp': now.toIso8601String(),
    });
  }

  Future<void> logAction(String action, String detail, String actor) async {
    final db = await database;
    await db.insert('audit_logs', {
      'action': action,
      'detail': detail,
      'actor': actor,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // --- DASHBOARD & ANALYTICS ---
  Future> getDashboardSummary() async {
    final db = await database;
    final wallets = await db.query('wallets');
    final transactions = await db.query('transactions');
    final categories = await db.query('categories', where: 'type = ?', whereArgs: ['expense']);

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> walletDelta = {};
    final Map<String, double> categoryExpenseMap = {};

    for (final tx in transactions) {
      final amt = (tx['amount'] as num).toDouble();
      final type = tx['type'] as String;
      final wallet = tx['wallet'] as String;
      final category = tx['category'] as String;

      if (type == 'income') {
        totalIncome += amt;
        walletDelta[wallet] = (walletDelta[wallet] ?? 0) + amt;
      } else {
        totalExpense += amt;
        walletDelta[wallet] = (walletDelta[wallet] ?? 0) - amt;
        categoryExpenseMap[category] = (categoryExpenseMap[category] ?? 0) + amt;
      }
    }

    double totalInitialWallet = 0;
    final List> walletBalances = [];
    for (final w in wallets) {
      final name = w['name'] as String;
      final initial = (w['initial_balance'] as num).toDouble();
      totalInitialWallet += initial;
      walletBalances.add({
        ...w,
        'current_balance': initial + (walletDelta[name] ?? 0),
      });
    }

    double totalBudget = 0;
    final List> categoryBreakdown = [];
    for (final cat in categories) {
      final name = cat['name'] as String;
      final limit = (cat['budget_limit'] as num).toDouble();
      final spent = categoryExpenseMap[name] ?? 0.0;
      totalBudget += limit;
      categoryBreakdown.add({
        ...cat,
        'spent': spent,
      });
    }

    categoryBreakdown.sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double));

    return {
      'total_balance': totalInitialWallet + totalIncome - totalExpense,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'total_budget': totalBudget,
      'wallets': walletBalances,
      'category_breakdown': categoryBreakdown,
    };
  }

  // --- TRANSACTIONS CRUD ---
  Future<List>> getTransactions({
    String query = '',
    String typeFilter = 'all',
  }) async {
    final db = await database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (typeFilter != 'all') {
      whereClauses.add('type = ?');
      whereArgs.add(typeFilter);
    }
    if (query.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR category LIKE ? OR note LIKE ? OR wallet LIKE ?)');
      final q = '%${query.trim()}%';
      whereArgs.addAll([q, q, q, q]);
    }

    return await db.query(
      'transactions',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<void> insertTransaction(Map<String, dynamic> data, String actor) async {
    final db = await database;
    await db.insert('transactions', data);
    await logAction(
      'CREATE_TX',
      'Menambah ${data['type'] == 'income' ? 'Pemasukan' : 'Pengeluaran'}: ${data['title']} (${data['amount']})',
      actor,
    );
  }

  Future<void> updateTransaction(int id, Map<String, dynamic> data, String actor) async {
    final db = await database;
    await db.update('transactions', data, where: 'id = ?', whereArgs: [id]);
    await logAction(
      'UPDATE_TX',
      'Mengubah transaksi #$id: ${data['title']} (${data['amount']})',
      actor,
    );
  }

  Future<void> deleteTransaction(int id, String title, String actor) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    await logAction('DELETE_TX', 'Menghapus transaksi #$id ($title)', actor);
  }

  // --- ADMIN: CATEGORIES ---
  Future<List>> getCategories({String? type}) async {
    final db = await database;
    if (type != null) {
      return await db.query('categories', where: 'type = ?', whereArgs: [type], orderBy: 'id ASC');
    }
    return await db.query('categories', orderBy: 'type DESC, id ASC');
  }

  Future<void> insertCategory(Map<String, dynamic> data, String actor) async {
    final db = await database;
    await db.insert('categories', data);
    await logAction('ADD_CATEGORY', 'Menambah kategori: ${data['name']} (${data['type']})', actor);
  }

  Future<void> updateCategoryBudget(int id, String name, double budget, String actor) async {
    final db = await database;
    await db.update('categories', {'budget_limit': budget}, where: 'id = ?', whereArgs: [id]);
    await logAction('UPDATE_BUDGET', 'Mengubah limit anggaran $name menjadi$budget', actor);
  }

  Future<void> deleteCategory(int id, String name, String actor) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await logAction('DELETE_CATEGORY', 'Menghapus kategori: $name', actor);
  }

  // --- ADMIN: WALLETS ---
  Future<List>> getWallets() async {
    final db = await database;
    return await db.query('wallets', orderBy: 'id ASC');
  }

  Future<void> insertWallet(Map<String, dynamic> data, String actor) async {
    final db = await database;
    await db.insert('wallets', data);
    await logAction('ADD_WALLET', 'Menambah dompet: ${data['name']}', actor);
  }

  Future<void> deleteWallet(int id, String name, String actor) async {
    final db = await database;
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
    await logAction('DELETE_WALLET', 'Menghapus dompet: $name', actor);
  }

  // --- ADMIN: USERS & RBAC ---
  Future<List>> getUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'id ASC');
  }

  Future<void> insertUser(Map<String, dynamic> data, String actor) async {
    final db = await database;
    await db.insert('users', data);
    await logAction('ADD_USER', 'Menambah akun ${data['username']} (${data['role']})', actor);
  }

  Future<void> updateUserPin(int id, String username, String newPin, String actor) async {
    final db = await database;
    await db.update('users', {'pin': newPin}, where: 'id = ?', whereArgs: [id]);
    await logAction('CHANGE_PIN', 'Mengubah PIN akses untuk $username', actor);
  }

  Future<void> toggleUserStatus(int id, String username, int newStatus, String actor) async {
    final db = await database;
    await db.update('users', {'is_active': newStatus}, where: 'id = ?', whereArgs: [id]);
    await logAction(
      'USER_STATUS',
      '${newStatus == 1 ? 'Mengaktifkan' : 'Menonaktifkan'} akun$username',
      actor,
    );
  }

  // --- ADMIN: AUDIT LOGS & SQL MAINTENANCE ---
  Future<List>> getAuditLogs() async {
    final db = await database;
    return await db.query('audit_logs', orderBy: 'id DESC', limit: 100);
  }

  Future> getTableStats() async {
    final db = await database;
    final txCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM transactions')) ?? 0;
    final catCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
    final walCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM wallets')) ?? 0;
    final usrCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
    final logCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM audit_logs')) ?? 0;
    return {
      'transactions': txCount,
      'categories': catCount,
      'wallets': walCount,
      'users': usrCount,
      'audit_logs': logCount,
    };
  }

  Future<String> exportFullJsonBackup() async {
    final db = await database;
    final backup = {
      'exported_at': DateTime.now().toIso8601String(),
      'transactions': await db.query('transactions'),
      'categories': await db.query('categories'),
      'wallets': await db.query('wallets'),
      'users': await db.query('users'),
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  Future<void> seedDemoTransactions(String actor) async {
    final db = await database;
    final now = DateTime.now();
    final samples = [
      {'title': 'Pembayaran Proyek Aplikasi', 'amount': 4500000.0, 'type': 'income', 'category': 'Bonus & Proyek', 'wallet': 'Rekening BCA', 'note': 'Termin 1'},
      {'title': 'Belanja Bulanan Supermarket', 'amount': 680000.0, 'type': 'expense', 'category': 'Belanja & Kebutuhan', 'wallet': 'Rekening BCA', 'note': 'Kebutuhan rumah'},
      {'title': 'Tagihan Listrik & WiFi', 'amount': 540000.0, 'type': 'expense', 'category': 'Tagihan & Internet', 'wallet': 'E-Wallet (GoPay/OVO)', 'note': 'Auto debet'},
      {'title': 'Langganan Cloud & Streaming', 'amount': 189000.0, 'type': 'expense', 'category': 'Hiburan & Langganan', 'wallet': 'E-Wallet (GoPay/OVO)', 'note': 'Bulanan'},
      {'title': 'Makan Malam Keluarga', 'amount': 320000.0, 'type': 'expense', 'category': 'Makan & Minum', 'wallet': 'Dompet Tunai', 'note': 'Akhir pekan'},
      {'title': 'Dividen Saham & Reksadana', 'amount': 620000.0, 'type': 'income', 'category': 'Investasi & Dividen', 'wallet': 'Rekening BCA', 'note': 'Imbal hasil'},
    ];
    for (int i = 0; i < samples.length; i++) {
      await db.insert('transactions', {
        ...samples[i],
        'date': now.subtract(Duration(days: i + 1)).toIso8601String(),
        'created_by': actor,
      });
    }
    await logAction('SEED_DEMO', 'Menambahkan 6 transaksi simulasi ke SQLite', actor);
  }

  Future<void> resetAllData(String actor) async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('categories');
    await db.delete('wallets');
    await db.delete('users');
    await db.delete('audit_logs');
    await _seedInitialData(db);
    await logAction('FACTORY_RESET', 'Reset database kembali ke pengaturan pabrik', actor);
  }
}

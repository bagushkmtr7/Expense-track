import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final VoidCallback onDataChanged;

  const AdminScreen({
    super.key,
    required this.currentUser,
    required this.onDataChanged,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _adminVerified = false;
  final _pinController = TextEditingController();
  int _selectedSection = 0;

  List> _categories = [];
  List> _wallets = [];
  List> _users = [];
  List> _auditLogs = [];
  Map<String, int> _tableStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _adminVerified = widget.currentUser['role'] == 'admin';
    _loadAdminData();
  }

  @override
  void didUpdateWidget(covariant AdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser['id'] != widget.currentUser['id']) {
      _adminVerified = widget.currentUser['role'] == 'admin';
    }
  }

  Future<void> _loadAdminData() async {
    setState(() => _loading = true);
    final cats = await DatabaseHelper.instance.getCategories();
    final wals = await DatabaseHelper.instance.getWallets();
    final usrs = await DatabaseHelper.instance.getUsers();
    final logs = await DatabaseHelper.instance.getAuditLogs();
    final stats = await DatabaseHelper.instance.getTableStats();

    if (!mounted) return;
    setState(() {
      _categories = cats;
      _wallets = wals;
      _users = usrs;
      _auditLogs = logs;
      _tableStats = stats;
      _loading = false;
    });
  }

  Future<void> _verifyAdminPin() async {
    final admins = _users.where((u) => u['role'] == 'admin' && u['is_active'] == 1);
    final entered = _pinController.text.trim();
    final valid = admins.any((a) => a['pin'] == entered);
    if (valid) {
      setState(() => _adminVerified = true);
      _pinController.clear();
      await DatabaseHelper.instance.logAction(
        'ADMIN_OVERRIDE',
        'Akses Panel Admin dibuka dengan verifikasi PIN',
        widget.currentUser['username'],
      );
      _loadAdminData();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN Admin salah! (Default Admin PIN: 1234)'),
          backgroundColor: AppTheme.rose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_adminVerified) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.gold, size: 42),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Area Terbatas Administrator',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Anda login sebagai Staff. Masukkan PIN Admin (default: 1234) untuk membuka kontrol sistem & database.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Masukkan PIN Admin',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _verifyAdminPin,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Buka Panel Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    final tabs = ['Kategori', 'Dompet', 'Pengguna', 'Audit Log', 'SQL & Backup'];

    return Column(
      children: [
        // Admin Header Banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security_rounded, color: AppTheme.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADMIN CONTROL CENTER',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SQLite Aktif • ${_tableStats['transactions'] ?? 0} Transaksi • ${_users.length} Akun',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadAdminData,
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.gold),
                tooltip: 'Segarkan Data SQL',
              ),
            ],
          ),
        ),

        // Sub-navigation Pills
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final active = _selectedSection == index;
              return ChoiceChip(
                label: Text(tabs[index]),
                selected: active,
                selectedColor: AppTheme.gold,
                backgroundColor: AppTheme.cardDark,
                labelStyle: TextStyle(
                  color: active ? Colors.black : AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => _selectedSection = index),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: IndexedStack(
            index: _selectedSection,
            children: [
              _buildCategoriesSection(),
              _buildWalletsSection(),
              _buildUsersSection(),
              _buildAuditLogsSection(),
              _buildSqlMaintenanceSection(),
            ],
          ),
        ),
      ],
    );
  }

  // 1. KATEGORI & BUDGET
  Widget _buildCategoriesSection() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _showAddCategoryDialog,
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Tambah Kategori & Limit Anggaran', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        ..._categories.map((cat) {
          final isExpense = cat['type'] == 'expense';
          final limit = (cat['budget_limit'] as num).toDouble();
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(cat['color_hex'] as int).withValues(alpha: 0.2),
                child: Icon(
                  AppTheme.getIcon(cat['icon_code'] as int?),
                  color: Color(cat['color_hex'] as int),
                  size: 20,
                ),
              ),
              title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                isExpense
                    ? 'Pengeluaran • Limit: ${limit > 0 ? AppFormatters.rupiah(limit) : 'Tanpa Batas'}'
                    : 'Kategori Pemasukan',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isExpense)
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: AppTheme.gold, size: 20),
                      tooltip: 'Atur Limit Budget',
                      onPressed: () => _showEditBudgetDialog(cat),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.rose, size: 20),
                    onPressed: () async {
                      await DatabaseHelper.instance.deleteCategory(
                        cat['id'],
                        cat['name'],
                        widget.currentUser['username'],
                      );
                      _loadAdminData();
                      widget.onDataChanged();
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController(text: '1000000');
    String type = 'expense';
    int selectedIcon = 1;
    int selectedColor = 0xFFF59E0B;

    final colors = [0xFFF59E0B, 0xFF10B981, 0xFF3B82F6, 0xFFEC4899, 0xFF8B5CF6, 0xFFF43F5E];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Kategori Baru', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Kategori'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                    ButtonSegment(value: 'income', label: Text('Pemasukan')),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setDialogState(() => type = v.first),
                ),
                if (type == 'expense') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Batas Anggaran Bulanan (Rp)'),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: colors.map((c) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(c),
                        child: selectedColor == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppTheme.categoryIcons.entries.map((entry) {
                    final isSel = selectedIcon == entry.key;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedIcon = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.gold : AppTheme.cardElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(entry.value, size: 20, color: isSel ? Colors.black : Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await DatabaseHelper.instance.insertCategory({
                  'name': nameCtrl.text.trim(),
                  'type': type,
                  'icon_code': selectedIcon,
                  'color_hex': selectedColor,
                  'budget_limit': type == 'expense' ? (double.tryParse(budgetCtrl.text) ?? 0) : 0,
                }, widget.currentUser['username']);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadAdminData();
                widget.onDataChanged();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog(Map<String, dynamic> cat) {
    final ctrl = TextEditingController(text: (cat['budget_limit'] as num).toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Budget: ${cat['name']}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Limit Anggaran (Rp)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
            onPressed: () async {
              final val = double.tryParse(ctrl.text) ?? 0;
              await DatabaseHelper.instance.updateCategoryBudget(
                cat['id'],
                cat['name'],
                val,
                widget.currentUser['username'],
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadAdminData();
              widget.onDataChanged();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // 2. DOMPET & REKENING
  Widget _buildWalletsSection() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emerald,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _showAddWalletDialog,
          icon: const Icon(Icons.account_balance_wallet_rounded),
          label: const Text('Tambah Dompet / Rekening Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        ..._wallets.map((w) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(w['color_hex'] as int).withValues(alpha: 0.2),
                child: Icon(Icons.wallet_rounded, color: Color(w['color_hex'] as int)),
              ),
              title: Text(w['name'], style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                'Saldo Awal: ${AppFormatters.rupiah(w['initial_balance'])}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              trailing: _wallets.length > 1
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.rose),
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteWallet(
                          w['id'],
                          w['name'],
                          widget.currentUser['username'],
                        );
                        _loadAdminData();
                        widget.onDataChanged();
                      },
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  void _showAddWalletDialog() {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Dompet / Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Dompet (misal: Bank Mandiri)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Saldo Awal (Rp)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.black),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await DatabaseHelper.instance.insertWallet({
                'name': nameCtrl.text.trim(),
                'initial_balance': double.tryParse(balCtrl.text) ?? 0,
                'color_hex': 0xFF06B6D4,
              }, widget.currentUser['username']);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadAdminData();
              widget.onDataChanged();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // 3. MANAJEMEN PENGGUNA & PIN
  Widget _buildUsersSection() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _showAddUserDialog,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Tambah User (Admin / Staff)', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        ..._users.map((u) {
          final isAdmin = u['role'] == 'admin';
          final isActive = u['is_active'] == 1;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isAdmin ? AppTheme.gold : AppTheme.emerald).withValues(alpha: 0.2),
                child: Icon(
                  isAdmin ? Icons.verified_user_rounded : Icons.badge_rounded,
                  color: isAdmin ? AppTheme.gold : AppTheme.emerald,
                ),
              ),
              title: Row(
                children: [
                  Text(u['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isAdmin ? AppTheme.gold : AppTheme.emerald).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAdmin ? 'ADMIN' : 'STAFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isAdmin ? AppTheme.gold : AppTheme.emerald,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'PIN: •••• • Status: ${isActive ? 'Aktif' : 'Nonaktif'}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.password_rounded, color: AppTheme.gold, size: 20),
                    tooltip: 'Ganti PIN',
                    onPressed: () => _showChangePinDialog(u),
                  ),
                  if (u['id'] != 1)
                    Switch(
                      value: isActive,
                      activeColor: AppTheme.emerald,
                      onChanged: (val) async {
                        await DatabaseHelper.instance.toggleUserStatus(
                          u['id'],
                          u['username'],
                          val ? 1 : 0,
                          widget.currentUser['username'],
                        );
                        _loadAdminData();
                      },
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    String role = 'staff';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Akun Pengguna'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'PIN Akses (4-6 digit)', counterText: ''),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'staff', label: Text('Staff / Kasir')),
                  ButtonSegment(value: 'admin', label: Text('Administrator')),
                ],
                selected: {role},
                onSelectionChanged: (v) => setDialogState(() => role = v.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || pinCtrl.text.trim().length < 4) return;
                await DatabaseHelper.instance.insertUser({
                  'username': nameCtrl.text.trim(),
                  'pin': pinCtrl.text.trim(),
                  'role': role,
                  'is_active': 1,
                }, widget.currentUser['username']);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadAdminData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog(Map<String, dynamic> user) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ganti PIN: ${user['username']}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'PIN Baru (min. 4 angka)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
            onPressed: () async {
              if (ctrl.text.trim().length < 4) return;
              await DatabaseHelper.instance.updateUserPin(
                user['id'],
                user['username'],
                ctrl.text.trim(),
                widget.currentUser['username'],
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadAdminData();
            },
            child: const Text('Simpan PIN'),
          ),
        ],
      ),
    );
  }

  // 4. AUDIT LOG KEAMANAN
  Widget _buildAuditLogsSection() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      itemCount: _auditLogs.length,
      itemBuilder: (context, idx) {
        final log = _auditLogs[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log['action'],
                        style: const TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      log['actor'],
                      style: const TextStyle(color: AppTheme.emerald, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(log['detail'], style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatDate(log['timestamp']),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 5. SQL MAINTENANCE & BACKUP
  Widget _buildSqlMaintenanceSection() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATISTIK TABEL DATABASE SQLITE',
                  style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                ..._tableStats.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tabel `${e.key}`', style: const TextStyle(color: AppTheme.textSecondary)),
                          Text('${e.value} baris', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          tileColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: const Icon(Icons.copy_all_rounded, color: AppTheme.emerald),
          title: const Text('Salin Backup Full Database (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Menyalin seluruh isi SQLite ke clipboard untuk disimpan aman'),
          onTap: () async {
            final jsonStr = await DatabaseHelper.instance.exportFullJsonBackup();
            await Clipboard.setData(ClipboardData(text: jsonStr));
            await DatabaseHelper.instance.logAction('EXPORT_BACKUP', 'Export backup JSON SQLite', widget.currentUser['username']);
            _loadAdminData();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup JSON SQLite berhasil disalin ke Clipboard!')),
            );
          },
        ),
        const SizedBox(height: 10),
        ListTile(
          tileColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: const Icon(Icons.auto_awesome_rounded, color: AppTheme.gold),
          title: const Text('Generate 6 Transaksi Simulasi', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Isi data contoh otomatis untuk menguji grafik & laporan'),
          onTap: () async {
            await DatabaseHelper.instance.seedDemoTransactions(widget.currentUser['username']);
            _loadAdminData();
            widget.onDataChanged();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('6 transaksi simulasi berhasil ditambahkan ke SQLite!')),
            );
          },
        ),
        const SizedBox(height: 10),
        ListTile(
          tileColor: AppTheme.rose.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.rose.withValues(alpha: 0.4)),
          ),
          leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.rose),
          title: const Text('Factory Reset Database SQLite', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.rose)),
          subtitle: const Text('Hapus semua data dan kembalikan ke pengaturan awal'),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Konfirmasi Reset Database'),
                content: const Text('Seluruh transaksi, dompet custom, dan log akan dihapus permanen. Lanjutkan?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Reset Sekarang', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await DatabaseHelper.instance.resetAllData(widget.currentUser['username']);
              _loadAdminData();
              widget.onDataChanged();
            }
          },
        ),
      ],
    );
  }
}

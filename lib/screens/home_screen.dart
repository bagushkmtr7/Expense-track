import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/luxury_charts.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final ValueChanged> onSwitchUser;
  final VoidCallback onLockApp;

  const HomeScreen({
    super.key,
    required this.currentUser,
    required this.onSwitchUser,
    required this.onLockApp,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  bool _loading = true;

  Map<String, dynamic> _summary = {};
  List> _transactions = [];
  List> _allCategories = [];
  List> _wallets = [];

  String _searchQuery = '';
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _loading = true);
    final summary = await DatabaseHelper.instance.getDashboardSummary();
    final txs = await DatabaseHelper.instance.getTransactions(
      query: _searchQuery,
      typeFilter: _typeFilter,
    );
    final cats = await DatabaseHelper.instance.getCategories();
    final wals = await DatabaseHelper.instance.getWallets();

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _transactions = txs;
      _allCategories = cats;
      _wallets = wals;
      _loading = false;
    });
  }

  Future<void> _showUserSwitcher() async {
    final users = await DatabaseHelper.instance.getUsers();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ganti Akun Pengguna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...users.where((u) => u['is_active'] == 1).map((u) {
              final isCurrent = u['id'] == widget.currentUser['id'];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (u['role'] == 'admin' ? AppTheme.gold : AppTheme.emerald).withValues(alpha: 0.2),
                  child: Icon(
                    u['role'] == 'admin' ? Icons.verified_user_rounded : Icons.person_rounded,
                    color: u['role'] == 'admin' ? AppTheme.gold : AppTheme.emerald,
                  ),
                ),
                title: Text(u['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Role: ${u['role'].toString().toUpperCase()}'),
                trailing: isCurrent ? const Icon(Icons.check_circle, color: AppTheme.gold) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onSwitchUser(u);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser['role'] == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.gold, Color(0xFFD97706)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.diamond_rounded, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('AURELIA FINANCE'),
          ],
        ),
        actions: [
          InkWell(
            onTap: _showUserSwitcher,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isAdmin ? AppTheme.gold.withValues(alpha: 0.5) : AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(
                    isAdmin ? Icons.verified_user_rounded : Icons.person_rounded,
                    size: 14,
                    color: isAdmin ? AppTheme.gold : AppTheme.emerald,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.currentUser['username'].toString().split(' ').first,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onLockApp,
            icon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary, size: 20),
            tooltip: 'Kunci Layar PIN',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : IndexedStack(
              index: _navIndex,
              children: [
                _buildDashboardTab(),
                _buildTransactionsTab(),
                _buildAnalyticsTab(),
                AdminScreen(
                  currentUser: widget.currentUser,
                  onDataChanged: _refreshAll,
                ),
              ],
            ),
      floatingActionButton: _navIndex != 3
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
              onPressed: () => _openTransactionSheet(),
              icon: const Icon(Icons.add_rounded, fontWeight: FontWeight.bold),
              label: const Text('Catat', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.cardDark,
        indicatorColor: AppTheme.gold.withValues(alpha: 0.2),
        selectedIndex: _navIndex,
        onDestinationSelected: (idx) => setState(() => _navIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.gold),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.gold),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded, color: AppTheme.gold),
            label: 'Analitik',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded, color: AppTheme.gold),
            label: 'Admin',
          ),
        ],
      ),
    );
  }

  // TAB 1: BERANDA MEWAH
  Widget _buildDashboardTab() {
    final totalBalance = (_summary['total_balance'] as num?)?.toDouble() ?? 0;
    final totalIncome = (_summary['total_income'] as num?)?.toDouble() ?? 0;
    final totalExpense = (_summary['total_expense'] as num?)?.toDouble() ?? 0;
    final totalBudget = (_summary['total_budget'] as num?)?.toDouble() ?? 0;
    final walletList = (_summary['wallets'] as List>?) ?? [];

    final budgetRatio = totalBudget > 0 ? (totalExpense / totalBudget).clamp(0.0, 1.0) : 0.0;

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 95),
        children: [
          // Executive Balance Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F2937), Color(0xFF111827), Color(0xFF090D16)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.45), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL KEKAYAAN BERSIH',
                      style: TextStyle(
                        color: AppTheme.goldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SQLITE LIVE',
                        style: TextStyle(color: AppTheme.emerald, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  AppFormatters.rupiah(totalBalance),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatMiniBox(
                        label: 'Pemasukan',
                        amount: totalIncome,
                        icon: Icons.arrow_downward_rounded,
                        color: AppTheme.emerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatMiniBox(
                        label: 'Pengeluaran',
                        amount: totalExpense,
                        icon: Icons.arrow_upward_rounded,
                        color: AppTheme.rose,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Multi-Wallet Horizontal Section
          const Text(
            'DOMPET & REKENING',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: walletList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final w = walletList[idx];
                final color = Color(w['color_hex'] as int);
                final bal = (w['current_balance'] as num).toDouble();
                return Container(
                  width: 175,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: color, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              w['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        AppFormatters.rupiah(bal),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: bal >= 0 ? Colors.white : AppTheme.rose,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Monthly Budget Progress
          if (totalBudget > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Penyerapan Anggaran', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${(budgetRatio * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: budgetRatio > 0.85 ? AppTheme.rose : AppTheme.gold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: budgetRatio,
                        minHeight: 8,
                        backgroundColor: AppTheme.cardElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          budgetRatio > 0.85 ? AppTheme.rose : AppTheme.gold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Terpakai ${AppFormatters.rupiah(totalExpense)} dari total limit ${AppFormatters.rupiah(totalBudget)}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Recent Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TRANSAKSI TERBARU',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
              ),
              TextButton(
                onPressed: () => setState(() => _navIndex = 1),
                child: const Text('Lihat Semua', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
              ),
            ],
          ),
          if (_transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Belum ada transaksi tercatat.', style: TextStyle(color: AppTheme.textSecondary))),
            )
          else
            ..._transactions.take(6).map((tx) => _buildTransactionCard(tx)),
        ],
      ),
    );
  }

  Widget _buildStatMiniBox({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.compactRupiah(amount),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: DAFTAR TRANSAKSI & PENCARIAN
  Widget _buildTransactionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Cari judul, kategori, dompet, catatan...',
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.gold),
            ),
            onChanged: (val) {
              _searchQuery = val;
              _refreshAll();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _filterChip('Semua', 'all'),
              const SizedBox(width: 8),
              _filterChip('Pemasukan', 'income'),
              const SizedBox(width: 8),
              _filterChip('Pengeluaran', 'expense'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _transactions.isEmpty
              ? const Center(child: Text('Tidak ada transaksi ditemukan', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 95),
                  itemCount: _transactions.length,
                  itemBuilder: (context, idx) => _buildTransactionCard(_transactions[idx]),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _typeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      selectedColor: AppTheme.gold,
      backgroundColor: AppTheme.cardDark,
      labelStyle: TextStyle(
        color: active ? Colors.black : AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      onSelected: (_) {
        _typeFilter = value;
        _refreshAll();
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final isIncome = tx['type'] == 'income';
    final amount = (tx['amount'] as num).toDouble();
    final color = isIncome ? AppTheme.emerald : AppTheme.rose;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openTransactionSheet(existingTx: tx),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['title'],
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tx['category']} • ${tx['wallet']}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    Text(
                      '${AppFormatters.formatDate(tx['date'])} • oleh ${tx['created_by']}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} ${AppFormatters.rupiah(amount)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _confirmDeleteTx(tx),
                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTx(Map<String, dynamic> tx) async {
    if (widget.currentUser['role'] != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses Ditolak: Hanya Admin yang dapat menghapus transaksi!'),
          backgroundColor: AppTheme.rose,
        ),
      );
      return;
    }
    await DatabaseHelper.instance.deleteTransaction(
      tx['id'],
      tx['title'],
      widget.currentUser['username'],
    );
    _refreshAll();
  }

  // TAB 3: ANALITIK & EXPORT CSV
  Widget _buildAnalyticsTab() {
    final totalExpense = (_summary['total_expense'] as num?)?.toDouble() ?? 0;
    final breakdown = (_summary['category_breakdown'] as List>?) ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 95),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'DISTRIBUSI PENGELUARAN PER KATEGORI',
                  style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 16),
                DonutChartWidget(items: breakdown, totalExpense: totalExpense),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardElevated,
                    foregroundColor: AppTheme.gold,
                    side: const BorderSide(color: AppTheme.gold),
                  ),
                  onPressed: _copyCsvReport,
                  icon: const Icon(Icons.table_view_rounded, size: 18),
                  label: const Text('Salin Laporan Excel / CSV ke Clipboard'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'REALISASI VS ANGGARAN KATEGORI',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        ...breakdown.map((item) {
          final spent = (item['spent'] as num).toDouble();
          final limit = (item['budget_limit'] as num).toDouble();
          final color = Color(item['color_hex'] as int);
          final ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : (totalExpense > 0 ? spent / totalExpense : 0.0);
          final overBudget = limit > 0 && spent > limit;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppTheme.getIcon(item['icon_code'] as int?), color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Text(
                        AppFormatters.rupiah(spent),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: overBudget ? AppTheme.rose : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 7,
                      backgroundColor: AppTheme.cardElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(overBudget ? AppTheme.rose : color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    limit > 0
                        ? 'Limit Anggaran: ${AppFormatters.rupiah(limit)} ${overBudget ? '(MELEBIHI BATAS!)' : ''}'
                        : 'Tidak ada batas anggaran',
                    style: TextStyle(
                      fontSize: 11,
                      color: overBudget ? AppTheme.rose : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _copyCsvReport() async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Tanggal,Tipe,Judul,Kategori,Dompet,Nominal,Catatan,Dicatat Oleh');
    for (final tx in _transactions) {
      buffer.writeln(
        '${tx['id']},"${tx['date']}",${tx['type']},"${tx['title']}","${tx['category']}","${tx['wallet']}",${tx['amount']},"${tx['note'] ?? ''}","${tx['created_by']}"',
      );
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laporan CSV berhasil disalin! Tinggal tempel di Excel/Sheets/WhatsApp.')),
    );
  }

  // MODAL TAMBAH / EDIT TRANSAKSI
  void _openTransactionSheet({Map<String, dynamic>? existingTx}) {
    final isEdit = existingTx != null;
    String type = existingTx?['type'] ?? 'expense';
    final titleCtrl = TextEditingController(text: existingTx?['title'] ?? '');
    final amountCtrl = TextEditingController(
      text: existingTx != null ? (existingTx['amount'] as num).toInt().toString() : '',
    );
    final noteCtrl = TextEditingController(text: existingTx?['note'] ?? '');

    String? selectedCategory = existingTx?['category'];
    String? selectedWallet = existingTx?['wallet'] ?? (_wallets.isNotEmpty ? _wallets.first['name'] : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filteredCats = _allCategories.where((c) => c['type'] == type).toList();
          if (selectedCategory == null || !filteredCats.any((c) => c['name'] == selectedCategory)) {
            selectedCategory = filteredCats.isNotEmpty ? filteredCats.first['name'] : null;
          }
          if (selectedWallet == null || !_wallets.any((w) => w['name'] == selectedWallet)) {
            selectedWallet = _wallets.isNotEmpty ? _wallets.first['name'] : null;
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Transaksi' : 'Catat Transaksi Baru',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'expense',
                          icon: Icon(Icons.north_east_rounded),
                          label: Text('Pengeluaran'),
                        ),
                        ButtonSegment(
                          value: 'income',
                          icon: Icon(Icons.south_west_rounded),
                          label: Text('Pemasukan'),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (v) => setSheetState(() => type = v.first),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold),
                    decoration: const InputDecoration(
                      labelText: 'Nominal (Rp)',
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Judul Transaksi (misal: Makan Siang)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: AppTheme.cardElevated,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: filteredCats
                        .map((c) => DropdownMenuItem<String>(value: c['name'], child: Text(c['name'])))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedCategory = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedWallet,
                    dropdownColor: AppTheme.cardElevated,
                    decoration: const InputDecoration(labelText: 'Dompet / Rekening'),
                    items: _wallets
                        .map((w) => DropdownMenuItem<String>(value: w['name'], child: Text(w['name'])))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedWallet = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Catatan Tambahan (Opsional)'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                        if (amt <= 0 || titleCtrl.text.trim().isEmpty || selectedCategory == null || selectedWallet == null) {
                          return;
                        }
                        final payload = {
                          'title': titleCtrl.text.trim(),
                          'amount': amt,
                          'type': type,
                          'category': selectedCategory,
                          'wallet': selectedWallet,
                          'note': noteCtrl.text.trim(),
                          'date': existingTx?['date'] ?? DateTime.now().toIso8601String(),
                          'created_by': widget.currentUser['username'],
                        };
                        if (isEdit) {
                          await DatabaseHelper.instance.updateTransaction(
                            existingTx['id'],
                            payload,
                            widget.currentUser['username'],
                          );
                        } else {
                          await DatabaseHelper.instance.insertTransaction(
                            payload,
                            widget.currentUser['username'],
                          );
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _refreshAll();
                      },
                      child: Text(
                        isEdit ? 'Simpan Perubahan' : 'Simpan ke Database SQL',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

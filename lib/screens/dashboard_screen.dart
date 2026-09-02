import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  List<dynamic> _wallets = [];
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  double _totalBalance = 0;
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _apiService.processRecurrings().catchError((_) {});

      final now = DateTime.now();
      final wallets = await _apiService.getWallets();
      final savedOrder = await _apiService.getWalletOrder();
      final transactions = await _apiService.getTransactions(month: now.month, year: now.year);
      
      if (savedOrder.isNotEmpty) {
        wallets.sort((a, b) {
          int indexA = savedOrder.indexOf(a['id']);
          int indexB = savedOrder.indexOf(b['id']);
          if (indexA == -1) indexA = 9999;
          if (indexB == -1) indexB = 9999;
          return indexA.compareTo(indexB);
        });
      }

      double tBalance = 0;
      for (var w in wallets) {
        tBalance += (w['balance'] ?? 0).toDouble();
      }

      double mIncome = 0;
      double mExpense = 0;
      for (var tx in transactions) {
        final amount = (tx['amount'] ?? 0).toDouble();
        if (tx['type'] == 'income') {
          mIncome += amount;
        } else if (tx['type'] == 'expense') {
          mExpense += amount;
        }
      }

      setState(() {
        _wallets = wallets;
        _transactions = transactions;
        _totalBalance = tBalance;
        _monthlyIncome = mIncome;
        _monthlyExpense = mExpense;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  List<BarChartGroupData> _generateChartData() {
    final now = DateTime.now();
    List<double> dailyExpenses = List.filled(7, 0.0);
    
    for (var tx in _transactions) {
      if (tx['type'] == 'expense') {
        final txDate = DateTime.parse(tx['date']);
        final diff = now.difference(txDate).inDays;
        if (diff >= 0 && diff < 7) {
          dailyExpenses[6 - diff] += (tx['amount'] ?? 0).toDouble();
        }
      }
    }

    List<BarChartGroupData> barGroups = [];
    double maxAmount = dailyExpenses.reduce((a, b) => a > b ? a : b);
    if (maxAmount == 0) maxAmount = 100; // prevent divide by zero

    for (int i = 0; i < 7; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dailyExpenses[i],
              color: Theme.of(context).colorScheme.error,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxAmount * 1.2,
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
    }
    return barGroups;
  }

  void _showAddWalletDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    final targetController = TextEditingController();
    bool isGoal = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('เพิ่มกระเป๋าเงิน/เป้าหมาย'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('ตั้งเป็นเป้าหมายการออม?'),
                        const Spacer(),
                        Switch(
                          value: isGoal,
                          onChanged: (val) => setDialogState(() => isGoal = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: isGoal ? 'ชื่อเป้าหมาย (เช่น ซื้อ PS5)' : 'ชื่อกระเป๋าเงิน',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'ยอดเงินเริ่มต้น',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (isGoal) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: targetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'เป้าหมายที่ต้องการ (บาท)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    
                    try {
                      await _apiService.createWallet(
                        nameController.text.trim(),
                        double.tryParse(balanceController.text) ?? 0,
                        targetAmount: isGoal ? (double.tryParse(targetController.text) ?? 0) : null,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditWalletDialog(dynamic wallet) {
    final nameController = TextEditingController(text: wallet['name']);
    final balanceController = TextEditingController(text: wallet['balance']?.toString() ?? '0');
    final formatCurrency = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('แก้ไขกระเป๋าเงิน'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'ชื่อกระเป๋าเงิน', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'ยอดเงินปัจจุบัน',
                  border: OutlineInputBorder(),
                  helperText: 'หากแก้ไขยอดเงิน ระบบจะบันทึกประวัติปรับปรุงยอดเงินให้อัตโนมัติ',
                  helperMaxLines: 2,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                try {
                  await _apiService.updateWallet(
                    wallet['id'],
                    nameController.text.trim(),
                    double.tryParse(balanceController.text) ?? 0,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัพเดทกระเป๋าเงินสำเร็จ')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ภาพรวม'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'จัดการบัญชี',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Total Balance Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Theme.of(context).colorScheme.primary, const Color(0xFF818CF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text('ยอดเงินคงเหลือรวม', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(
                              formatCurrency.format(_totalBalance),
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('รายรับเดือนนี้', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(formatCurrency.format(_monthlyIncome), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(width: 1, height: 30, color: Colors.white30),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('รายจ่ายเดือนนี้', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(formatCurrency.format(_monthlyExpense), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 2. Wallets Horizontal List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('กระเป๋าเงินของฉัน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: _showAddWalletDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('เพิ่ม'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: _wallets.isEmpty
                            ? Center(child: Text('ยังไม่มีกระเป๋าเงิน', style: TextStyle(color: Colors.grey[500])))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _wallets.length,
                                itemBuilder: (context, index) {
                                  final wallet = _wallets[index];
                                  final bool isGoal = wallet['target_amount'] != null;
                                  final double progress = isGoal ? ((wallet['balance'] ?? 0) / wallet['target_amount']).clamp(0.0, 1.0) : 0.0;

                                  return GestureDetector(
                                    onTap: () => _showEditWalletDialog(wallet),
                                    child: Container(
                                      width: 160,
                                      margin: const EdgeInsets.only(right: 16, bottom: 8),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardTheme.color,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(isGoal ? Icons.flag : Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(wallet['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            formatCurrency.format(wallet['balance'] ?? 0),
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                          ),
                                          if (isGoal) ...[
                                            const SizedBox(height: 8),
                                            LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: Colors.grey[300],
                                              color: Theme.of(context).colorScheme.primary,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 32),

                      // 3. Mini Chart
                      const Text('รายจ่าย 7 วันล่าสุด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _generateChartData().isEmpty ? 100 : null,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => Theme.of(context).colorScheme.primary,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    formatCurrency.format(rod.toY),
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(DateFormat('EEE').format(date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: _generateChartData(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
        ).then((_) => _loadData()),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('บันทึกรายการ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

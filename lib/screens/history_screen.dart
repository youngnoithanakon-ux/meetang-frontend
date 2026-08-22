import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'add_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _apiService.getTransactions(
        month: _selectedDate.month,
        year: _selectedDate.year,
      );
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteTransaction(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบรายการนี้ใช่หรือไม่?\n(ยอดเงินในกระเป๋าจะถูกคืนให้อัตโนมัติ)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบรายการ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteTransaction(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบรายการและคืนเงินสำเร็จ')));
          _loadTransactions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
        }
      }
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
      _isLoading = true;
    });
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    final displayMonth = '${monthNames[_selectedDate.month - 1]} ${_selectedDate.year + 543}';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('ประวัติรายการ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  displayMonth,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: _transactions.isEmpty
                  ? const Center(child: Text('ไม่มีประวัติการทำรายการ'))
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        final isExpense = tx['type'] == 'expense';
                        final isTransfer = tx['type'] == 'transfer';
                        
                        Color? amountColor = isTransfer ? Colors.blue[600] : (isExpense ? Colors.red[600] : Colors.green[600]);
                        final sign = isTransfer ? '' : (isExpense ? '-' : '+');
                        
                        final date = DateTime.parse(tx['date']);
                        final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

                        String title = tx['category']?['name'] ?? 'ไม่มีหมวดหมู่';
                        String subtitle = '${tx['wallet']?['name']} • $formattedDate';
                        IconData icon = isExpense ? Icons.arrow_downward : Icons.arrow_upward;
                        Color? bgColor = isExpense ? Colors.red[50] : Colors.green[50];

                        if (isTransfer) {
                          title = 'โอนเงิน';
                          subtitle = '${tx['wallet']?['name']} ➔ ${tx['destination_wallet']?['name']} • $formattedDate';
                          icon = Icons.sync_alt;
                          bgColor = Colors.blue[50];
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: bgColor,
                              child: Icon(icon, color: amountColor),
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subtitle),
                                if (tx['note'] != null && tx['note'].toString().isNotEmpty)
                                  Text(tx['note'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tx['image_path'] != null)
                                  IconButton(
                                    icon: const Icon(Icons.image, color: Colors.blue, size: 20),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          contentPadding: EdgeInsets.zero,
                                          content: Image.network('http://${ApiService.serverIp}/storage/${tx['image_path']}'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('ปิด'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                Text(
                                  '$sign ฿${double.parse(tx['amount'].toString()).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: amountColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      _deleteTransaction(tx['id']);
                                    } else if (value == 'edit') {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddTransactionScreen(initialTransaction: tx),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadTransactions();
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('แก้ไขรายการ'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('ลบรายการ', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

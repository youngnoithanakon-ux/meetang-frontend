import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _recurrings = [];
  List<dynamic> _wallets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final recurrings = await _apiService.getRecurringTransactions();
      final wallets = await _apiService.getWallets();
      setState(() {
        _recurrings = recurrings;
        _wallets = wallets;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final dayController = TextEditingController(text: '1');
    String type = 'expense';
    String? selectedWalletId = _wallets.isNotEmpty ? _wallets.first['id'].toString() : null;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('ตั้งเวลารายการประจำ'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'expense', label: Text('รายจ่าย')),
                        ButtonSegment(value: 'income', label: Text('รายรับ')),
                      ],
                      selected: {type},
                      onSelectionChanged: (Set<String> newSelection) {
                        setDialogState(() {
                          type = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'จำนวนเงิน', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'ชื่อรายการ (เช่น Netflix)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'หักทุกวันที่ (1-31)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    if (_wallets.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'กระเป๋าเงิน', border: OutlineInputBorder()),
                        value: selectedWalletId,
                        items: _wallets.map((w) => DropdownMenuItem<String>(
                          value: w['id'].toString(),
                          child: Text(w['name']),
                        )).toList(),
                        onChanged: (val) => setDialogState(() => selectedWalletId = val),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (amountController.text.isEmpty || selectedWalletId == null) return;
                    setDialogState(() => isSaving = true);
                    try {
                      await _apiService.createRecurringTransaction({
                        'type': type,
                        'amount': amountController.text,
                        'note': noteController.text,
                        'day_of_month': int.parse(dayController.text),
                        'wallet_id': selectedWalletId,
                      });
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    } finally {
                      if (mounted) setDialogState(() => isSaving = false);
                    }
                  },
                  child: isSaving ? const CircularProgressIndicator() : const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _delete(int id) async {
    try {
      await _apiService.deleteRecurringTransaction(id);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการประจำอัตโนมัติ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recurrings.isEmpty
              ? const Center(child: Text('ยังไม่มีการตั้งเวลารายการประจำ'))
              : ListView.builder(
                  itemCount: _recurrings.length,
                  itemBuilder: (context, index) {
                    final item = _recurrings[index];
                    final isExpense = item['type'] == 'expense';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        child: Icon(isExpense ? Icons.arrow_downward : Icons.arrow_upward, color: isExpense ? Colors.red : Colors.green),
                      ),
                      title: Text(item['note'] ?? 'ไม่มีชื่อรายการ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('หักจาก: ${item['wallet']?['name']} | ทุกวันที่ ${item['day_of_month']} ของเดือน'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('฿${item['amount']}', style: TextStyle(fontWeight: FontWeight.bold, color: isExpense ? Colors.red : Colors.green)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => _delete(item['id']),
                          )
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มรายการประจำ'),
      ),
    );
  }
}

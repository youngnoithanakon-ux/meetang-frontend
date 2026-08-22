import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _apiService = ApiService();
  List<dynamic> _categories = [];
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _apiService.getCategories();
      final transactions = await _apiService.getTransactions(
        month: _selectedDate.month,
        year: _selectedDate.year,
      );

      setState(() {
        _categories = categories.where((c) => c['type'] == 'expense').toList();
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
      _isLoading = true;
    });
    _loadData();
  }

  void _showSetBudgetDialog(dynamic category) {
    final controller = TextEditingController(
      text: category['budget_limit'] != null ? category['budget_limit'].toString() : '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('ตั้งงบประมาณ: ${category['name']}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'งบประมาณสูงสุดต่อเดือน (฿)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        await _apiService.updateCategory(
                          category['id'].toString(),
                          {'budget_limit': controller.text.isEmpty ? null : controller.text},
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    final displayMonth = '${monthNames[_selectedDate.month - 1]} ${_selectedDate.year + 543}';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('งบประมาณรายจ่าย'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                Text(displayMonth, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                
                // Calculate total spent for this category this month
                double spent = 0;
                for (var tx in _transactions) {
                  if (tx['type'] == 'expense' && tx['category_id'] == category['id']) {
                    spent += double.parse(tx['amount'].toString());
                  }
                }

                final hasBudget = category['budget_limit'] != null;
                final limit = hasBudget ? double.parse(category['budget_limit'].toString()) : 0.0;
                final percent = hasBudget && limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                
                Color progressColor = Colors.green;
                if (percent > 0.8) progressColor = Colors.red;
                else if (percent > 0.5) progressColor = Colors.orange;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(category['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () => _showSetBudgetDialog(category),
                              child: Text(hasBudget ? 'แก้ไขงบ' : '+ ตั้งงบ'),
                            ),
                          ],
                        ),
                        if (hasBudget) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.grey[200],
                            color: progressColor,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ใช้ไป: ฿${spent.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[700])),
                              Text('งบ: ฿${limit.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: progressColor)),
                            ],
                          ),
                        ] else
                          Text('ใช้ไป: ฿${spent.toStringAsFixed(0)} (ยังไม่ได้ตั้งงบประมาณ)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

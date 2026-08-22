import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    String type = 'expense';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('เพิ่มหมวดหมู่ใหม่'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('รายจ่าย')),
                  ButtonSegment(value: 'income', label: Text('รายรับ')),
                ],
                selected: {type},
                onSelectionChanged: (newSelection) {
                  setDialogState(() => type = newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'ชื่อหมวดหมู่', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.trim().isEmpty) return;
                setDialogState(() => isSaving = true);
                try {
                  await _apiService.createCategory(nameController.text.trim(), type);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadCategories();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setDialogState(() => isSaving = false);
                }
              },
              child: isSaving ? const CircularProgressIndicator() : const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    try {
      await _apiService.deleteCategory(id);
      _loadCategories();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการหมวดหมู่')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isExpense = cat['type'] == 'expense';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    child: Icon(isExpense ? Icons.arrow_downward : Icons.arrow_upward, color: isExpense ? Colors.red : Colors.green),
                  ),
                  title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isExpense ? 'รายจ่าย' : 'รายรับ'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => _deleteCategory(cat['id']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มหมวดหมู่'),
      ),
    );
  }
}

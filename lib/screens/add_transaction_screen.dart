import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTransaction;

  const AddTransactionScreen({super.key, this.initialTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _apiService = ApiService();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<dynamic> _wallets = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;

  String? _selectedWalletId;
  String? _selectedCategoryId;
  String? _destinationWalletId;
  String _type = 'expense';
  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.initialTransaction != null) {
      final tx = widget.initialTransaction!;
      _type = tx['type'];
      _amountController.text = tx['amount'].toString();
      _noteController.text = tx['note'] ?? '';
      _selectedDateTime = DateTime.parse(tx['date']);
      // We will set selected wallet/category after _loadData completes
    }
  }

  Future<void> _loadData() async {
    try {
      final wallets = await _apiService.getWallets();
      final categories = await _apiService.getCategories();
      
      setState(() {
        _wallets = wallets;
        _categories = categories;
        
        if (widget.initialTransaction != null) {
          final tx = widget.initialTransaction!;
          _selectedWalletId = tx['wallet_id'].toString();
          if (_type == 'transfer') {
            _destinationWalletId = tx['destination_wallet_id']?.toString() ?? wallets.first['id'].toString();
          } else {
            _selectedCategoryId = tx['category_id']?.toString();
          }
        } else if (_wallets.isNotEmpty) {
          _selectedWalletId = _wallets.first['id'].toString();
          _destinationWalletId = _wallets.length > 1 ? _wallets[1]['id'].toString() : _wallets.first['id'].toString();
        }
        
        if (widget.initialTransaction == null && _categories.isNotEmpty) {
          final filteredCats = _categories.where((c) => c['type'] == _type).toList();
          if (filteredCats.isNotEmpty) {
            _selectedCategoryId = filteredCats.first['id'].toString();
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _saveTransaction() async {
    if (_amountController.text.isEmpty || _selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    if (_type == 'transfer' && _selectedWalletId == _destinationWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กระเป๋าต้นทางและปลายทางต้องไม่ซ้ำกัน')),
      );
      return;
    }

    if (_type != 'transfer' && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกหมวดหมู่')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'wallet_id': _selectedWalletId,
        'amount': _amountController.text,
        'type': _type,
        'date': _selectedDateTime.toIso8601String(),
        'note': _noteController.text,
      };

      if (_type == 'transfer') {
        data['destination_wallet_id'] = _destinationWalletId;
      } else {
        data['category_id'] = _selectedCategoryId;
      }

      if (widget.initialTransaction != null) {
        await _apiService.updateTransaction(widget.initialTransaction!['id'], data, imageFile: _selectedImage);
      } else {
        await _apiService.createTransaction(data, imageFile: _selectedImage);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh dashboard
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        // พยายามดึงข้อความที่เป็นภาษาไทยออกมาถ้ามี
        if (errorMsg.contains('"message":"')) {
          final regex = RegExp(r'"message":"(.*?)"');
          final match = regex.firstMatch(errorMsg);
          if (match != null) {
            errorMsg = match.group(1) ?? errorMsg;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredCategories = _categories.where((c) => c['type'] == _type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTransaction != null ? 'แก้ไขรายการ' : 'เพิ่มรายการใหม่'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type Selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('รายจ่าย')),
                ButtonSegment(value: 'income', label: Text('รายรับ')),
                ButtonSegment(value: 'transfer', label: Text('โอนเงิน')),
              ],
              selected: {_type},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _type = newSelection.first;
                  // Reset category when type changes to prevent Dropdown error
                  if (_categories.isNotEmpty) {
                    final filteredCats = _categories.where((c) => c['type'] == _type).toList();
                    if (filteredCats.isNotEmpty) {
                      _selectedCategoryId = filteredCats.first['id'].toString();
                    } else {
                      _selectedCategoryId = null;
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Amount
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'จำนวนเงิน (฿)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Wallet Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: _type == 'transfer' ? 'จากกระเป๋า (ต้นทาง)' : 'กระเป๋าเงิน',
                prefixIcon: const Icon(Icons.account_balance_wallet),
              ),
              value: _selectedWalletId,
              items: _wallets.map((wallet) {
                return DropdownMenuItem<String>(
                  value: wallet['id'].toString(),
                  child: Text(wallet['name']),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedWalletId = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            // Conditional Dropdown: Destination Wallet OR Category
            if (_type == 'transfer')
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'ไปยังกระเป๋า (ปลายทาง)',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                value: _destinationWalletId,
                items: _wallets.map((wallet) {
                  return DropdownMenuItem<String>(
                    value: wallet['id'].toString(),
                    child: Text(wallet['name']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _destinationWalletId = newValue;
                  });
                },
              )
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่',
                  prefixIcon: Icon(Icons.category),
                ),
                value: _selectedCategoryId,
                items: filteredCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'].toString(),
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategoryId = newValue;
                  });
                },
                hint: const Text('เลือกหมวดหมู่'),
              ),
            
            const SizedBox(height: 16),

            // Date & Time Picker
            InkWell(
              onTap: _pickDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'วันเวลาที่ทำรายการ',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(_selectedDateTime),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'บันทึกช่วยจำ',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 16),

            // Image Picker
            InkWell(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedImage == null ? 'แนบสลิป/รูปภาพ' : _selectedImage!.name,
                        style: TextStyle(
                          color: _selectedImage == null ? Colors.grey[700] : Colors.black,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedImage != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }
}

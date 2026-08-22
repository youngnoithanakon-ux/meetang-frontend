import 'package:flutter/material.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      // Process recurring transactions first silently
      _apiService.processRecurrings().catchError((_) {});

      final wallets = await _apiService.getWallets();
      final savedOrder = await _apiService.getWalletOrder();
      
      // Sort wallets based on savedOrder
      if (savedOrder.isNotEmpty) {
        wallets.sort((a, b) {
          int indexA = savedOrder.indexOf(a['id']);
          int indexB = savedOrder.indexOf(b['id']);
          // If not found in saved order, put them at the end
          if (indexA == -1) indexA = 9999;
          if (indexB == -1) indexB = 9999;
          return indexA.compareTo(indexB);
        });
      }

      setState(() {
        _wallets = wallets;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _logout() async {
    await _apiService.removeToken();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _showAddWalletDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    final targetController = TextEditingController();
    bool isSaving = false;
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
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) return;
                          
                          setDialogState(() => isSaving = true);
                          try {
                            await _apiService.createWallet(
                              nameController.text.trim(),
                              double.tryParse(balanceController.text) ?? 0.0,
                              targetAmount: isGoal ? double.tryParse(targetController.text) : null,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              _loadWallets();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('เพิ่มสำเร็จ!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditWalletDialog(Map<String, dynamic> wallet) {
    final nameController = TextEditingController(text: wallet['name']);
    final balanceController = TextEditingController(text: wallet['balance'].toString());
    final targetController = TextEditingController(
      text: wallet['target_amount'] != null ? wallet['target_amount'].toString() : '',
    );
    bool isSaving = false;
    bool isGoal = wallet['target_amount'] != null && double.parse(wallet['target_amount'].toString()) > 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('แก้ไขกระเป๋าเงิน/เป้าหมาย'),
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
                        labelText: isGoal ? 'ชื่อเป้าหมาย' : 'ชื่อกระเป๋าเงิน',
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
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) return;
                          
                          setDialogState(() => isSaving = true);
                          try {
                            await _apiService.updateWallet(
                              wallet['id'],
                              nameController.text.trim(),
                              double.tryParse(balanceController.text) ?? 0.0,
                              targetAmount: isGoal ? double.tryParse(targetController.text) : null,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              _loadWallets();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('แก้ไขสำเร็จ!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteWallet(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบกระเป๋า/เป้าหมายนี้ใช่หรือไม่?\n(รายการประวัติที่ผูกกับกระเป๋านี้อาจได้รับผลกระทบ)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบกระเป๋า', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteWallet(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบสำเร็จ')));
          _loadWallets();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
        }
      }
    }
  }

  void _showQuickTransferDialog(Map<String, dynamic> sourceWallet, Map<String, dynamic> destWallet) {
    final amountController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('โอนเงินด่วน 💸'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sourceWallet['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const Icon(Icons.arrow_forward),
                      Text(destWallet['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'จำนวนเงินที่ต้องการโอน',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
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
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (amountController.text.trim().isEmpty) return;
                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) return;

                          setDialogState(() => isSaving = true);
                          try {
                            final data = {
                              'type': 'transfer',
                              'amount': amount.toString(),
                              'wallet_id': sourceWallet['id'].toString(),
                              'destination_wallet_id': destWallet['id'].toString(),
                              'date': DateTime.now().toIso8601String(),
                              'note': 'โอนเงินด่วน (ลากวาง)',
                            };
                            await _apiService.createTransaction(data);
                            if (mounted) {
                              Navigator.pop(context);
                              _loadWallets();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('โอนเงินสำเร็จแล้ว! 🎉')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('ยืนยันโอน'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('กระเป๋าเงินของฉัน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            onPressed: _showAddWalletDialog,
            tooltip: 'เพิ่มกระเป๋า',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'ออกจากระบบ',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWallets,
              child: _wallets.isEmpty
                  ? Center(
                      child: Text(
                        'ยังไม่มีกระเป๋าเงิน\nกดปุ่ม + เพื่อเพิ่มกระเป๋า',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.all(16),
                      itemCount: _wallets.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = _wallets.removeAt(oldIndex);
                          _wallets.insert(newIndex, item);
                          
                          // Save new order
                          final newOrderIds = _wallets.map<int>((w) => w['id'] as int).toList();
                          _apiService.saveWalletOrder(newOrderIds);
                        });
                      },
                      itemBuilder: (context, index) {
                        final wallet = _wallets[index];
                        final double balance = double.parse(wallet['balance'].toString());
                        final double? targetAmount = wallet['target_amount'] != null ? double.parse(wallet['target_amount'].toString()) : null;
                        final bool isGoal = targetAmount != null && targetAmount > 0;
                        final double progress = isGoal ? (balance / targetAmount).clamp(0.0, 1.0) : 0.0;

                        final walletCard = Card(
                          margin: EdgeInsets.zero,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isGoal 
                                        ? Colors.orange.withOpacity(0.1)
                                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isGoal ? Icons.flag_rounded : Icons.drag_indicator,
                                      color: isGoal ? Colors.orange : Colors.grey[400],
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wallet['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (isGoal) ...[
                                        Text(
                                          'เป้าหมาย: ฿${targetAmount.toStringAsFixed(0)}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.orange.withOpacity(0.2),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              progress >= 1.0 ? Colors.green : Colors.orange,
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          'ยอดคงเหลือ (กดค้างเพื่อโอน)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '฿${balance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isGoal && progress >= 1.0 
                                            ? Colors.green 
                                            : Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    if (isGoal) ...[
                                      Text(
                                        '${(progress * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: progress >= 1.0 ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditWalletDialog(wallet);
                                    } else if (value == 'delete') {
                                      _deleteWallet(wallet['id']);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('แก้ไข'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('ลบ', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );

                        return Container(
                          key: ValueKey(wallet['id']),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: DragTarget<Map<String, dynamic>>(
                            onWillAcceptWithDetails: (details) {
                              return details.data['id'] != wallet['id'];
                            },
                            onAcceptWithDetails: (details) {
                              _showQuickTransferDialog(details.data, wallet);
                            },
                            builder: (context, candidateData, rejectedData) {
                              final isHovering = candidateData.isNotEmpty;
                              return LongPressDraggable<Map<String, dynamic>>(
                                data: wallet,
                                delay: const Duration(milliseconds: 300),
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Opacity(
                                    opacity: 0.8,
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width - 32,
                                      child: walletCard,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: walletCard,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isHovering ? Colors.blue : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: walletCard,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
          
          if (result == true) {
            _loadWallets(); // Refresh dashboard
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('บันทึกรายการสำเร็จ!')),
              );
            }
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('บันทึกรายการ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

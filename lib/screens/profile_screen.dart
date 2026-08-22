import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _biometricsEnabled = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _apiService.getUserProfile();
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _user = user;
        _nameController.text = user['name'] ?? '';
        _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
        _hasPin = prefs.getString('user_pin') != null;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _apiService.updateUserProfile(
        _nameController.text.trim(),
        _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัพเดทโปรไฟล์สำเร็จ!')));
        _passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    if (!canAuthenticate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อุปกรณ์ไม่รองรับการสแกนนิ้ว/ใบหน้า')));
      }
      return;
    }

    if (value && !_hasPin) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาตั้งรหัส PIN ก่อนเปิดใช้งานสแกนนิ้ว')));
       }
       return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', value);
    setState(() {
      _biometricsEnabled = value;
    });
  }

  void _showPinDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตั้งรหัส PIN (6 หลัก)'),
        content: TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'กรอก PIN 6 หลัก', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              if (_pinController.text.length == 6) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_pin', _pinController.text);
                setState(() => _hasPin = true);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ตั้งค่า PIN สำเร็จ!')));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกให้ครบ 6 หลัก')));
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('ต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการบัญชี')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(_user?['email'] ?? '', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ),
                  const SizedBox(height: 32),
                  const Text('ชื่อ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 24),
                  const Text('เปลี่ยนรหัสผ่าน (เว้นว่างถ้าไม่เปลี่ยน)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), hintText: 'รหัสผ่านใหม่'),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('บันทึกการเปลี่ยนแปลง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('ความปลอดภัยและอื่นๆ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('ตั้งรหัส PIN (6 หลัก)'),
                    subtitle: Text(_hasPin ? 'ตั้งค่าแล้ว' : 'ยังไม่ได้ตั้งค่า'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showPinDialog,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('สแกนลายนิ้วมือ/ใบหน้า'),
                    subtitle: const Text('ต้องตั้ง PIN ก่อนถึงจะเปิดได้'),
                    value: _biometricsEnabled,
                    onChanged: _toggleBiometrics,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/categories'),
                    icon: const Icon(Icons.category),
                    label: const Text('จัดการหมวดหมู่รายรับ/รายจ่าย'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

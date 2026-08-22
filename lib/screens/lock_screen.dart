import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  
  static bool isUnlocked = false;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _savedPin;
  bool _isChecking = true;
  bool _biometricsEnabled = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    _savedPin = prefs.getString('user_pin');
    _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;

    // ถ้าไม่มี PIN ให้ข้ามไปหน้า Dashboard เลย หรือบังคับตั้ง PIN ก็ได้
    // ในที่นี้เราจะข้ามไปเลยถ้ายังไม่ได้ตั้ง PIN
    if (_savedPin == null) {
      LockScreen.isUnlocked = true;
      if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
      return;
    }

    setState(() {
      _isChecking = false;
    });

    if (_biometricsEnabled) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'สแกนลายนิ้วมือหรือใบหน้าเพื่อปลดล็อค',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        if (didAuthenticate && mounted) {
          LockScreen.isUnlocked = true;
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      }
    } catch (e) {
      // Fallback to PIN
      debugPrint('Biometrics error: $e');
    }
  }

  void _onPinPress(String digit) {
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
      });
      if (_pin.length == 6) {
        if (_pin == _savedPin) {
          LockScreen.isUnlocked = true;
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN ไม่ถูกต้อง'), backgroundColor: Colors.red),
          );
          setState(() {
            _pin = '';
          });
        }
      }
    }
  }

  void _onDeletePress() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'กรุณายืนยันตัวตน',
              style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? Colors.white : Colors.white.withOpacity(0.3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),
            _buildPinPad(),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () async {
                final apiService = ApiService();
                await apiService.removeToken();
                if (mounted) Navigator.of(context).pushReplacementNamed('/');
              },
              icon: const Icon(Icons.logout, color: Colors.white70),
              label: const Text('ออกจากระบบ', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        children: [
          for (var i = 1; i <= 9; i++) _buildPinButton(i.toString()),
          _biometricsEnabled ? _buildActionButton(Icons.fingerprint, _authenticate) : const SizedBox(),
          _buildPinButton('0'),
          _buildActionButton(Icons.backspace_outlined, _onDeletePress),
        ],
      ),
    );
  }

  Widget _buildPinButton(String digit) {
    return InkWell(
      onTap: () => _onPinPress(digit),
      customBorder: const CircleBorder(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Center(
          child: Icon(icon, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}

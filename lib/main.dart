import 'package:flutter/material.dart';
import 'db/database_helper.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const AureliaFinanceApp());
}

class AureliaFinanceApp extends StatefulWidget {
  const AureliaFinanceApp({super.key});

  @override
  State<AureliaFinanceApp> createState() => _AureliaFinanceAppState();
}

class _AureliaFinanceAppState extends State<AureliaFinanceApp> {
  Map<String, dynamic>? _activeUser;
  bool _isLocked = false;
  final _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDefaultUser();
  }

  Future<void> _initDefaultUser() async {
    final users = await DatabaseHelper.instance.getUsers();
    if (users.isNotEmpty && mounted) {
      setState(() => _activeUser = users.first);
    }
  }

  void _unlockWithPin() {
    if (_activeUser == null) return;
    if (_pinCtrl.text.trim() == _activeUser!['pin']) {
      setState(() {
        _isLocked = false;
        _pinCtrl.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN Salah! (Default Admin: 1234, Staff: 0000)'),
          backgroundColor: AppTheme.rose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurelia Finance Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _activeUser == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.gold)))
          : _isLocked
              ? Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_person_rounded, color: AppTheme.gold, size: 48),
                              const SizedBox(height: 14),
                              Text(
                                'Sesi Terkunci (${_activeUser!['username']})',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _pinCtrl,
                                obscureText: true,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(labelText: 'Masukkan PIN', counterText: ''),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.gold,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: _unlockWithPin,
                                  child: const Text('Buka Kunci', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : HomeScreen(
                  currentUser: _activeUser!,
                  onSwitchUser: (newUser) => setState(() => _activeUser = newUser),
                  onLockApp: () => setState(() => _isLocked = true),
                ),
    );
  }
}

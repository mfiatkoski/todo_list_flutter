import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/app_storage.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final AppStorage _appStorage = AppStorage();

  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadAppState();
  }

  Future<void> _loadAppState() async {
    await _appStorage.ensureDefaultUser();
    final isLoggedIn = await _appStorage.loadIsLoggedIn();
    final settings = await _appStorage.loadSettings();

    setState(() {
      _isLoggedIn = isLoggedIn;
      _darkMode = settings.darkMode;
      _isLoading = false;
    });
  }

  void _handleLogin() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  void _handleThemeChanged(bool darkMode) {
    setState(() {
      _darkMode = darkMode;
    });
  }

@override
Widget build(BuildContext context) {
  const seedColor = Color(0xFF1565C0);

  return MaterialApp(
    title: 'Minhas Tarefas',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 19, 32, 109),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
      ),
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 60, 122, 194),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
       centerTitle: false,
      ),
    ),
    themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
    home: _isLoading
    ? const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    )
    : _isLoggedIn
    ? HomePage(
      onLogout: _handleLogout,
      onThemeChanged: _handleThemeChanged,
    )
    : LoginPage(onLogin: _handleLogin)
  );
 }
}
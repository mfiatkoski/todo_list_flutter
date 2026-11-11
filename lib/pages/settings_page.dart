
import 'package:flutter/material.dart';
import '../services/app_storage.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onLogout;
  final ValueChanged<bool> onThemeChanged;

  const SettingsPage({
    super.key,
    required this.onLogout,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppStorage _appStorage = AppStorage();

  bool _isLoading = true;
  bool _darkMode = false;
  bool _confirmDelete = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _appStorage.loadSettings();

    setState(() {
      _darkMode = settings.darkmode;
      _confirmDelete = settings.confirmDelete;
      _isLoading = false;
    });
  }

  Future<void> _toogledDarkMode(bool value) async {
    setState(() {
      _darkMode = value;
    });

    await _appStorage.saveDarkMode(value);
    widget.onThemeChanged(value);
  }

  Future<void> toggleConfirmDelete(bool value) async {
    setState(() {
      _confirmDelete = value;
    });

    await _appStorage.saveConfirmDelete(value);
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmação'),
          content: const Text('Deseja sair da conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _appStorage.setLoggedIn(false);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Modo escuro'),
            value: _darkMode,
            onChanged: _toogledDarkMode,
          ),
          SwitchListTile(
            title: const Text('Confirmar exclusão'),
            value: _confirmDelete,
            onChanged: toggleConfirmDelete,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair da conta'),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }
}

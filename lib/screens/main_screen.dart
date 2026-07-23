import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'announcements_screen.dart';
import 'submissions_screen.dart';
import 'habarnama_screen.dart';
import 'login_screen.dart';
import 'admin/admin_pending_screen.dart';
import 'admin/admin_announcements_screen.dart';
import 'admin/admin_managers_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _username = '';
  bool _isAdmin = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final username = await AuthService().getUsername();
    final isAdmin = await AuthService().isAdmin();
    if (mounted) {
      setState(() {
        _username = username ?? '';
        _isAdmin = isAdmin;
        _loaded = true;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Çykmak'),
        content: const Text('Hasapdan çykmak isleýärsiňizmi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ýok')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hawa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  // ── Manager layout ─────────────────────────────────────────────
  static const _managerScreens = [
    AnnouncementsScreen(),
    SubmissionsScreen(),
    HabarnamaScreen(),
  ];

  static const _managerDestinations = [
    NavigationDestination(
      icon: Icon(Icons.campaign_outlined),
      selectedIcon: Icon(Icons.campaign),
      label: 'Bildirişler',
    ),
    NavigationDestination(
      icon: Icon(Icons.pending_outlined),
      selectedIcon: Icon(Icons.pending),
      label: 'Iberilen',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: 'Habarnama',
    ),
  ];

  // ── Admin layout ───────────────────────────────────────────────
  static const _adminScreens = [
    AdminPendingScreen(),
    AdminAnnouncementsScreen(),
    AdminManagersScreen(),
    HabarnamaScreen(),
  ];

  static const _adminTitles = ['Garaşylýanlar', 'Bildirişler', 'Dolandyryjylar', 'Habarnama'];

  static const _adminDestinations = [
    NavigationDestination(
      icon: Icon(Icons.pending_actions_outlined),
      selectedIcon: Icon(Icons.pending_actions),
      label: 'Garaşylýanlar',
    ),
    NavigationDestination(
      icon: Icon(Icons.campaign_outlined),
      selectedIcon: Icon(Icons.campaign),
      label: 'Bildirişler',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Dolandyryjylar',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: 'Habarnama',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = _isAdmin ? _adminScreens : _managerScreens;
    final destinations = _isAdmin ? _adminDestinations : _managerDestinations;
    final title = _isAdmin ? _adminTitles[_currentIndex] : 'Eziz Obam Staff';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_username.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  _isAdmin ? '$_username (Admin)' : _username,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çykmak',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: destinations,
      ),
    );
  }
}

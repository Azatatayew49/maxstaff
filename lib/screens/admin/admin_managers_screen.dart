import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class AdminManagersScreen extends StatefulWidget {
  const AdminManagersScreen({super.key});

  @override
  State<AdminManagersScreen> createState() => _AdminManagersScreenState();
}

class _AdminManagersScreenState extends State<AdminManagersScreen> {
  late Future<List<Manager>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().fetchManagers();
  }

  void _reload() => setState(() => _future = ApiService().fetchManagers());

  Future<void> _create() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _CreateManagerDialog(),
    );
    if (result == null) return;
    try {
      await ApiService().createManager(result['username']!, result['password']!);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _toggle(Manager m) async {
    final action = m.isActive ? 'öçürmek' : 'işjeňleşdirmek';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hasaby ${m.isActive ? "öçür" : "işjeňleşdir"}'),
        content: Text('"${m.username}" hasabyny $action isleýärsiňizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ýok')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hawa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService().toggleManagerActive(m.id, !m.isActive);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Manager>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('${snap.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _reload, child: const Text('Täzeden synanyş')),
                ],
              ),
            );
          }
          final list = snap.data ?? [];
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: list.isEmpty
                ? const Center(child: Text('Dolandyryjy ýok'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ManagerTile(
                      manager: list[i],
                      onToggle: () => _toggle(list[i]),
                    ),
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Täze dolandyryjy'),
      ),
    );
  }
}

class _ManagerTile extends StatelessWidget {
  final Manager manager;
  final VoidCallback onToggle;
  const _ManagerTile({required this.manager, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final joined = DateFormat('dd.MM.yyyy').format(manager.dateJoined.toLocal());
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: manager.isActive
              ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
              : Colors.grey[200],
          child: Icon(
            Icons.person_rounded,
            color: manager.isActive ? const Color(0xFF2E7D32) : Colors.grey,
          ),
        ),
        title: Text(manager.username,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Goşuldy: $joined'),
        trailing: Switch(
          value: manager.isActive,
          activeThumbColor: const Color(0xFF2E7D32),
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}

class _CreateManagerDialog extends StatefulWidget {
  @override
  State<_CreateManagerDialog> createState() => _CreateManagerDialogState();
}

class _CreateManagerDialogState extends State<_CreateManagerDialog> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Täze dolandyryjy'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _user,
              decoration: const InputDecoration(
                labelText: 'Ulanyjy ady',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Hökmany' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pass,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Açar söz',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Azyndan 6 harp' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Goý')),
        ElevatedButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, {
                'username': _user.text.trim(),
                'password': _pass.text,
              });
            }
          },
          child: const Text('Döret'),
        ),
      ],
    );
  }
}

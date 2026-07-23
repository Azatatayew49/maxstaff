import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class AdminPendingScreen extends StatefulWidget {
  const AdminPendingScreen({super.key});

  @override
  State<AdminPendingScreen> createState() => _AdminPendingScreenState();
}

class _AdminPendingScreenState extends State<AdminPendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Future<List<PendingAnnouncement>> _annFuture;
  late Future<List<PendingEdit>> _editFuture;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _annFuture = ApiService().fetchAllPendingAnnouncements();
      _editFuture = ApiService().fetchAllPendingEdits();
    });
  }

  Future<void> _approveAnn(int id) async {
    try {
      await ApiService().approvePendingAnnouncement(id);
      _reload();
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _rejectAnn(int id, String name) async {
    final reason = await _askReason(name);
    if (reason == null) return;
    try {
      await ApiService().rejectPendingAnnouncement(id, reason: reason);
      _reload();
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _approveEdit(int id) async {
    try {
      await ApiService().approvePendingEdit(id);
      _reload();
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _rejectEdit(int id, String name) async {
    final reason = await _askReason(name);
    if (reason == null) return;
    try {
      await ApiService().rejectPendingEdit(id, reason: reason);
      _reload();
    } catch (e) {
      _showError('$e');
    }
  }

  Future<String?> _askReason(String name) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ret etmek'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Sebäp (isleg boýunça)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Goý')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Ret et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Täze bildirişler'),
            Tab(text: 'Üýtgetmeler'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _AnnList(future: _annFuture, onApprove: _approveAnn, onReject: _rejectAnn),
              _EditList(future: _editFuture, onApprove: _approveEdit, onReject: _rejectEdit),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnnList extends StatelessWidget {
  final Future<List<PendingAnnouncement>> future;
  final void Function(int) onApprove;
  final void Function(int, String) onReject;
  const _AnnList({required this.future, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PendingAnnouncement>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) return const _Empty('Täze bildiriş ýok');
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final a = list[i];
            return _PendingCard(
              title: a.name,
              subtitle: '${a.categoryName} · ${a.villageName}',
              meta: '${a.createdByUsername} · ${DateFormat('dd.MM.yy').format(a.createdAt)}',
              onApprove: () => onApprove(a.id),
              onReject: () => onReject(a.id, a.name),
            );
          },
        );
      },
    );
  }
}

class _EditList extends StatelessWidget {
  final Future<List<PendingEdit>> future;
  final void Function(int) onApprove;
  final void Function(int, String) onReject;
  const _EditList({required this.future, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PendingEdit>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) return const _Empty('Garaşylýan üýtgetme ýok');
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final e = list[i];
            return _PendingCard(
              title: e.name,
              subtitle: '${e.categoryName} · ${e.villageName}',
              meta: '${e.editedByUsername} · ${e.originalAnnouncementName}',
              onApprove: () => onApprove(e.id),
              onReject: () => onReject(e.id, e.name),
            );
          },
        );
      },
    );
  }
}

class _PendingCard extends StatelessWidget {
  final String title, subtitle, meta;
  final VoidCallback onApprove, onReject;
  const _PendingCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 2),
            Text(meta, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Ret et'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Tassykla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

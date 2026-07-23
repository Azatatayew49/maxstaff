import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Future<List<PendingAnnouncement>> _pendingFuture;
  late Future<List<PendingEdit>> _editsFuture;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
        _pendingFuture = ApiService().fetchMyPendingAnnouncements();
        _editsFuture = ApiService().fetchMyPendingEdits();
      });

  Future<void> _deletePending(int id) async {
    try {
      await ApiService().deletePendingAnnouncement(id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pozmak başartmady: $e')),
        );
      }
    }
  }

  Future<void> _deleteEdit(int id) async {
    try {
      await ApiService().deletePendingEdit(id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pozmak başartmady: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iberilen haýyşlarym'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Täze bildirişler'),
            Tab(text: 'Üýtgetmeler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PendingList(future: _pendingFuture, onDelete: _deletePending),
          _EditsList(future: _editsFuture, onDelete: _deleteEdit),
        ],
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final Future<List<PendingAnnouncement>> future;
  final Future<void> Function(int) onDelete;

  const _PendingList({required this.future, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PendingAnnouncement>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text(snap.error.toString()));
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('Garaşylýan bildiriş ýok',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) => _PendingCard(
            item: list[i],
            onDelete: () => onDelete(list[i].id),
          ),
        );
      },
    );
  }
}

class _PendingCard extends StatelessWidget {
  final PendingAnnouncement item;
  final VoidCallback onDelete;

  const _PendingCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                _StatusBadge(label: 'Garaşylýar', color: Colors.orange),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(item.categoryName,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500])),
                const Spacer(),
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(item.expirationDate,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Pozmak?'),
                      content:
                          const Text('Bu haýyşy pozmak isleýärsiňizmi?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Ýok')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Hawa',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) onDelete();
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Pozmak'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditsList extends StatelessWidget {
  final Future<List<PendingEdit>> future;
  final Future<void> Function(int) onDelete;

  const _EditsList({required this.future, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PendingEdit>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text(snap.error.toString()));
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_off_outlined, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('Garaşylýan üýtgetme ýok',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) => _EditCard(
            item: list[i],
            onDelete: () => onDelete(list[i].id),
          ),
        );
      },
    );
  }
}

class _EditCard extends StatelessWidget {
  final PendingEdit item;
  final VoidCallback onDelete;

  const _EditCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                _StatusBadge(label: 'Garaşylýar', color: Colors.orange),
              ],
            ),
            const SizedBox(height: 4),
            Text('Asyl: ${item.originalAnnouncementName}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 6),
            Text(item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Pozmak?'),
                      content:
                          const Text('Bu üýtgetme haýyşyny pozmak isleýärsiňizmi?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Ýok')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Hawa',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) onDelete();
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Pozmak'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

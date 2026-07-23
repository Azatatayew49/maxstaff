import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  late Future<List<Announcement>> _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _future = ApiService().fetchAllAnnouncements();
  }

  void _reload() => setState(() => _future = ApiService().fetchAllAnnouncements());

  List<Announcement> _filtered(List<Announcement> all) {
    if (_filter == 'all') return all;
    return all.where((a) => a.status == _filter).toList();
  }

  Future<void> _setStatus(Announcement a, String newStatus) async {
    try {
      await ApiService().updateAnnouncementStatus(a.id, newStatus);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _delete(Announcement a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bildirişi poz'),
        content: Text('"${a.name}" pozulmak isleýärsiňizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ýok')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Poz', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService().deleteAnnouncement(a.id);
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
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (final f in [
                ('all', 'Hemmesi'),
                ('active', 'Işjeň'),
                ('not_active', 'Işjeň däl'),
                ('expired', 'Möhleti geçen'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.$2),
                    selected: _filter == f.$1,
                    onSelected: (_) => setState(() => _filter = f.$1),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Announcement>>(
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
              final list = _filtered(snap.data ?? []);
              if (list.isEmpty) {
                return Center(
                  child: Text('Bildiriş ýok', style: TextStyle(color: Colors.grey[600])),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _AnnCard(
                    ann: list[i],
                    onSetStatus: (s) => _setStatus(list[i], s),
                    onDelete: () => _delete(list[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnnCard extends StatelessWidget {
  final Announcement ann;
  final void Function(String) onSetStatus;
  final VoidCallback onDelete;

  const _AnnCard({required this.ann, required this.onSetStatus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ann.photos.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: ann.photos.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ann.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ann.statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(ann.statusLabel,
                            style: TextStyle(color: ann.statusColor, fontSize: 11)),
                      ),
                      const SizedBox(width: 6),
                      Text(ann.category.name,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (ann.status != 'active')
                        _ActionBtn(
                          label: 'Işjeňleşdir',
                          color: const Color(0xFF2E7D32),
                          onTap: () => onSetStatus('active'),
                        ),
                      if (ann.status == 'active') ...[
                        _ActionBtn(
                          label: 'Öçür',
                          color: Colors.orange,
                          onTap: () => onSetStatus('not_active'),
                        ),
                      ],
                      const SizedBox(width: 6),
                      _ActionBtn(
                        label: 'Poz',
                        color: Colors.red,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

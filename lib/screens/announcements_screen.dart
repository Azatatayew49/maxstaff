import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'create_announcement_screen.dart';
import 'edit_announcement_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  late Future<List<Announcement>> _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() {
        _future = ApiService().fetchAllAnnouncements();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirişler'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _FilterBar(
            current: _filter,
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => const CreateAnnouncementScreen()),
          );
          if (created == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Täze bildiriş'),
      ),
      body: FutureBuilder<List<Announcement>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(snap.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _reload, child: const Text('Gaýtala')),
                ],
              ),
            );
          }

          final all = snap.data!;
          final filtered = _filter == 'all'
              ? all
              : all.where((a) => a.status == _filter).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text('Bildiriş ýok', style: TextStyle(color: Colors.grey)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: filtered.length,
              itemBuilder: (_, i) =>
                  _AnnouncementTile(announcement: filtered[i], onEdit: _reload),
            ),
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('all', 'Hemmesi'),
      ('active', 'Işjeň'),
      ('not_active', 'Işjeň däl'),
      ('expired', 'Möhleti geçen'),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: items.map((item) {
          final selected = current == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item.$2),
              selected: selected,
              onSelected: (_) => onChanged(item.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onEdit;

  const _AnnouncementTile(
      {required this.announcement, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final edited = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => EditAnnouncementScreen(announcement: a)),
          );
          if (edited == true) onEdit();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: a.photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: a.photos.first,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))),
                        errorWidget: (_, __, ___) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child:
                                const Icon(Icons.image, color: Colors.grey)),
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey)),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(a.category.name,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: a.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: a.statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(a.statusLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: a.statusColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(a.expirationDate,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

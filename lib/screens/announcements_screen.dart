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
  String _statusFilter = 'all';
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedVillage;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() {
        _future = ApiService().fetchAllAnnouncements();
        _selectedCategory = null;
        _selectedVillage = null;
      });

  List<Announcement> _filtered(List<Announcement> all) {
    return all.where((a) {
      if (_statusFilter != 'all' && a.status != _statusFilter) { return false; }
      if (_selectedCategory != null && a.category.name != _selectedCategory) { return false; }
      if (_selectedVillage != null && a.villageName != _selectedVillage) { return false; }
      if (_searchQuery.isNotEmpty &&
          !a.name.toLowerCase().contains(_searchQuery.toLowerCase())) { return false; }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirişler'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
          );
          if (created == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Täze bildiriş'),
      ),
      body: FutureBuilder<List<Announcement>>(
        future: _future,
        builder: (context, snap) {
          final allLoaded = snap.data ?? [];
          final categories =
              allLoaded.map((a) => a.category.name).toSet().toList()..sort();
          final villages =
              allLoaded.map((a) => a.villageName).toSet().toList()..sort();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Gözle...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              // Status + category + village filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          selected: _statusFilter == f.$1,
                          onSelected: (_) =>
                              setState(() => _statusFilter = f.$1),
                        ),
                      ),
                    if (categories.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _DropChip(
                        label: _selectedCategory ?? 'Kategoriýa',
                        active: _selectedCategory != null,
                        items: categories,
                        onSelected: (v) =>
                            setState(() => _selectedCategory = v),
                        onClear: () => setState(() => _selectedCategory = null),
                      ),
                    ],
                    if (villages.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _DropChip(
                        label: _selectedVillage ?? 'Oba',
                        active: _selectedVillage != null,
                        items: villages,
                        onSelected: (v) =>
                            setState(() => _selectedVillage = v),
                        onClear: () => setState(() => _selectedVillage = null),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Builder(builder: (_) {
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
                              onPressed: _reload,
                              child: const Text('Gaýtala')),
                        ],
                      ),
                    );
                  }
                  final filtered = _filtered(allLoaded);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Bildiriş ýok',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _AnnouncementTile(
                          announcement: filtered[i], onEdit: _reload),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DropChip extends StatelessWidget {
  final String label;
  final bool active;
  final List<String> items;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  const _DropChip({
    required this.label,
    required this.active,
    required this.items,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => ListView(
            shrinkWrap: true,
            children: [
              if (active)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Arassala'),
                  onTap: () => Navigator.pop(context, '__clear__'),
                ),
              ...items.map((item) => ListTile(
                    title: Text(item),
                    onTap: () => Navigator.pop(context, item),
                  )),
            ],
          ),
        );
        if (picked == null) { return; }
        if (picked == '__clear__') {
          onClear();
        } else {
          onSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? cs.primary : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: active ? cs.primary : cs.onSurface,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 18, color: active ? cs.primary : cs.onSurface),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onEdit;

  const _AnnouncementTile({required this.announcement, required this.onEdit});

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
                            child: const Icon(Icons.image,
                                color: Colors.grey)),
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child:
                            const Icon(Icons.image, color: Colors.grey)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(a.villageName,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(height: 4),
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
                        const SizedBox(width: 6),
                        Text(a.category.name,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
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

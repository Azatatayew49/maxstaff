import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../edit_announcement_screen.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  late Future<List<Announcement>> _future;
  String _statusFilter = 'all';
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedVillage;

  @override
  void initState() {
    super.initState();
    _future = ApiService().fetchAllAnnouncements();
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
    return FutureBuilder<List<Announcement>>(
      future: _future,
      builder: (ctx, snap) {
        final allLoaded = snap.data ?? [];
        final categories = allLoaded.map((a) => a.category.name).toSet().toList()..sort();
        final villages = allLoaded.map((a) => a.villageName).toSet().toList()..sort();

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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            // Status + category + village filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        onSelected: (_) => setState(() => _statusFilter = f.$1),
                      ),
                    ),
                  if (categories.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _DropChip(
                      label: _selectedCategory ?? 'Kategoriýa',
                      active: _selectedCategory != null,
                      items: categories,
                      onSelected: (v) => setState(() => _selectedCategory = v),
                      onClear: () => setState(() => _selectedCategory = null),
                    ),
                  ],
                  if (villages.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _DropChip(
                      label: _selectedVillage ?? 'Oba',
                      active: _selectedVillage != null,
                      items: villages,
                      onSelected: (v) => setState(() => _selectedVillage = v),
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
                        Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('${snap.error}'),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _reload, child: const Text('Täzeden synanyş')),
                      ],
                    ),
                  );
                }
                final list = _filtered(allLoaded);
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
                      onEdit: _reload,
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
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
        if (picked == null) return;
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
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18,
                color: active ? cs.primary : cs.onSurface),
          ],
        ),
      ),
    );
  }
}

class _AnnCard extends StatelessWidget {
  final Announcement ann;
  final void Function(String) onSetStatus;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _AnnCard({
    required this.ann,
    required this.onSetStatus,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final edited = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => EditAnnouncementScreen(announcement: ann)),
          );
          if (edited == true) onEdit();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ann.photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ann.photos.first,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.image, size: 40, color: Colors.grey),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ann.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(ann.villageName,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ann.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(ann.statusLabel,
                              style: TextStyle(
                                  color: ann.statusColor, fontSize: 11)),
                        ),
                        const SizedBox(width: 6),
                        Text(ann.category.name,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
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
                        if (ann.status == 'active')
                          _ActionBtn(
                            label: 'Öçür',
                            color: Colors.orange,
                            onTap: () => onSetStatus('not_active'),
                          ),
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
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
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
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

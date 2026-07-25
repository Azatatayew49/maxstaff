import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'edit_pending_screen.dart';

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
          SnackBar(content: Text('Pozmak başartmady: $e')));
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
          SnackBar(content: Text('Pozmak başartmady: $e')));
      }
    }
  }

  void _openDetail(PendingAnnouncement item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PendingDetailSheet(
        item: item,
        onEdit: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPendingScreen(pending: item),
            ),
          ).then((changed) { if (changed == true) _reload(); });
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(() => _deletePending(item.id));
        },
      ),
    );
  }

  Future<void> _confirmDelete(VoidCallback onConfirmed) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pozmak?'),
        content: const Text('Bu haýyşy pozmak isleýärsiňizmi?'),
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
    if (confirm == true) onConfirmed();
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
          _PendingList(
            future: _pendingFuture,
            onTap: _openDetail,
            onEdit: (item) => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditPendingScreen(pending: item)),
            ).then((changed) { if (changed == true) _reload(); }),
            onDelete: (id) => _confirmDelete(() => _deletePending(id)),
          ),
          _EditsList(
            future: _editsFuture,
            onDelete: (id) => _confirmDelete(() => _deleteEdit(id)),
          ),
        ],
      ),
    );
  }
}

// ── Pending list ──────────────────────────────────────────────────────────────

class _PendingList extends StatelessWidget {
  final Future<List<PendingAnnouncement>> future;
  final void Function(PendingAnnouncement) onTap;
  final void Function(PendingAnnouncement) onEdit;
  final void Function(int) onDelete;

  const _PendingList({
    required this.future,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PendingAnnouncement>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return Center(child: Text(snap.error.toString()));
        final list = snap.data!;
        if (list.isEmpty) {
          return const _Empty(
            icon: Icons.inbox_outlined,
            text: 'Garaşylýan bildiriş ýok',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) => _PendingCard(
            item: list[i],
            onTap: () => onTap(list[i]),
            onEdit: () => onEdit(list[i]),
            onDelete: () => onDelete(list[i].id),
          ),
        );
      },
    );
  }
}

class _PendingCard extends StatelessWidget {
  final PendingAnnouncement item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PendingCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.photos.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.photos.first,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            width: 52, height: 52, color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => Container(
                            width: 52,
                            height: 52,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(label: 'Garaşylýar', color: Colors.orange),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category_outlined,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(item.categoryName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const Spacer(),
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(item.expirationDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Düzetmek'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Pozmak'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edits list ────────────────────────────────────────────────────────────────

class _EditsList extends StatelessWidget {
  final Future<List<PendingEdit>> future;
  final void Function(int) onDelete;

  const _EditsList({required this.future, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PendingEdit>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return Center(child: Text(snap.error.toString()));
        final list = snap.data!;
        if (list.isEmpty) {
          return const _Empty(
            icon: Icons.edit_off_outlined,
            text: 'Garaşylýan üýtgetme ýok',
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
                onPressed: onDelete,
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

// ── Detail sheet ──────────────────────────────────────────────────────────────

class _PendingDetailSheet extends StatefulWidget {
  final PendingAnnouncement item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PendingDetailSheet({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PendingDetailSheet> createState() => _PendingDetailSheetState();
}

class _PendingDetailSheetState extends State<_PendingDetailSheet> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  // Status badge
                  Row(
                    children: [
                      _StatusBadge(label: 'Garaşylýar', color: Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Photos
                  if (item.photos.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 240,
                        child: PageView.builder(
                          itemCount: item.photos.length,
                          onPageChanged: (i) =>
                              setState(() => _photoIndex = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: item.photos[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child:
                                  const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (item.photos.length > 1) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          item.photos.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: _photoIndex == i ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _photoIndex == i
                                  ? theme.primaryColor
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // Title
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Meta
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaChip(
                          icon: Icons.category_rounded,
                          label: item.categoryName),
                      _MetaChip(
                          icon: Icons.location_on_rounded,
                          label: item.villageName),
                      _MetaChip(
                          icon: Icons.calendar_today,
                          label: 'Möhleti: ${item.expirationDate}'),
                      _MetaChip(
                          icon: Icons.access_time,
                          label: DateFormat('dd.MM.yyyy')
                              .format(item.createdAt)),
                      if (item.phoneNumber != null &&
                          item.phoneNumber!.isNotEmpty)
                        _MetaChip(
                            icon: Icons.phone_rounded,
                            label: item.phoneNumber!),
                      if (item.latitude != null && item.longitude != null)
                        _MetaChip(
                          icon: Icons.location_on,
                          label:
                              '${item.latitude!.toStringAsFixed(5)}, ${item.longitude!.toStringAsFixed(5)}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (item.description.isNotEmpty) ...[
                    Text(
                      'Beýany',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark
                            ? Colors.grey[300]
                            : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Pozmak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Düzetmek'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
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

// ── Shared helpers ────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
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
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

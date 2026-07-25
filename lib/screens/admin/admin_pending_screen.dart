import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  void _openAnnDetail(BuildContext context, PendingAnnouncement a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        title: a.name,
        description: a.description,
        phoneNumber: a.phoneNumber,
        expirationDate: a.expirationDate,
        categoryName: a.categoryName,
        villageName: a.villageName,
        authorUsername: a.createdByUsername,
        date: DateFormat('dd.MM.yyyy').format(a.createdAt),
        photos: a.photos,
        onApprove: () {
          Navigator.pop(context);
          _approveAnn(a.id);
        },
        onReject: () {
          Navigator.pop(context);
          _rejectAnn(a.id, a.name);
        },
      ),
    );
  }

  void _openEditDetail(BuildContext context, PendingEdit e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        title: e.name,
        description: e.description,
        expirationDate: e.expirationDate,
        categoryName: e.categoryName,
        villageName: e.villageName,
        authorUsername: e.editedByUsername,
        date: DateFormat('dd.MM.yyyy').format(e.editedAt),
        photos: e.photos,
        originalName: e.originalAnnouncementName,
        onApprove: () {
          Navigator.pop(context);
          _approveEdit(e.id);
        },
        onReject: () {
          Navigator.pop(context);
          _rejectEdit(e.id, e.name);
        },
      ),
    );
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
              _AnnList(
                future: _annFuture,
                onApprove: _approveAnn,
                onReject: _rejectAnn,
                onTap: (a) => _openAnnDetail(context, a),
              ),
              _EditList(
                future: _editFuture,
                onApprove: _approveEdit,
                onReject: _rejectEdit,
                onTap: (e) => _openEditDetail(context, e),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── List widgets ──────────────────────────────────────────────────────────────

class _AnnList extends StatelessWidget {
  final Future<List<PendingAnnouncement>> future;
  final void Function(int) onApprove;
  final void Function(int, String) onReject;
  final void Function(PendingAnnouncement) onTap;
  const _AnnList({
    required this.future,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

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
              photos: a.photos,
              onTap: () => onTap(a),
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
  final void Function(PendingEdit) onTap;
  const _EditList({
    required this.future,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

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
              photos: e.photos,
              onTap: () => onTap(e),
              onApprove: () => onApprove(e.id),
              onReject: () => onReject(e.id, e.name),
            );
          },
        );
      },
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final String title, subtitle, meta;
  final List<String> photos;
  final VoidCallback onTap, onApprove, onReject;
  const _PendingCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.photos,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Thumbnail if photos exist
                  if (photos.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: photos.first,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[200],
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(meta,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: Colors.grey[400], size: 20),
                ],
              ),
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
      ),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

class _DetailSheet extends StatefulWidget {
  final String title;
  final String description;
  final String? phoneNumber;
  final String expirationDate;
  final String categoryName;
  final String villageName;
  final String authorUsername;
  final String date;
  final List<String> photos;
  final String? originalName;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DetailSheet({
    required this.title,
    required this.description,
    this.phoneNumber,
    required this.expirationDate,
    required this.categoryName,
    required this.villageName,
    required this.authorUsername,
    required this.date,
    required this.photos,
    this.originalName,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            // drag handle
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
                  // If it's an edit, show original announcement label
                  if (widget.originalName != null && widget.originalName!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Üýtgetme: ${widget.originalName}',
                              style: const TextStyle(
                                  color: Colors.orange, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Photo gallery
                  if (widget.photos.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 240,
                        child: PageView.builder(
                          itemCount: widget.photos.length,
                          onPageChanged: (i) =>
                              setState(() => _photoIndex = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: widget.photos[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.photos.length > 1) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.photos.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
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
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Meta chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Chip(
                          icon: Icons.category_rounded,
                          label: widget.categoryName),
                      _Chip(
                          icon: Icons.location_on_rounded,
                          label: widget.villageName),
                      _Chip(
                          icon: Icons.person_rounded,
                          label: widget.authorUsername),
                      _Chip(icon: Icons.calendar_today, label: widget.date),
                      _Chip(
                          icon: Icons.timer_outlined,
                          label: 'Möhleti: ${widget.expirationDate}'),
                      if (widget.phoneNumber != null &&
                          widget.phoneNumber!.isNotEmpty)
                        _Chip(
                            icon: Icons.phone_rounded,
                            label: widget.phoneNumber!),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (widget.description.isNotEmpty) ...[
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
                      widget.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onReject,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Ret et'),
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
                          onPressed: widget.onApprove,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Tassykla'),
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

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
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
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

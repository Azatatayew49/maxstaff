import 'dart:io';
import 'package:flutter/material.dart' hide Banner;
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class AdminMediaScreen extends StatefulWidget {
  const AdminMediaScreen({super.key});
  @override
  State<AdminMediaScreen> createState() => _AdminMediaScreenState();
}

class _AdminMediaScreenState extends State<AdminMediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Future<List<Banner>> _bannersFuture;
  late Future<List<Promotion>> _promotionsFuture;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _bannersFuture = ApiService().fetchBanners();
    _promotionsFuture = ApiService().fetchAllPromotions();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reloadBanners() => setState(() { _bannersFuture = ApiService().fetchBanners(); });
  void _reloadPromotions() => setState(() { _promotionsFuture = ApiService().fetchAllPromotions(); });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            indicatorColor: cs.primary,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
            tabs: const [
              Tab(text: 'Bannerler'),
              Tab(text: 'Mahabatlar'),
              Tab(text: 'Habarnamalar'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _BannersTab(future: _bannersFuture, onReload: _reloadBanners),
                _PromotionsTab(future: _promotionsFuture, onReload: _reloadPromotions),
                const _PushTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabs,
        builder: (_, __) {
          if (_tabs.index == 0) {
            return FloatingActionButton.extended(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const _BannerFormScreen()),
                );
                if (ok == true) _reloadBanners();
              },
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Täze banner'),
            );
          }
          if (_tabs.index == 1) {
            return FloatingActionButton.extended(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const _PromotionFormScreen()),
                );
                if (ok == true) _reloadPromotions();
              },
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Täze mahabat'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Banners Tab ────────────────────────────────────────────────────────────

class _BannersTab extends StatelessWidget {
  final Future<List<Banner>> future;
  final VoidCallback onReload;
  const _BannersTab({required this.future, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Banner>>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${snap.error}'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onReload, child: const Text('Täzeden synanyş')),
          ]));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('Banner ýok'));
        }
        return RefreshIndicator(
          onRefresh: () async => onReload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (_, i) => _BannerCard(banner: list[i], onDeleted: onReload),
          ),
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Banner banner;
  final VoidCallback onDeleted;
  const _BannerCard({required this.banner, required this.onDeleted});

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Banneri poz'),
        content: const Text('Bu banneri pozmak isleýärsiňizmi?'),
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
      await ApiService().deleteBanner(banner.id);
      onDeleted();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: banner.photo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: banner.photo,
                      width: 80, height: 50, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_linkTypeLabel(banner.linkType),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (banner.linkLabel.isNotEmpty)
                    Text(banner.linkLabel,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _delete(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
      width: 80, height: 50, color: Colors.grey[200],
      child: const Icon(Icons.image, color: Colors.grey));
}

// ── Promotions Tab ─────────────────────────────────────────────────────────

class _PromotionsTab extends StatelessWidget {
  final Future<List<Promotion>> future;
  final VoidCallback onReload;
  const _PromotionsTab({required this.future, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Promotion>>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${snap.error}'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onReload, child: const Text('Täzeden synanyş')),
          ]));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('Mahabat ýok'));
        }
        return RefreshIndicator(
          onRefresh: () async => onReload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (_, i) =>
                _PromotionCard(promotion: list[i], onChanged: onReload),
          ),
        );
      },
    );
  }
}

class _PromotionCard extends StatefulWidget {
  final Promotion promotion;
  final VoidCallback onChanged;
  const _PromotionCard({required this.promotion, required this.onChanged});
  @override
  State<_PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<_PromotionCard> {
  bool _loading = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    try {
      await ApiService().togglePromotion(widget.promotion.id,
          isActive: !widget.promotion.isActive);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mahabaty poz'),
        content: const Text('Bu mahabaty pozmak isleýärsiňizmi?'),
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
      await ApiService().deletePromotion(widget.promotion.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promotion;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: p.photo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: p.photo,
                      width: 80, height: 50, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_linkTypeLabel(p.linkType),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  if (p.linkLabel.isNotEmpty)
                    Text(p.linkLabel,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      _chip(_frequencyLabel(p.frequency), Colors.blue),
                      const SizedBox(width: 4),
                      _chip('Ileri: ${p.priority}', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(
                        value: p.isActive,
                        onChanged: (_) => _toggle(),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: _delete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
      width: 80, height: 50, color: Colors.grey[200],
      child: const Icon(Icons.image, color: Colors.grey));

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );
}

// ── Push Notifications Tab ─────────────────────────────────────────────────

class _PushTab extends StatefulWidget {
  const _PushTab();
  @override
  State<_PushTab> createState() => _PushTabState();
}

class _PushTabState extends State<_PushTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _annIdCtrl = TextEditingController();
  String _navType = 'home';
  bool _sending = false;
  Future<List<NotificationLog>>? _logsFuture;
  Future<Map<String, dynamic>>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _annIdCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _logsFuture = ApiService().fetchNotificationLogs();
      _statsFuture = ApiService().fetchDeviceStats();
    });
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Başlyk we tekst hökmany')));
      return;
    }
    final annId = _navType == 'announcement_detail'
        ? int.tryParse(_annIdCtrl.text.trim())
        : null;
    if (_navType == 'announcement_detail' && annId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildiriş ID-sini giriziň')));
      return;
    }
    setState(() => _sending = true);
    try {
      await ApiService().sendPushNotification(
        title: title,
        body: body,
        navigationType: _navType,
        announcementId: annId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Habarname iberildi!'),
          backgroundColor: Color(0xFF2E7D32)));
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _annIdCtrl.clear();
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Device stats
        FutureBuilder<Map<String, dynamic>>(
          future: _statsFuture,
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final s = snap.data!;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statTile('Enjam', '${s['total_devices']}', Colors.blue),
                    _statTile('Işjeň', '${s['active_devices']}', const Color(0xFF2E7D32)),
                    _statTile('Android', '${(s['by_platform'] as Map?)?['android'] ?? 0}', Colors.green),
                    _statTile('iOS', '${(s['by_platform'] as Map?)?['ios'] ?? 0}', Colors.grey),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Habarname iber', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Başlyk', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bodyCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Tekst', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _navType,
          decoration: const InputDecoration(labelText: 'Geçiş', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'home', child: Text('Baş sahypa')),
            DropdownMenuItem(value: 'announcement_detail', child: Text('Bildiriş sahypasy')),
          ],
          onChanged: (v) => setState(() { _navType = v!; }),
        ),
        if (_navType == 'announcement_detail') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _annIdCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Bildiriş ID', border: OutlineInputBorder()),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: const Text('Iber', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Iberilen habarnamalar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        FutureBuilder<List<NotificationLog>>(
          future: _logsFuture,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final logs = snap.data ?? [];
            if (logs.isEmpty) {
              return Center(child: Text('Log ýok', style: TextStyle(color: Colors.grey[600])));
            }
            return Column(
              children: logs.map((log) => _LogCard(log: log)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) => Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      );
}

class _LogCard extends StatelessWidget {
  final NotificationLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final date = '${log.createdAt.day.toString().padLeft(2,'0')}.${log.createdAt.month.toString().padLeft(2,'0')}.${log.createdAt.year} ${log.createdAt.hour.toString().padLeft(2,'0')}:${log.createdAt.minute.toString().padLeft(2,'0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(log.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 4),
            Text(log.body, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const SizedBox(height: 6),
            Row(
              children: [
                _pill('${log.sentTo} iberildi', Colors.blue),
                const SizedBox(width: 6),
                _pill('${log.successCount} ýetdi', const Color(0xFF2E7D32)),
                if (log.failureCount > 0) ...[
                  const SizedBox(width: 6),
                  _pill('${log.failureCount} ýetmedi', Colors.red),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}

// ── Banner Form ────────────────────────────────────────────────────────────

class _BannerFormScreen extends StatefulWidget {
  const _BannerFormScreen();
  @override
  State<_BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends State<_BannerFormScreen> {
  final _linkIdCtrl = TextEditingController();
  String _linkType = 'none';
  File? _photo;
  bool _loading = false;

  @override
  void dispose() {
    _linkIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Surat saýlaň')));
      return;
    }
    final linkId = _linkType != 'none' ? int.tryParse(_linkIdCtrl.text.trim()) : null;
    if (_linkType != 'none' && linkId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID-ni giriziň')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService().createBanner(photo: _photo!, linkType: _linkType, linkId: linkId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Täze banner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_photo!, fit: BoxFit.cover, width: double.infinity))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Banner surat saýlaň *', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _linkType,
            decoration: const InputDecoration(labelText: 'Geçiş görnüşi', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('Ýok')),
              DropdownMenuItem(value: 'announcement', child: Text('Bildiriş')),
              DropdownMenuItem(value: 'store', child: Text('Dükan')),
            ],
            onChanged: (v) => setState(() { _linkType = v!; _linkIdCtrl.clear(); }),
          ),
          if (_linkType != 'none') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkIdCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: _linkType == 'announcement' ? 'Bildiriş ID' : 'Dükan ID',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Döret', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Promotion Form ─────────────────────────────────────────────────────────

class _PromotionFormScreen extends StatefulWidget {
  const _PromotionFormScreen();
  @override
  State<_PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends State<_PromotionFormScreen> {
  final _linkIdCtrl = TextEditingController();
  final _priorityCtrl = TextEditingController(text: '0');
  String _linkType = 'none';
  String _frequency = 'always';
  bool _isActive = true;
  File? _photo;
  bool _loading = false;

  @override
  void dispose() {
    _linkIdCtrl.dispose();
    _priorityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Surat saýlaň')));
      return;
    }
    final linkId = _linkType != 'none' ? int.tryParse(_linkIdCtrl.text.trim()) : null;
    if (_linkType != 'none' && linkId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID-ni giriziň')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService().createPromotion(
        photo: _photo!,
        linkType: _linkType,
        linkId: linkId,
        frequency: _frequency,
        priority: int.tryParse(_priorityCtrl.text.trim()) ?? 0,
        isActive: _isActive,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Täze mahabat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_photo!, fit: BoxFit.cover, width: double.infinity))
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Mahabat surat saýlaň *', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _linkType,
            decoration: const InputDecoration(labelText: 'Geçiş görnüşi', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('Ýok')),
              DropdownMenuItem(value: 'announcement', child: Text('Bildiriş')),
              DropdownMenuItem(value: 'store', child: Text('Dükan')),
            ],
            onChanged: (v) => setState(() { _linkType = v!; _linkIdCtrl.clear(); }),
          ),
          if (_linkType != 'none') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkIdCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: _linkType == 'announcement' ? 'Bildiriş ID' : 'Dükan ID',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _frequency,
            decoration: const InputDecoration(labelText: 'Ýygylyk', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'always', child: Text('Hemişe')),
              DropdownMenuItem(value: 'once', child: Text('Bir gezek')),
              DropdownMenuItem(value: 'daily', child: Text('Gündelik')),
              DropdownMenuItem(value: 'weekly', child: Text('Hepdelik')),
            ],
            onChanged: (v) => setState(() => _frequency = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priorityCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Ileri tutma (0 = pes)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Işjeň'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Döret', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

String _linkTypeLabel(String t) => switch (t) {
      'announcement' => 'Bildiriş',
      'store' => 'Dükan',
      _ => 'Geçişsiz',
    };

String _frequencyLabel(String f) => switch (f) {
      'once' => 'Bir gezek',
      'daily' => 'Gündelik',
      'weekly' => 'Hepdelik',
      _ => 'Hemişe',
    };

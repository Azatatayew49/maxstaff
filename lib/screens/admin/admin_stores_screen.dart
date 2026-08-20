import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/gps_field.dart';

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});
  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Future<List<Store>> _storesFuture;
  late Future<List<PendingStoreItem>> _pendingFuture;
  late Future<List<StoreCategory>> _catFuture;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _storesFuture = ApiService().fetchStores();
    _pendingFuture = ApiService().fetchMyPendingStoreItems();
    _catFuture = ApiService().fetchStoreCategories();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reloadStores() => setState(() { _storesFuture = ApiService().fetchStores(); });
  void _reloadPending() => setState(() { _pendingFuture = ApiService().fetchMyPendingStoreItems(); });
  void _reloadCats() => setState(() { _catFuture = ApiService().fetchStoreCategories(); });

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
              Tab(text: 'Dükanlary'),
              Tab(text: 'Garaşylýanlar'),
              Tab(text: 'Bölümler'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _StoresTab(future: _storesFuture, onReload: _reloadStores),
                _PendingTab(future: _pendingFuture, onReload: _reloadPending),
                _CategoriesTab(future: _catFuture, onReload: _reloadCats),
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
                  MaterialPageRoute(builder: (_) => const _StoreFormScreen()),
                );
                if (ok == true) _reloadStores();
              },
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Täze dükan'),
            );
          }
          if (_tabs.index == 2) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddCategoryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Täze bölüm'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Täze bölüm'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Bölüm ady',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ýok')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Döret')),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await ApiService().createStoreCategory(ctrl.text.trim());
      _reloadCats();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }
}

// ── Stores Tab ─────────────────────────────────────────────────────────────

class _StoresTab extends StatelessWidget {
  final Future<List<Store>> future;
  final VoidCallback onReload;
  const _StoresTab({required this.future, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Store>>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text('${snap.error}'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onReload, child: const Text('Täzeden synanyş')),
            ]),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('Dükan ýok'));
        }
        return RefreshIndicator(
          onRefresh: () async => onReload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (_, i) => _StoreCard(
              store: list[i],
              onDeleted: onReload,
              onUpdated: onReload,
            ),
          ),
        );
      },
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;
  const _StoreCard({required this.store, required this.onDeleted, required this.onUpdated});

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dükany poz'),
        content: Text('"${store.name}" pozulmak isleýärsiňizmi?'),
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
      await ApiService().deleteStore(store.id);
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => _StoreItemsScreen(store: store)),
          );
          if (changed == true) onUpdated();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: store.picture.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: store.picture,
                        width: 60, height: 60, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(width: 60, height: 60, color: Colors.grey[200],
                                child: const Icon(Icons.store, color: Colors.grey)),
                      )
                    : Container(width: 60, height: 60, color: Colors.grey[200],
                        child: const Icon(Icons.store, color: Colors.grey)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(store.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('ID: ${store.id}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    Text(store.categoryName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(store.villageName,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () async {
                      final ok = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => _StoreFormScreen(store: store)),
                      );
                      if (ok == true) onUpdated();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _delete(context),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pending Tab ────────────────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  final Future<List<PendingStoreItem>> future;
  final VoidCallback onReload;
  const _PendingTab({required this.future, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PendingStoreItem>>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text('${snap.error}'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onReload, child: const Text('Täzeden synanyş')),
            ]),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('Garaşylýan haryt ýok'));
        }
        return RefreshIndicator(
          onRefresh: () async => onReload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (_, i) => _PendingCard(item: list[i], onChanged: onReload),
          ),
        );
      },
    );
  }
}

// ── Categories Tab ─────────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  final Future<List<StoreCategory>> future;
  final VoidCallback onReload;
  const _CategoriesTab({required this.future, required this.onReload});

  Future<void> _delete(BuildContext context, StoreCategory cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bölümi poz'),
        content: Text('"${cat.name}" pozulmak isleýärsiňizmi?'),
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
      await ApiService().deleteStoreCategory(cat.id);
      onReload();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StoreCategory>>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${snap.error}'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onReload, child: const Text('Täzeden synanyş')),
            ]),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('Bölüm ýok'));
        }
        return RefreshIndicator(
          onRefresh: () async => onReload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final cat = list[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(cat.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _delete(context, cat),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PendingCard extends StatefulWidget {
  final PendingStoreItem item;
  final VoidCallback onChanged;
  const _PendingCard({required this.item, required this.onChanged});
  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  bool _loading = false;

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await ApiService().approvePendingStoreItem(widget.item.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _loading = true);
    try {
      await ApiService().rejectPendingStoreItem(widget.item.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.picture.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.picture,
                          width: 60, height: 60, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(width: 60, height: 60, color: Colors.grey[200],
                                  child: const Icon(Icons.image, color: Colors.grey)),
                        )
                      : Container(width: 60, height: 60, color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(item.storeName,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      if (item.price != null)
                        Text('${item.price!.toStringAsFixed(2)} TMT',
                            style: const TextStyle(
                                color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Text('Garaşylýar',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (item.messageToAdmin.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Habar: ${item.messageToAdmin}',
                  style: TextStyle(
                      color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 4),
            Text('Iberen: ${item.submittedByUsername}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _approve,
                    icon: _loading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Tassykla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _reject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Ret et'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

// ── Store Items Screen ─────────────────────────────────────────────────────

class _StoreItemsScreen extends StatefulWidget {
  final Store store;
  const _StoreItemsScreen({required this.store});
  @override
  State<_StoreItemsScreen> createState() => _StoreItemsScreenState();
}

class _StoreItemsScreenState extends State<_StoreItemsScreen> {
  late Future<List<StoreItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().fetchStoreItems(widget.store.id);
  }

  void _reload() => setState(() { _future = ApiService().fetchStoreItems(widget.store.id); });

  Future<void> _delete(StoreItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Haryt poz'),
        content: Text('"${item.name}" pozulmak isleýärsiňizmi?'),
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
      await ApiService().deleteStoreItem(item.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.store.name, overflow: TextOverflow.ellipsis)),
      body: FutureBuilder<List<StoreItem>>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${snap.error}'),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _reload, child: const Text('Täzeden synanyş')),
              ]),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Haryt ýok'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: list.length,
              itemBuilder: (_, i) => _StoreItemCard(
                  item: list[i], onDelete: () => _delete(list[i])),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => _AddStoreItemScreen(storeId: widget.store.id)),
          );
          if (ok == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Haryt goş'),
      ),
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  final StoreItem item;
  final VoidCallback onDelete;
  const _StoreItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.picture.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.picture,
                      width: 60, height: 60, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(width: 60, height: 60, color: Colors.grey[200],
                              child: const Icon(Icons.image, color: Colors.grey)),
                    )
                  : Container(width: 60, height: 60, color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (item.price != null)
                    Text('${item.price!.toStringAsFixed(2)} TMT',
                        style: const TextStyle(
                            color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                  Text(item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Store Item Screen ──────────────────────────────────────────────────

class _AddStoreItemScreen extends StatefulWidget {
  final int storeId;
  const _AddStoreItemScreen({required this.storeId});
  @override
  State<_AddStoreItemScreen> createState() => _AddStoreItemScreenState();
}

class _AddStoreItemScreenState extends State<_AddStoreItemScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  File? _picture;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPicture() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) setState(() => _picture = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_picture == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Surat saýlaň')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService().createStoreItem(
        storeId: widget.storeId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: _priceCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_priceCtrl.text.trim()),
        picture: _picture!,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Haryt goş')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Haryt ady', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Hökmany' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Düşündiriş', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Hökmany' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Bahasy TMT (islege görä)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickPicture,
              icon: const Icon(Icons.image_outlined),
              label: Text(_picture != null ? 'Surat saýlandy ✓' : 'Surat saý *'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            if (_picture != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_picture!,
                    height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
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
                    : const Text('Goş',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Store Form Screen (Create / Edit) ─────────────────────────────────────

class _StoreFormScreen extends StatefulWidget {
  final Store? store;
  const _StoreFormScreen({this.store});
  @override
  State<_StoreFormScreen> createState() => _StoreFormScreenState();
}

class _StoreFormScreenState extends State<_StoreFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _openCtrl;
  late final TextEditingController _closeCtrl;
  late final TextEditingController _phoneCtrl;

  double? _latitude;
  double? _longitude;
  bool _gpsLoading = false;

  List<StoreCategory> _categories = [];
  List<Village> _villages = [];
  StoreCategory? _selectedCategory;
  Village? _selectedVillage;
  File? _picture;
  bool _loading = false;

  bool get _isEdit => widget.store != null;

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _openCtrl = TextEditingController(text: s?.openTime ?? '');
    _closeCtrl = TextEditingController(text: s?.closeTime ?? '');
    _phoneCtrl = TextEditingController(text: s?.phoneNumber ?? '');
    _latitude = s?.latitude;
    _longitude = s?.longitude;
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final cats = await ApiService().fetchStoreCategories();
      final vills = await ApiService().fetchVillages();
      if (mounted) {
        setState(() {
          _categories = cats;
          _villages = vills;
          if (widget.store != null) {
            _selectedCategory =
                cats.where((c) => c.id == widget.store!.categoryId).firstOrNull;
            _selectedVillage =
                vills.where((v) => v.id == widget.store!.villageId).firstOrNull;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _openCtrl.dispose();
    _closeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _getGps() async {
    setState(() => _gpsLoading = true);
    try {
      final result = await GpsField.getLocation(context);
      if (result != null && mounted) {
        setState(() { _latitude = result.lat; _longitude = result.lng; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS alynmady: $e')));
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _pickPicture() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) setState(() => _picture = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bölüm we ýer saýlaň')));
      return;
    }
    if (!_isEdit && _picture == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Surat saýlaň')));
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await ApiService().updateStore(
          id: widget.store!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          categoryId: _selectedCategory!.id,
          villageId: _selectedVillage!.id,
          openTime: _openCtrl.text.trim().isEmpty ? null : _openCtrl.text.trim(),
          closeTime: _closeCtrl.text.trim().isEmpty ? null : _closeCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          clearLocation: _latitude == null && widget.store?.latitude != null,
          picture: _picture,
        );
      } else {
        await ApiService().createStore(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          categoryId: _selectedCategory!.id,
          villageId: _selectedVillage!.id,
          openTime: _openCtrl.text.trim().isEmpty ? null : _openCtrl.text.trim(),
          closeTime: _closeCtrl.text.trim().isEmpty ? null : _closeCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          picture: _picture!,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Dükany üýtget' : 'Täze dükan')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Dükan ady', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Hökmany' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Düşündiriş', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Hökmany' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<StoreCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                  labelText: 'Bölüm', border: OutlineInputBorder()),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Saýlaň' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Village>(
              value: _selectedVillage,
              decoration: const InputDecoration(
                  labelText: 'Ýer', border: OutlineInputBorder()),
              items: _villages
                  .map((v) => DropdownMenuItem(value: v, child: Text(v.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedVillage = v),
              validator: (v) => v == null ? 'Saýlaň' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon belgisi (islege görä)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            GpsField(
              latitude: _latitude,
              longitude: _longitude,
              loading: _gpsLoading,
              onGet: _getGps,
              onClear: () => setState(() { _latitude = null; _longitude = null; }),
              onManual: (c) => setState(() { _latitude = c.lat; _longitude = c.lng; }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _openCtrl,
              decoration: const InputDecoration(
                labelText: 'Açylýan wagty (islege görä, mysal: 09:00)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _closeCtrl,
              decoration: const InputDecoration(
                labelText: 'Ýapylýan wagty (islege görä, mysal: 18:00)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickPicture,
              icon: const Icon(Icons.image_outlined),
              label: Text(_picture != null
                  ? 'Surat saýlandy ✓'
                  : _isEdit
                      ? 'Täze surat saý (islege görä)'
                      : 'Surat saý *'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            if (_picture != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_picture!,
                    height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEdit ? 'Ýatda sakla' : 'Döret',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

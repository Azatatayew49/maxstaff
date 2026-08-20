import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ManagerStoreItemsScreen extends StatefulWidget {
  const ManagerStoreItemsScreen({super.key});

  @override
  State<ManagerStoreItemsScreen> createState() => _ManagerStoreItemsScreenState();
}

class _ManagerStoreItemsScreenState extends State<ManagerStoreItemsScreen> {
  late Future<List<PendingStoreItem>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() { _future = ApiService().fetchMyPendingStoreItems(); });
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pozmak'),
        content: const Text('Bu haýyşy pozmak isleýärsiňizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Goý')),
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
      await ApiService().deletePendingStoreItem(id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dükan harytlary')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final submitted = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const _SubmitStoreItemScreen()),
          );
          if (submitted == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Haryt iber'),
      ),
      body: FutureBuilder<List<PendingStoreItem>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Iberilen haryt ýok', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Täze haryt ibermek üçin + düwmä basyň',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) => _PendingItemCard(
                item: items[i],
                onDelete: () => _delete(items[i].id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PendingItemCard extends StatelessWidget {
  final PendingStoreItem item;
  final VoidCallback onDelete;
  const _PendingItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (item.picture.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.picture, width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder()),
              )
            else
              _placeholder(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(item.storeName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (item.price != null)
                    Text('${item.price!.toStringAsFixed(item.price! % 1 == 0 ? 0 : 2)} TMT',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: const Text('Garaşylýar',
                        style: TextStyle(fontSize: 11, color: Colors.orange,
                            fontWeight: FontWeight.w600)),
                  ),
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

  Widget _placeholder() => Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.inventory_2, color: Colors.grey),
      );
}

// ── Submit form ───────────────────────────────────────────────────────────────

class _SubmitStoreItemScreen extends StatefulWidget {
  const _SubmitStoreItemScreen();

  @override
  State<_SubmitStoreItemScreen> createState() => _SubmitStoreItemScreenState();
}

class _SubmitStoreItemScreenState extends State<_SubmitStoreItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  List<Store> _stores = [];
  Store? _selectedStore;
  File? _picture;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    ApiService().fetchStores().then((s) {
      if (mounted) setState(() => _stores = s);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null && mounted) setState(() => _picture = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_picture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surat saýlaň')));
      return;
    }
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dükan saýlaň')));
      return;
    }
    setState(() => _loading = true);
    try {
      final price = _priceCtrl.text.trim().isNotEmpty
          ? double.tryParse(_priceCtrl.text.trim())
          : null;
      await ApiService().submitPendingStoreItem(
        storeId: _selectedStore!.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: price,
        messageToAdmin: _msgCtrl.text.trim(),
        picture: _picture!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Haryt iberildi. Admin tassyklamasyna garaşylýar.'),
          backgroundColor: Color(0xFF2E7D32)));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ýalňyşlyk: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Haryt iber')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Store dropdown
            DropdownButtonFormField<Store>(
              initialValue: _selectedStore,
              decoration: const InputDecoration(
                  labelText: 'Dükan', border: OutlineInputBorder()),
              items: _stores
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedStore = v),
              validator: (v) => v == null ? 'Dükan saýlaň' : null,
            ),
            const SizedBox(height: 12),
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
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(
                  labelText: 'Baha (TMT, islege görä)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            // Picture picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _picture != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_picture!, fit: BoxFit.cover,
                            width: double.infinity))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Surat saýlaň',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _msgCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Admina habar (islege görä)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Ibermek',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

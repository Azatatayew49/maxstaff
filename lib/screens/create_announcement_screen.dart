import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  DateTime? _expirationDate;
  Category? _selectedCategory;
  Village? _selectedVillage;
  List<File> _photos = [];
  bool _loading = false;

  List<Category> _categories = [];
  List<Village> _villages = [];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final cats = await ApiService().fetchCategories();
      final vills = await ApiService().fetchVillages();
      if (mounted) setState(() { _categories = cats; _villages = vills; });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() => _photos = picked.map((x) => File(x.path)).toList());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expirationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Möhletini saýlaň')));
      return;
    }
    if (_selectedCategory == null || _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bölüm we ýer saýlaň')));
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService().createAnnouncement(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        expirationDate:
            '${_expirationDate!.year}-${_expirationDate!.month.toString().padLeft(2, '0')}-${_expirationDate!.day.toString().padLeft(2, '0')}',
        categoryId: _selectedCategory!.id,
        villageId: _selectedVillage!.id,
        messageToAdmin: _msgCtrl.text.trim(),
        photos: _photos,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildiriş iberildi. Admin tassyklamasyna garaşylýar.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ýalňyşlyk: $e'),
              backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Täze bildiriş')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_nameCtrl, 'Bildirişiň ady', required: true),
            const SizedBox(height: 12),
            _field(_descCtrl, 'Düşündiriş',
                maxLines: 4, required: true),
            const SizedBox(height: 12),
            _field(_phoneCtrl, 'Telefon (8 san)', keyboardType: TextInputType.phone),
            const SizedBox(height: 12),

            // Category dropdown
            DropdownButtonFormField<Category>(
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

            // Village dropdown
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

            // Expiration date
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_expirationDate == null
                  ? 'Möhletini saýlaň'
                  : 'Möhleti: ${_expirationDate!.year}-${_expirationDate!.month.toString().padLeft(2, '0')}-${_expirationDate!.day.toString().padLeft(2, '0')}'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 12),

            // Photos
            OutlinedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_photos.isEmpty
                  ? 'Surat saýlaň'
                  : '${_photos.length} surat saýlandy'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_photos[i],
                          width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _field(_msgCtrl, 'Admina habar (islege görä)', maxLines: 2),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
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
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Hökmany' : null
          : null,
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/gps_field.dart';
import '../widgets/date_or_days_field.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final Announcement announcement;

  const EditAnnouncementScreen({super.key, required this.announcement});

  @override
  State<EditAnnouncementScreen> createState() =>
      _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _phoneCtrl;
  final _msgCtrl = TextEditingController();

  DateTime? _expirationDate;
  Category? _selectedCategory;
  Village? _selectedVillage;
  List<File> _newPhotos = [];
  bool _loading = false;
  double? _latitude;
  double? _longitude;
  bool _gpsLoading = false;

  List<Category> _categories = [];
  List<Village> _villages = [];

  @override
  void initState() {
    super.initState();
    final a = widget.announcement;
    _nameCtrl = TextEditingController(text: a.name);
    _descCtrl = TextEditingController(text: a.description);
    _phoneCtrl = TextEditingController(text: a.phoneNumber ?? '');
    if (a.expirationDate.isNotEmpty) {
      _expirationDate = DateTime.tryParse(a.expirationDate);
    }
    _latitude = a.latitude;
    _longitude = a.longitude;
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final cats = await ApiService().fetchCategories();
      final vills = await ApiService().fetchVillages();
      if (mounted) {
        setState(() {
          _categories = cats;
          _villages = vills;
          _selectedCategory = cats.where((c) => c.id == widget.announcement.category.id).firstOrNull;
          _selectedVillage = vills.where((v) => v.name == widget.announcement.villageName).firstOrNull;
        });
      }
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

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() => _newPhotos = picked.map((x) => File(x.path)).toList());
    }
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
      await ApiService().editAnnouncement(
        announcementId: widget.announcement.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        expirationDate:
            '${_expirationDate!.year}-${_expirationDate!.month.toString().padLeft(2, '0')}-${_expirationDate!.day.toString().padLeft(2, '0')}',
        categoryId: _selectedCategory!.id,
        villageId: _selectedVillage!.id,
        messageToAdmin: _msgCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        photos: _newPhotos,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Üýtgetme iberildi. Admin tassyklamasyna garaşylýar.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
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
    final a = widget.announcement;
    return Scaffold(
      appBar: AppBar(
        title: Text(a.name, overflow: TextOverflow.ellipsis),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: a.statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: a.statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: a.statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text('Häzirki ýagdaý: ${a.statusLabel}',
                      style: TextStyle(
                          color: a.statusColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _field(_nameCtrl, 'Bildirişiň ady', required: true),
            const SizedBox(height: 12),
            _field(_descCtrl, 'Düşündiriş', maxLines: 4, required: true),
            const SizedBox(height: 12),
            _field(_phoneCtrl, 'Telefon (8 san)', keyboardType: TextInputType.phone),
            const SizedBox(height: 12),

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

            DateOrDaysField(
              value: _expirationDate,
              onChanged: (d) => setState(() => _expirationDate = d),
            ),
            const SizedBox(height: 12),

            GpsField(
              latitude: _latitude,
              longitude: _longitude,
              loading: _gpsLoading,
              onGet: _getGps,
              onClear: () => setState(() { _latitude = null; _longitude = null; }),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_newPhotos.isEmpty
                  ? 'Täze surat goş (islege görä)'
                  : '${_newPhotos.length} surat saýlandy'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            if (_newPhotos.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newPhotos.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_newPhotos[i],
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
                    : const Text('Üýtgetme ibermek',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

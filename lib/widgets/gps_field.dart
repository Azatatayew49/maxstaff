import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GpsField extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final bool loading;
  final VoidCallback onGet;
  final VoidCallback onClear;
  final ValueChanged<({double lat, double lng})> onManual;

  const GpsField({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.loading,
    required this.onGet,
    required this.onClear,
    required this.onManual,
  });

  static Future<({double lat, double lng})?> getLocation(BuildContext context) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS rugsady berilmedi')));
      }
      return null;
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (lat: pos.latitude, lng: pos.longitude);
  }

  static Future<({double lat, double lng})?> showManualDialog(
      BuildContext context, double? currentLat, double? currentLng) async {
    final latCtrl = TextEditingController(
        text: currentLat != null ? currentLat.toString() : '');
    final lngCtrl = TextEditingController(
        text: currentLng != null ? currentLng.toString() : '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<({double lat, double lng})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('GPS koordinatlary'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: latCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Giňlik (latitude)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Hökmany';
                  final n = double.tryParse(v.trim());
                  if (n == null || n < -90 || n > 90) return '-90 … 90';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lngCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Uzynlyk (longitude)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Hökmany';
                  final n = double.tryParse(v.trim());
                  if (n == null || n < -180 || n > 180) return '-180 … 180';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ýatyr'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final lat = double.parse(latCtrl.text.trim());
                final lng = double.parse(lngCtrl.text.trim());
                Navigator.pop(ctx, (lat: lat, lng: lng));
              }
            },
            child: const Text('Ýatla'),
          ),
        ],
      ),
    );

    latCtrl.dispose();
    lngCtrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;
    final color = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: hasLocation ? color : Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              color: hasLocation ? color : Colors.grey[500], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasLocation
                  ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                  : 'GPS koordinatlary (islege görä)',
              style: TextStyle(
                color: hasLocation ? color : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final coords = await showManualDialog(context, latitude, longitude);
              if (coords != null) onManual(coords);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[600]),
            ),
          ),
          if (hasLocation)
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
            )
          else
            loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onGet,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Al'),
                  ),
        ],
      ),
    );
  }
}

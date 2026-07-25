import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GpsField extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final bool loading;
  final VoidCallback onGet;
  final VoidCallback onClear;

  const GpsField({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.loading,
    required this.onGet,
    required this.onClear,
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

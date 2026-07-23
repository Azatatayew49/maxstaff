import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class HabarnamaScreen extends StatefulWidget {
  const HabarnamaScreen({super.key});

  @override
  State<HabarnamaScreen> createState() => _HabarnamaScreenState();
}

class _HabarnamaScreenState extends State<HabarnamaScreen> {
  late Future<List<AnnouncementLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = ApiService().fetchAnnouncementLogs();
  }

  void _reload() => setState(() => _logsFuture = ApiService().fetchAnnouncementLogs());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habarnama'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: FutureBuilder<List<AnnouncementLog>>(
        future: _logsFuture,
        builder: (context, snap) {
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
                  Text('${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _reload, child: const Text('Täzeden synanyş')),
                ],
              ),
            );
          }
          final logs = snap.data ?? [];
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Habar ýok', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: logs.length,
              itemBuilder: (ctx, i) => _LogTile(log: logs[i]),
            ),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final AnnouncementLog log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = DateFormat('dd.MM.yyyy HH:mm').format(log.createdAt.toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: log.actionColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                log.isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: log.actionColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: log.actionColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          log.actionLabel,
                          style: TextStyle(
                            color: log.actionColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(log.typeLabel,
                            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(log.announcementName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  if (log.reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Sebäp: ${log.reason}',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(date,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

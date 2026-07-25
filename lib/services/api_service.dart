import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/models.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);
  static const String baseUrl = AuthService.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    };
  }

  // ── Announcements ──────────────────────────────────────────────
  Future<List<Announcement>> fetchAllAnnouncements() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$baseUrl/api/announcements/manager_list/'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((j) => Announcement.fromJson(j)).toList();
    }
    throw Exception('Bildirişler ýüklenip bilinmedi');
  }

  // ── Categories & Villages ──────────────────────────────────────
  Future<List<Category>> fetchCategories() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/categories/'))
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List list = data is Map ? data['results'] ?? data : data;
      return list.map((j) => Category.fromJson(j)).toList();
    }
    throw Exception('Bölümler ýüklenip bilinmedi');
  }

  Future<List<Village>> fetchVillages() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/villages/'))
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List list = data is Map ? data['results'] ?? data : data;
      return list.map((j) => Village.fromJson(j)).toList();
    }
    throw Exception('Ýerler ýüklenip bilinmedi');
  }

  // ── Create pending announcement ────────────────────────────────
  Future<void> createAnnouncement({
    required String name,
    required String description,
    required String phoneNumber,
    required String expirationDate,
    required int categoryId,
    required int villageId,
    String messageToAdmin = '',
    double? latitude,
    double? longitude,
    List<File> photos = const [],
  }) async {
    final token = await AuthService().getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/announcements/'),
    )
      ..headers['Authorization'] = 'Token $token'
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['phone_number'] = phoneNumber
      ..fields['expiration_date'] = expirationDate
      ..fields['category'] = categoryId.toString()
      ..fields['village'] = villageId.toString()
      ..fields['message_to_admin'] = messageToAdmin;

    if (latitude != null) request.fields['latitude'] = latitude.toStringAsFixed(7);
    if (longitude != null) request.fields['longitude'] = longitude.toStringAsFixed(7);

    for (final file in photos) {
      request.files.add(await http.MultipartFile.fromPath('photos', file.path));
    }

    final streamed = await request.send().timeout(_timeout);
    if (streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Bildiriş iberilip bilinmedi: $body');
    }
  }

  // ── Create pending edit ────────────────────────────────────────
  Future<void> editAnnouncement({
    required int announcementId,
    required String name,
    required String description,
    required String phoneNumber,
    required String expirationDate,
    required int categoryId,
    required int villageId,
    String messageToAdmin = '',
    double? latitude,
    double? longitude,
    List<File> photos = const [],
  }) async {
    final token = await AuthService().getToken();
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/api/announcements/$announcementId/'),
    )
      ..headers['Authorization'] = 'Token $token'
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['phone_number'] = phoneNumber
      ..fields['expiration_date'] = expirationDate
      ..fields['category'] = categoryId.toString()
      ..fields['village'] = villageId.toString()
      ..fields['message_to_admin'] = messageToAdmin;

    if (latitude != null) request.fields['latitude'] = latitude.toStringAsFixed(7);
    if (longitude != null) request.fields['longitude'] = longitude.toStringAsFixed(7);

    for (final file in photos) {
      request.files.add(await http.MultipartFile.fromPath('photos', file.path));
    }

    final streamed = await request.send().timeout(_timeout);
    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Üýtgetme iberilip bilinmedi: $body');
    }
  }

  // ── Update pending announcement (manager corrects before approval) ─
  Future<void> updatePendingAnnouncement({
    required int id,
    required String name,
    required String description,
    required String phoneNumber,
    required String expirationDate,
    required int categoryId,
    required int villageId,
    String messageToAdmin = '',
    double? latitude,
    double? longitude,
    List<File> photos = const [],
  }) async {
    final token = await AuthService().getToken();
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/api/pending-announcements/$id/'),
    )
      ..headers['Authorization'] = 'Token $token'
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['phone_number'] = phoneNumber
      ..fields['expiration_date'] = expirationDate
      ..fields['category'] = categoryId.toString()
      ..fields['village'] = villageId.toString()
      ..fields['message_to_admin'] = messageToAdmin;

    if (latitude != null) request.fields['latitude'] = latitude.toStringAsFixed(7);
    if (longitude != null) request.fields['longitude'] = longitude.toStringAsFixed(7);

    for (final file in photos) {
      request.files.add(await http.MultipartFile.fromPath('photos', file.path));
    }

    final streamed = await request.send().timeout(_timeout);
    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Üýtgetme iberilip bilinmedi: $body');
    }
  }

  // ── My submissions ─────────────────────────────────────────────
  Future<List<PendingAnnouncement>> fetchMyPendingAnnouncements() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$baseUrl/api/pending-announcements/'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List list = data is Map ? data['results'] ?? data : data;
      return list.map((j) => PendingAnnouncement.fromJson(j)).toList();
    }
    throw Exception('Garaşylýan bildirişler ýüklenip bilinmedi');
  }

  Future<List<PendingEdit>> fetchMyPendingEdits() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$baseUrl/api/pending-edits/'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List list = data is Map ? data['results'] ?? data : data;
      return list.map((j) => PendingEdit.fromJson(j)).toList();
    }
    throw Exception('Garaşylýan üýtgetmeler ýüklenip bilinmedi');
  }

  Future<void> deletePendingAnnouncement(int id) async {
    final headers = await _authHeaders();
    await http
        .delete(Uri.parse('$baseUrl/api/pending-announcements/$id/'), headers: headers)
        .timeout(_timeout);
  }

  Future<void> deletePendingEdit(int id) async {
    final headers = await _authHeaders();
    await http
        .delete(Uri.parse('$baseUrl/api/pending-edits/$id/'), headers: headers)
        .timeout(_timeout);
  }

  // ── Announcement logs ──────────────────────────────────────────
  Future<List<AnnouncementLog>> fetchAnnouncementLogs() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$baseUrl/api/announcement-logs/'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List list = data is Map ? data['results'] ?? data : data;
      return list.map((j) => AnnouncementLog.fromJson(j)).toList();
    }
    throw Exception('Habarlar ýüklenip bilinmedi');
  }

  // ── Admin: pending queue ───────────────────────────────────────
  Future<List<PendingAnnouncement>> fetchAllPendingAnnouncements() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$baseUrl/api/pending-announcements/'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List list = data is Map ? data['results'] ?? data : data;
      return list.map((j) => PendingAnnouncement.fromJson(j)).toList();
    }
    throw Exception('Garaşylýanlar ýüklenip bilinmedi');
  }

  Future<List<PendingEdit>> fetchAllPendingEdits() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$baseUrl/api/pending-edits/'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List list = data is Map ? data['results'] ?? data : data;
      return list.map((j) => PendingEdit.fromJson(j)).toList();
    }
    throw Exception('Garaşylýan üýtgetmeler ýüklenip bilinmedi');
  }

  Future<void> approvePendingAnnouncement(int id) async {
    final headers = await _authHeaders();
    final res = await http
        .post(Uri.parse('$baseUrl/api/pending-announcements/$id/approve/'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Tassyklamak başartmady');
  }

  Future<void> rejectPendingAnnouncement(int id, {String reason = ''}) async {
    final headers = {...await _authHeaders(), 'Content-Type': 'application/json'};
    final res = await http
        .post(Uri.parse('$baseUrl/api/pending-announcements/$id/reject/'),
            headers: headers, body: json.encode({'reason': reason}))
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Ret etmek başartmady');
  }

  Future<void> approvePendingEdit(int id) async {
    final headers = await _authHeaders();
    final res = await http
        .post(Uri.parse('$baseUrl/api/pending-edits/$id/approve/'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Tassyklamak başartmady');
  }

  Future<void> rejectPendingEdit(int id, {String reason = ''}) async {
    final headers = {...await _authHeaders(), 'Content-Type': 'application/json'};
    final res = await http
        .post(Uri.parse('$baseUrl/api/pending-edits/$id/reject/'),
            headers: headers, body: json.encode({'reason': reason}))
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Ret etmek başartmady');
  }

  // ── Admin: announcement status ─────────────────────────────────
  Future<void> updateAnnouncementStatus(int id, String status) async {
    final token = await AuthService().getToken();
    final request = http.MultipartRequest(
      'PATCH', Uri.parse('$baseUrl/api/announcements/$id/'))
      ..headers['Authorization'] = 'Token $token'
      ..fields['status'] = status;
    final streamed = await request.send().timeout(_timeout);
    if (streamed.statusCode != 200) throw Exception('Ýagdaý üýtgedilip bilinmedi');
  }

  Future<void> deleteAnnouncement(int id) async {
    final headers = await _authHeaders();
    final res = await http
        .delete(Uri.parse('$baseUrl/api/announcements/$id/'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode != 204) throw Exception('Bildiriş pozulup bilinmedi');
  }

  // ── Admin: managers ────────────────────────────────────────────
  Future<List<Manager>> fetchManagers() async {
    final headers = await _authHeaders();
    final res = await http
        .get(Uri.parse('$baseUrl/api/managers/'), headers: headers)
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List list = data is Map ? data['results'] ?? data : data;
      return list.map((j) => Manager.fromJson(j)).toList();
    }
    throw Exception('Dolandyryjylar ýüklenip bilinmedi');
  }

  Future<Manager> createManager(String username, String password) async {
    final headers = {...await _authHeaders(), 'Content-Type': 'application/json'};
    final res = await http
        .post(Uri.parse('$baseUrl/api/managers/'),
            headers: headers,
            body: json.encode({'username': username, 'password': password}))
        .timeout(_timeout);
    if (res.statusCode == 201) return Manager.fromJson(json.decode(res.body));
    final body = json.decode(res.body);
    throw Exception(body.toString());
  }

  Future<void> toggleManagerActive(int id, bool isActive) async {
    final headers = {...await _authHeaders(), 'Content-Type': 'application/json'};
    final res = await http
        .patch(Uri.parse('$baseUrl/api/managers/$id/'),
            headers: headers,
            body: json.encode({'is_active': isActive}))
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Ýagdaý üýtgedilip bilinmedi');
  }
}

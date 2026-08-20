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
  Future<void> updateAnnouncementStatus(int id, String newStatus) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/api/announcements/$id/'),
      headers: headers,
      body: json.encode({'status': newStatus}),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Ýagdaý üýtgedilip bilinmedi');
  }

  Future<void> updateAnnouncementPriority(int id, int priority) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/api/announcements/$id/'),
      headers: headers,
      body: json.encode({'priority': priority}),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Ileri tutma üýtgedilip bilinmedi');
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

  // ── Banners ────────────────────────────────────────────────────

  Future<List<Banner>> fetchBanners() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/api/banners/'), headers: headers).timeout(_timeout);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] as List? ?? []);
      return list.map((j) => Banner.fromJson(j)).toList();
    }
    throw Exception('Bannerler ýüklenip bilinmedi');
  }

  Future<void> createBanner({required File photo, required String linkType, int? linkId}) async {
    final token = await AuthService().getToken();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/banners/'));
    req.headers['Authorization'] = 'Token $token';
    req.fields['link_type'] = linkType;
    if (linkId != null) req.fields['link_id'] = '$linkId';
    req.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 201) throw Exception('Banner döredilip bilinmedi: ${res.body}');
  }

  Future<void> deleteBanner(int id) async {
    final token = await AuthService().getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/api/banners/$id/'),
      headers: {'Authorization': 'Token $token'},
    ).timeout(_timeout);
    if (res.statusCode != 204) throw Exception('Banner pozulup bilinmedi');
  }

  // ── Promotions ─────────────────────────────────────────────────

  Future<List<Promotion>> fetchAllPromotions() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/api/promotions/'), headers: headers).timeout(_timeout);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] as List? ?? []);
      return list.map((j) => Promotion.fromJson(j)).toList();
    }
    throw Exception('Mahabatlar ýüklenip bilinmedi');
  }

  Future<void> createPromotion({
    required File photo,
    required String linkType,
    int? linkId,
    required String frequency,
    int priority = 0,
    bool isActive = true,
  }) async {
    final token = await AuthService().getToken();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/promotions/'));
    req.headers['Authorization'] = 'Token $token';
    req.fields['link_type'] = linkType;
    if (linkId != null) req.fields['link_id'] = '$linkId';
    req.fields['frequency'] = frequency;
    req.fields['priority'] = '$priority';
    req.fields['is_active'] = isActive ? 'true' : 'false';
    req.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 201) throw Exception('Mahabat döredilip bilinmedi: ${res.body}');
  }

  Future<void> togglePromotion(int id, {required bool isActive}) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/api/promotions/$id/'),
      headers: headers,
      body: json.encode({'is_active': isActive}),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Mahabat üýtgedilip bilinmedi');
  }

  Future<void> deletePromotion(int id) async {
    final token = await AuthService().getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/api/promotions/$id/'),
      headers: {'Authorization': 'Token $token'},
    ).timeout(_timeout);
    if (res.statusCode != 204) throw Exception('Mahabat pozulup bilinmedi');
  }

  // ── Push Notifications ─────────────────────────────────────────

  Future<Map<String, dynamic>> fetchDeviceStats() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/api/device-tokens/stats/'), headers: headers).timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Statistika ýüklenip bilinmedi');
  }

  Future<void> sendPushNotification({
    required String title,
    required String body,
    String navigationType = 'home',
    int? announcementId,
  }) async {
    final headers = await _authHeaders();
    final payload = <String, dynamic>{'title': title, 'body': body, 'navigation_type': navigationType};
    if (announcementId != null) payload['announcement_id'] = announcementId;
    final res = await http.post(
      Uri.parse('$baseUrl/api/device-tokens/send_notification/'),
      headers: headers,
      body: json.encode(payload),
    ).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Habarname iberilip bilinmedi: ${res.body}');
  }

  Future<List<NotificationLog>> fetchNotificationLogs() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/api/notification-logs/'), headers: headers).timeout(_timeout);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] as List? ?? []);
      return list.map((j) => NotificationLog.fromJson(j)).toList();
    }
    throw Exception('Loglar ýüklenip bilinmedi');
  }

  // ── Stores ─────────────────────────────────────────────────────

  Future<List<StoreCategory>> fetchStoreCategories() async {
    final token = await AuthService().getToken();
    final res = await http
        .get(Uri.parse('$baseUrl/api/store-categories/'),
            headers: {'Authorization': 'Token $token'})
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] as List? ?? []);
      return list.map((j) => StoreCategory.fromJson(j)).toList();
    }
    throw Exception('Dükan bölümleri ýüklenip bilinmedi');
  }

  Future<StoreCategory> createStoreCategory(String name) async {
    final headers = await _authHeaders();
    final res = await http
        .post(Uri.parse('$baseUrl/api/store-categories/'),
            headers: headers, body: json.encode({'name': name}))
        .timeout(_timeout);
    if (res.statusCode == 201) return StoreCategory.fromJson(jsonDecode(res.body));
    throw Exception('Bölüm döredilip bilinmedi');
  }

  Future<void> deleteStoreCategory(int id) async {
    final token = await AuthService().getToken();
    final res = await http
        .delete(Uri.parse('$baseUrl/api/store-categories/$id/'),
            headers: {'Authorization': 'Token $token'})
        .timeout(_timeout);
    if (res.statusCode != 204) throw Exception('Bölüm pozulup bilinmedi');
  }

  Future<List<Store>> fetchStores({int? categoryId}) async {
    final token = await AuthService().getToken();
    final uri = Uri.parse('$baseUrl/api/stores/').replace(
      queryParameters: categoryId != null ? {'category': '$categoryId'} : null,
    );
    final res = await http
        .get(uri, headers: {'Authorization': 'Token $token'})
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] as List? ?? []);
      return list.map((j) => Store.fromJson(j)).toList();
    }
    throw Exception('Dükanlar ýüklenip bilinmedi');
  }

  Future<Store> createStore({
    required String name,
    required String description,
    required int categoryId,
    required int villageId,
    String? openTime,
    String? closeTime,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    required File picture,
  }) async {
    final token = await AuthService().getToken();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/stores/'));
    req.headers['Authorization'] = 'Token $token';
    req.fields['name'] = name;
    req.fields['description'] = description;
    req.fields['category'] = '$categoryId';
    req.fields['village'] = '$villageId';
    req.fields['is_active'] = 'true';
    if (openTime != null) req.fields['open_time'] = openTime;
    if (closeTime != null) req.fields['close_time'] = closeTime;
    if (phoneNumber != null) req.fields['phone_number'] = phoneNumber;
    if (latitude != null) req.fields['latitude'] = latitude.toStringAsFixed(6);
    if (longitude != null) req.fields['longitude'] = longitude.toStringAsFixed(6);
    req.files.add(await http.MultipartFile.fromPath('picture', picture.path));
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 201) return Store.fromJson(jsonDecode(res.body));
    throw Exception('Dükan döredilip bilinmedi: ${res.body}');
  }

  Future<Store> updateStore({
    required int id,
    required String name,
    required String description,
    required int categoryId,
    required int villageId,
    String? openTime,
    String? closeTime,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    File? picture,
  }) async {
    final token = await AuthService().getToken();
    final req = http.MultipartRequest('PATCH', Uri.parse('$baseUrl/api/stores/$id/'));
    req.headers['Authorization'] = 'Token $token';
    req.fields['name'] = name;
    req.fields['description'] = description;
    req.fields['category'] = '$categoryId';
    req.fields['village'] = '$villageId';
    if (openTime != null) req.fields['open_time'] = openTime;
    if (closeTime != null) req.fields['close_time'] = closeTime;
    if (phoneNumber != null) req.fields['phone_number'] = phoneNumber;
    if (latitude != null) req.fields['latitude'] = latitude.toStringAsFixed(6);
    if (longitude != null) req.fields['longitude'] = longitude.toStringAsFixed(6);
    if (clearLocation) { req.fields['latitude'] = ''; req.fields['longitude'] = ''; }
    if (picture != null) {
      req.files.add(await http.MultipartFile.fromPath('picture', picture.path));
    }
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) return Store.fromJson(jsonDecode(res.body));
    throw Exception('Dükan üýtgedilip bilinmedi: ${res.body}');
  }

  Future<void> deleteStore(int id) async {
    final token = await AuthService().getToken();
    final res = await http
        .delete(Uri.parse('$baseUrl/api/stores/$id/'),
            headers: {'Authorization': 'Token $token'})
        .timeout(_timeout);
    if (res.statusCode != 204) throw Exception('Dükan pozulup bilinmedi');
  }

  Future<List<StoreItem>> fetchStoreItems(int storeId) async {
    final token = await AuthService().getToken();
    final res = await http
        .get(Uri.parse('$baseUrl/api/store-items/?store=$storeId'),
            headers: {'Authorization': 'Token $token'})
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] as List? ?? []);
      return list.map((j) => StoreItem.fromJson(j)).toList();
    }
    throw Exception('Harytlar ýüklenip bilinmedi');
  }

  Future<void> createStoreItem({
    required int storeId,
    required String name,
    required String description,
    double? price,
    required File picture,
  }) async {
    final token = await AuthService().getToken();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/store-items/'));
    req.headers['Authorization'] = 'Token $token';
    req.fields['store'] = '$storeId';
    req.fields['name'] = name;
    req.fields['description'] = description;
    if (price != null) req.fields['price'] = price.toString();
    req.files.add(await http.MultipartFile.fromPath('picture', picture.path));
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 201) throw Exception('Haryt döredilip bilinmedi: ${res.body}');
  }

  Future<void> deleteStoreItem(int id) async {
    final token = await AuthService().getToken();
    final res = await http
        .delete(Uri.parse('$baseUrl/api/store-items/$id/'),
            headers: {'Authorization': 'Token $token'})
        .timeout(_timeout);
    if (res.statusCode != 204) throw Exception('Haryt pozulup bilinmedi');
  }

  Future<List<PendingStoreItem>> fetchMyPendingStoreItems() async {
    final token = await AuthService().getToken();
    final res = await http
        .get(Uri.parse('$baseUrl/api/pending-store-items/'),
            headers: {'Authorization': 'Token $token'})
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] as List? ?? []);
      return list.map((j) => PendingStoreItem.fromJson(j)).toList();
    }
    throw Exception('Garaşylýan harytlar ýüklenip bilinmedi');
  }

  Future<void> submitPendingStoreItem({
    required int storeId,
    required String name,
    required String description,
    double? price,
    String messageToAdmin = '',
    required File picture,
  }) async {
    final token = await AuthService().getToken();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/pending-store-items/'));
    req.headers['Authorization'] = 'Token $token';
    req.fields['store'] = '$storeId';
    req.fields['name'] = name;
    req.fields['description'] = description;
    if (price != null) req.fields['price'] = price.toString();
    if (messageToAdmin.isNotEmpty) req.fields['message_to_admin'] = messageToAdmin;
    req.files.add(await http.MultipartFile.fromPath('picture', picture.path));
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 201) throw Exception('Haryt iberilip bilinmedi: ${res.body}');
  }

  Future<void> deletePendingStoreItem(int id) async {
    final token = await AuthService().getToken();
    final res = await http
        .delete(Uri.parse('$baseUrl/api/pending-store-items/$id/'),
            headers: {'Authorization': 'Token $token'})
        .timeout(_timeout);
    if (res.statusCode != 204) throw Exception('Pozulup bilinmedi');
  }

  Future<void> approvePendingStoreItem(int id) async {
    final token = await AuthService().getToken();
    final res = await http
        .post(Uri.parse('$baseUrl/api/pending-store-items/$id/approve/'),
            headers: {'Authorization': 'Token $token'})
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Tassyklanyp bilinmedi');
  }

  Future<void> rejectPendingStoreItem(int id, {String reason = ''}) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/pending-store-items/$id/reject/'),
          headers: await _authHeaders(),
          body: json.encode({'reason': reason}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Ret edilip bilinmedi');
  }
}

import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json['id'] ?? 0, name: json['name'] ?? '');
}

class Village {
  final int id;
  final String name;

  Village({required this.id, required this.name});

  factory Village.fromJson(Map<String, dynamic> json) =>
      Village(id: json['id'] ?? 0, name: json['name'] ?? '');
}

class Announcement {
  final int id;
  final String name;
  final String description;
  final String? phoneNumber;
  final String status;
  final String expirationDate;
  final Category category;
  final String villageName;
  final double? latitude;
  final double? longitude;
  final List<String> photos;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.name,
    required this.description,
    this.phoneNumber,
    required this.status,
    required this.expirationDate,
    required this.category,
    required this.villageName,
    this.latitude,
    this.longitude,
    required this.photos,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      phoneNumber: json['phone_number'],
      status: json['status'] ?? 'active',
      expirationDate: json['expiration_date'] ?? '',
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : Category(id: 0, name: ''),
      villageName: json['village_name'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      photos: (json['photos'] as List?)
              ?.map((p) => p['image'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Color get statusColor {
    switch (status) {
      case 'active':
        return const Color(0xFF2E7D32);
      case 'expired':
        return const Color(0xFFB71C1C);
      default:
        return const Color(0xFFF57F17);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Işjeň';
      case 'expired':
        return 'Möhleti geçen';
      case 'not_active':
        return 'Işjeň däl';
      default:
        return status;
    }
  }
}

class PendingAnnouncement {
  final int id;
  final String name;
  final String description;
  final String? phoneNumber;
  final String expirationDate;
  final String categoryName;
  final String villageName;
  final String createdByUsername;
  final DateTime createdAt;
  final List<String> photos;

  PendingAnnouncement({
    required this.id,
    required this.name,
    required this.description,
    this.phoneNumber,
    required this.expirationDate,
    required this.categoryName,
    required this.villageName,
    required this.createdByUsername,
    required this.createdAt,
    required this.photos,
  });

  factory PendingAnnouncement.fromJson(Map<String, dynamic> json) {
    return PendingAnnouncement(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      phoneNumber: json['phone_number'],
      expirationDate: json['expiration_date'] ?? '',
      categoryName: json['category_name'] ?? '',
      villageName: json['village_name'] ?? '',
      createdByUsername: json['created_by_username'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      photos: (json['pending_photos'] as List?)
              ?.map((p) => p['image'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
    );
  }
}

class PendingEdit {
  final int id;
  final String name;
  final String description;
  final String expirationDate;
  final String categoryName;
  final String villageName;
  final String editedByUsername;
  final DateTime editedAt;
  final String originalAnnouncementName;
  final List<String> photos;

  PendingEdit({
    required this.id,
    required this.name,
    required this.description,
    required this.expirationDate,
    required this.categoryName,
    required this.villageName,
    required this.editedByUsername,
    required this.editedAt,
    required this.originalAnnouncementName,
    required this.photos,
  });

  factory PendingEdit.fromJson(Map<String, dynamic> json) {
    return PendingEdit(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      expirationDate: json['expiration_date'] ?? '',
      categoryName: json['category_name'] ?? '',
      villageName: json['village_name'] ?? '',
      editedByUsername: json['edited_by_username'] ?? '',
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : DateTime.now(),
      originalAnnouncementName:
          json['original_announcement']?['name'] ?? '',
      photos: (json['pending_photos'] as List?)
              ?.map((p) => p['image'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
    );
  }
}

class AnnouncementLog {
  final int id;
  final String logType;
  final String action;
  final String announcementName;
  final String managerUsername;
  final String adminUsername;
  final String reason;
  final DateTime createdAt;

  AnnouncementLog({
    required this.id,
    required this.logType,
    required this.action,
    required this.announcementName,
    required this.managerUsername,
    required this.adminUsername,
    required this.reason,
    required this.createdAt,
  });

  factory AnnouncementLog.fromJson(Map<String, dynamic> json) {
    return AnnouncementLog(
      id: json['id'] ?? 0,
      logType: json['log_type'] ?? '',
      action: json['action'] ?? '',
      announcementName: json['announcement_name'] ?? '',
      managerUsername: json['manager_username'] ?? '',
      adminUsername: json['admin_username'] ?? '',
      reason: json['reason'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  bool get isApproved => action == 'approved';
  bool get isEdit => logType == 'edit';

  Color get actionColor =>
      isApproved ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);

  String get actionLabel => isApproved ? 'Tassyklandy' : 'Ret edildi';
  String get typeLabel => isEdit ? 'Üýtgetme' : 'Bildiriş';
}

class Manager {
  final int id;
  final String username;
  final bool isActive;
  final DateTime dateJoined;

  Manager({
    required this.id,
    required this.username,
    required this.isActive,
    required this.dateJoined,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      isActive: json['is_active'] ?? true,
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : DateTime.now(),
    );
  }
}

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
  final int priority;

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
    this.priority = 0,
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
      priority: json['priority'] ?? 0,
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
  final double? latitude;
  final double? longitude;

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
    this.latitude,
    this.longitude,
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
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
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

class Banner {
  final int id;
  final String photo;
  final String linkType;
  final int? linkId;
  final String linkLabel;

  Banner({required this.id, required this.photo, required this.linkType, this.linkId, required this.linkLabel});

  factory Banner.fromJson(Map<String, dynamic> json) => Banner(
        id: json['id'] ?? 0,
        photo: json['photo'] ?? '',
        linkType: json['link_type'] ?? 'none',
        linkId: json['link_id'] as int?,
        linkLabel: json['link_label'] ?? '',
      );
}

class Promotion {
  final int id;
  final String photo;
  final String linkType;
  final int? linkId;
  final String linkLabel;
  final String frequency;
  final bool isActive;
  final int priority;

  Promotion({
    required this.id,
    required this.photo,
    required this.linkType,
    this.linkId,
    required this.linkLabel,
    required this.frequency,
    required this.isActive,
    required this.priority,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
        id: json['id'] ?? 0,
        photo: json['photo'] ?? '',
        linkType: json['link_type'] ?? 'none',
        linkId: json['link_id'] as int?,
        linkLabel: json['link_label'] ?? '',
        frequency: json['frequency'] ?? 'always',
        isActive: json['is_active'] ?? true,
        priority: json['priority'] ?? 0,
      );
}

class NotificationLog {
  final int id;
  final String title;
  final String body;
  final int sentTo;
  final int successCount;
  final int failureCount;
  final DateTime createdAt;

  NotificationLog({
    required this.id,
    required this.title,
    required this.body,
    required this.sentTo,
    required this.successCount,
    required this.failureCount,
    required this.createdAt,
  });

  factory NotificationLog.fromJson(Map<String, dynamic> json) => NotificationLog(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        sentTo: json['sent_to'] ?? 0,
        successCount: json['success_count'] ?? 0,
        failureCount: json['failure_count'] ?? 0,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      );
}

class StoreCategory {
  final int id;
  final String name;
  StoreCategory({required this.id, required this.name});
  factory StoreCategory.fromJson(Map<String, dynamic> json) =>
      StoreCategory(id: json['id'] ?? 0, name: json['name'] ?? '');
  @override
  bool operator ==(Object other) => other is StoreCategory && other.id == id;
  @override
  int get hashCode => id.hashCode;
  @override
  String toString() => name;
}

class Store {
  final int id;
  final String name;
  final String picture;
  final String description;
  final String? openTime;
  final String? closeTime;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final int villageId;
  final String villageName;
  final int categoryId;
  final String categoryName;
  final bool isActive;

  Store({
    required this.id,
    required this.name,
    required this.picture,
    required this.description,
    this.openTime,
    this.closeTime,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    required this.villageId,
    required this.villageName,
    required this.categoryId,
    required this.categoryName,
    required this.isActive,
  });

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        picture: json['picture'] ?? '',
        description: json['description'] ?? '',
        openTime: json['open_time'] as String?,
        closeTime: json['close_time'] as String?,
        phoneNumber: json['phone_number'] as String?,
        latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
        longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
        villageId: json['village'] ?? 0,
        villageName: json['village_name'] ?? '',
        categoryId: json['category'] ?? 0,
        categoryName: json['category_name'] ?? '',
        isActive: json['is_active'] ?? true,
      );
}

class StoreItem {
  final int id;
  final int storeId;
  final String name;
  final String picture;
  final String description;
  final double? price;

  StoreItem({
    required this.id,
    required this.storeId,
    required this.name,
    required this.picture,
    required this.description,
    this.price,
  });

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    double? price;
    if (json['price'] != null) price = double.tryParse(json['price'].toString());
    return StoreItem(
      id: json['id'] ?? 0,
      storeId: json['store'] ?? 0,
      name: json['name'] ?? '',
      picture: json['picture'] ?? '',
      description: json['description'] ?? '',
      price: price,
    );
  }
}

class PendingStoreItem {
  final int id;
  final int storeId;
  final String storeName;
  final String name;
  final String picture;
  final String description;
  final double? price;
  final String messageToAdmin;
  final String submittedByUsername;
  final DateTime createdAt;

  PendingStoreItem({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.name,
    required this.picture,
    required this.description,
    this.price,
    required this.messageToAdmin,
    required this.submittedByUsername,
    required this.createdAt,
  });

  factory PendingStoreItem.fromJson(Map<String, dynamic> json) {
    double? price;
    if (json['price'] != null) price = double.tryParse(json['price'].toString());
    return PendingStoreItem(
      id: json['id'] ?? 0,
      storeId: json['store'] ?? 0,
      storeName: json['store_name'] ?? '',
      name: json['name'] ?? '',
      picture: json['picture'] ?? '',
      description: json['description'] ?? '',
      price: price,
      messageToAdmin: json['message_to_admin'] ?? '',
      submittedByUsername: json['submitted_by_username'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
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

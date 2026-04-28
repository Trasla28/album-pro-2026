import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

typedef NavigateToTabCallback = void Function(int tabIndex);

class NotificationService {
  static final _foregroundController =
      StreamController<RemoteMessage>.broadcast();

  static Stream<RemoteMessage> get foregroundMessages =>
      _foregroundController.stream;

  static bool _initialized = false;

  static Future<void> initialize({
    required String userId,
    required NavigateToTabCallback onNavigate,
  }) async {
    if (_initialized) return;
    _initialized = true;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(token, userId);
      FirebaseMessaging.instance.onTokenRefresh
          .listen((t) => _saveToken(t, userId));
    } catch (_) {}

    FirebaseMessaging.onMessage.listen((message) {
      _saveNotification(message, userId);
      _foregroundController.add(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNavigation(message.data['type'] as String? ?? '', onNavigate);
    });

    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleNavigation(initial.data['type'] as String? ?? '', onNavigate);
      }
    } catch (_) {}
  }

  // Call on logout so the next login re-initializes.
  static void reset() => _initialized = false;

  static Future<void> _saveToken(String token, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('device_tokens')
          .doc(userId)
          .set({
        'userId': userId,
        'fcmToken': token,
        'platform': defaultTargetPlatform.name.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<void> _saveNotification(
      RemoteMessage message, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .add({
        'userId': userId,
        'type': message.data['type'] ?? 'generic',
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static void _handleNavigation(String type, NavigateToTabCallback onNavigate) {
    switch (type) {
      case 'swap_proposed':
      case 'swap_accepted':
        onNavigate(2);
      case 'sticker_obtained':
      case 'duplicate_available':
      case 'duplicate_claimed':
      case 'claim_reminder':
      case 'group_milestone':
        onNavigate(1);
      default:
        onNavigate(3);
    }
  }

  // Saves a notification locally (for events triggered within the app).
  static Future<void> saveLocalNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .add({
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}

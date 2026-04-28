enum NotificationType {
  stickerObtained,
  duplicateAvailable,
  duplicateClaimed,
  claimReminder,
  swapProposed,
  swapAccepted,
  groupMilestone,
  generic,
}

class NotificationEntity {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationEntity.fromMap(String id, Map<String, dynamic> map) {
    return NotificationEntity(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: parseType(map['type'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
      isRead: map['isRead'] as bool? ?? false,
      readAt: (map['readAt'] as dynamic)?.toDate() as DateTime?,
      createdAt:
          (map['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime.now(),
    );
  }

  static NotificationType parseType(String s) => switch (s) {
    'sticker_obtained' => NotificationType.stickerObtained,
    'duplicate_available' => NotificationType.duplicateAvailable,
    'duplicate_claimed' => NotificationType.duplicateClaimed,
    'claim_reminder' => NotificationType.claimReminder,
    'swap_proposed' => NotificationType.swapProposed,
    'swap_accepted' => NotificationType.swapAccepted,
    'group_milestone' => NotificationType.groupMilestone,
    _ => NotificationType.generic,
  };

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} d';
    return 'hace ${(diff.inDays / 7).floor()} sem';
  }
}

class NotificationPrefsEntity {
  final bool stickerObtained;
  final bool duplicateAvailable;
  final bool duplicateClaimed;
  final bool claimReminder;
  final bool swapProposed;
  final bool swapAccepted;
  final bool groupMilestone;

  const NotificationPrefsEntity({
    this.stickerObtained = true,
    this.duplicateAvailable = true,
    this.duplicateClaimed = true,
    this.claimReminder = true,
    this.swapProposed = true,
    this.swapAccepted = true,
    this.groupMilestone = true,
  });

  factory NotificationPrefsEntity.fromMap(Map<String, dynamic> map) {
    return NotificationPrefsEntity(
      stickerObtained: map['stickerObtained'] as bool? ?? true,
      duplicateAvailable: map['duplicateAvailable'] as bool? ?? true,
      duplicateClaimed: map['duplicateClaimed'] as bool? ?? true,
      claimReminder: map['claimReminder'] as bool? ?? true,
      swapProposed: map['swapProposed'] as bool? ?? true,
      swapAccepted: map['swapAccepted'] as bool? ?? true,
      groupMilestone: map['groupMilestone'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'stickerObtained': stickerObtained,
    'duplicateAvailable': duplicateAvailable,
    'duplicateClaimed': duplicateClaimed,
    'claimReminder': claimReminder,
    'swapProposed': swapProposed,
    'swapAccepted': swapAccepted,
    'groupMilestone': groupMilestone,
  };

  NotificationPrefsEntity copyWith({
    bool? stickerObtained,
    bool? duplicateAvailable,
    bool? duplicateClaimed,
    bool? claimReminder,
    bool? swapProposed,
    bool? swapAccepted,
    bool? groupMilestone,
  }) =>
      NotificationPrefsEntity(
        stickerObtained: stickerObtained ?? this.stickerObtained,
        duplicateAvailable: duplicateAvailable ?? this.duplicateAvailable,
        duplicateClaimed: duplicateClaimed ?? this.duplicateClaimed,
        claimReminder: claimReminder ?? this.claimReminder,
        swapProposed: swapProposed ?? this.swapProposed,
        swapAccepted: swapAccepted ?? this.swapAccepted,
        groupMilestone: groupMilestone ?? this.groupMilestone,
      );
}

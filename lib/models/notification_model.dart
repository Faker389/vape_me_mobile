class NotificationModel {
  bool pushNotifications;
  bool pointsActivity;
  bool promotions;
  bool newsUpdates;

  NotificationModel({
    required this.pushNotifications,
    required this.pointsActivity,
    required this.promotions,
    required this.newsUpdates,
  });

  factory NotificationModel.fromPrefs(Map<String, bool> prefs) {
    return NotificationModel(
      pushNotifications: prefs['push_notifications'] ?? true,
      pointsActivity: prefs['points_activity'] ?? true,
      promotions: prefs['promotions'] ?? true,
      newsUpdates: prefs['news_updates'] ?? false,
    );
  }

  Map<String, bool> toPrefs() {
    return {
      'push_notifications': pushNotifications,
      'points_activity': pointsActivity,
      'promotions': promotions,
      'news_updates': newsUpdates,
    };
  }
}

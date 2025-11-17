import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vape_me/models/user_model.dart';
import 'package:vape_me/utils/checkUser.dart';
import 'package:vape_me/utils/hive_storage.dart';

import '../../utils/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  UserModel? user;
  bool isLoadingUser = true;
  bool _pushNotifications = true;
  bool _pointsActivity = true;
  bool _promotions = true;
  bool _newsUpdates = false;
  bool _isLoading = false;
Future<void> loadUser() async {
  setState(() {
    isLoadingUser = true;
  });

  final loadedUser = await UserAuthHelper.checkUser(context);
  
  if (mounted) {
    setState(() {
      user = loadedUser;
      isLoadingUser = false;
    });
    
  }
}
  @override
  void initState() {
    loadUser();
    super.initState();
    _loadSettings();
  }
    void setStates(bool value) async {
  if (value) {
    // User turned ON the main switch
    await requestNotificationPermission();
    final bool checkedPermissions = await checkNotificationPermission();

    if (checkedPermissions) {
      // If permission granted, turn all ON
      setState(() {
        _pushNotifications = true;
        _pointsActivity = true;
        _promotions = true;
        _newsUpdates = true;
      });
    } else {
      // Permission denied — show popup and keep them off
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Powiadomienia wyłączone"),
            content: const Text(
              "Aby włączyć powiadomienia, zezwól na nie w ustawieniach urządzenia.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }

      setState(() {
        _pushNotifications = false;
        _pointsActivity = false;
        _promotions = false;
        _newsUpdates = false;
      });
    }
  } else {
    // User turned OFF the main switch → turn everything OFF
    setState(() {
      _pushNotifications = false;
      _pointsActivity = false;
      _promotions = false;
      _newsUpdates = false;
    });
  }
}



  Future<bool> checkNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.getNotificationSettings();
  return settings.authorizationStatus == AuthorizationStatus.authorized;
}
Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }
}
  Future<void> _loadSettings() async {
  setState(() => _isLoading = true);
  
  final bool hasPermission = await checkNotificationPermission();
  
  if (!hasPermission) {
    // No permission → disable all
    setState(() {
      _pushNotifications = false;
      _pointsActivity = false;
      _promotions = false;
      _newsUpdates = false;
      _isLoading = false;
    });
    return;
  }
  final push = user!.notifications!['pushNotifications'];

  setState(() {
    _pushNotifications = push!;
    _pointsActivity = push ? (user!.notifications!['pointsActivity'] ?? true) : false;
    _promotions = push ? (user!.notifications!['promotions'] ?? true) : false;
    _newsUpdates = push ? (user!.notifications!['newsUpdates'] ?? false) : false;
    _isLoading = false;
  });
}


  Future<Map<String, bool>> _saveSettings() async {
  setState(() => _isLoading = true);
  Map<String, bool> notificationModel = {
    "pushNotifications": _pushNotifications,
    "pointsActivity": _pointsActivity,
    "promotions": _promotions,
    "newsUpdates": _newsUpdates,
  };
  UserModel user = UserStorage.getUser()!;
  user.notifications=notificationModel;
  final response = await UserStorage.updateUser(user);
  print("Wynik koncowy: "+response.toString());
  setState(() => _isLoading = false);

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ustawienia zapisane'),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Return NotificationModel instance
  return notificationModel;
}


  @override
  Widget build(BuildContext context) {
    if (isLoadingUser || user == null) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackground,
              AppTheme.primaryPurple.withOpacity(0.1),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primaryPurple,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Ładowanie...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Powiadomienia'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryPurple.withOpacity(0.1),
                                AppTheme.primaryPink.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryPurple.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryPurple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryPurple,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Zarządzaj tym, o czym chcesz być powiadamiany',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // General Section
                        _buildSectionHeader('Ogólne'),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          'Powiadomienia Push',
                          'Otrzymuj powiadomienia na urządzeniu',
                          Icons.notifications_active,
                          _pushNotifications,
                          (value) => setStates(value),
                          const Color(0xFF667eea),
                        ),
                        const SizedBox(height: 32),
                        
                        // Activity Section
                        _buildSectionHeader('Aktywność'),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          'Aktywność buszków',
                          'Informacje o zmianach buszków',
                          Icons.stars,
                          _pointsActivity,
                          (value) => setState(() => _pointsActivity = value),
                          const Color(0xFF4facfe),
                        ),
                        const SizedBox(height: 32),
                        
                        // Marketing Section
                        _buildSectionHeader('Marketing'),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          'Promocje i oferty',
                          'Specjalne promocje i rabaty',
                          Icons.local_offer,
                          _promotions,
                          (value) => setState(() => _promotions = value),
                          const Color(0xFF43e97b),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingCard(
                          'Nowości',
                          'Informacje o nowych funkcjach',
                          Icons.new_releases,
                          _newsUpdates,
                          (value) => setState(() => _newsUpdates = value),
                          const Color(0xFFfa709a),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                
                // Save Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Zapisz ustawienia',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground,
            AppTheme.primaryPurple.withOpacity(0.05),
            AppTheme.primaryPink.withOpacity(0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.2),
                    AppTheme.primaryPurple.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryPink.withOpacity(0.15),
                    AppTheme.primaryPink.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingCard(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: color,
                activeTrackColor: color.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

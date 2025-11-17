import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vape_me/models/user_model.dart';
import 'package:vape_me/utils/hive_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();
  final _firebaseMess = FirebaseMessaging.instance;
  final user = UserStorage.getUser();

static final serviceAccount = {
    "type":dotenv.env["FIREBASE_type"],
    "project_id":dotenv.env["FIREBASE_project_id"],
    "private_key_id":dotenv.env["FIREBASE_private_key_id"],
    "private_key":dotenv.env["FIREBASE_private_key"],
    "client_email":dotenv.env["FIREBASE_client_email"],
    "client_id":dotenv.env["FIREBASE_client_id"],
    "auth_uri":dotenv.env["FIREBASE_auth_uri"],
    "token_uri":dotenv.env["FIREBASE_token_uri"],
    "auth_provider_x509_cert_url":dotenv.env["FIREBASE_auth_provider_x509_cert_url"],
    "client_x509_cert_url":dotenv.env["FIREBASE_client_x509_cert_url"],
    "universe_domain":dotenv.env["FIREBASE_universe_domain"],
}
;
      final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final projectId = "vapeme-61377";
      final notificationUrl = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
  static final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccount);
  static final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  final _localNotification = FlutterLocalNotificationsPlugin();
  
  static const String CHANNEL_ID = 'vape_me_channel';
  bool _notificationsInitialized = false;
  String? token;
   Future<bool> checkUser() async {
    final user = UserStorage.getUser();
    FirebaseAuth auth = FirebaseAuth.instance;
    final isUserAuthenticated = auth.currentUser;
    if (user == null) {
      if (isUserAuthenticated==null) return false;
      final phoneNumber = isUserAuthenticated.phoneNumber;
      await UserStorage.getUserFromDB(phoneNumber!);
      return true;
    } else {
      return true;
    }
  }
  // Initialize Firebase and local notifications
  Future<void> initialize() async {
    print('Initializing Firebase Messaging Service...');
  //   bool userExists = await checkUser();
  //   if (!userExists) {
  //   print('User not authenticated, skipping messaging init.');
  //   return;
  // }
    // Initialize Firebase (should be done once in main.dart, but safe to call multiple times)
    await Firebase.initializeApp();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request notification permissions
    await _firebaseMess.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Firebase Messaging Service initialized successfully');
  }

  Future<void> _initializeLocalNotifications() async {
    if (_notificationsInitialized) return;

    try {
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _localNotification.initialize(initializationSettings);

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        CHANNEL_ID,
        'Vape Me Notifications',
        description: 'Notifications for Vape Me app',
        importance: Importance.high,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotification.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
      }

      _notificationsInitialized = true;
      print('Local notifications initialized successfully');
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  // Get FCM token
  Future<String> getToken() async {
    try {
      String? token = await _firebaseMess.getToken();
      if (token == null || token.isEmpty) {
        // Wait for token refresh if no token available
        token = await _firebaseMess.onTokenRefresh.first;
      }
      print("FCM token: $token");
      return token;
    } catch (e) {
      print("Error getting FCM token: $e");
      return "no_token_available";
    }
  }



  // Set FCM token (for when you implement actual Firebase Messaging)
  void setToken(String newToken) {
    token = newToken;
    print('FCM Token set: $newToken');
  }
  Future<void> SendPointUpdateNotification(
    {
      required String points,
      required String token,
      String? phoneNumber
    }
  )async{
    if (user == null) {
    print("User not found, skipping notification.");
    return;
  }
  if(user!.notifications==null){
    return;
  }
      if(user!.notifications!["pushNotifications"]==false||(user!.notifications!["pushNotifications"]==true&&user!.notifications!["pointsActivity"]!=true)) return;
      String fcmToken="";
      if(phoneNumber!=null){
       final docSnapshot = await _db.collection('users').doc(phoneNumber).get();
      if (docSnapshot.exists) {
        final user = UserModel.fromMap(docSnapshot.data() as Map<String, dynamic>);
        fcmToken=user.token!;
      }else{
        fcmToken=token;
      }
      }
      final authClient = await clientViaServiceAccount(accountCredentials, scopes);
      
      final message = {
        "message": {
          "token": fcmToken,
          "notification": {"title": "Otrzymałeś nowe buszki!", "body": "Za twoją ostatnią transakcje otrzymałeś $points buszków!"},
          // "data": data ?? {},
          "android": {"priority": "high"},
        },
      };
    try {

    final response = await authClient.post(
      Uri.parse(notificationUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("✅ Notification sent!");
    } else {
      print("❌ Failed: ${response.statusCode}");
      print(response.body);
    }
  } catch (e) {
    print("Error sending notification: $e");
  } finally {
    authClient.close();
  }
  }
  Future<void> sendTransferedPointsNotification(
    {
      required String points,
      required String phoneNumber
    }
  )async{
    if (user == null) {
    print("User not found, skipping notification.");
    return;
  }
  if(user!.notifications==null){
    return;
  }
       final docSnapshot = await _db.collection('users').doc(phoneNumber).get();
      String fcmToken;
      if (docSnapshot.exists) {
        final user = UserModel.fromMap(docSnapshot.data() as Map<String, dynamic>);
        if(user.notifications!["pushNotifications"]==false||(user.notifications!["pushNotifications"]==true&&user.notifications!["pointsActivity"]!=true)) return;
        fcmToken=user.token!;
      }else{
        return;
      }
      
      final authClient = await clientViaServiceAccount(accountCredentials, scopes);
      
      final message = {
        "message": {
          "token": fcmToken,
          "notification": {"title": "Otrzymałeś nowe buszki!", "body": "Ktoś przelał ci nowe buszki w wysokości $points"},
          // "data": data ?? {},
          "android": {"priority": "high"},
        },
      };
    try {

    final response = await authClient.post(
      Uri.parse(notificationUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("✅ Notification sent!");
    } else {
      print("❌ Failed: ${response.statusCode}");
      print(response.body);
    }
  } catch (e) {
    print("Error sending notification: $e");
  } finally {
    authClient.close();
  }
  }
  Future<void> SendNewPromotionsNotification(
    {
        required String promotion,
       required String token,
      String? phoneNumber
    }
  )async{
    if (user == null) {
    print("User not found, skipping notification.");
    return;
  }
  if(user!.notifications==null){
    return;
  }
      if(user!.notifications!["pushNotifications"]==false||(user!.notifications!["pushNotifications"]==true&&user!.notifications!["promotions"]!=true)) return;
    String fcmToken="";
      if(phoneNumber!=null){
       final docSnapshot = await _db.collection('users').doc(phoneNumber).get();
      if (docSnapshot.exists) {
        final user = UserModel.fromMap(docSnapshot.data() as Map<String, dynamic>);
        fcmToken=user.token!;
      }else{
        fcmToken=token;
      }
      }
      final authClient = await clientViaServiceAccount(accountCredentials, scopes);
      
      final message = {
        "message": {
          "token": fcmToken,
          "notification": {"title": "Sprawdź nową promocję!", "body": promotion},
          // "data": data ?? {},
          "android": {"priority": "high"},
        },
      };
    try {

    final response = await authClient.post(
      Uri.parse(notificationUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("✅ Notification sent!");
    } else {
      print("❌ Failed: ${response.statusCode}");
      print(response.body);
    }
  } catch (e) {
    print("Error sending notification: $e");
  } finally {
    authClient.close();
  }
  }
  Future<void> SendAppNewsNotification(
    {
      required String changes,
       required String token,
      String? phoneNumber
    }
  )async{ if (user == null) {
    print("User not found, skipping notification.");
    return;
  }
  if(user!.notifications==null){
    return;
  }
      if(user!.notifications!["pushNotifications"]==false||(user!.notifications!["pushNotifications"]==true&&user!.notifications!["newsUpdates"]!=true)) return;
    String fcmToken="";
      if(phoneNumber!=null){
       final docSnapshot = await _db.collection('users').doc(phoneNumber).get();
      if (docSnapshot.exists) {
        final user = UserModel.fromMap(docSnapshot.data() as Map<String, dynamic>);
        fcmToken=user.token!;
      }else{
        fcmToken=token;
      }
      }
      final authClient = await clientViaServiceAccount(accountCredentials, scopes);
      
      final message = {
        "message": {
          "token": fcmToken,
          "notification": {"title": "Nowe zmiany w aplikacji", "body": changes},
          // "data": data ?? {},
          "android": {"priority": "high"},
        },
      };
    try {

    final response = await authClient.post(
      Uri.parse(notificationUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("✅ Notification sent!");
    } else {
      print("❌ Failed: ${response.statusCode}");
      print(response.body);
    }
  } catch (e) {
    print("Error sending notification: $e");
  } finally {
    authClient.close();
  }
  }
  // Send notification to a specific FCM token
  Future<void> sendNotificationToToken({
    required String title,
    required String body,
    required String fcmToken,
    Map<String, dynamic>? data,
  }) async {
    print('Sending notification to token: $fcmToken');

 
      final authClient = await clientViaServiceAccount(accountCredentials, scopes);
      
      final message = {
        "message": {
          "token": fcmToken,
          "notification": {"title": title, "body": body},
          "data": data ?? {},
          "android": {"priority": "high"},
        },
      };
    try {

    final response = await authClient.post(
      Uri.parse(notificationUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("✅ Notification sent!");
    } else {
      print("❌ Failed: ${response.statusCode}");
      print(response.body);
    }
  } catch (e) {
    print("Error sending notification: $e");
  } finally {
    authClient.close();
  }
  }


  // Show local notification on current device
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsInitialized) {
      await _initializeLocalNotifications();
    }

    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      const androidDetails = AndroidNotificationDetails(
        CHANNEL_ID,
        'Vape Me Notifications',
        channelDescription: 'Notifications for Vape Me app',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotification.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('Local notification shown successfully with ID: $notificationId');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Test method to send a notification
  Future<void> sendTestNotification() async {
    final token = await getToken();
    print("Token: "+token);
    try{

    await sendNotificationToToken(
      title: 'Test Notification',
      body: 'This is a test notification from Vape Me',
      fcmToken: token,
      data: {'type': 'test'},
    );
    }  catch (e) {
      print('Error sending test notification: $e');
    }
  }
  }

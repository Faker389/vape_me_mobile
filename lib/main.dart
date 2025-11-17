import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:vape_me/models/coupon_model.dart';
import 'package:vape_me/models/transaction_model.dart';
import 'package:vape_me/providers/coupon_provider.dart';
import 'package:vape_me/screens/auth/welcome_screen.dart';
import 'package:vape_me/screens/main_screen.dart';
import 'package:vape_me/utils/hive_storage.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/rewards_provider.dart';
import 'utils/theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';
import 'utils/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb; // 👈 Add this
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.deleteBoxFromDisk("userBox");
  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionTypeAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TransactionModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(CouponModelAdapter());
  await UserStorage.init();

  // Initialize Firebase Messaging
 final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
await flutterLocalNotificationsPlugin.initialize(
  const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  ),
);

FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  final notification = message.notification;
  if (notification != null) {
    flutterLocalNotificationsPlugin.show(
      0,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          FirebaseMessagingService.CHANNEL_ID,
          'Vape Me Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
});
  // ✅ Check if user is already logged in
  final firebaseUser = fb.FirebaseAuth.instance.currentUser;
  
  runApp(MyApp(
    isUserLoggedIn: firebaseUser != null, // 👈 Pass this info to MyApp
  ));
}

class MyApp extends StatelessWidget {
  final bool isUserLoggedIn;
  const MyApp({Key? key, required this.isUserLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RewardsProvider()),
        ChangeNotifierProvider(create: (_) => CouponsProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
        final firebaseUser = fb.FirebaseAuth.instance.currentUser;
          // Start user listener when authenticated
          if (firebaseUser!=null&&firebaseUser.phoneNumber!=null) {
            UserStorage.syncFromFirestore(firebaseUser.phoneNumber!);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<UserProvider>(context, listen: false).startUserListener();
            });
          }

          return MaterialApp(
            title: 'Vape Me',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home:firebaseUser!=null? const MainScreen():const WelcomeScreen(),
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:vape_me/utils/firebase_messaging.dart';

import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../main_screen.dart';
import '../../utils/hive_storage.dart';
import '../../models/user_model.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? name;
  final String? email;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.name,
    this.email,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _otpController = TextEditingController();
  String _currentOTP = '';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<bool> checkNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  void _verifyOTP() async {
    if (_currentOTP.length != 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wpisz cały kod weryfikacyjny (6 cyfr)'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOTP(
      _currentOTP,
      name: widget.name,
      email: widget.email,
    );

    if (!mounted) return;
    if (authProvider.user?.uid==null) return;
    if (success) {
      
      await _handleUserData(authProvider.user!.uid);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Niepoprawny kod weryfikacyjny'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
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
  }}
  Future<void> _handleUserData(userID) async {
    try {
      if (widget.name != null && widget.email != null) {
        await _createNewUser(userID);
      } else {
        await _loadExistingUser();
      }

      if (!mounted) return;

      // ✅ Navigate safely
      await requestNotificationPermission();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error handling user data: $e');
    }
  }

  Future<void> _createNewUser(userID) async {
    final token = await FirebaseMessagingService().getToken();

    final user = UserModel(
      uid: userID,
      name: widget.name!,
      email: widget.email!,
      phoneNumber: widget.phoneNumber,
      points: 0,
      qrCode: widget.phoneNumber,
      createdAt: DateTime.now().toIso8601String(),
      transactions: [],
      token: token,
      coupons: [],
      notifications: {
        "pushNotifications": await checkNotificationPermission(),
        "pointsActivity": false,
        "promotions": false,
        "newsUpdates": false,
      },
    );

    final response = await UserStorage.updateUser(user);
    if (response) {
      debugPrint("✅ New user created successfully");
    } else {
      debugPrint("❌ Error creating new user");
    }
  }

  Future<void> _loadExistingUser() async {
    final docSnapshot = await _db.collection('users').doc(widget.phoneNumber).get();
    if (docSnapshot.exists) {
      final user = UserModel.fromMap(docSnapshot.data() as Map<String, dynamic>);
      await UserStorage.updateUser(user);
    }
  }

  void _resendOTP() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.sendOTP(widget.phoneNumber);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wysłano kod weryfikacyjny'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard
      child: Scaffold(
        resizeToAvoidBottomInset: true, // ✅ fixes overflow
        appBar: AppBar(
          title: const Text('Zweryfikuj telefon'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.sms,
                    size: 40,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Kod weryfikacyjny',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),

                Text(
                  'Wysłaliśmy ci 6-cyfrowy kod',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),

                Text(
                  widget.phoneNumber,
                  style: const TextStyle(
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),

                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  autoFocus: true,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 56,
                    fieldWidth: 48,
                    activeFillColor: AppTheme.surfaceColor,
                    inactiveFillColor: AppTheme.surfaceColor,
                    selectedFillColor: AppTheme.surfaceColor,
                    activeColor: AppTheme.primaryPurple,
                    inactiveColor: AppTheme.textSecondary,
                    selectedColor: AppTheme.primaryPurple,
                  ),
                  enableActiveFill: true,
                  textStyle: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (value) {
                    if (mounted) {
                      setState(() => _currentOTP = value);
                    }
                  },
                  onCompleted: (_) => _verifyOTP(),
                ),
                const SizedBox(height: 32),

                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _verifyOTP,
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Zweryfikuj kod'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Nie otrzymałeś kodu?',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: _resendOTP,
                      child: const Text(
                        'Wyślij ponownie',
                        style: TextStyle(color: AppTheme.primaryPurple),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

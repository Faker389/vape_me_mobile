import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vape_me/models/user_model.dart';
import 'package:vape_me/screens/auth/welcome_screen.dart';
import 'package:vape_me/utils/hive_storage.dart';

class UserAuthHelper {
  /// Checks for user authentication and returns UserModel if authenticated.
  /// Navigates to WelcomeScreen if user is not found or not authenticated.
  /// 
  /// This function checks in the following order:
  /// 1. Local storage (Hive) - fastest
  /// 2. Firebase Auth current user
  /// 3. Database lookup via phone number
  /// 4. Redirects to WelcomeScreen if all checks fail
  static Future<UserModel?> checkUser(BuildContext context) async {
    final firebaseAuth = FirebaseAuth.instance;
    final localUser = UserStorage.getUser();

    // 1️⃣ If user exists locally — return it immediately
    if (localUser != null) {
      return localUser;
    }

    // 2️⃣ If user does NOT exist locally
    final firebaseUser = firebaseAuth.currentUser;

    // 2a️⃣ If there is no logged-in Firebase user → go to WelcomeScreen
    if (firebaseUser == null) {
      _navigateToWelcome(context);
      return null;
    }

    // 2b️⃣ If there IS a Firebase user → try to load from DB
    final phoneNumber = firebaseUser.phoneNumber;
    if (phoneNumber == null) {
      return null;
    }

    final dbUser = await UserStorage.getUserFromDB(phoneNumber);
    if (dbUser != null) {
      return dbUser;
    }

    // 3️⃣ If not found anywhere → go to WelcomeScreen
    _navigateToWelcome(context);
    return null;
  }

  /// Helper method to navigate to WelcomeScreen
  static void _navigateToWelcome(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
        );
      }
    });
  }

  /// Checks if user is authenticated without navigation
  /// Useful for checking auth status without side effects
  static Future<bool> isUserAuthenticated() async {
    final localUser = UserStorage.getUser();
    if (localUser != null) {
      return true;
    }

    final firebaseAuth = FirebaseAuth.instance;
    final firebaseUser = firebaseAuth.currentUser;
    
    if (firebaseUser == null) {
      return false;
    }

    final phoneNumber = firebaseUser.phoneNumber;
    if (phoneNumber == null) {
      return false;
    }

    final dbUser = await UserStorage.getUserFromDB(phoneNumber);
    return dbUser != null;
  }
}
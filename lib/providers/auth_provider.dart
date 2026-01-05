import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _loadUserModel();
    } else {
      _userModel = null;
    }
    notifyListeners();
  }
Future<void> deleteAccount() async {
  try {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setError('User not logged in');
      return;
    }

    final phoneNumber = user.phoneNumber;
    if (phoneNumber == null) {
      _setError('Phone number not found');
      return;
    }

    /// 1️⃣ DELETE USER DATA FIRST (still authenticated)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(phoneNumber)
        .delete();
    print("USUNIETO LUDZIA00'");
    /// 2️⃣ DELETE AUTH ACCOUNT
    await user.delete();
    print("USUNIETO LUDZIA00 2'");

  } on FirebaseAuthException catch (e) {

    if (e.code == 'requires-recent-login') {
      _setError('REAUTH_REQUIRED');
    } else {
      _setError(e.message ?? 'Auth error');
    }
    return;
  } catch (e) {
    _setError('Failed to delete account');
    return;
  }
}

  Future<void> _loadUserModel() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      _errorMessage = 'Failed to load user data: $e';
    }
    notifyListeners();
  }

  // <CHANGE> Fixed sendOTP to prevent infinite loading and auto sign-in
Future<bool> sendOTP(String phoneNumber) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  final completer = Completer<bool>();

  try {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),

      // Don't auto sign in immediately
      verificationCompleted: (PhoneAuthCredential credential) {
        // Only store the credential, don't sign in yet
        // User will manually enter code
        if (!completer.isCompleted) completer.complete(true);
        _isLoading = false;
        notifyListeners();
      },

      verificationFailed: (FirebaseAuthException e) {
        _errorMessage = e.message;
        _isLoading = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(false);
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _isLoading = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(true);
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        _isLoading = false;
        notifyListeners();
      },
    );

    return completer.future;
  } catch (e) {
    _errorMessage = e.toString();
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  Future<bool> verifyOTP(String smsCode, {String? name, String? email}) async {
    if (_verificationId == null) {
      _errorMessage = "No verification ID. Please request a new code.";
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to sign in: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to send reset email: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
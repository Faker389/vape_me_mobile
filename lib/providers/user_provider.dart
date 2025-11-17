import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:vape_me/models/user_model.dart';
import 'package:vape_me/utils/hive_storage.dart';

import '../models/transaction_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
void startUserListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Cancel any existing subscription
    _userSubscription?.cancel();

    // Listen to user document changes
    _userSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final userData = snapshot.data()!;
          final userModel = UserModel.fromMap(userData);
          
          // Update Hive storage with latest data
          UserStorage.saveUser(userModel);
          
          // Notify listeners that user data changed
          notifyListeners();
        }
      },
      onError: (error) {
        print('Error listening to user changes: $error');
      },
    );
  }

  // Stop listening to user document changes
  void stopUserListener() {
    _userSubscription?.cancel();
    _userSubscription = null;
  }

  // Manual refresh from Firestore
  Future<void> refreshUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    print("Refreshing user data");
    try {
      await UserStorage.syncFromFirestore(user.phoneNumber!);
      notifyListeners();
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }
  Future<void> loadTransactions() async {
    final user = UserStorage.getUser();
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
     
      _transactions = user.transactions!.toList();
      // If no transactions found, use dummy data for demo
      if (_transactions.isEmpty) {
        _transactions = [];
      }

      _setLoading(false);
    } catch (e) {
      // If there's an error (like no internet), use dummy data
      _transactions = [];
      _setLoading(false);
    }
  }

  Future<bool> addPoints(int points, String description) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final batch = _firestore.batch();
      
      // Create transaction
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        type: TransactionType.earn,
        points: points,
        description: description,
        timestamp: DateTime.now(),
      );

      batch.set(
        _firestore.collection('transactions').doc(transaction.id),
        transaction.toMap(),
      );

      // Update user points
      batch.update(
        _firestore.collection('users').doc(user.uid),
        {
          'points': FieldValue.increment(points),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      await batch.commit();
      await loadTransactions();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add points: $e');
      return false;
    }
  }

  Future<bool> redeemPoints(int points, String description, String? rewardId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      // Check if user has enough points
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final currentPoints = userDoc.data()?['points'] ?? 0;
      
      if (currentPoints < points) {
        _setError('Insufficient points');
        return false;
      }

      final batch = _firestore.batch();
      
      // Create transaction
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        type: TransactionType.redeem,
        points: points,
        description: description,
        timestamp: DateTime.now(),
        rewardId: rewardId,
      );

      batch.set(
        _firestore.collection('transactions').doc(transaction.id),
        transaction.toMap(),
      );

      // Update user points
      batch.update(
        _firestore.collection('users').doc(user.uid),
        {
          'points': FieldValue.increment(-points),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      await batch.commit();
      await loadTransactions();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to redeem points: $e');
      return false;
    }
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
    @override
  void dispose() {
    stopUserListener();
    super.dispose();
  }
}

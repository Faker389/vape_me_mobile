import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/coupon_model.dart';

class CouponsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CouponModel> _coupons = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CouponModel> get allCoupons => _coupons;

  List<CouponModel> get activeCoupons {
    return _coupons
        .where((c) => c.isActive && !c.isExpired)
        .toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  List<CouponModel> get usedCoupons {
    return _coupons
        .where((c) => c.isUsed)
        .toList()
        ..sort((a, b) {
          if (a.usedDate == null) return 1;
          if (b.usedDate == null) return -1;
          return b.usedDate!.compareTo(a.usedDate!);
        });
  }

  List<CouponModel> get expiredCoupons {
    return _coupons
        .where((c) => c.isExpired && !c.isUsed)
        .toList()
        ..sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load user's claimed coupons from Firestore
  Future<void> loadUserCoupons() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.phoneNumber)
          .collection('coupons')
          .get();

      _coupons = snapshot.docs.map((doc) {
        final data = doc.data();
        return CouponModel(
          id: data["id"],
          rewardID: data["rewardID"],
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          pointsCost: data['pointsCost'] ?? 0,
          isDiscount:data['isDiscount']??false,
          claimedDate: (data['claimedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ??
              DateTime.now().add(const Duration(days: 30)),
          isUsed: data['isUsed'] ?? false,
          usedDate: (data['usedDate'] as Timestamp?)?.toDate(),
          category: data['category'] ?? 'Inne',
          imageUrl: data['imageUrl'],
        );
      }).toList();

      _setLoading(false);
    } catch (e) {
      _setError('Nie udało się załadować kuponów: $e');
    }
  }

  /// Claim a reward and convert it to a coupon
  Future<bool> claimReward({
    required String rewardId,
    required String title,
    required String description,
    required int pointsCost,
    required String category,
    required bool isDiscount,
    required int discountPercentage,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('Musisz być zalogowany');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Generate unique coupon code
      
      // Create coupon
      final coupon = CouponModel(
        id: Uuid().v4(), // Will be set by Firestore
        title: title,
        rewardID: rewardId,
        description: description,
        pointsCost: pointsCost,
        claimedDate: DateTime.now(),
        isDiscount:isDiscount,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        isUsed: false,
        category: category,
        imageUrl: imageUrl,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(user.phoneNumber)
          .collection('coupons')
          .add({
        'title': coupon.title,
        'description': coupon.description,
        'pointsCost': coupon.pointsCost,
        'claimedDate': Timestamp.fromDate(coupon.claimedDate),
        'expiryDate': Timestamp.fromDate(coupon.expiryDate),
        'isUsed': coupon.isUsed,
        'usedDate': null,
        'category': coupon.category,
        'imageUrl': coupon.imageUrl,
      });

      // Add to local list with Firestore ID
      final newCoupon = CouponModel(
        id: docRef.id,
        rewardID: coupon.rewardID,
        title: coupon.title,
        description: coupon.description,
        pointsCost: coupon.pointsCost,
        isDiscount: isDiscount,
        claimedDate: coupon.claimedDate,
        expiryDate: coupon.expiryDate,
        isUsed: coupon.isUsed,
        category: coupon.category,
        imageUrl: coupon.imageUrl,
      );

      _coupons.add(newCoupon);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Nie udało się odebrać nagrody: $e');
      return false;
    }
  }

  /// Mark a coupon as used
  Future<bool> useCoupon(String couponId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _firestore
          .collection('users')
          .doc(user.phoneNumber)
          .collection('coupons')
          .doc(couponId)
          .update({
        'isUsed': true,
        'usedDate': Timestamp.fromDate(DateTime.now()),
      });

      // Update local list
      final index = _coupons.indexWhere((c) => c.id == couponId);
      if (index != -1) {
        _coupons[index] = _coupons[index].copyWith(
          isUsed: true,
          usedDate: DateTime.now(),
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Nie udało się użyć kuponu: $e');
      return false;
    }
  }

  /// Delete a coupon
  Future<bool> deleteCoupon(String couponId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _firestore
          .collection('users')
          .doc(user.phoneNumber)
          .collection('coupons')
          .doc(couponId)
          .delete();

      _coupons.removeWhere((c) => c.id == couponId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Nie udało się usunąć kuponu: $e');
      return false;
    }
  }

  /// Generate a random coupon code


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

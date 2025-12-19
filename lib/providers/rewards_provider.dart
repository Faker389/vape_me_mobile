import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';

class RewardsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<RewardModel> _rewards = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  List<RewardModel> get rewards => _selectedCategory == 'All'
      ? _rewards
      : _rewards.where((r) => r.category == _selectedCategory).toList();
  List<String> get categories => ['All', ..._categories];
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ✅ Load rewards from Firestore
Future<void> loadRewards() async {
  _setLoading(true);
  _clearError();

  try {
    final snapshot = await _firestore.collection('coupons').get();
    _rewards = snapshot.docs.map((doc) {
      final data = doc.data();
      return RewardModel(
        id: doc.id,
        isDiscount: data['isDiscount'] ?? false,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        pointsCost: data['pointsCost'] ?? 0,
        category: data['category'] ?? 'Uncategorized',
        discountAmount: data['discountamount'] ?? 0, 
        expiryDate: data["expiryDate"] ?? DateTime.now(),
        minimalPrice: data["minimalPrice"]??0
      );
    }).toList();
    
    _categories = _rewards.map((r) => r.category).toSet().toList();
    
    _setLoading(false); // ✅ ADD THIS - was missing!
  } catch (e) {
    print("Error loading rewards: $e"); // ✅ Add debug print
    _setError('Failed to load rewards: $e');
  }
}

  /// ✅ Insert initial dummy rewards into Firestore
  

  /// Dummy data (only used for initial Firestore seed)
 

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  RewardModel? getRewardById(String id) {
    try {
      return _rewards.firstWhere((reward) => reward.id == id);
    } catch (e) {
      return null;
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
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

class UserStorage {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final Box<UserModel> _userBox = Hive.box<UserModel>('userBox');
  static Box<UserModel>? _box;
  
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    _box = await Hive.openBox<UserModel>("userBox");
  }
  
  static Box<UserModel> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('UserStorage not initialized. Call UserStorage.init() first.');
    }
    return _box!;
  }
  
  // <CHANGE> Use Firebase Auth UID as document ID
  static Future<bool> updateUser(UserModel user) async {
    try {
      // Use the user's UID (which should match Firebase Auth UID) as document ID
      await _db.collection('users').doc(user.phoneNumber).set(user.toMap());
      await saveUser(user);
      return true;
    } catch(e) {
      print('Error updating user: $e');
      return false;
    }
  }
  
  static bool hasUser() {
    return box.containsKey("userBox");
  }
  
  // <CHANGE> Query users by phone number to check if account exists
  static Future<UserModel?> getUserFromDB(String phoneNumber) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final userData = querySnapshot.docs.first.data();
      final user = UserModel.fromMap(userData);
      await saveUser(user);
      return user;
    } catch (e) {
      print('Error fetching user from DB: $e');
      return null;
    }
  }
  
  static Future<void> saveUser(UserModel user) async {
    await box.put("userBox", user);
  }
  
  static Future<void> syncFromFirestore(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docSnapshot = await firestore.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;
        final user = UserModel.fromMap(userData);
        await saveUser(user);
      }
    } catch (e) {
      print('Error syncing from Firestore: $e');
    }
  }
  
  static UserModel? getUser() {
    return _userBox.get('userBox');
  }

  static Future<void> clearUser() async {
    await _userBox.delete('userBox');
  }
}
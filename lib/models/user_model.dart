import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vape_me/models/transaction_model.dart';
import 'package:vape_me/models/coupon_model.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phoneNumber;

  @HiveField(4)
  int points;

  @HiveField(5)
  String qrCode;

  @HiveField(6)
  String createdAt;

  @HiveField(7)
  List<TransactionModel>? transactions;

  @HiveField(8)
  String? token;

  @HiveField(9)
  Map<String, bool>? notifications;

  @HiveField(10)
  List<CouponModel>? coupons;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.points,
    required this.qrCode,
    required this.createdAt,
    this.transactions,
    this.token,
    this.notifications,
    this.coupons,
  });

  // ✅ Safe setters
  set setName(String value) => name = value;
  set setEmail(String value) => email = value;
  set setPoints(int value) => points = value;
  set setTransactions(List<TransactionModel> value) => transactions = value;
  set setNotifications(Map<String, bool> value) => notifications = value;
  set setCoupons(List<CouponModel> value) => coupons = value;

  // 🎫 Coupon helper getters
  List<CouponModel> get allCoupons => (coupons ?? []).toList();
  List<CouponModel> get activeCoupons =>
      (coupons ?? []).where((c) => c.isActive).toList();
  List<CouponModel> get usedCoupons =>
      (coupons ?? []).where((c) => c.isUsed).toList();
  List<CouponModel> get expiredCoupons =>
      (coupons ?? []).where((c) => c.isExpired && !c.isUsed).toList();
  List<String> getCouponIds() {
    return (coupons ?? []).map((coupon) => coupon.rewardID).toList();
  }
  // 🧩 Add a new transaction safely
  void addTransaction(TransactionModel newTransaction) {
    transactions = (transactions ?? [])..add(newTransaction);
  }

  // 🧩 Add a new coupon safely
  void addCoupon(CouponModel newCoupon) {
    coupons = (coupons ?? [])..add(newCoupon);
  }

  // 🧩 Factory & serialization
  factory UserModel.fromMap(Map<String, dynamic> map) {
  // handle Firestore Timestamp or String
  String createdAtStr;
  if (map['createdAt'] is String) {
    createdAtStr = map['createdAt'];
  } else if (map['createdAt'] is Timestamp) {
    createdAtStr = (map['createdAt'] as Timestamp).toDate().toIso8601String();
  } else {
    createdAtStr = DateTime.now().toIso8601String();
  }

  return UserModel(
    uid: map['uid'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    phoneNumber: map['phoneNumber'] ?? '',
    points: map['points'] ?? 0,
    qrCode: map['qrCode'] ?? '',
    createdAt: createdAtStr,
    transactions: (map['transactions'] as List<dynamic>?)
            ?.map((e) => TransactionModel.fromMap(e))
            .toList() ??
        [],
    token: map['token'],
    notifications: (map['notifications'] != null)
        ? Map<String, bool>.from(map['notifications'])
        : {},
    coupons: (map['coupons'] as List<dynamic>?)
            ?.map((e) => CouponModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}


  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'points': points,
        'qrCode': qrCode,
        'createdAt': createdAt,
        'transactions': (transactions ?? []).map((t) => t.toMap()).toList(),
        'token': token,
        'notifications': notifications ?? {},
        'coupons': (coupons ?? []).map((c) => c.toJson()).toList(),
      };
}

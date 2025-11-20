import 'package:hive/hive.dart';

part 'coupon_model.g.dart';

@HiveType(typeId: 3)
class CouponModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int pointsCost;

  @HiveField(4)
  final DateTime claimedDate;

  @HiveField(5)
  final DateTime expiryDate;

  @HiveField(6)
  final bool isUsed;

  @HiveField(7)
  final DateTime? usedDate;

  @HiveField(8)
  final String category;

  @HiveField(9)
  final String? imageUrl;
  
  @HiveField(10)
  final String rewardID;
  
  @HiveField(11)
  final bool isDiscount;

  @HiveField(12)
  final int minimalPrice;

  @HiveField(13)
  final int? discountAmount;

  CouponModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.claimedDate,
    required this.expiryDate,
    required this.isDiscount,
    this.isUsed = false,
    this.usedDate,
    this.discountAmount=0,
    this.minimalPrice=0,
    required this.category,
    this.imageUrl,
    required this.rewardID
  });

  // Status checks
  bool get isExpired => DateTime.now().isAfter(expiryDate);
  
  bool get isActive => !isUsed && !isExpired;

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  // From JSON (Firestore)
  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      pointsCost: json['pointsCost'] ?? 0,
      isDiscount: json["isDiscount"]??false,
      claimedDate: json['claimedDate'] != null 
          ? DateTime.parse(json['claimedDate']) 
          : DateTime.now(),
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate']) 
          : DateTime.now().add(const Duration(days: 30)),
      isUsed: json['isUsed'] ?? false,
      usedDate: json['usedDate'] != null 
          ? DateTime.parse(json['usedDate']) 
          : null,
      category: json['category'] ?? 'Inne',
      imageUrl: json['imageUrl'],
      rewardID: json["rewardID"]??"",
      minimalPrice: json['minimalPrice'] ?? 0,
      discountAmount: json['discountAmount'] ?? 0,
    );
  }

  // To JSON (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'claimedDate': claimedDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'isUsed': isUsed,
      'isDiscount':isDiscount,
      'usedDate': usedDate?.toIso8601String(),
      'category': category,
      'imageUrl': imageUrl,
      'rewardID': rewardID,
      'minimalPrice': minimalPrice,
      'discountAmount': discountAmount,
    };
  }

  // CopyWith method for updating coupon
  CouponModel copyWith({
    String? id,
    String? title,
    String? description,
    String? code,
    int? pointsCost,
    DateTime? claimedDate,
    DateTime? expiryDate,
    bool? isUsed,
    DateTime? usedDate,
    String? category,
    int? discountPercentage,
    String? imageUrl,
    String? rewardID,
    int? minimalPrice,
  }) {
    return CouponModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      claimedDate: claimedDate ?? this.claimedDate,
      isDiscount:isDiscount,
      discountAmount: discountAmount,
      expiryDate: expiryDate ?? this.expiryDate,
      isUsed: isUsed ?? this.isUsed,
      usedDate: usedDate ?? this.usedDate,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      rewardID: rewardID ?? this.rewardID,
      minimalPrice: minimalPrice ?? this.minimalPrice,
    );
  }
}

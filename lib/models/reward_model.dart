import 'package:cloud_firestore/cloud_firestore.dart';

class RewardModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int pointsCost;
  final String category;
  final bool isDiscount;
  final int? discountamount;
  final String expiryDate;
  final int? minimalPrice;
  RewardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.pointsCost,
    required this.category,
    required this.isDiscount,
    this.discountamount,
    required this.expiryDate,
    this.minimalPrice,
  });

  factory RewardModel.fromMap(Map<String, dynamic> map) {
    return RewardModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      pointsCost: map['pointsCost'] ?? 0,
      category: map['category'] ?? '',
      isDiscount: map['isDiscount'] ?? false,
      expiryDate: map["expiryDate"]??DateTime.now().toIso8601String(),
      discountamount: map['discountamount']??0,
      minimalPrice: map['minimalPrice'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'pointsCost': pointsCost,
      'category': category,
      'isDiscount':isDiscount,
      'expiryDate': expiryDate,
      'minimalPrice': minimalPrice,
      'discountamount':discountamount,
    };
  }
}

import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  earn,
  @HiveField(1)
  redeem,
}

@HiveType(typeId: 2)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final TransactionType type;

  @HiveField(2)
  final int points;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? rewardId;

  @HiveField(6)
  final String? imageUrl;

  TransactionModel({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    required this.timestamp,
    this.rewardId,
    this.imageUrl,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      type: map['type'] == 'earn' ? TransactionType.earn : TransactionType.redeem,
      points: map['points'] ?? 0,
      description: map['description'] ?? '',
      timestamp: (map['timestamp'])?.toDate() ??
          DateTime.tryParse(map['timestamp'] ?? '') ??
          DateTime.now(),
      rewardId: map['rewardId'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'points': points,
      'description': description,
      'timestamp': timestamp,
      'rewardId': rewardId,
      'imageUrl': imageUrl,
    };
  }
}

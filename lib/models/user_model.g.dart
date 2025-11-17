// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      uid: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      phoneNumber: fields[3] as String,
      points: fields[4] as int,
      qrCode: fields[5] as String,
      createdAt: fields[6] as String,
      transactions: (fields[7] as List?)?.cast<TransactionModel>(),
      token: fields[8] as String?,
      notifications: (fields[9] as Map?)?.cast<String, bool>(),
      coupons: (fields[10] as List?)?.cast<CouponModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(4)
      ..write(obj.points)
      ..writeByte(5)
      ..write(obj.qrCode)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.transactions)
      ..writeByte(8)
      ..write(obj.token)
      ..writeByte(9)
      ..write(obj.notifications)
      ..writeByte(10)
      ..write(obj.coupons);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

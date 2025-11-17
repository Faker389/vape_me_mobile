// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CouponModelAdapter extends TypeAdapter<CouponModel> {
  @override
  final int typeId = 3;

 @override
CouponModel read(BinaryReader reader) {
  final numOfFields = reader.readByte();
  final fields = <int, dynamic>{
    for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
  };
  return CouponModel(
    id: fields[0] as String,
    title: fields[1] as String,
    description: fields[2] as String,
    pointsCost: fields[3] as int,
    claimedDate: fields[4] as DateTime,
    expiryDate: fields[5] as DateTime,
    isDiscount: fields[11] as bool? ?? false,  // ✅ default to false if null
    isUsed: fields[6] as bool? ?? false,       // ✅ default to false if null
    usedDate: fields[7] as DateTime?,
    category: fields[8] as String,
    imageUrl: fields[9] as String?,
    rewardID: fields[10] as String,
  );
}

  @override
  void write(BinaryWriter writer, CouponModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.pointsCost)
      ..writeByte(4)
      ..write(obj.claimedDate)
      ..writeByte(5)
      ..write(obj.expiryDate)
      ..writeByte(6)
      ..write(obj.isUsed)
      ..writeByte(7)
      ..write(obj.usedDate)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.imageUrl)
      ..writeByte(10)
      ..write(obj.rewardID)
      ..writeByte(11)
      ..write(obj.isDiscount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CouponModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

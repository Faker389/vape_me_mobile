import 'package:cloud_firestore/cloud_firestore.dart';


class VersionManager {
  static final VersionManager _instance = VersionManager._internal();
  factory VersionManager() => _instance;
  VersionManager._internal();

  final _db = FirebaseFirestore.instance;

  Stream<int> versionStream() {
    return _db
        .collection("version")
        .doc("tKgVv0pQwNzcN59MDaGy")
        .snapshots()
        .map((doc) => int.tryParse(doc.data()?["currentVersion"] ?? "0") ?? 0);
  }
}

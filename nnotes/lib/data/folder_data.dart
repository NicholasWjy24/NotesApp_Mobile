import 'package:localstore/localstore.dart';

class FolderData {
  final String folderId;
  final String name;

  FolderData({required this.folderId, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'folderId': folderId,
      'name': name,
    };
  }

  factory FolderData.fromMap(Map<String, dynamic> map) {
    return FolderData(
      folderId: map['folderId'] as String,
      name: map['name'] as String,
    );
  }

  Future<void> save() async {
    final db = Localstore.instance;
    await db.collection('FolderData').doc(folderId).set(toMap());
  }

  Future<void> delete() async {
    final db = Localstore.instance;
    await db.collection('FolderData').doc(folderId).delete();
  }
}

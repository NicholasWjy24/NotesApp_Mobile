import 'package:localstore/localstore.dart';

class NoteData {
  final String id;
  final String title;
  final String contentJson;
  final String plainTextContent;
  final DateTime time;
  final bool done;
  final String? folderId;

  NoteData({
    required this.id,
    required this.title,
    required this.contentJson,
    required this.plainTextContent,
    required this.time,
    required this.done,
    this.folderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'contentJson': contentJson,
      'plainTextContent': plainTextContent,
      'time': time.toIso8601String(),
      'done': done,
      'folderId': folderId,
    };
  }

  static NoteData fromMap(Map<String, dynamic> map) {
    return NoteData(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      contentJson: map['contentJson'] ?? '',
      plainTextContent: map['plainTextContent'] ?? '',
      time: DateTime.parse(map['time']),
      done: map['done'] ?? false,
      folderId: map['folderId'],
    );
  }

  Future<void> save() async {
    final db = Localstore.instance;
    await db.collection('NoteData').doc(id).set(toMap());
  }

  Future<void> delete() async {
    final db = Localstore.instance;
    await db.collection('NoteData').doc(id).delete();
  }

  static Future<List<NoteData>> getAllNotes() async {
    final db = Localstore.instance;
    final notes = await db.collection('NoteData').get();
    if (notes == null) return [];
    
    return notes.entries
        .map((entry) => NoteData.fromMap(entry.value))
        .toList();
  }

  static Future<List<NoteData>> getNotesByFolder(String? folderId) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.folderId == folderId).toList();
  }

  static Future<List<NoteData>> getNotesWithoutFolder() async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.folderId == null).toList();
  }
}

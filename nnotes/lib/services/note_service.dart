import 'package:localstore/localstore.dart';
import 'package:nnotes/data/note_data.dart';

class NoteService {
  static final _db = Localstore.instance;

  // Get all notes
  static Future<Map<String, NoteData>> getAllNotes() async {
    final Map<String, NoteData> notes = {};
    final value = await _db.collection('NoteData').get();
    
    value?.entries.forEach((element) {
      final item = NoteData.fromMap(element.value);
      notes[item.id] = item;
    });
    
    return notes;
  }

  // Get notes by folder
  static List<NoteData> getNotesByFolder(
    Map<String, NoteData> notes, 
    String? folderId
  ) {
    return notes.values
        .where((note) => note.folderId == folderId)
        .toList();
  }

  // Get notes without folder
  static List<NoteData> getNotesWithoutFolder(Map<String, NoteData> notes) {
    return notes.values
        .where((note) => note.folderId == null)
        .toList();
  }

  // Count notes in folder (including subfolders)
  static int getNoteCountInFolder(
    String folderId, 
    Map<String, NoteData> notes, 
    Map<String, dynamic> folders
  ) {
    int count = 0;
    
    // Count direct notes in this folder
    count += notes.values
        .where((note) => note.folderId == folderId)
        .length;
    
    // Count notes in subfolders
    final subfolders = folders.values
        .where((folder) => folder.parentId == folderId)
        .map((folder) => folder.folderId);
    
    for (final subfolderId in subfolders) {
      count += getNoteCountInFolder(subfolderId, notes, folders);
    }
    
    return count;
  }

  // Update note
  static Future<void> updateNote(NoteData note) async {
    await note.save();
  }

  // Delete note
  static Future<void> deleteNote(NoteData note) async {
    await note.delete();
  }

  // Remove notes from folder and subfolders
  static Future<void> removeNotesFromFolder(
    Set<String> folderIds, 
    Map<String, NoteData> notes
  ) async {
    for (final note in notes.values) {
      if (folderIds.contains(note.folderId)) {
        final updatedNote = NoteData(
          id: note.id,
          title: note.title,
          contentJson: note.contentJson,
          plainTextContent: note.plainTextContent,
          time: note.time,
          done: note.done,
          folderId: null, // Remove from folder
        );
        await updatedNote.save();
      }
    }
  }
}

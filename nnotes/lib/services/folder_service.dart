import 'package:localstore/localstore.dart';
import 'package:nnotes/data/folder_data.dart';

class FolderService {
  static final _db = Localstore.instance;

  // Get all folders
  static Future<Map<String, FolderData>> getAllFolders() async {
    final Map<String, FolderData> folders = {};
    final value = await _db.collection('FolderData').get();
    
    value?.entries.forEach((element) {
      final item = FolderData.fromMap(element.value);
      folders[item.folderId] = item;
    });
    
    return folders;
  }

  // Get folders by parent
  static List<FolderData> getFoldersByParent(
    Map<String, FolderData> folders, 
    String? parentId
  ) {
    return folders.values
        .where((folder) => folder.parentId == parentId)
        .toList();
  }

  // Get root folders
  static List<FolderData> getRootFolders(Map<String, FolderData> folders) {
    return folders.values
        .where((folder) => folder.parentId == null)
        .toList();
  }

  // Get subfolders of a folder
  static List<FolderData> getSubfolders(
    Map<String, FolderData> folders, 
    String folderId
  ) {
    return folders.values
        .where((folder) => folder.parentId == folderId)
        .toList();
  }

  // Create new folder
  static Future<FolderData> createFolder(String name, String? parentId) async {
    final id = _db.collection('FolderData').doc().id;
    final folder = FolderData(
      folderId: id,
      name: name,
      parentId: parentId,
    );
    await folder.save();
    return folder;
  }

  // Update folder
  static Future<void> updateFolder(FolderData folder) async {
    await folder.save();
  }

  // Delete folder and its subfolders
  static Future<void> deleteFolderAndSubfolders(
    String folderId, 
    Map<String, FolderData> folders
  ) async {
    final foldersToDelete = _getAllSubfolderIds(folderId, folders);
    
    // Delete all folders
    for (final folderIdToDelete in foldersToDelete) {
      final folder = folders[folderIdToDelete];
      if (folder != null) {
        await folder.delete();
      }
    }
  }

  // Get all subfolder IDs recursively
  static Set<String> _getAllSubfolderIds(
    String folderId, 
    Map<String, FolderData> folders
  ) {
    final Set<String> ids = {folderId};
    final subfolders = folders.values
        .where((folder) => folder.parentId == folderId)
        .map((folder) => folder.folderId);
    
    for (final subfolderId in subfolders) {
      ids.addAll(_getAllSubfolderIds(subfolderId, folders));
    }
    
    return ids;
  }

  // Check if a folder is a descendant of another
  static bool isDescendant(
    String potentialDescendantId, 
    String ancestorId, 
    Map<String, FolderData> folders
  ) {
    if (potentialDescendantId == ancestorId) return true;
    
    final folder = folders[potentialDescendantId];
    if (folder?.parentId == null) return false;
    
    return isDescendant(folder!.parentId!, ancestorId, folders);
  }

  // Get folder path
  static String getFolderPath(
    String folderId, 
    Map<String, FolderData> folders
  ) {
    final folder = folders[folderId];
    if (folder == null) return 'NNotes';
    
    if (folder.parentId == null) {
      return folder.name;
    } else {
      final parentPath = getFolderPath(folder.parentId!, folders);
      return '$parentPath > ${folder.name}';
    }
  }
}

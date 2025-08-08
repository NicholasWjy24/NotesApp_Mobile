import 'package:flutter/material.dart';
import 'package:nnotes/data/folder_data.dart';
import 'package:nnotes/data/note_data.dart';
import 'package:nnotes/services/folder_service.dart';
import 'package:nnotes/services/note_service.dart';

class AppDrawer extends StatelessWidget {
  final Map<String, FolderData> folders;
  final Map<String, NoteData> notes;
  final String? selectedFolderId;
  final Function(String?) onFolderSelected;
  final Function(String) onEditFolder;
  final Function(String) onMoveToRoot;
  final Function(FolderData) onMoveToFolder;
  final Function(String) onAddSubfolder;
  final Function(String) onDeleteFolder;

  const AppDrawer({
    super.key,
    required this.folders,
    required this.notes,
    required this.selectedFolderId,
    required this.onFolderSelected,
    required this.onEditFolder,
    required this.onMoveToRoot,
    required this.onMoveToFolder,
    required this.onAddSubfolder,
    required this.onDeleteFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary
            ),
            child: const Center(
              child: Text(
                'NNotes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 40
                ),
              ),
            ),
          ),
          // All Notes option
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('All Notes'),
            selected: selectedFolderId == null,
            onTap: () {
              onFolderSelected(null);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          // Root folders (no parentId)
          if (folders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No Folders',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey
                ),
              ),
            )
          else
            ..._buildFolderTree(),
        ],
      ),
    );
  }

  List<Widget> _buildFolderTree() {
    final List<Widget> widgets = [];
    
    // Get root folders (no parentId)
    final rootFolders = FolderService.getRootFolders(folders);
    
    for (final rootFolder in rootFolders) {
      widgets.add(_buildFolderTile(rootFolder, 0));
    }
    
    return widgets;
  }

  Widget _buildFolderTile(FolderData folder, int level) {
    // Count notes in this folder (including subfolders)
    final noteCount = NoteService.getNoteCountInFolder(
      folder.folderId, 
      notes, 
      folders
    );
    
    // Get subfolders
    final subfolders = FolderService.getSubfolders(folders, folder.folderId);
    
    return Builder(
      builder: (context) => Column(
        children: [
          ListTile(
            leading: Icon(
              subfolders.isNotEmpty ? Icons.folder_open : Icons.folder,
              color: level == 0 ? null : Colors.grey[600],
            ),
            title: Text(
              folder.name,
              style: TextStyle(
                fontWeight: level == 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            subtitle: Text('$noteCount notes'),
            selected: selectedFolderId == folder.folderId,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subfolders.isNotEmpty)
                  Text(
                    '${subfolders.length} sub',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEditFolder(folder.folderId);
                        break;
                      case 'move_to_root':
                        onMoveToRoot(folder.folderId);
                        break;
                      case 'move_to_folder':
                        onMoveToFolder(folder);
                        break;
                      case 'add_subfolder':
                        onAddSubfolder(folder.folderId);
                        break;
                      case 'delete':
                        onDeleteFolder(folder.folderId);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    if (folder.parentId != null)
                      const PopupMenuItem(
                        value: 'move_to_root',
                        child: Text('Move to Root Level'),
                      ),
                    const PopupMenuItem(
                      value: 'move_to_folder',
                      child: Text('Move to Folder'),
                    ),
                    const PopupMenuItem(
                      value: 'add_subfolder',
                      child: Text('Add Subfolder'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              onFolderSelected(folder.folderId);
              Navigator.pop(context);
            },
          ),
          // Show subfolders with indentation
          if (subfolders.isNotEmpty)
            ...subfolders.map((subfolder) => Padding(
              padding: EdgeInsets.only(left: 16.0 * (level + 1)),
              child: _buildFolderTile(subfolder, level + 1),
            )),
        ],
      ),
    );
  }
}

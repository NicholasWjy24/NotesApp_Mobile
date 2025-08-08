import 'package:flutter/material.dart';
import 'package:nnotes/data/folder_data.dart';
import 'package:nnotes/data/note_data.dart';
import 'package:nnotes/services/folder_service.dart';
import 'package:nnotes/services/note_service.dart';

class FolderCard extends StatelessWidget {
  final FolderData folder;
  final Map<String, FolderData> folders;
  final Map<String, NoteData> notes;
  final String? selectedFolderId;
  final VoidCallback onTap;
  final Function(String) onEdit;
  final Function(String) onAddSubfolder;
  final Function(String) onDelete;
  final Function(String) onOpen;

  const FolderCard({
    super.key,
    required this.folder,
    required this.folders,
    required this.notes,
    required this.selectedFolderId,
    required this.onTap,
    required this.onEdit,
    required this.onAddSubfolder,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    // Count notes in this folder (including subfolders)
    final noteCount = NoteService.getNoteCountInFolder(
      folder.folderId, 
      notes, 
      folders
    );
    
    // Get subfolders
    final subfolders = FolderService.getSubfolders(folders, folder.folderId);

    // Check if this folder can be added to current folder (for visual feedback only)
    final canBeAdded = selectedFolderId != null && 
                      selectedFolderId != folder.folderId && 
                      !FolderService.isDescendant(selectedFolderId!, folder.folderId, folders);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: canBeAdded ? 4 : 2,
        color: canBeAdded 
            ? Theme.of(context).colorScheme.onSecondary
            : Theme.of(context).colorScheme.onSecondary,
        child: ListTile(
          leading: Icon(
            subfolders.isNotEmpty ? Icons.folder_open : Icons.folder,
            color: Theme.of(context).primaryColor,
            size: 32,
          ),
          title: Text(
            folder.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$noteCount notes'),
              if (subfolders.isNotEmpty)
                Text('${subfolders.length} subfolders'),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'open':
                  onOpen(folder.folderId);
                  break;
                case 'edit':
                  onEdit(folder.folderId);
                  break;
                case 'add_subfolder':
                  onAddSubfolder(folder.folderId);
                  break;
                case 'delete':
                  onDelete(folder.folderId);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open',
                child: Text('Open Folder'),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
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
          onTap: onTap,
        ),
      ),
    );
  }
}

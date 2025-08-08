import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nnotes/data/note_data.dart';
import 'package:nnotes/data/folder_data.dart';
import 'package:nnotes/screen/note/note_screen.dart';
import 'package:nnotes/services/folder_service.dart';
import 'package:nnotes/widget/folder_selection_overlay.dart';

class NoteCard extends StatelessWidget {
  final NoteData note;
  final Map<String, FolderData> folders;
  final String? selectedFolderId;
  final VoidCallback onTap;
  final Function(NoteData) onDelete;
  final Function(NoteData) onEdit;
  final Function(NoteData) onAddToFolder;
  final Function(NoteData) onRemoveFromFolder;

  const NoteCard({
    super.key,
    required this.note,
    required this.folders,
    required this.selectedFolderId,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    required this.onAddToFolder,
    required this.onRemoveFromFolder,
  });

  @override
  Widget build(BuildContext context) {
    // Get folder name for display
    String? folderName;
    if (note.folderId != null && folders.containsKey(note.folderId)) {
      folderName = FolderService.getFolderPath(note.folderId!, folders);
    }

    // Check if this note can be added to current folder
    final canBeAdded = selectedFolderId != null && note.folderId != selectedFolderId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: canBeAdded ? 4 : 2,
        color: canBeAdded 
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : null,
        child: ListTile(
          titleAlignment: ListTileTitleAlignment.top,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.length > 30
                          ? '${note.title.substring(0, 30)}...'
                          : note.title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (folderName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        folderName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                note.plainTextContent.length > 80
                    ? '${note.plainTextContent.substring(0, 80)}...'
                    : note.plainTextContent,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Text(
                'Last Update:\n${DateFormat('dd-MM-yyyy').format(note.time)} - ${DateFormat('HH:mm').format(note.time)}',
                textAlign: TextAlign.left,
                style: const TextStyle(color: Colors.black38, fontSize: 12),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  onDelete(note);
                  break;
                case 'edit':
                  onEdit(note);
                  break;
                case 'add_to_folder':
                  onAddToFolder(note);
                  break;
                case 'remove_from_folder':
                  onRemoveFromFolder(note);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              if (note.folderId != null)
                const PopupMenuItem(
                  value: 'remove_from_folder',
                  child: Text('Remove from Folder'),
                )
              else
                const PopupMenuItem(
                  value: 'add_to_folder',
                  child: Text('Add to Folder'),
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

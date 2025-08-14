import 'package:flutter/material.dart';
import 'package:localstore/localstore.dart';
import 'package:nnotes/screen/note/note_screen.dart';
import 'package:nnotes/data/folder_data.dart';

class PopupMenuContent extends StatefulWidget {
  final VoidCallback onClose;
  final String? selectedFolderId;

  const PopupMenuContent({
    required this.onClose,
    this.selectedFolderId,
  });

  @override
  State<PopupMenuContent> createState() => _PopupMenuContentState();
}

class _PopupMenuContentState extends State<PopupMenuContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  final _db = Localstore.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  Future<void> _addFolder() async {
    final folderName = await _showAddFolderDialog();
    if (folderName != null && folderName.trim().isNotEmpty) {
      final id = _db.collection('FolderData').doc().id;
      final newFolder = FolderData(
        folderId: id,
        name: folderName.trim(),
        parentId: widget.selectedFolderId,
      );
      await newFolder.save();
    }
  }

  Future<String?> _showAddFolderDialog() async {
    String folderName = '';

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Folder Name'),
          content: TextField(
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'e.g., Kuliah, Pribadi'),
            onChanged: (value) {
              folderName = value;
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () => Navigator.of(context).pop(folderName),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Material(
        // gives elevation and background
        borderRadius: BorderRadius.circular(12),
        elevation: 6,
        child: Container(
          width: 220, // set fixed width to prevent infinite constraint
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.create_new_folder),
                title: const Text('Add Folder'),
                onTap: () async {
                  final newFolderName = await _showAddFolderDialog();
                  if (newFolderName != null &&
                      newFolderName.trim().isNotEmpty) {
                    final id = _db.collection('FolderData').doc().id;
                    final newFolder = FolderData(
                      folderId: id,
                      name: newFolderName.trim(),
                      parentId: widget.selectedFolderId,
                    );
                    await newFolder.save();
                    widget.onClose();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_add),
                title: const Text('Add Note'),
                onTap: () {
                  widget.onClose();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteScreen(
                        initialFolderId: widget.selectedFolderId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

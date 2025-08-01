import 'package:flutter/material.dart';
import 'package:nnotes/data/folder_data.dart';

class FolderSelectionOverlay extends StatefulWidget {
  final List<FolderData> folders;
  final void Function(String folderId) onFolderSelected;

  const FolderSelectionOverlay({
    super.key,
    required this.folders,
    required this.onFolderSelected,
  });

  @override
  State<FolderSelectionOverlay> createState() => _FolderSelectionOverlayState();
}

class _FolderSelectionOverlayState extends State<FolderSelectionOverlay> {
  late TextEditingController _searchController;
  List<FolderData> _filteredFolders = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredFolders = widget.folders;

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredFolders = widget.folders
            .where((folder) => folder.name.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search folder...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_filteredFolders.isEmpty)
            const Text('No folders found.')
          else
            ..._filteredFolders.map((folder) {
              return ListTile(
                title: Text(folder.name),
                onTap: () => widget.onFolderSelected(folder.folderId),
              );
            }),
        ],
      ),
    );
  }
}

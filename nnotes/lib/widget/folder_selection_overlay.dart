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
            Expanded(
              child: ListView(
                children: _buildFolderTree(_filteredFolders),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFolderTree(List<FolderData> folders) {
    final List<Widget> widgets = [];
    
    // Get root folders (no parentId)
    final rootFolders = folders.where((folder) => folder.parentId == null).toList();
    
    for (final rootFolder in rootFolders) {
      widgets.add(_buildFolderTile(rootFolder, 0, folders));
    }
    
    return widgets;
  }

  Widget _buildFolderTile(FolderData folder, int level, List<FolderData> allFolders) {
    // Get subfolders
    final subfolders = allFolders
        .where((f) => f.parentId == folder.folderId)
        .toList();
    
    return Column(
      children: [
        ListTile(
          leading: Icon(
            subfolders.isNotEmpty ? Icons.folder_open : Icons.folder,
            color: level == 0 ? null : Colors.grey[600],
            size: level == 0 ? 24 : 20,
          ),
          title: Text(
            folder.name,
            style: TextStyle(
              fontWeight: level == 0 ? FontWeight.w500 : FontWeight.normal,
              fontSize: level == 0 ? 16 : 14,
            ),
          ),
          subtitle: level == 0 ? null : Text(
            'Subfolder',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          onTap: () => widget.onFolderSelected(folder.folderId),
        ),
        // Show subfolders with indentation
        if (subfolders.isNotEmpty)
          ...subfolders.map((subfolder) => Padding(
            padding: EdgeInsets.only(left: 16.0 * (level + 1)),
            child: _buildFolderTile(subfolder, level + 1, allFolders),
          )),
      ],
    );
  }
}

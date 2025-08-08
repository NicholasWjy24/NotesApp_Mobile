import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nnotes/data/note_data.dart';
import 'package:nnotes/screen/note/note_screen.dart';
import 'package:localstore/localstore.dart';
import 'package:nnotes/data/folder_data.dart';
import 'package:nnotes/widget/folder_selection_overlay.dart';
import 'package:nnotes/widget/pop_up_add_button_home_screen_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = Localstore.instance;
  final Map<String, FolderData> _folders = {};
  final _noteData = <String, NoteData>{};
  final GlobalKey _fabKey = GlobalKey(); //for Floating Add Button
  List<String> folders = [];
  int folderCounter = 1;
  String? _selectedFolderId;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  @override
  void initState() {
    _subscription = _db.collection('NoteData').stream.listen((event) {
      setState(() {
        final item = NoteData.fromMap(event);
        _noteData[item.id] = item;
      });
    });

    _db.collection('FolderData').get().then((value) {
      setState(() {
        value?.entries.forEach((element) {
          final item = FolderData.fromMap(element.value);
          _folders[item.folderId] = item;
        });
      });
    });

    _db.collection('FolderData').stream.listen((event) {
      if (event == null || event['folderId'] == null) return;

      final id = event['folderId'] as String;

      setState(() {
        if (event.isEmpty) {
          _folders.remove(id);
        } else {
          final item = FolderData.fromMap(event);
          _folders[id] = item;
        }
      });
    });

    if (kIsWeb) {
      _db.collection('NoteData').stream.asBroadcastStream();
      _db.collection('FolderData').stream.asBroadcastStream();
    }
    super.initState();
  }

  void _showFabPopup(BuildContext context, GlobalKey fabKey) {
    final RenderBox button =
        fabKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset position =
        button.localToGlobal(Offset.zero, ancestor: overlay);

    late OverlayEntry overlayEntry;
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: Navigator.of(context),
    );

    final Animation<Offset> offsetAnimation = Tween<Offset>(
      begin: const Offset(0.2, 1), // starts from bottom-right
      end: Offset.zero, // ends at natural position
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));

    final Animation<double> fadeAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeIn,
    );

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Dismiss area
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  controller.reverse().then((_) {
                    overlayEntry.remove();
                    controller.dispose();
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // Popup with animated position and opacity
            Positioned(
              left: position.dx - 160,
              top: position.dy - 140,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: PopupMenuContent(
                      selectedFolderId: _selectedFolderId,
                      onClose: () {
                        controller.reverse().then((_) {
                          overlayEntry.remove();
                          controller.dispose();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
    controller.forward();
  }

  Future<String?> _showEditFolderDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Folder Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: nNotesAppBar(),
      drawer: nNotesDrawer(context),
      body: nNotescontains(),
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        tooltip: 'Add',
        child: const Icon(Icons.add),
        onPressed: () => _showFabPopup(context, _fabKey),
      ),
    );
  }

  Drawer nNotesDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration:
                BoxDecoration(color: Theme.of(context).colorScheme.onPrimary),
            child: const Center(
              child: Text(
                'NNotes',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 40),
              ),
            ),
          ),
          // All Notes option
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('All Notes'),
            selected: _selectedFolderId == null,
            onTap: () {
              setState(() {
                _selectedFolderId = null;
                Navigator.pop(context);
              });
            },
          ),
          const Divider(),
          // Root folders (no parentId)
          if (_folders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No Folders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
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
    final rootFolders = _folders.values.where((folder) => folder.parentId == null).toList();
    
    for (final rootFolder in rootFolders) {
      widgets.add(_buildFolderTile(rootFolder, 0));
    }
    
    return widgets;
  }

  Widget _buildFolderTile(FolderData folder, int level) {
    // Count notes in this folder (including subfolders)
    final noteCount = _getNoteCountInFolder(folder.folderId);
    
    // Get subfolders
    final subfolders = _folders.values
        .where((f) => f.parentId == folder.folderId)
        .toList();
    
    return Column(
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
          selected: _selectedFolderId == folder.folderId,
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
                onSelected: (value) async {
                  if (value == 'edit') {
                    final newName = await _showEditFolderDialog(folder.name);
                    if (newName != null && newName.trim().isNotEmpty) {
                      final updatedFolder = FolderData(
                        folderId: folder.folderId,
                        name: newName.trim(),
                        parentId: folder.parentId,
                      );
                      await updatedFolder.save();
                    }
                  } else if (value == 'move_to_root') {
                    // Move folder to root level
                    final updatedFolder = FolderData(
                      folderId: folder.folderId,
                      name: folder.name,
                      parentId: null, // Remove parent
                    );
                    await updatedFolder.save();
                  } else if (value == 'move_to_folder') {
                    await _showMoveFolderDialog(folder);
                  } else if (value == 'add_subfolder') {
                    final newSubfolderName = await _showAddSubfolderDialog();
                    if (newSubfolderName != null && newSubfolderName.trim().isNotEmpty) {
                      final id = _db.collection('FolderData').doc().id;
                      final newSubfolder = FolderData(
                        folderId: id,
                        name: newSubfolderName.trim(),
                        parentId: folder.folderId,
                      );
                      await newSubfolder.save();
                    }
                  } else if (value == 'delete') {
                    // Show confirmation dialog
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Folder'),
                        content: Text(
                          'Are you sure you want to delete "${folder.name}"? '
                          'This will remove all notes from this folder and its subfolders.'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    
                    if (shouldDelete == true) {
                      await _deleteFolderAndSubfolders(folder.folderId);
                    }
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
            setState(() {
              _selectedFolderId = folder.folderId;
              Navigator.pop(context);
            });
          },
        ),
        // Show subfolders with indentation
        if (subfolders.isNotEmpty)
          ...subfolders.map((subfolder) => Padding(
            padding: EdgeInsets.only(left: 16.0 * (level + 1)),
            child: _buildFolderTile(subfolder, level + 1),
          )),
      ],
    );
  }

  int _getNoteCountInFolder(String folderId) {
    int count = 0;
    
    // Count direct notes in this folder
    count += _noteData.values
        .where((note) => note.folderId == folderId)
        .length;
    
    // Count notes in subfolders
    final subfolders = _folders.values
        .where((folder) => folder.parentId == folderId)
        .map((folder) => folder.folderId);
    
    for (final subfolderId in subfolders) {
      count += _getNoteCountInFolder(subfolderId);
    }
    
    return count;
  }

  Future<void> _deleteFolderAndSubfolders(String folderId) async {
    // Get all subfolders recursively
    final foldersToDelete = <String>{folderId};
    final subfolders = _folders.values
        .where((folder) => folder.parentId == folderId)
        .map((folder) => folder.folderId);
    
    for (final subfolderId in subfolders) {
      foldersToDelete.addAll(_getAllSubfolderIds(subfolderId));
    }
    
    // Remove folder from all notes in this folder and subfolders
    for (final note in _noteData.values) {
      if (foldersToDelete.contains(note.folderId)) {
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
        _noteData[note.id] = updatedNote;
      }
    }
    
    // Delete all folders
    for (final folderIdToDelete in foldersToDelete) {
      final folder = _folders[folderIdToDelete];
      if (folder != null) {
        await folder.delete();
        _folders.remove(folderIdToDelete);
      }
    }
    
    setState(() {});
  }

  Set<String> _getAllSubfolderIds(String folderId) {
    final Set<String> ids = {folderId};
    final subfolders = _folders.values
        .where((folder) => folder.parentId == folderId)
        .map((folder) => folder.folderId);
    
    for (final subfolderId in subfolders) {
      ids.addAll(_getAllSubfolderIds(subfolderId));
    }
    
    return ids;
  }

  Set<String> _getFolderAndSubfolderIds(String folderId) {
    final Set<String> ids = {folderId};
    final subfolders = _folders.values
        .where((folder) => folder.parentId == folderId)
        .map((folder) => folder.folderId);
    
    for (final subfolderId in subfolders) {
      ids.addAll(_getFolderAndSubfolderIds(subfolderId));
    }
    
    return ids;
  }

  Future<String?> _showAddSubfolderDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Subfolder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Subfolder name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMoveFolderDialog(FolderData folderToMove) async {
    // Get available target folders (excluding the folder itself and its descendants)
    final availableFolders = _folders.values
        .where((folder) => folder.folderId != folderToMove.folderId)
        .where((folder) => !_isDescendant(folder.folderId, folderToMove.folderId))
        .toList();

    if (availableFolders.isEmpty) {
      // Show message that no folders are available
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Available Folders'),
          content: const Text('No other folders available to move this folder into.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show folder selection dialog
    final selectedFolderId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move "${folderToMove.name}" to Folder'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: Column(
            children: [
              const Text('Select the target folder:'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    // Option to move to root level
                    ListTile(
                      leading: const Icon(Icons.folder),
                      title: const Text('Root Level (No Parent)'),
                      subtitle: const Text('Move to top level'),
                      onTap: () => Navigator.of(context).pop('root'),
                    ),
                    const Divider(),
                    // Available folders
                    ...availableFolders.map((folder) {
                      final folderPath = _getFolderPath(folder.folderId);
                      return ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text(folder.name),
                        subtitle: Text(folderPath),
                        onTap: () => Navigator.of(context).pop(folder.folderId),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedFolderId != null) {
      // Update the folder's parentId
      final newParentId = selectedFolderId == 'root' ? null : selectedFolderId;
      final updatedFolder = FolderData(
        folderId: folderToMove.folderId,
        name: folderToMove.name,
        parentId: newParentId,
      );
      await updatedFolder.save();
    }
  }

  bool _isDescendant(String potentialDescendantId, String ancestorId) {
    if (potentialDescendantId == ancestorId) return true;
    
    final folder = _folders[potentialDescendantId];
    if (folder?.parentId == null) return false;
    
    return _isDescendant(folder!.parentId!, ancestorId);
  }

  Future<void> _addFolderToCurrentFolder(String folderId) async {
    final folder = _folders[folderId];
    if (folder == null || _selectedFolderId == null) return;

    // Check if this would create a circular reference
    if (_isDescendant(_selectedFolderId!, folderId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add folder: would create circular reference'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update the folder's parentId to the current folder
    final updatedFolder = FolderData(
      folderId: folder.folderId,
      name: folder.name,
      parentId: _selectedFolderId,
    );
    await updatedFolder.save();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${folder.name}" to current folder'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _addNoteToCurrentFolder(NoteData note) async {
    if (_selectedFolderId == null) return;

    // Update the note's folderId to the current folder
    final updatedNote = NoteData(
      id: note.id,
      title: note.title,
      contentJson: note.contentJson,
      plainTextContent: note.plainTextContent,
      time: note.time,
      done: note.done,
      folderId: _selectedFolderId,
    );
    await updatedNote.save();
    _noteData[note.id] = updatedNote;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${note.title}" to current folder'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget nNotescontains() {
    // Get folders to display
    List<FolderData> foldersToShow;
    if (_selectedFolderId == null) {
      // Show root folders when no folder is selected
      foldersToShow = _folders.values.where((folder) => folder.parentId == null).toList();
    } else {
      // Show subfolders of the selected folder AND other folders that can be added
      final subfolders = _folders.values
          .where((folder) => folder.parentId == _selectedFolderId)
          .toList();
      
      // Get other folders that can be added to the current folder
      final addableFolders = _folders.values
          .where((folder) => 
              folder.folderId != _selectedFolderId && 
              folder.parentId != _selectedFolderId &&
              !_isDescendant(_selectedFolderId!, folder.folderId))
          .toList();
      
      // Combine subfolders and addable folders
      foldersToShow = [...subfolders, ...addableFolders];
    }

    // Filter notes based on selected folder
    List<NoteData> filteredNotes;
    if (_selectedFolderId == null) {
      // Show notes without folders when no folder is selected
      filteredNotes = _noteData.values
          .where((note) => note.folderId == null)
          .toList();
    } else {
      // Show notes that belong to the selected folder (not subfolders)
      filteredNotes = _noteData.values
          .where((note) => note.folderId == _selectedFolderId)
          .toList();
    }

    // Sort notes by time (newest first)
    filteredNotes.sort((a, b) => b.time.compareTo(a.time));

    // Combine folders and notes
    final allItems = <Widget>[];
    
    // Add folder cards first (always at top)
    for (final folder in foldersToShow) {
      allItems.add(_buildFolderCard(folder));
    }
    
    // Add note cards
    for (final note in filteredNotes) {
      allItems.add(_buildNoteCard(note));
    }

    if (allItems.isNotEmpty) {
      return ListView.builder(
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          return allItems[index];
        },
      );
    } else {
      String message;
      if (_selectedFolderId == null) {
        message = 'No notes yet. Click + to add one!';
      } else {
        final folderName = _folders[_selectedFolderId]?.name ?? 'this folder';
        message = 'No notes in $folderName yet. Click + to add one!';
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  AppBar nNotesAppBar() {
    String title = 'NNotes';
    if (_selectedFolderId != null && _folders.containsKey(_selectedFolderId)) {
      title = _getFolderPath(_selectedFolderId!);
    }
    
    return AppBar(
      title: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      actions: [
        if (_selectedFolderId != null)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final currentFolder = _folders[_selectedFolderId];
              if (currentFolder?.parentId != null) {
                // Go back to parent folder
                setState(() {
                  _selectedFolderId = currentFolder!.parentId;
                });
              } else {
                // Go back to root level
                setState(() {
                  _selectedFolderId = null;
                });
              }
            },
            tooltip: 'Go Back',
          ),
        if (_selectedFolderId != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _selectedFolderId = null;
              });
            },
            tooltip: 'Show All Notes',
          ),
      ],
    );
  }

  String _getFolderPath(String folderId) {
    final folder = _folders[folderId];
    if (folder == null) return 'NNotes';
    
    if (folder.parentId == null) {
      return folder.name;
    } else {
      final parentPath = _getFolderPath(folder.parentId!);
      return '$parentPath > ${folder.name}';
    }
  }

  Widget _buildFolderCard(FolderData folder) {
    // Count notes in this folder (including subfolders)
    final noteCount = _getNoteCountInFolder(folder.folderId);
    
    // Get subfolders
    final subfolders = _folders.values
        .where((f) => f.parentId == folder.folderId)
        .toList();

    // Check if this folder can be added to current folder (for visual feedback only)
    final canBeAdded = _selectedFolderId != null && 
                      _selectedFolderId != folder.folderId && 
                      !_isDescendant(_selectedFolderId!, folder.folderId);

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
              if (value == 'open') {
                setState(() {
                  _selectedFolderId = folder.folderId;
                });
              } else if (value == 'edit') {
                final newName = await _showEditFolderDialog(folder.name);
                if (newName != null && newName.trim().isNotEmpty) {
                  final updatedFolder = FolderData(
                    folderId: folder.folderId,
                    name: newName.trim(),
                    parentId: folder.parentId,
                  );
                  await updatedFolder.save();
                }
              } else if (value == 'add_subfolder') {
                final newSubfolderName = await _showAddSubfolderDialog();
                if (newSubfolderName != null && newSubfolderName.trim().isNotEmpty) {
                  final id = _db.collection('FolderData').doc().id;
                  final newSubfolder = FolderData(
                    folderId: id,
                    name: newSubfolderName.trim(),
                    parentId: folder.folderId,
                  );
                  await newSubfolder.save();
                }
              } else if (value == 'delete') {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Folder'),
                    content: Text(
                      'Are you sure you want to delete "${folder.name}"? '
                      'This will remove all notes from this folder and its subfolders.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                
                if (shouldDelete == true) {
                  await _deleteFolderAndSubfolders(folder.folderId);
                }
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
                     onTap: () {
             // If this is a subfolder (has parentId), always navigate into it
             if (folder.parentId != null) {
               setState(() {
                 _selectedFolderId = folder.folderId;
               });
             } else {
               // For root folders, check if we should add or navigate
               if (_selectedFolderId != null && _selectedFolderId != folder.folderId) {
                 _addFolderToCurrentFolder(folder.folderId);
               } else {
                 // Otherwise, navigate into the folder
                 setState(() {
                   _selectedFolderId = folder.folderId;
                 });
               }
             }
           },
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteData item) {
    // Get folder name for display
    String? folderName;
    if (item.folderId != null && _folders.containsKey(item.folderId)) {
      folderName = _getFolderPath(item.folderId!);
    }

    // Check if this note can be added to current folder
    final canBeAdded = _selectedFolderId != null && item.folderId != _selectedFolderId;

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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title.length > 30
                          ? '${item.title.substring(0, 30)}...'
                          : item.title,
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
                item.plainTextContent.length > 80
                    ? '${item.plainTextContent.substring(0, 80)}...'
                    : item.plainTextContent,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Text(
                'Last Update:\n${DateFormat('dd-MM-yyyy').format(item.time)} - ${DateFormat('HH:mm').format(item.time)}',
                textAlign: TextAlign.left,
                style:
                    const TextStyle(color: Colors.black38, fontSize: 12),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                setState(() {
                  item.delete();
                  _noteData.remove(item.id);
                });
              } else if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NoteScreen(note: item)),
                );
                setState(() {});
              } else if (value == 'add_to_folder') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Folder'),
                    content: SizedBox(
                      width: 300,
                      height: 400,
                      child: FolderSelectionOverlay(
                        folders: _folders.values.toList(),
                        onFolderSelected: (folderId) async {
                          final updatedNote = NoteData(
                            id: item.id,
                            title: item.title,
                            contentJson: item.contentJson,
                            plainTextContent: item.plainTextContent,
                            time: item.time,
                            done: item.done,
                            folderId: folderId,
                          );
                          await updatedNote.save();
                          _noteData[item.id] = updatedNote;
                          setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                );
              } else if (value == 'remove_from_folder') {
                final updatedNote = NoteData(
                  id: item.id,
                  title: item.title,
                  contentJson: item.contentJson,
                  plainTextContent: item.plainTextContent,
                  time: item.time,
                  done: item.done,
                  folderId: null, // Remove from folder
                );
                updatedNote.save();
                _noteData[item.id] = updatedNote;
                setState(() {});
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
              if (item.folderId != null)
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
                     onTap: () async {
             // If we're inside a folder and the note is not in this folder, add it
             if (_selectedFolderId != null && item.folderId != _selectedFolderId) {
               _addNoteToCurrentFolder(item);
             } else {
               // Otherwise, open the note for editing
               await Navigator.push(
                 context,
                 MaterialPageRoute(
                     builder: (context) => NoteScreen(note: item)),
               );
               setState(() {});
             }
           },
        ),
      ),
    );
  }
}

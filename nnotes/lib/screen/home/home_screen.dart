import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localstore/localstore.dart';
import 'package:nnotes/data/note_data.dart';
import 'package:nnotes/data/folder_data.dart';
import 'package:nnotes/screen/note/note_screen.dart';
import 'package:nnotes/services/folder_service.dart';
import 'package:nnotes/services/note_service.dart';
import 'package:nnotes/widgets/app_drawer.dart';
import 'package:nnotes/widgets/folder_card.dart';
import 'package:nnotes/widgets/note_card.dart';
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
  final Map<String, NoteData> _notes = {};
  final GlobalKey _fabKey = GlobalKey();
  String? _selectedFolderId;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Listen to note changes
    _subscription = _db.collection('NoteData').stream.listen((event) {
      setState(() {
        final item = NoteData.fromMap(event);
        _notes[item.id] = item;
      });
    });

    // Load initial folders
    FolderService.getAllFolders().then((folders) {
      setState(() {
        _folders.addAll(folders);
      });
    });

    // Listen to folder changes
    _db.collection('FolderData').stream.listen((event) {
      if (event['folderId'] == null) return;

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
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    String title = 'NNotes';
    if (_selectedFolderId != null && _folders.containsKey(_selectedFolderId)) {
      title = FolderService.getFolderPath(_selectedFolderId!, _folders);
    }

    return AppBar(
      title: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      actions: [
        if (_selectedFolderId != null)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
            tooltip: 'Go Back',
          ),
        if (_selectedFolderId != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() => _selectedFolderId = null),
            tooltip: 'Show All Notes',
          ),
      ],
    );
  }

  Widget _buildDrawer() {
    return AppDrawer(
      folders: _folders,
      notes: _notes,
      selectedFolderId: _selectedFolderId,
      onFolderSelected: (folderId) =>
          setState(() => _selectedFolderId = folderId),
      onEditFolder: _editFolder,
      onMoveToRoot: _moveFolderToRoot,
      onMoveToFolder: _moveFolderToFolder,
      onAddSubfolder: _addSubfolder,
      onDeleteFolder: _deleteFolder,
    );
  }

  Widget _buildBody() {
    // Get folders to display (only direct children of the current folder)
    List<FolderData> foldersToShow;
    if (_selectedFolderId == null) {
      foldersToShow = FolderService.getRootFolders(_folders);
    } else {
      foldersToShow =
          FolderService.getSubfolders(_folders, _selectedFolderId!);
    }

    // Filter notes
    List<NoteData> filteredNotes;
    if (_selectedFolderId == null) {
      filteredNotes = NoteService.getNotesWithoutFolder(_notes);
    } else {
      filteredNotes = NoteService.getNotesByFolder(_notes, _selectedFolderId);
    }

    // Sort notes by time (newest first)
    filteredNotes.sort((a, b) => b.time.compareTo(a.time));

    // Combine folders and notes
    final allItems = <Widget>[];

    // Add folder cards first
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
        itemBuilder: (context, index) => allItems[index],
      );
    } else {
      return _buildEmptyState();
    }
  }

  Widget _buildFolderCard(FolderData folder) {
    return FolderCard(
      folder: folder,
      folders: _folders,
      notes: _notes,
      selectedFolderId: _selectedFolderId,
      onTap: () => _handleFolderTap(folder),
      onEdit: _editFolder,
      onAddSubfolder: _addSubfolder,
      onDelete: _deleteFolder,
      onOpen: (folderId) => setState(() => _selectedFolderId = folderId),
    );
  }

  Widget _buildNoteCard(NoteData note) {
    return NoteCard(
      note: note,
      folders: _folders,
      selectedFolderId: _selectedFolderId,
      onTap: () => _handleNoteTap(note),
      onDelete: _deleteNote,
      onEdit: _editNote,
      onAddToFolder: _addNoteToFolder,
      onRemoveFromFolder: _removeNoteFromFolder,
    );
  }

  Widget _buildEmptyState() {
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
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      key: _fabKey,
      tooltip: 'Add',
      child: const Icon(Icons.add),
      onPressed: () => _showFabPopup(context, _fabKey),
    );
  }

  // Event Handlers
  void _handleFolderTap(FolderData folder) {
    if (folder.parentId != null) {
      // Subfolder - always navigate into it
      setState(() => _selectedFolderId = folder.folderId);
    } else {
      // Root folder - check if we should add or navigate
      if (_selectedFolderId != null && _selectedFolderId != folder.folderId) {
        _addFolderToCurrentFolder(folder.folderId);
      } else {
        setState(() => _selectedFolderId = folder.folderId);
      }
    }
  }

  void _handleNoteTap(NoteData note) async {
    if (_selectedFolderId != null && note.folderId != _selectedFolderId) {
      _addNoteToCurrentFolder(note);
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NoteScreen(note: note)),
      );
      setState(() {});
    }
  }

  void _goBack() {
    final currentFolder = _folders[_selectedFolderId];
    if (currentFolder?.parentId != null) {
      setState(() => _selectedFolderId = currentFolder!.parentId);
    } else {
      setState(() => _selectedFolderId = null);
    }
  }

  // Folder Operations
  Future<void> _editFolder(String folderId) async {
    final folder = _folders[folderId];
    if (folder == null) return;

    final newName = await _showEditDialog('Edit Folder Name', folder.name);
    if (newName != null && newName.trim().isNotEmpty) {
      final updatedFolder = FolderData(
        folderId: folder.folderId,
        name: newName.trim(),
        parentId: folder.parentId,
      );
      await FolderService.updateFolder(updatedFolder);
    }
  }

  Future<void> _moveFolderToRoot(String folderId) async {
    final folder = _folders[folderId];
    if (folder == null) return;

    final updatedFolder = FolderData(
      folderId: folder.folderId,
      name: folder.name,
      parentId: null,
    );
    await FolderService.updateFolder(updatedFolder);
  }

  Future<void> _moveFolderToFolder(FolderData folderToMove) async {
    final availableFolders = _folders.values
        .where((folder) => folder.folderId != folderToMove.folderId)
        .where((folder) => !FolderService.isDescendant(
            folder.folderId, folderToMove.folderId, _folders))
        .toList();

    if (availableFolders.isEmpty) {
      _showMessage('No Available Folders',
          'No other folders available to move this folder into.');
      return;
    }

    final selectedFolderId = await _showFolderSelectionDialog(
      'Move "${folderToMove.name}" to Folder',
      availableFolders,
    );

    if (selectedFolderId != null) {
      final newParentId = selectedFolderId == 'root' ? null : selectedFolderId;
      final updatedFolder = FolderData(
        folderId: folderToMove.folderId,
        name: folderToMove.name,
        parentId: newParentId,
      );
      await FolderService.updateFolder(updatedFolder);
    }
  }

  Future<void> _addSubfolder(String parentFolderId) async {
    final subfolderName = await _showEditDialog('Add Subfolder', '');
    if (subfolderName != null && subfolderName.trim().isNotEmpty) {
      await FolderService.createFolder(subfolderName.trim(), parentFolderId);
    }
  }

  Future<void> _deleteFolder(String folderId) async {
    final folder = _folders[folderId];
    if (folder == null) return;

    final shouldDelete = await _showConfirmationDialog(
      'Delete Folder',
      'Are you sure you want to delete "${folder.name}"? This will remove all notes from this folder and its subfolders.',
    );

    if (shouldDelete == true) {
      final foldersToDelete = <String>{folderId};
      final subfolders = _folders.values
          .where((folder) => folder.parentId == folderId)
          .map((folder) => folder.folderId);

      for (final subfolderId in subfolders) {
        foldersToDelete.addAll(_getAllSubfolderIds(subfolderId));
      }

      // Delete notes in the entire subtree first
      await NoteService.deleteNotesInFolders(foldersToDelete, _notes);
      // Then delete folders
      await FolderService.deleteFolderAndSubfolders(folderId, _folders);

      // Immediately reflect deletion in UI
      setState(() {
        for (final id in foldersToDelete) {
          _folders.remove(id);
        }
        // Also remove deleted notes from local state
        _notes.removeWhere((_, note) => foldersToDelete.contains(note.folderId));
        if (_selectedFolderId != null &&
            foldersToDelete.contains(_selectedFolderId)) {
          _selectedFolderId = null;
        }
      });
    }
  }

  Future<void> _addFolderToCurrentFolder(String folderId) async {
    final folder = _folders[folderId];
    if (folder == null || _selectedFolderId == null) return;

    if (FolderService.isDescendant(_selectedFolderId!, folderId, _folders)) {
      _showSnackBar('Cannot add folder: would create circular reference',
          isError: true);
      return;
    }

    final updatedFolder = FolderData(
      folderId: folder.folderId,
      name: folder.name,
      parentId: _selectedFolderId,
    );
    await FolderService.updateFolder(updatedFolder);
    _showSnackBar('Added "${folder.name}" to current folder');
  }

  // Note Operations
  Future<void> _deleteNote(NoteData note) async {
    await NoteService.deleteNote(note);
    setState(() => _notes.remove(note.id));
  }

  Future<void> _editNote(NoteData note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteScreen(note: note)),
    );
    setState(() {});
  }

  Future<void> _addNoteToFolder(NoteData note) async {
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
                id: note.id,
                title: note.title,
                contentJson: note.contentJson,
                plainTextContent: note.plainTextContent,
                time: note.time,
                done: note.done,
                folderId: folderId,
              );
              await NoteService.updateNote(updatedNote);
              _notes[note.id] = updatedNote;
              setState(() {});
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _removeNoteFromFolder(NoteData note) async {
    final updatedNote = NoteData(
      id: note.id,
      title: note.title,
      contentJson: note.contentJson,
      plainTextContent: note.plainTextContent,
      time: note.time,
      done: note.done,
      folderId: null,
    );
    await NoteService.updateNote(updatedNote);
    _notes[note.id] = updatedNote;
    setState(() {});
  }

  Future<void> _addNoteToCurrentFolder(NoteData note) async {
    if (_selectedFolderId == null) return;

    final updatedNote = NoteData(
      id: note.id,
      title: note.title,
      contentJson: note.contentJson,
      plainTextContent: note.plainTextContent,
      time: note.time,
      done: note.done,
      folderId: _selectedFolderId,
    );
    await NoteService.updateNote(updatedNote);
    _notes[note.id] = updatedNote;
    _showSnackBar('Added "${note.title}" to current folder');
  }

  // UI Helpers
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
      begin: const Offset(0.2, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));

    final Animation<double> fadeAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeIn,
    );

    bool isOverlayClosed = false;

    Future<void> closeOverlay() async {
      if (isOverlayClosed) return;
      isOverlayClosed = true;
      if (controller.status != AnimationStatus.dismissed) {
        await controller.reverse();
      }
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
      controller.dispose();
    }

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  closeOverlay();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
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
                        closeOverlay();
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

  Future<String?> _showEditDialog(String title, String initialValue) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
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
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
  }

  Future<String?> _showFolderSelectionDialog(
      String title, List<FolderData> availableFolders) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
                    ListTile(
                      leading: const Icon(Icons.folder),
                      title: const Text('Root Level (No Parent)'),
                      subtitle: const Text('Move to top level'),
                      onTap: () => Navigator.of(context).pop('root'),
                    ),
                    const Divider(),
                    ...availableFolders.map((folder) {
                      final folderPath = FolderService.getFolderPath(
                          folder.folderId, _folders);
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
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
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
}

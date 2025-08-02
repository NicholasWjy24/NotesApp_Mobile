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
                'All Folder',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 40),
              ),
            ),
          ),
          if (_folders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No Folder Added',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            )
          else
            ..._folders.values.map((folder) {
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(folder.name),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final newName = await _showEditFolderDialog(folder.name);
                      if (newName != null && newName.trim().isNotEmpty) {
                        final updatedFolder = FolderData(
                          folderId: folder.folderId,
                          name: newName.trim(),
                        );
                        await updatedFolder.save();
                      }
                    } else if (value == 'delete') {
                      await folder.delete();
                      _folders.remove(folder.folderId);
                      setState(() {});
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedFolderId = folder.folderId;
                    Navigator.pop(context);
                  });
                },
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget nNotescontains() {
    // Filter notes sesuai folder yang dipilih
    final filteredNotes = _noteData.values
        .where((note) => note.folderId == _selectedFolderId)
        .toList();

    if (filteredNotes.isNotEmpty) {
      return ListView.builder(
        itemCount: filteredNotes.length,
        itemBuilder: (context, index) {
          final item = filteredNotes[index];

          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                titleAlignment: ListTileTitleAlignment.top,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.length > 30
                          ? '${item.title.substring(0, 30)}...'
                          : item.title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
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
                    const PopupMenuItem(
                      value: 'add_to_folder',
                      child: Text('Add to Folder'),
                    ),
                  ],
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NoteScreen(note: item)),
                  );
                  setState(() {});
                },
              ),
            ),
          );
        },
      );
    } else {
      return const Center(
        child: Text(
          'No notes yet. Click + to add one!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  AppBar nNotesAppBar() {
    return AppBar(
      title: const Text('NNotes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}

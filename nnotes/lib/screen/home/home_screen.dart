import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nnotes/data/note_data.dart';
import 'package:nnotes/screen/note/note_screen.dart';
import 'package:localstore/localstore.dart';
import 'package:nnotes/data/folder_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = Localstore.instance;
  final Map<String, FolderData> _folders = {};
  final _noteData = <String, NoteData>{};
  List<String> folders = [];
  int folderCounter = 1;
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

  Future<void> _addFolder() async {
    final folderName = await _showAddFolderDialog();
    if (folderName != null && folderName.trim().isNotEmpty) {
      final id = _db.collection('FolderData').doc().id;
      final newFolder = FolderData(folderId: id, name: folderName.trim());
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
      floatingActionButton: nNotesAddButton(context),
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
                'MENU',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 40),
              ),
            ),
          ),
          ListTile(
            title: const Text('Add Folder'),
            leading: const Icon(Icons.create_new_folder_sharp),
            onTap: () async {
              final newFolderName = await _showAddFolderDialog();
              if (newFolderName != null && newFolderName.trim().isNotEmpty) {
                final id = _db.collection('FolderData').doc().id;
                final newFolder =
                    FolderData(folderId: id, name: newFolderName.trim());
                await newFolder.save();
                // Otomatis masuk ke _folders karena stream listener
              }
            },
          ),
          const Divider(),
          ..._folders.values.map((folder) {
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(folder.name),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert), // Titik tiga
                onSelected: (value) async {
                  if (value == 'edit') {
                    final newName = await _showEditFolderDialog(folder.name);
                    if (newName != null && newName.trim().isNotEmpty) {
                      final updatedFolder = FolderData(
                        folderId: folder.folderId,
                        name: newName.trim(),
                      );
                      await updatedFolder.save(); // replace existing folder
                    }
                  } else if (value == 'delete') {
                    await folder.delete();
                    _folders.remove(folder.folderId); // penting
                    setState(() {}); // trigger rebuild
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
                // Aksi saat folder diklik, misalnya filter catatan
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  FloatingActionButton nNotesAddButton(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Add Notes',
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const NoteScreen()));
      },
      child: const Icon(Icons.add),
    );
  }

  Widget nNotescontains() {
    if (_noteData.isNotEmpty) {
      return ListView.builder(
        itemCount: _noteData.length,
        itemBuilder: (context, index) {
          final key = _noteData.keys.elementAt(index);
          final item = _noteData[key]!;

          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
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
                trailing: IconButton(
                  icon: Icon(Icons.delete,
                      color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () {
                    setState(() {
                      item.delete();
                      _noteData.remove(item.id);
                    });
                  },
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

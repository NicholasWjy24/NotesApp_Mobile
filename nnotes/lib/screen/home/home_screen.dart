import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nnotes/screen/note/note_data.dart';
import 'package:nnotes/screen/note/note_screen.dart';
import 'package:localstore/localstore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = Localstore.instance;
  final _noteData = <String, NoteData>{};
  StreamSubscription<Map<String, dynamic>>? _subscription;
  @override
  void initState() {
    /*
    _db.collection('todos').get().then((value) {
      setState(() {
        value?.entries.forEach((element) {
          final item = Todo.fromMap(element.value);
          _items.putIfAbsent(item.id, () => item);
        });
      });
    });
    */
    _subscription = _db.collection('NoteData').stream.listen((event) {
      setState(() {
        final item = NoteData.fromMap(event);
        _noteData[item.id] = item;
      });
    });
    if (kIsWeb) _db.collection('NoteData').stream.asBroadcastStream();
    super.initState();
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
            title: const Text('Add Notes'),
            onTap: () {},
          ),
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
                      item.content.length > 80
                          ? '${item.content.substring(0, 80)}...'
                          : item.content,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height:20),
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

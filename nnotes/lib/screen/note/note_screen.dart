import 'package:nnotes/screen/note/note_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localstore/localstore.dart';
import 'dart:async';

class NoteScreen extends StatefulWidget {
  final NoteData? note;
  const NoteScreen({super.key, this.note});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final _db = Localstore.instance;
  final _noteData = <String, NoteData>{};

  final noteTitleTextFieldController = TextEditingController();
  final contentsNoteController = TextEditingController();
  int? noteID;
  Timer? _debounce;

  @override
  void dispose() {
    noteTitleTextFieldController.removeListener(_autoSave);
    contentsNoteController.removeListener(_autoSave);
    noteTitleTextFieldController.dispose();
    contentsNoteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.note != null) {
      noteTitleTextFieldController.text = widget.note!.title;
      contentsNoteController.text = widget.note!.content;
    }
    if (kIsWeb) _db.collection('NoteData').stream.asBroadcastStream();
    noteTitleTextFieldController.addListener(_autoSave);
    contentsNoteController.addListener(_autoSave);
    super.initState();
  }

  void _autoSave() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(seconds: 1), () {
      final title = noteTitleTextFieldController.text.trim();
      final content = contentsNoteController.text.trim();

      if (title.isEmpty || content.isEmpty) {
        return;
      }

      final note = NoteData(
        id: widget.note?.id ?? _db.collection('NoteData').doc().id,
        title: title,
        content: content,
        time: DateTime.now(),
        done: false,
      );
      note.save();
      print("Autosaved");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: noteTitleTextFieldController,
          maxLength: 18,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            border: OutlineInputBorder(borderSide: BorderSide.none),
            hintText: 'Input the Title...',
            hintStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (contentsNoteController.text.trim().isEmpty ||
                  noteTitleTextFieldController.text.trim().isEmpty) {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => Dialog(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(height: 12),
                          const Text(
                            textAlign: TextAlign.center,
                            'You must fill in the title and content of this note to save the note.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.onSecondary),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'I Understand',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                final id =
                    widget.note?.id ?? _db.collection('NoteData').doc().id;
                final now = DateTime.now();
                final item = NoteData(
                  id: id,
                  title: noteTitleTextFieldController.text,
                  content: contentsNoteController.text,
                  time: now,
                  done: false,
                );
                await item.save();
                setState(() {
                  _noteData[item.id] = item;
                });
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Save',
              style:
                  TextStyle(fontSize: 16, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: contentsNoteController,
            maxLines: 100,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
        ),
      ),
    );
  }
}

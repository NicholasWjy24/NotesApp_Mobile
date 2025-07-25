import 'dart:async';
import 'dart:convert';
import 'package:flutter_quill/quill_delta.dart';
import 'package:nnotes/widget/quill_tool_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:localstore/localstore.dart';
import 'package:nnotes/screen/note/note_data.dart';

class NoteScreen extends StatefulWidget {
  final NoteData? note;
  const NoteScreen({super.key, this.note});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final _db = Localstore.instance;
  final _noteData = <String, NoteData>{};

  final _noteTitleTextFieldController = TextEditingController();
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  int? noteID;
  Timer? _debounce;
  StreamSubscription? _quillSubscription;

  @override
  void dispose() {
    _noteTitleTextFieldController.removeListener(_autoSave);
    _quillController.removeListener(_autoSave);
    _quillSubscription?.cancel();
    _debounce?.cancel();
    _noteTitleTextFieldController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Initialize Quill controller with existing content or empty document
    Document document;
    if (widget.note != null && widget.note!.contentJson.isNotEmpty) {
      final delta = Delta.fromJson(jsonDecode(widget.note!.contentJson));
      final plainText = Document.fromDelta(delta).toPlainText().trim();
      if (plainText.isEmpty) {
        document = Document();
      } else {
        document = Document.fromDelta(delta);
      }
    } else {
      document = Document();
    }

    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    if (widget.note != null) {
      _noteTitleTextFieldController.text = widget.note!.title;
    }

    // Listen to changes for auto-save
    _noteTitleTextFieldController.addListener(_autoSave);
    _quillController.addListener(_autoSave);
  }

  bool isDeltaEmpty(Delta delta) {
    final text = delta
        .toList()
        .where((op) => op.key == 'insert')
        .map((op) => op.value)
        .whereType<String>()
        .join();

    return text.trim().isEmpty;
  }

  void _autoSave() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(seconds: 1), () {
      final title = _noteTitleTextFieldController.text.trim();
      final delta = _quillController.document.toDelta();
      final plainText = _quillController.document.toPlainText().trim();

      final isContentEmpty = isDeltaEmpty(delta);

      if ((title.isEmpty && isContentEmpty) || widget.note?.id == null) {
        return;
      }

      final note = NoteData(
        id: widget.note!.id,
        title: title,
        contentJson: jsonEncode(delta.toJson()),
        plainTextContent: plainText,
        time: DateTime.now(),
        done: false,
      );
      note.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _noteTitleTextFieldController,
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
              final title = _noteTitleTextFieldController.text.trim();
              final delta = _quillController.document.toDelta();
              final plainText = Document.fromDelta(delta).toPlainText().trim();

              if (title.isEmpty || plainText.isEmpty) {
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
                                  Theme.of(context).colorScheme.onSecondary,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'I Understand',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                return; // <-- Penting: agar proses tidak lanjut ke save
              } else {
                final id =
                    widget.note?.id ?? _db.collection('NoteData').doc().id;
                final now = DateTime.now();
                final delta = _quillController.document.toDelta();
                final plainText =
                    _quillController.document.toPlainText().trim();
                final title = _noteTitleTextFieldController.text.trim();

                final item = NoteData(
                  id: id,
                  title: title,
                  contentJson: jsonEncode(delta.toJson()),
                  plainTextContent: plainText,
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
          padding: const EdgeInsets.all(12),
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      isScrollControlled: true, // penting jika isi card tinggi
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            height:
                                400, // atau pakai `Wrap` jika ingin fleksibel
                            child: Column(
                              children: [
                                quillToolBar(quillController: _quillController),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.filter_alt)),
              Expanded(
                  child: QuillEditor(
                      configurations: QuillEditorConfigurations(
                          controller: _quillController),
                      focusNode: _focusNode,
                      scrollController: _scrollController))
            ],
          ),
        ),
      ),
    );
  }
}

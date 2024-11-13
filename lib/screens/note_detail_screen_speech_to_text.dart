// lib/screens/note_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import 'drawing_screen.dart';

class NoteDetailScreenSpeechToText extends StatefulWidget {
  final Note? note;
  final bool isNewNote;
  final bool autoDrawing;

  NoteDetailScreenSpeechToText(
      {this.note, this.isNewNote = false, this.autoDrawing = false});

  @override
  _NoteDetailScreenSpeechToTextState createState() =>
      _NoteDetailScreenSpeechToTextState();
}

class _NoteDetailScreenSpeechToTextState
    extends State<NoteDetailScreenSpeechToText> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Note _currentNote;
  late TextEditingController _newItemController;
  late AssetsAudioPlayer _audioPlayer;
  late Record _audioRecorder;
  SpeechToText _speechToText = SpeechToText();
  bool _isRecording = false;
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note ?? Note();
    _titleController = TextEditingController(text: _currentNote.title);
    _contentController = TextEditingController(text: _currentNote.content);
    _newItemController = TextEditingController();
    // _recorder = FlutterSoundRecorder();
    // _player = FlutterSoundPlayer();
    // _speech = stt.SpeechToText();
    _audioPlayer = AssetsAudioPlayer();
    _audioRecorder = Record();

    _initSpeech();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoDrawing && _currentNote.type == NoteType.drawing) {
        _navigateToDrawing(autoDrawing: widget.autoDrawing);
      }
    });
  }

  // Future<void> _initSpeech() async {
  // bool available = await _speech.initialize(
  //   onError: (error) => print('Speech recognition error: $error'),
  //   onStatus: (status) => print('Speech recognition status: $status'),
  //   finalTimeout: const Duration(seconds: 20),
  //   debugLogging: true,
  // );
  // if (!available) {
  //   print('Speech recognition not available');
  // }
  // }

  Future<bool> _initSpeech() async {
    final available = _speechEnabled = await _speechToText.initialize();
    setState(() {});
    return available;
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          // print("Result: $result");
          if (result.finalResult) {
            // Append new text with a space if content is not empty
            if (_contentController.text.isNotEmpty) {
              _contentController.text += ' ';
            }
            _contentController.text += result.recognizedWords;
            print("Speech recoginzed: ${result.recognizedWords}");
            // print("Result Speech: $result");
            if (result.recognizedWords.isNotEmpty) {
              _startListening();
            }
            // Move cursor to end of text
            _contentController.selection = TextSelection.fromPosition(
              TextPosition(offset: _contentController.text.length),
            );
          }
        });
      },
      pauseFor: Duration(seconds: 10),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        onDevice: false,
        partialResults: true,
        cancelOnError: true,
      ),
      listenFor: Duration(minutes: 30),
    );
  }

  Future<void> _startRecording() async {
    // final status = await Permission.microphone.request();
    // if (status != PermissionStatus.granted) return;

    try {
      if (await _audioRecorder.hasPermission()) {
        // Start audio recording
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(path: path);

        // Start speech recognition
        bool available = await _initSpeech();
        if (available) {
          setState(() {
            _isRecording = true;
            _isListening = true;
            _currentNote.audioPath = path;
          });

          await _speechToText.listen(
            onResult: (result) {
              setState(() {
                // print("Result: $result");
                if (result.finalResult) {
                  // Append new text with a space if content is not empty
                  if (_contentController.text.isNotEmpty) {
                    _contentController.text += ' ';
                  }
                  _contentController.text += result.recognizedWords;
                  print("Speech recoginzed: ${result.recognizedWords}");
                  print("Result Speech: $result");
                  if (result.finalResult) {
                    _startListening();
                  }
                  // Move cursor to end of text
                  _contentController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _contentController.text.length),
                  );
                }
              });
            },
            pauseFor: Duration(seconds: 10),
            listenOptions: SpeechListenOptions(
              listenMode: ListenMode.dictation,
              onDevice: false,
              partialResults: true,
              cancelOnError: true,
            ),
            listenFor: Duration(minutes: 30),
          );
        }
      }
    } catch (e) {
      print('Error starting recording and speech recognition: $e');
    }
  }

  // Future<void> _startRecording() async {
  //   final status = await Permission.microphone.request();
  //   if (status != PermissionStatus.granted) return;

  //   await _recorder.openRecorder();
  //   await _recorder.startRecorder(toFile: 'temp_audio.aac');
  //   setState(() => _isRecording = true);

  //   _speech.listen(
  //     onResult: (result) {
  //       if (result.finalResult) {
  //         setState(() {
  //           _contentController.text += ' ${result.recognizedWords}';
  //         });
  //       }
  //     },
  //   );
  // }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    await _speechToText.stop();
    setState(() {
      _isRecording = false;
      _isListening = false;
      _currentNote.audioPath = path;
    });
  }

  // void _onSpeechResult(SpeechRecognitionResult result) {
  //   setState(() {
  //     _contentController.text += result.recognizedWords;
  //   });
  // }

  // void _saveNote() {
  //   if (_titleController.text.trim().isEmpty &&
  //       _contentController.text.trim().isEmpty &&
  //       _currentNote.images.isEmpty &&
  //       _currentNote.checklistItems.isEmpty &&
  //       _currentNote.drawingPath == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Cannot save an empty note')),
  //     );
  //     Navigator.pop(context);
  //     return;
  //   }

  //   _currentNote.title = _titleController.text;
  //   _currentNote.content = _contentController.text;
  //   _currentNote.modifiedAt = DateTime.now();

  //   if (widget.note == null || widget.isNewNote == true) {
  //     Provider.of<NotesProvider>(context, listen: false).addNote(_currentNote);
  //   } else {
  //     Provider.of<NotesProvider>(context, listen: false)
  //         .updateNote(_currentNote);
  //   }

  //   Navigator.pop(context);
  // }

  void _saveNote() {
    // Check if note is empty
    bool isNoteEmpty = _titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty &&
        _currentNote.images.isEmpty &&
        _currentNote.checklistItems.isEmpty &&
        _currentNote.drawingPath == null;
    _currentNote.audioPath == null;

    if (isNoteEmpty) {
      // Show message and pop only once
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save an empty note')),
      );
      Navigator.pop(context);
      return;
    }

    // Update note data
    _currentNote.title = _titleController.text;
    _currentNote.content = _contentController.text;
    _currentNote.modifiedAt = DateTime.now();

    // Save note using provider
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    if (widget.note == null || widget.isNewNote == true) {
      notesProvider.addNote(_currentNote);
    } else {
      notesProvider.updateNote(_currentNote);
    }

    // Pop only once after saving
    Navigator.pop(context);
    debugPrint("Note saved");
  }

  void _toggleNoteType() {
    setState(() {
      if (_currentNote.type == NoteType.regular) {
        _currentNote.type = NoteType.checklist;
      } else {
        _currentNote.type = NoteType.regular;
      }
    });
  }

  void _addChecklistItem(String text) {
    if (text.isEmpty) return;
    setState(() {
      _currentNote.checklistItems.add(ChecklistItem(text: text));
      _newItemController.clear();
    });
  }

  void _toggleChecklistItem(String id) {
    setState(() {
      final item =
          _currentNote.checklistItems.firstWhere((item) => item.id == id);
      item.isChecked = !item.isChecked;
    });
  }

  void _removeChecklistItem(String id) {
    setState(() {
      _currentNote.checklistItems.removeWhere((item) => item.id == id);
    });
  }

  void _navigateToDrawing({bool autoDrawing = false}) async {
    final drawingPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingScreen(
            initialDrawing: _currentNote.drawingPath,
            isFromHomeScreen: autoDrawing),
      ),
    );

    if (drawingPath != null) {
      setState(() {
        _currentNote.drawingPath = drawingPath;
        _currentNote.type = NoteType.drawing;
      });
    }
  }

  Future<void> _addImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _currentNote.images.add(image.path);
      });
    }
  }

  // Future<void> _recordAudio() async {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('Audio recording not implemented yet')),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _saveNote,
        ),
        actions: [
          IconButton(
            icon: Icon(_currentNote.type == NoteType.checklist
                ? Icons.subject
                : Icons.check_box),
            onPressed: _toggleNoteType,
          ),
          IconButton(
            icon: Icon(Icons.brush),
            onPressed: _navigateToDrawing,
          ),
          IconButton(
            icon: Icon(Icons.push_pin_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _addImage,
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Delete'),
                onTap: () {
                  Provider.of<NotesProvider>(context, listen: false)
                      .deleteNote(_currentNote.id);
                  Navigator.pop(context);
                },
              ),
              if (_currentNote.audioPath != null)
                PopupMenuItem(
                  child: Text('Delete Recording'),
                  onTap: () {
                    setState(() {
                      _currentNote.audioPath = null;
                    });
                  },
                ),
              PopupMenuItem(
                child: Text('Share'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_currentNote.type == NoteType.regular)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          hintText: 'Note',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                      if (_isListening)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Listening...',
                              style: TextStyle(color: Colors.green)),
                        ),
                      if (_currentNote.audioPath != null)
                        ElevatedButton(
                          child: Text('Play Recorded Audio'),
                          onPressed: () async {
                            _audioPlayer.open(
                              Audio.file(_currentNote.audioPath!),
                              autoStart: true,
                            );
                          },
                        ),
                      ..._currentNote.images
                          .map((imagePath) => Image.file(File(imagePath)))
                          .toList(),
                    ],
                  ),
                ),
              )
            else if (_currentNote.type == NoteType.checklist)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _currentNote.checklistItems.length,
                        itemBuilder: (context, index) {
                          final item = _currentNote.checklistItems[index];
                          return ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.drag_indicator),
                                  onPressed: () {},
                                ),
                                Checkbox(
                                  value: item.isChecked,
                                  onChanged: (_) =>
                                      _toggleChecklistItem(item.id),
                                ),
                              ],
                            ),
                            title: Text(
                              item.text,
                              style: TextStyle(
                                decoration: item.isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => _removeChecklistItem(item.id),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _newItemController,
                              decoration: InputDecoration(
                                hintText: 'List item',
                                border: InputBorder.none,
                              ),
                              onSubmitted: _addChecklistItem,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (_currentNote.type == NoteType.drawing &&
                _currentNote.drawingPath != null)
              Expanded(
                child: Image.file(File(_currentNote.drawingPath!)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _newItemController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    // _speech.stop();
    _speechToText.stop();
    super.dispose();
  }
}

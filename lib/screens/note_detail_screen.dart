import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import 'drawing_screen.dart';
import '../utils/vosk_result.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note? note;
  final bool isNewNote;
  final bool autoDrawing;
  final bool autoRecording;

  NoteDetailScreen(
      {this.note,
      this.isNewNote = false,
      this.autoDrawing = false,
      this.autoRecording = false});

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Note _currentNote;
  late TextEditingController _newItemController;
  late AssetsAudioPlayer _audioPlayer;
  late Record _audioRecorder;
  bool _isRecording = false;

  // Vosk-related variables
  static const _modelName = 'vosk-model-small-en-us-0.15';
  static const _sampleRate = 16000;
  final _vosk = VoskFlutterPlugin.instance();
  final _modelLoader = ModelLoader();
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  String _sttAllWords = '';

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note ?? Note();
    _titleController = TextEditingController(text: _currentNote.title);
    _contentController = TextEditingController(text: _currentNote.content);
    _newItemController = TextEditingController();
    _audioPlayer = AssetsAudioPlayer();
    _audioRecorder = Record();

    _initVosk();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoDrawing && _currentNote.type == NoteType.drawing) {
        _navigateToDrawing(autoDrawing: widget.autoDrawing);
      }
      if (widget.autoRecording) {
        _recordAudio();
      }
    });
  }

  Future<void> _initVosk() async {
    print("Init Vosk");
    await Permission.microphone.request();
    _modelLoader
        .loadModelsList()
        .then((modelsList) =>
            modelsList.firstWhere((model) => model.name == _modelName))
        .then((modelDescription) =>
            _modelLoader.loadFromNetwork(modelDescription.url))
        .then((modelPath) => _vosk.createModel(modelPath))
        .then((model) => setState(() => _model = model))
        .then((_) =>
            _vosk.createRecognizer(model: _model!, sampleRate: _sampleRate))
        .then((value) => _recognizer = value)
        .then((recognizer) async {
      if (Platform.isAndroid) {
        _vosk
            .initSpeechService(_recognizer!)
            .then((speechService) => setState(() {
                  _speechService = speechService;
                }))
            .catchError((e) => print('Error initializing speech service: $e'));
        print('Speech Service $_speechService');
        print('Recognizer $_recognizer');
      }
      print('Speech Service $_speechService');
      print('Recognizer $_recognizer');
    }).catchError((e) => print('Error initializing Vosk: $e'));
  }

  // Future<void> _initVosk() async {
  //   await Permission.microphone.request();
  //   try {
  //     final modelsList = await _modelLoader.loadModelsList();
  //     final modelDescription =
  //         modelsList.firstWhere((model) => model.name == _modelName);
  //     final modelPath =
  //         await _modelLoader.loadFromNetwork(modelDescription.url);
  //     _model = await _vosk.createModel(modelPath);
  //     _recognizer =
  //         await _vosk.createRecognizer(model: _model!, sampleRate: _sampleRate);

  //     if (Platform.isAndroid) {
  //       _speechService = await _vosk.initSpeechService(_recognizer!);
  //     }
  //   } catch (e) {
  //     print('Error initializing Vosk: $e');
  //   }
  // }

  Future<void> _destroyVosk() async {
    try {
      await _speechService?.stop();
      await _recognizer?.dispose();
      _model?.dispose();
      _speechService = null;
      _recognizer = null;
      _model = null;
    } catch (e) {
      print('Error destroying Vosk: $e');
    }
  }

  // Future<void> _startRecording() async {
  //   final status = await Permission.microphone.request();
  //   if (status != PermissionStatus.granted) return;
  //   try {
  //     if (await _audioRecorder.hasPermission()) {
  //       print('Recording...');
  //       await _destroyVosk(); // Destroy previous instances
  //       await _initVosk();
  //       final directory = await getApplicationDocumentsDirectory();
  //       final path =
  //           '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
  //       // await _audioRecorder.start(path: path);

  //       setState(() {
  //         _isRecording = true;
  //         _currentNote.audioPath = path;
  //       });

  //       _speechService?.start();
  //       _speechService?.onResult().listen(_onSpeechResult);
  //     }
  //   } catch (e) {
  //     print('Error starting recording and speech recognition: $e');
  //   }
  // }

  Future<void> _recordAudio() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
          samplingRate: 16000,
          encoder: AudioEncoder.wav,
          numChannels: 1,
          path: path);
      setState(() {
        _isRecording = true;
        _currentNote.audioPath = path;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Future<void> _stopRecording() async {
  //   final path = await _audioRecorder.stop();
  //   _speechService?.stop();
  //   setState(() {
  //     _isRecording = false;
  //     _currentNote.audioPath = path;
  //   });
  // }

  Future<void> _stopRecording() async {
    try {
      print('Speech Service $_speechService');
      print('Recognizer $_recognizer');
      final filePath = await _audioRecorder.stop();
      _speechService?.stop();
      if (filePath != null) {
        final bytes = File(filePath).readAsBytesSync();
        _recognizer!.acceptWaveformBytes(bytes);
        final result = await _recognizer!.getFinalResult();
        final resultMap = jsonDecode(result);
        if (_contentController.text.isNotEmpty) {
          _contentController.text += ' ';
        }
        _contentController.text += resultMap['text'];
        setState(() {
          _isRecording = false;
          _currentNote.audioPath = filePath;
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _onSpeechResult(dynamic result) {
    Map<String, dynamic> decoded = json.decode(result);
    VoskResult voskResult = VoskResult.fromJson(decoded);
    setState(() {
      _sttAllWords += voskResult.text;
      _contentController.text = _sttAllWords;
    });
    print("record result: ${voskResult.text}");
  }

  void _saveNote() {
    bool isNoteEmpty = _titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty &&
        _currentNote.images.isEmpty &&
        _currentNote.checklistItems.isEmpty &&
        _currentNote.drawingPath == null &&
        _currentNote.audioPath == null;

    if (isNoteEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save an empty note')),
      );
      Navigator.pop(context);
      return;
    }

    _currentNote.title = _titleController.text;
    _currentNote.content = _contentController.text;
    _currentNote.modifiedAt = DateTime.now();

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    if (widget.note == null || widget.isNewNote == true) {
      notesProvider.addNote(_currentNote);
    } else {
      notesProvider.updateNote(_currentNote);
    }

    Navigator.pop(context);
    debugPrint("Note saved");
  }

  // ... (other methods remain the same: _toggleNoteType, _addChecklistItem, _toggleChecklistItem, _removeChecklistItem, _navigateToDrawing, _addImage
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
            onPressed: _isRecording ? _stopRecording : _recordAudio,
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
                      if (_isRecording)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Recording...',
                              style: TextStyle(color: Colors.red)),
                        ),
                      if (_currentNote.audioPath != null)
                        ElevatedButton(
                          child: Text('Play Recorded Audio'),
                          onPressed: () {
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
            // ... (checklist and drawing type widgets remain the same)
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
    _speechService?.stop();
    super.dispose();
  }
}

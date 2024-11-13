import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../helpers/database_helper.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  String _searchQuery = '';

  NotesProvider() {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    _notes = await DatabaseHelper.instance.getNotes();
    notifyListeners();
  }

  List<Note> get activeNotes {
    var activeNotes = _notes.where((note) => note.status == NoteStatus.active).toList();

    if (_searchQuery.isEmpty) {
      return activeNotes;
    }
    return activeNotes
        .where((note) =>
            note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<Note> get archivedNotes {
    return _notes.where((note) => note.status == NoteStatus.archived).toList();
  }

  List<Note> get deletedNotes {
    return _notes.where((note) => note.status == NoteStatus.deleted).toList();
  }

  Future<void> addNote(Note note) async {
    await DatabaseHelper.instance.insertNote(note);
    _notes.add(note);
    notifyListeners();
  }

  Future<void> updateNote(Note updatedNote) async {
    await DatabaseHelper.instance.updateNote(updatedNote);
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }
  }

  Future<void> archiveNote(String id) async {
    final note = _notes.firstWhere((n) => n.id == id);
    note.status = NoteStatus.archived;
    await updateNote(note);
  }

  Future<void> unarchiveNote(String id) async {
    final note = _notes.firstWhere((n) => n.id == id);
    note.status = NoteStatus.active;
    await updateNote(note);
  }

  Future<void> deleteNote(String id) async {
    final note = _notes.firstWhere((n) => n.id == id);
    note.status = NoteStatus.deleted;
    note.deletedAt = DateTime.now();
    await updateNote(note);
  }

  Future<void> restoreNote(String id) async {
    final note = _notes.firstWhere((n) => n.id == id);
    note.status = NoteStatus.active;
    note.deletedAt = null;
    await updateNote(note);
  }

  Future<void> permanentlyDeleteNote(String id) async {
    await DatabaseHelper.instance.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> cleanupDeletedNotes() async {
    final now = DateTime.now();
    for (var note in _notes) {
      if (note.status == NoteStatus.deleted &&
          note.deletedAt != null &&
          now.difference(note.deletedAt!).inDays > 7) {
        await permanentlyDeleteNote(note.id);
      }
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addImageToNote(String noteId, String imagePath) async {
    final noteIndex = _notes.indexWhere((note) => note.id == noteId);
    if (noteIndex != -1) {
      _notes[noteIndex].images.add(imagePath);
      await updateNote(_notes[noteIndex]);
    }
  }

  Future<void> removeImageFromNote(String noteId, String imagePath) async {
    final noteIndex = _notes.indexWhere((note) => note.id == noteId);
    if (noteIndex != -1) {
      _notes[noteIndex].images.remove(imagePath);
      await updateNote(_notes[noteIndex]);
    }
  }
}
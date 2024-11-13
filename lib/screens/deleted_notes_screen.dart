// lib/screens/deleted_notes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_grid.dart';

class DeletedNotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deleted Notes'),
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, child) {
          final deletedNotes = notesProvider.deletedNotes;
          return NoteGrid(notes: deletedNotes, isTrash: true);
        },
      ),
    );
  }
}
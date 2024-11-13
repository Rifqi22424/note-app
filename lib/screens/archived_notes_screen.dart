// lib/screens/archived_notes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_grid.dart';

class ArchivedNotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archived Notes'),
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, child) {
          final archivedNotes = notesProvider.archivedNotes;
          return NoteGrid(notes: archivedNotes, isArchive: true);
        },
      ),
    );
  }
}
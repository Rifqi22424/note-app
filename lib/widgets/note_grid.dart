import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../screens/note_detail_screen.dart';
import '../models/note.dart';

class NoteGrid extends StatelessWidget {
  final List<Note> notes;
  final bool isArchive;
  final bool isTrash;

  NoteGrid({
    required this.notes,
    this.isArchive = false,
    this.isTrash = false,
  });

  Widget _getAlternativeContent(Note note) {
    if (note.checklistItems.isNotEmpty) {
      return Text(
        note.checklistItems.first.text,
        style: TextStyle(fontSize: 14),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    } else if (note.drawingPath != null) {
      return Center(
        child: Image.file(
          File(note.drawingPath!),
          fit: BoxFit.cover,
          height: 120,
        ),
      );
    } else if (note.images.isNotEmpty) {
      return Center(
        child: Image.file(
          File(note.images.first),
          fit: BoxFit.cover,
          height: 100,
        ),
      );
    }
    return SizedBox.shrink();
  }

  void _showOptions(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isTrash)
              ListTile(
                leading: Icon(isArchive ? Icons.unarchive : Icons.archive),
                title: Text(isArchive ? 'Unarchive' : 'Archive'),
                onTap: () {
                  final notesProvider =
                      Provider.of<NotesProvider>(context, listen: false);
                  if (isArchive) {
                    notesProvider.unarchiveNote(note.id);
                  } else {
                    notesProvider.archiveNote(note.id);
                  }
                  Navigator.of(ctx).pop();
                },
              ),
            ListTile(
              leading: Icon(isTrash ? Icons.restore_from_trash : Icons.delete),
              title: Text(isTrash ? 'Restore' : 'Delete'),
              onTap: () {
                final notesProvider =
                    Provider.of<NotesProvider>(context, listen: false);
                if (isTrash) {
                  notesProvider.restoreNote(note.id);
                } else {
                  notesProvider.deleteNote(note.id);
                }
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        return GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return InkWell(
                onLongPress: () => _showOptions(context, note),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NoteDetailScreen(note: note),
                    ),
                  );
                },
                child: Card(
                  color: Color(0xFF2D2D2D),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.title.isNotEmpty)
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (note.title.isNotEmpty) SizedBox(height: 8),
                        if (note.content.isNotEmpty)
                          Expanded(
                            child: Text(
                              note.content,
                              style: TextStyle(fontSize: 14),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else
                          Expanded(
                            child: _getAlternativeContent(note),
                          ),
                        if (note.type == NoteType.checklist)
                          Icon(Icons.checklist, size: 16),
                        if (note.type == NoteType.drawing)
                          Icon(Icons.brush, size: 16),
                        if (note.images.isNotEmpty) Icon(Icons.image, size: 16),
                      ],
                    ),
                  ),
                ));
          },
        );
      },
    );
  }
}

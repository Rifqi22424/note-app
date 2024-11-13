import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_grid.dart';
import '../widgets/app_drawer.dart';
import 'note_detail_screen.dart';
import '../models/note.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: SearchBar(
          hintText: 'Search your notes',
          onChanged: (value) {
            Provider.of<NotesProvider>(context, listen: false)
                .setSearchQuery(value);
          },
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.person, color: Colors.blue),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: AppDrawer(),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, child) {
          final activeNotes = notesProvider.activeNotes;
          return NoteGrid(notes: activeNotes);
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.check_box_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NoteDetailScreen(
                        note: Note(type: NoteType.checklist),
                        isNewNote: true,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.brush),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NoteDetailScreen(
                        note: Note(
                          type: NoteType.drawing,
                        ),
                        autoDrawing: true,
                        isNewNote: true,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.mic),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NoteDetailScreen(
                        note: Note(
                          type: NoteType.regular,
                        ),
                        isNewNote: true,
                        autoRecording: true,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.image),
                onPressed: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);

                  if (image != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NoteDetailScreen(
                          note: Note(
                            type: NoteType.regular,
                            images: [image.path],
                          ),
                          isNewNote: true,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[800],
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(),
            ),
          );
        },
      ),
    );
  }
}

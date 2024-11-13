import 'package:flutter/material.dart';

import '../screens/archived_notes_screen.dart';
import '../screens/deleted_notes_screen.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            const DrawerHeader(
              child: Text(
                'Notes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.lightbulb_outline),
              title: Text('Notes'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_none),
              title: Text('Reminders'),
              onTap: () {},
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Create new label'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.archive_outlined),
              title: Text('Archive'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => ArchivedNotesScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Trash'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => DeletedNotesScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Help & feedback'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

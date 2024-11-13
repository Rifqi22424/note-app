import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/notes_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => NotesProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notes App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue,
          selectionColor: Colors.blue.withOpacity(0.4),
          selectionHandleColor: Colors.blue,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(Colors.white),
        ),
        // useMaterial3: false,
        scaffoldBackgroundColor: Color(0xFF1F1F1F),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
        ),
      ),
      home: HomeScreen(),
    );
  }
}

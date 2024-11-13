// lib/models/note.dart
import 'dart:convert';

class ChecklistItem {
  String id;
  String text;
  bool isChecked;

  ChecklistItem({
    String? id,
    required this.text,
    this.isChecked = false,
  }) : this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isChecked': isChecked,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'],
      text: map['text'],
      isChecked: map['isChecked'],
    );
  }
}

enum NoteType { regular, checklist, drawing }

enum NoteStatus { active, archived, deleted }

class Note {
  final String id;
  String title;
  String content;
  List<ChecklistItem> checklistItems;
  String? drawingPath;
  List<String> images;
  NoteType type;
  NoteStatus status;
  String? audioPath;
  DateTime? deletedAt;
  DateTime createdAt;
  DateTime modifiedAt;

  Note({
    String? id,
    this.title = '',
    this.content = '',
    List<ChecklistItem>? checklistItems,
    this.drawingPath,
    List<String>? images,
    this.type = NoteType.regular,
    this.status = NoteStatus.active,
    this.audioPath,
    this.deletedAt,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        this.checklistItems = checklistItems ?? [],
        this.images = images ?? [],
        this.createdAt = createdAt ?? DateTime.now(),
        this.modifiedAt = modifiedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'checklistItems': checklistItems.map((item) => item.toMap()).toList(),
      'drawingPath': drawingPath,
      'images': jsonEncode(images),
      'type': type.index,
      'status': status.index,
      'audioPath': audioPath,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      checklistItems: (map['checklistItems'] as List)
          .map((item) => ChecklistItem.fromMap(item))
          .toList(),
      drawingPath: map['drawingPath'],
      images: List<String>.from(jsonDecode(map['images'])),
      type: NoteType.values[map['type']],
      status: NoteStatus.values[map['status'] ?? 0],
      audioPath: map['audioPath'],
      deletedAt:
          map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      modifiedAt: DateTime.parse(map['modifiedAt']),
    );
  }
}

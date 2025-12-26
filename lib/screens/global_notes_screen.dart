import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';
import '../models/note.dart';

class GlobalNotesScreen extends ConsumerWidget {
  const GlobalNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(globalNotesProvider);

    return Scaffold(
      backgroundColor: Colors.amber.shade50, // Notebook feel
      appBar: AppBar(
        title: const Text("My Notebook", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.amber.shade300,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note, size: 60, color: Colors.brown.shade200),
                  const SizedBox(height: 10),
                  Text("No notes yet.\nTap the Pencil to write!", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.brown.shade300),
                  ),
                ],
              ),
            );
          }
          
          // Simple Grid/List for Notes
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                color: Colors.yellow.shade100,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showNoteDialog(context, ref, note),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.content,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "${note.updatedAt.day}/${note.updatedAt.month}",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.brown)),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, WidgetRef ref, Note? existingNote) {
    final controller = TextEditingController(text: existingNote?.content ?? "");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.yellow.shade50,
        title: const Text("Note"),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(border: InputBorder.none, hintText: "Write something..."),
        ),
        actions: [
          if (existingNote != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.brown),
              onPressed: () {
                ref.read(deleteNoteProvider)(existingNote.id!);
                Navigator.pop(context);
              },
            ),
          TextButton(
            child: const Text("Save", style: TextStyle(color: Colors.brown)),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(saveNoteProvider)(Note(
                  id: existingNote?.id,
                  content: controller.text,
                ));
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
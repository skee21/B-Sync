import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/providers.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/note.dart';
import 'task_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCatId = ref.watch(selectedCategoryProvider);

    ref.listen(selectedCategoryProvider, (previous, next) { 
      categoriesAsync.whenData((cats) {
        final index = cats.indexWhere((c) => c.id == next);
        if (index != -1 && _pageController.hasClients) {
          if (_pageController.page?.round() != index) {
            _pageController.animateToPage(index, duration: 300.ms, curve: Curves.easeOutQuad);
          }
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Mind Tunes")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreationMenu(context, ref),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 500.ms, duration: 300.ms, curve: Curves.elasticOut),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Error: $err")),
          data: (cats) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cats.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      if (i == cats.length) return _AddCategoryChip().animate().fadeIn(delay: 200.ms);
                      final cat = cats[i];
                      final isSelected = cat.id == selectedCatId;
                      return GestureDetector(
                        onLongPress: () {
                          if (cat.id == 1) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inbox cannot be edited.")));
                            return;
                          }
                          _showEditCategoryDialog(context, ref, cat);
                        },
                        child: ChoiceChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          selectedColor: Colors.deepPurple.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.deepPurple : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (bool selected) {
                            if (selected) ref.read(selectedCategoryProvider.notifier).state = cat.id!;
                          },
                        ),
                      ).animate().fadeIn(delay: (50 * i).ms).slideX(begin: -0.2, curve: Curves.easeOut);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: cats.length,
                    onPageChanged: (index) {
                      ref.read(selectedCategoryProvider.notifier).state = cats[index].id!;
                    },
                    itemBuilder: (context, index) => _CategoryListPage(
                      categoryId: cats[index].id!,
                      onNoteTap: (note) => _showNoteDialog(context, ref, existingNote: note),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  //Menus 

  void _showCreationMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CreationButton(icon: Icons.edit, label: "Note", color: Colors.amber, onTap: () { Navigator.pop(context); _showNoteDialog(context, ref); }),
              _CreationButton(icon: Icons.handyman, label: "Task", color: Colors.deepPurple, onTap: () { Navigator.pop(context); showAddTaskSheet(context); }),
            ],
          ),
        ).animate().slideY(begin: 1, duration: 300.ms, curve: Curves.easeOutBack);
      }
    );
  }

  void _showNoteDialog(BuildContext context, WidgetRef ref, {Note? existingNote}) async {
    final titleCtrl = TextEditingController(text: existingNote?.title ?? "");
    final contentCtrl = TextEditingController(text: existingNote?.content ?? "");
    final currentCatId = ref.read(selectedCategoryProvider);
    bool wasDeleted = false; 

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.amber.shade50,
        content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: titleCtrl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black), decoration: const InputDecoration(hintText: "Title", border: InputBorder.none)), const Divider(), TextField(controller: contentCtrl, maxLines: 6, style: const TextStyle(color: Colors.black), decoration: const InputDecoration(hintText: "Note content...", border: InputBorder.none))]),
        actions: [
          if (existingNote != null) IconButton(icon: const Icon(Icons.delete, color: Colors.brown), onPressed: () { ref.read(deleteNoteProvider)(existingNote.id!); wasDeleted = true; Navigator.pop(ctx); }),
          TextButton(child: const Text("Close", style: TextStyle(color: Colors.brown)), onPressed: () => Navigator.pop(ctx))
        ],
      ),
    );

    if (!wasDeleted && (contentCtrl.text.trim().isNotEmpty || titleCtrl.text.trim().isNotEmpty)) {
      ref.read(saveNoteProvider)(Note(id: existingNote?.id, title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), categoryId: existingNote?.categoryId ?? currentCatId));
    }
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, Category cat) {
    final controller = TextEditingController(text: cat.name);
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Edit Playlist"), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: "Playlist Name")), actions: [TextButton(child: const Text("Delete", style: TextStyle(color: Colors.red)), onPressed: () { Navigator.pop(context); showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Delete Playlist?"), content: const Text("All tasks in this playlist will be deleted permanently."), actions: [TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)), TextButton(child: const Text("Delete", style: TextStyle(color: Colors.red)), onPressed: () { ref.read(deleteCategoryProvider)(cat.id!); Navigator.pop(context); })])); }), TextButton(child: const Text("Save"), onPressed: () { if (controller.text.isNotEmpty) { ref.read(updateCategoryProvider)(cat.id!, controller.text.trim()); } Navigator.pop(context); })]));
  }
}

class _CategoryListPage extends ConsumerWidget {
  final int categoryId;
  final Function(Note) onNoteTap;

  const _CategoryListPage({required this.categoryId, required this.onNoteTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(mixedListProvider(categoryId));
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) return Center(child: Text("Empty playlist.", style: TextStyle(color: Colors.grey.shade400))).animate().fadeIn();
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final item = items[i];
            if (item is Task) return _TaskTile(task: item).animate().fadeIn(duration: 400.ms, delay: (50 * i).ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
            if (item is Note) return _NoteTile(note: item, onTap: () => onNoteTap(item)).animate().fadeIn(duration: 400.ms, delay: (50 * i).ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
            return const SizedBox();
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text("Error: $e"),
    );
  }
}

//Widgets

class _CreationButton extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _CreationButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.bold))]),).animate().scale(duration: 200.ms);
  }
}

class _AddCategoryChip extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return ActionChip(label: const Text("New Playlist"), avatar: const Icon(Icons.add, size: 16), onPressed: () { showDialog(context: context, builder: (_) => _AddCategoryDialog()); });
  }
}

class _AddCategoryDialog extends ConsumerWidget { 
  @override Widget build(BuildContext context, WidgetRef ref) { 
    final controller = TextEditingController(); 
    return AlertDialog(title: const Text("Create Playlist"), content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Name"), autofocus: true), actions: [TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)), TextButton(child: const Text("Create"), onPressed: () { if (controller.text.isNotEmpty) { ref.read(addCategoryProvider)(controller.text.trim()); } Navigator.pop(context); })]); } }

class _NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap; 

  const _NoteTile({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade100,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap, // Simply call the callback
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title.isNotEmpty) ...[
                Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                const SizedBox(height: 6),
              ],
              Text(
                note.content, 
                maxLines: 3, 
                overflow: TextOverflow.ellipsis, 
                style: TextStyle(color: Colors.brown.shade800)
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final Task task;
  const _TaskTile({required this.task});

  @override 
  Widget build(BuildContext context, WidgetRef ref) {
    int total = task.milestones.length; int done = task.milestones.where((m) => m.isCompleted).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.deepPurple.shade50;
    final textColor = isDark ? Colors.white : Colors.black;

    return Card(elevation: 0, color: bgColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: InkWell(borderRadius: BorderRadius.circular(12), 
      // LONG PRESS MENU
      onLongPress: () {
        showModalBottomSheet(context: context, builder: (_) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.folder_open), title: const Text("Move Playlist"), onTap: () { Navigator.pop(context); _showMoveDialog(context, ref, task); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text("Delete Task", style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); ref.read(deleteTaskProvider)(task.id!); }),
          ]),
        ));
      },
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(initialTask: task))), 
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.deepPurple)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)), if (total > 0) Padding(padding: const EdgeInsets.only(top: 4), child: Text("$done / $total objectives", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)))])), const Icon(Icons.chevron_right, color: Colors.grey)]))));
  }

  void _showMoveDialog(BuildContext context, WidgetRef ref, Task task) {
    final categoriesAsync = ref.read(categoriesProvider); // Read once
    categoriesAsync.whenData((cats) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text("Move to Playlist"),
        content: SizedBox(width: double.maxFinite, child: ListView.builder(
          shrinkWrap: true,
          itemCount: cats.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(cats[i].name),
            onTap: () {
              ref.read(moveTaskProvider)(task.id!, [cats[i].id!]);
              Navigator.pop(context);
            },
          ),
        )),
      ));
    });
  }
}

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _controller = TextEditingController();
  final Set<int> _selectedCatIds = {};

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("New Track", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "What needs to be done?"),
            autofocus: true,
          ),
          const SizedBox(height: 15),
          const Text("Add to Playlist (Optional):", style: TextStyle(fontSize: 12, color: Colors.grey)),
          categoriesAsync.when(
            data: (cats) => Wrap(
              spacing: 8,
              children: cats.map((cat) {
                final isSelected = _selectedCatIds.contains(cat.id);
                return FilterChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  selectedColor: Colors.deepPurple.shade100,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedCatIds.add(cat.id!);
                      } else {
                        _selectedCatIds.remove(cat.id!);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text("Add to Queue"),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  ref.read(addTaskProvider)(_controller.text.trim(), _selectedCatIds.toList());
                }
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

void showAddTaskSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const AddTaskSheet(),
  );
}

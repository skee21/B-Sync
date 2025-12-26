import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../models/milestone.dart';
import '../models/note.dart';
import '../data/providers.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task initialTask;
  const TaskDetailScreen({super.key, required this.initialTask});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  Timer? _uiTicker;

  @override
  void initState() {
    super.initState();
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    super.dispose();
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskProvider(widget.initialTask.id!));
    final task = taskAsync.value ?? widget.initialTask;

    int total = task.milestones.length;
    int done = task.milestones.where((m) => m.isCompleted).length;
    double progress = total == 0 ? 0 : done / total;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    bool isTimerRunning = task.timerEndTime != null && task.timerEndTime! > DateTime.now().millisecondsSinceEpoch;
    String timerText = "";
    if (isTimerRunning) {
      int remaining = task.timerEndTime! - DateTime.now().millisecondsSinceEpoch;
      timerText = _formatDuration(remaining);
    } else if (task.timerEndTime != null) {
      timerText = "Done!";
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Now Playing"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sticky_note_2_outlined),
            tooltip: "Track Notes",
            onPressed: () => _openNote(context, ref, taskId: task.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDeleteTask(context, ref, task.id!),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
                    image: task.imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(task.imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: task.imagePath == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_note, size: 80, color: Colors.white70),
                              const SizedBox(height: 10),
                              Text(
                                task.title,
                                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                              ).animate().fadeIn().moveY(begin: 10, end: 0),
                            ],
                          ),
                        )
                      : null,
                ),

                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                      onPressed: () => _showTaskSettings(context, ref, task),
                    ),
                  ),
                ),
                
                if (task.imagePath != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                      ),
                      child: Text(
                        task.title,
                        style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ActionChip(
                    avatar: Icon(Icons.calendar_today, size: 16, color: task.dueDate != null ? Colors.deepPurple : Colors.black54),
                    label: Text(
                      task.dueDate == null 
                        ? "Set Deadline" 
                        : "Edit: ${DateFormat('MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(task.dueDate!))}",
                      style: TextStyle(
                        color: task.dueDate != null ? Colors.deepPurple : Colors.black,
                        fontWeight: task.dueDate != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    backgroundColor: task.dueDate != null ? Colors.deepPurple.shade50 : null,
                    side: task.dueDate != null ? const BorderSide(color: Colors.deepPurple) : null,
                    onPressed: () => _pickDueDate(context, ref, task),
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: ActionChip(
                    avatar: Icon(
                      isTimerRunning ? Icons.timer : Icons.timer_outlined, 
                      color: isTimerRunning ? Colors.deepPurple : Colors.black54,
                    ),
                    label: Text(
                      isTimerRunning ? timerText : "Start Timer",
                      style: TextStyle(
                        color: isTimerRunning ? Colors.deepPurple : Colors.black,
                        fontWeight: isTimerRunning ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    backgroundColor: isTimerRunning ? Colors.deepPurple.shade50 : null,
                    side: isTimerRunning ? const BorderSide(color: Colors.deepPurple) : null,
                    onPressed: () => _showTimerDialog(context, ref, task),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              color: Colors.deepPurpleAccent,
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "$done / $total Objectives Complete",
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey : Colors.grey.shade600),
              ),
            ),

            const Divider(height: 20),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: task.milestones.length + 1,
              itemBuilder: (context, index) {
                if (index == task.milestones.length) {
                   return ListTile(
                     key: const ValueKey("ADD_BTN"),
                     leading: const Icon(Icons.add, color: Colors.deepPurple),
                     title: Text("Add Objective...", style: TextStyle(color: textColor)),
                     onTap: () => _showAddMilestoneDialog(context, ref, task.id!),
                   );
                }

                final m = task.milestones[index];
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: m.isCompleted ? Colors.amber.withOpacity(0.15) : cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]
                  ),
                  child: CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    
                    title: AnimatedDefaultTextStyle(
                      duration: 300.ms,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: m.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: Colors.grey,
                        color: m.isCompleted ? Colors.grey : textColor,
                      ),
                      child: Text(m.text),
                    ),
                    
                    value: m.isCompleted,
                    onChanged: (_) => ref.read(toggleMilestoneProvider)(m.id!, m.isCompleted),
                    secondary: IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () => ref.read(deleteMilestoneProvider)(m.id!),
                    ),
                  ),
                )
                .animate(key: ValueKey(m.id), target: m.isCompleted ? 1 : 0)
                .shimmer(duration: 400.ms, color: Colors.amber)
                .then(); 
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate(BuildContext context, WidgetRef ref, Task task) async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    ref.read(updateTaskProvider)(task.copyWith(dueDate: deadline.millisecondsSinceEpoch));
  }

  void _showTimerDialog(BuildContext context, WidgetRef ref, Task task) {
    double minutes = 30;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Focus Timer", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  if (task.timerEndTime != null && task.timerEndTime! > DateTime.now().millisecondsSinceEpoch)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text("Stop Timer"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                      onPressed: () {
                        ref.read(updateTaskProvider)(task.copyWith(clearTimer: true)); 
                        Navigator.pop(context);
                      },
                    )
                  else
                    Column(
                      children: [
                        Text("${minutes.toInt()} minutes", style: const TextStyle(fontSize: 24, color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                        Slider(value: minutes, min: 5, max: 120, divisions: 23, activeColor: Colors.deepPurple, label: "${minutes.toInt()}m", onChanged: (val) { setModalState(() => minutes = val); }),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                          child: const Text("Start Focus Session"),
                          onPressed: () {
                            final endTime = DateTime.now().add(Duration(minutes: minutes.toInt()));
                            ref.read(updateTaskProvider)(task.copyWith(timerEndTime: endTime.millisecondsSinceEpoch));
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTaskSettings(BuildContext context, WidgetRef ref, Task task) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Change Cover Image"),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  ref.read(updateTaskProvider)(task.copyWith(imagePath: image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Rename Track"),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, task);
              },
            ),
            // NEW OPTION: MOVE
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text("Move to Playlist"),
              onTap: () {
                Navigator.pop(context);
                _showMoveDialog(context, ref, task);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveDialog(BuildContext context, WidgetRef ref, Task task) {
    final categoriesAsync = ref.read(categoriesProvider);
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

  void _showRenameDialog(BuildContext context, WidgetRef ref, Task task) {
    final controller = TextEditingController(text: task.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(updateTaskProvider)(task.copyWith(title: controller.text.trim()));
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void _openNote(BuildContext context, WidgetRef ref, {required int? taskId}) async {
    Note? existingNote = await ref.read(noteForTaskProvider(taskId!).future);
    final titleCtrl = TextEditingController(text: existingNote?.title ?? "");
    final contentCtrl = TextEditingController(text: existingNote?.content ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Track Notes"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(hintText: "Title", border: InputBorder.none),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextField(
              controller: contentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(hintText: "Details...", border: InputBorder.none),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Save"),
            onPressed: () {
              if (contentCtrl.text.isNotEmpty || titleCtrl.text.isNotEmpty) {
                final newNote = Note(
                  id: existingNote?.id,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  taskId: taskId,
                );
                ref.read(saveNoteProvider)(newNote);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context, WidgetRef ref, int taskId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Objective"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(addMilestoneProvider)(Milestone(taskId: taskId, text: controller.text));
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, WidgetRef ref, int taskId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Track?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              ref.read(deleteTaskProvider)(taskId);
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
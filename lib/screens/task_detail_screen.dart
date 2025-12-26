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
    final colorScheme = Theme.of(context).colorScheme;

    int total = task.milestones.length;
    int done = task.milestones.where((m) => m.isCompleted).length;
    double progress = total == 0 ? 0 : done / total;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = colorScheme.surfaceContainerHighest;
    final textColor = colorScheme.onSurface;

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
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(blurRadius: 10, color: colorScheme.shadow.withOpacity(0.3))],
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
                              Icon(Icons.music_note, size: 80, color: colorScheme.onPrimary.withOpacity(0.7)),
                              const SizedBox(height: 10),
                              Text(
                                task.title,
                                style: TextStyle(fontSize: 28, color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
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
                    avatar: Icon(Icons.calendar_today, size: 16, color: task.dueDate != null ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5)),
                    label: Text(
                      task.dueDate == null 
                        ? "Set Deadline" 
                        : "Edit: ${DateFormat('MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(task.dueDate!))}",
                      style: TextStyle(
                        color: task.dueDate != null ? colorScheme.primary : textColor,
                        fontWeight: task.dueDate != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    backgroundColor: task.dueDate != null ? colorScheme.primaryContainer : null,
                    side: task.dueDate != null ? BorderSide(color: colorScheme.primary) : null,
                    onPressed: () => _pickDueDate(context, ref, task),
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: ActionChip(
                    avatar: Icon(
                      isTimerRunning ? Icons.timer : Icons.timer_outlined, 
                      color: isTimerRunning ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                    ),
                    label: Text(
                      isTimerRunning ? timerText : "Start Timer",
                      style: TextStyle(
                        color: isTimerRunning ? colorScheme.primary : textColor,
                        fontWeight: isTimerRunning ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    backgroundColor: isTimerRunning ? colorScheme.primaryContainer : null,
                    side: isTimerRunning ? BorderSide(color: colorScheme.primary) : null,
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
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "$done / $total Objectives Complete",
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface.withOpacity(0.6)),
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
                     leading: Icon(Icons.add, color: colorScheme.primary),
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
                    boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 2)]
                  ),
                  child: CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    
                    title: AnimatedDefaultTextStyle(
                      duration: 300.ms,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: m.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationColor: colorScheme.onSurface.withOpacity(0.5),
                        color: m.isCompleted ? colorScheme.onSurface.withOpacity(0.5) : textColor,
                      ),
                      child: Text(m.text),
                    ),
                    
                    value: m.isCompleted,
                    onChanged: (_) => ref.read(toggleMilestoneProvider)(m.id!, m.isCompleted),
                    secondary: IconButton(
                      icon: Icon(Icons.close, size: 18, color: colorScheme.onSurface.withOpacity(0.4)),
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
    final colorScheme = Theme.of(context).colorScheme;
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
                        Text("${minutes.toInt()} minutes", style: TextStyle(fontSize: 24, color: colorScheme.primary, fontWeight: FontWeight.bold)),
                        Slider(value: minutes, min: 5, max: 120, divisions: 23, activeColor: colorScheme.primary, label: "${minutes.toInt()}m", onChanged: (val) { setModalState(() => minutes = val); }),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
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
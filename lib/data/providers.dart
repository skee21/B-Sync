import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/milestone.dart';
import '../models/note.dart';
import '../services/notification_service.dart';
import 'local_db.dart';

final dbProvider = Provider<LocalDB>((ref) => LocalDB.instance);

final taskTrigger = StateProvider<int>((ref) => 0);
final categoryTrigger = StateProvider<int>((ref) => 0);
final selectedCategoryProvider = StateProvider<int>((ref) => 1);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(categoryTrigger); 
  return ref.read(dbProvider).getAllCategories();
});

final mixedListProvider = FutureProvider.family<List<dynamic>, int>((ref, categoryId) async {
  ref.watch(taskTrigger); 
  final db = ref.read(dbProvider);
  final tasks = await db.getTasksByCategory(categoryId);
  final notes = await db.getGlobalNotesByCategory(categoryId);
  List<dynamic> combined = [...tasks, ...notes];
  combined.sort((a, b) {
    int idA = a.id ?? 0;
    int idB = b.id ?? 0;
    return idB.compareTo(idA); 
  });
  return combined;
});

final taskProvider = FutureProvider.family<Task?, int>((ref, taskId) async {
  ref.watch(taskTrigger);
  return ref.read(dbProvider).getTask(taskId);
});

final saveNoteProvider = Provider((ref) {
  return (Note note) async {
    await ref.read(dbProvider).saveNote(note);
    ref.read(taskTrigger.notifier).state++;
  };
});

final deleteNoteProvider = Provider((ref) {
  return (int id) async {
    await ref.read(dbProvider).deleteNote(id);
    ref.read(taskTrigger.notifier).state++;
  };
});

final noteForTaskProvider = FutureProvider.family<Note?, int>((ref, taskId) async {
  ref.watch(taskTrigger); 
  return ref.read(dbProvider).getNoteForTarget(taskId: taskId);
});

final addTaskProvider = Provider((ref) {
  return (String title, List<int> catIds) async {
    await ref.read(dbProvider).addTask(Task(title: title), catIds);
    ref.read(taskTrigger.notifier).state++; 
  };
});

final deleteTaskProvider = Provider((ref) {
  return (int taskId) async {
    await ref.read(dbProvider).deleteTask(taskId);
    ref.read(taskTrigger.notifier).state++;
  };
});

final updateTaskProvider = Provider((ref) {
  return (Task t) async {
    await ref.read(dbProvider).updateTaskDetails(t);
    
    final notif = NotificationService();
    
    if (t.dueDate != null) {
      final deadline = DateTime.fromMillisecondsSinceEpoch(t.dueDate!);
      await notif.scheduleNotification(1000 + t.id!, "Deadline Reached", "${t.title} is due.", deadline);
      
      final warningTime = deadline.subtract(const Duration(hours: 6));
      if (warningTime.isAfter(DateTime.now())) {
         await notif.scheduleNotification(3000 + t.id!, "Upcoming Deadline", "${t.title} is due in 6 hours.", warningTime);
      }
    } else {
      await notif.cancelNotification(1000 + t.id!);
      await notif.cancelNotification(3000 + t.id!);
    }

    if (t.timerEndTime != null) {
      await notif.showOngoingNotification(
        2000 + t.id!, 
        "Focus Session Active", 
        "Working on ${t.title}..."
      );
      
      await notif.scheduleNotification(
        2100 + t.id!,
        "Timer Finished",
        "${t.title} session is complete.",
        DateTime.fromMillisecondsSinceEpoch(t.timerEndTime!)
      );
    } else {
      await notif.cancelNotification(2000 + t.id!);
      await notif.cancelNotification(2100 + t.id!);
    }

    ref.read(taskTrigger.notifier).state++;
  };
});

final moveTaskProvider = Provider((ref) {
  return (int taskId, List<int> newCatIds) async {
    await ref.read(dbProvider).updateTaskCategory(taskId, newCatIds);
    ref.read(taskTrigger.notifier).state++;
  };
});

final addMilestoneProvider = Provider((ref) {
  return (Milestone m) async {
    await ref.read(dbProvider).addMilestone(m);
    ref.read(taskTrigger.notifier).state++;
  };
});

final toggleMilestoneProvider = Provider((ref) {
  return (int id, bool current) async {
    await ref.read(dbProvider).toggleMilestone(id, current);
    ref.read(taskTrigger.notifier).state++;
  };
});

final deleteMilestoneProvider = Provider((ref) {
  return (int id) async {
    await ref.read(dbProvider).deleteMilestone(id);
    ref.read(taskTrigger.notifier).state++;
  };
});

final reorderMilestoneProvider = Provider((ref) {
  return (List<Milestone> m) async {
    await ref.read(dbProvider).reorderMilestones(m);
    ref.read(taskTrigger.notifier).state++;
  };
});

final addCategoryProvider = Provider((ref) {
  return (String name) async {
    await ref.read(dbProvider).addCategory(name);
    ref.read(categoryTrigger.notifier).state++;
  };
});

final updateCategoryProvider = Provider((ref) {
  return (int id, String name) async {
    await ref.read(dbProvider).updateCategory(id, name);
    ref.read(categoryTrigger.notifier).state++;
  };
});

final deleteCategoryProvider = Provider((ref) {
  return (int id) async {
    await ref.read(dbProvider).deleteCategory(id);
    ref.read(selectedCategoryProvider.notifier).state = 1; 
    ref.read(categoryTrigger.notifier).state++;
  };
});
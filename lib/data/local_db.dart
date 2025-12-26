import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/milestone.dart';
import '../models/note.dart';

class LocalDB {
  static final LocalDB instance = LocalDB._init();
  static Database? _database;

  LocalDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mind_tunes_v7.db'); 
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path, 
      version: 1, 
      onConfigure: _onConfigure,
      onCreate: _createDB
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');

    await db.execute('''
    CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      dueDate INTEGER,
      isCompleted INTEGER NOT NULL,
      imagePath TEXT,
      timerEndTime INTEGER 
    )
    ''');

    await db.execute('''
    CREATE TABLE task_categories (
      taskId INTEGER NOT NULL,
      categoryId INTEGER NOT NULL,
      PRIMARY KEY (taskId, categoryId),
      FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE,
      FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE milestones (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      taskId INTEGER NOT NULL,
      text TEXT NOT NULL,
      isCompleted INTEGER NOT NULL,
      sortOrder INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL, 
      content TEXT NOT NULL,
      categoryId INTEGER,
      taskId INTEGER,
      milestoneId INTEGER,
      updatedAt INTEGER NOT NULL,
      FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE,
      FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE,
      FOREIGN KEY (milestoneId) REFERENCES milestones (id) ON DELETE CASCADE
    )
    ''');

    await db.insert('categories', {'name': 'Inbox'});
    await db.insert('categories', {'name': 'Code'});
    await db.insert('categories', {'name': 'Creative'});
  }

  Future<Task?> getTask(int id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    
    if (maps.isNotEmpty) {
      final milestoneData = await db.query('milestones', where: 'taskId = ?', whereArgs: [id], orderBy: 'sortOrder ASC');
      return Task.fromMap(maps.first, milestones: milestoneData.map((m) => Milestone.fromMap(m)).toList());
    }
    return null;
  }

  Future<void> updateTaskDetails(Task task) async {
    final db = await database;
    await db.update(
      'tasks', 
      {
        'title': task.title, 
        'imagePath': task.imagePath,
        'dueDate': task.dueDate,
        'timerEndTime': task.timerEndTime
      },
      where: 'id = ?',
      whereArgs: [task.id]
    );
  }
  
  Future<void> updateTaskCategory(int taskId, List<int> newCategoryIds) async {
    final db = await database;
    await db.delete('task_categories', where: 'taskId = ?', whereArgs: [taskId]);
    
    final catsToLink = newCategoryIds.isEmpty ? [1] : newCategoryIds;
    for (int catId in catsToLink) {
      await db.insert('task_categories', {'taskId': taskId, 'categoryId': catId});
    }
  }

  Future<int> addCategory(String name) async => (await database).insert('categories', {'name': name});
  Future<List<Category>> getAllCategories() async => (await (await database).query('categories')).map((c) => Category.fromMap(c)).toList();
  
  Future<int> addTask(Task task, List<int> categoryIds) async {
    final db = await database;
    final taskId = await db.insert('tasks', task.toMap());
    final catsToLink = categoryIds.isEmpty ? [1] : categoryIds;
    for (int catId in catsToLink) await db.insert('task_categories', {'taskId': taskId, 'categoryId': catId});
    return taskId;
  }

  Future<List<Task>> getTasksByCategory(int categoryId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT t.* FROM tasks t
      INNER JOIN task_categories tc ON t.id = tc.taskId
      WHERE tc.categoryId = ?
      ORDER BY t.isCompleted ASC, t.id DESC
    ''', [categoryId]);
    List<Task> tasks = [];
    for (var row in result) {
      final taskId = row['id'] as int;
      final milestoneData = await db.query('milestones', where: 'taskId = ?', whereArgs: [taskId], orderBy: 'sortOrder ASC');
      tasks.add(Task.fromMap(row, milestones: milestoneData.map((m) => Milestone.fromMap(m)).toList()));
    }
    return tasks;
  }

  Future<List<Note>> getGlobalNotesByCategory(int categoryId) async {
    final db = await database;
    final res = await db.query('notes', where: 'categoryId = ? AND taskId IS NULL AND milestoneId IS NULL', whereArgs: [categoryId], orderBy: 'updatedAt DESC');
    return res.map((n) => Note.fromMap(n)).toList();
  }

  Future<void> saveNote(Note note) async {
    final db = await database;
    if (note.id != null) { await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]); return; }
    if (note.taskId != null || note.milestoneId != null) {
      String where = note.taskId != null ? 'taskId = ?' : 'milestoneId = ?';
      int arg = note.taskId ?? note.milestoneId!;
      final existing = await db.query('notes', where: where, whereArgs: [arg]);
      if (existing.isNotEmpty) { await db.update('notes', {'title': note.title, 'content': note.content, 'updatedAt': DateTime.now().millisecondsSinceEpoch}, where: where, whereArgs: [arg]); } 
      else { await db.insert('notes', note.toMap()); }
    } else { await db.insert('notes', note.toMap()); }
  }

  Future<Note?> getNoteForTarget({int? taskId, int? milestoneId}) async {
    final db = await database;
    String where = taskId != null ? 'taskId = ?' : 'milestoneId = ?';
    int arg = taskId ?? milestoneId!;
    final res = await db.query('notes', where: where, whereArgs: [arg], limit: 1);
    if (res.isNotEmpty) return Note.fromMap(res.first);
    return null;
  }

  Future<void> deleteNote(int id) async => (await database).delete('notes', where: 'id = ?', whereArgs: [id]);
  Future<void> deleteTask(int id) async => (await database).delete('tasks', where: 'id = ?', whereArgs: [id]);
  
  Future<void> addMilestone(Milestone m) async {
     final db = await database;
    final res = await db.rawQuery('SELECT MAX(sortOrder) as maxOrder FROM milestones WHERE taskId = ?', [m.taskId]);
    int nextOrder = (res.first['maxOrder'] as int? ?? 0) + 1;
    await db.insert('milestones', {...m.toMap(), 'sortOrder': nextOrder});
  }
  
  Future<void> toggleMilestone(int id, bool c) async => (await database).update('milestones', {'isCompleted': c ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
  Future<void> deleteMilestone(int id) async => (await database).delete('milestones', where: 'id = ?', whereArgs: [id]);
  
  Future<void> reorderMilestones(List<Milestone> ms) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < ms.length; i++) batch.update('milestones', {'sortOrder': i}, where: 'id = ?', whereArgs: [ms[i].id]);
    await batch.commit(noResult: true);
  }

  Future<void> updateCategory(int id, String name) async => (await database).update('categories', {'name': name}, where: 'id = ?', whereArgs: [id]);
  Future<void> deleteCategory(int id) async => (await database).delete('categories', where: 'id = ?', whereArgs: [id]);
}
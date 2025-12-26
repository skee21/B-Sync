import 'milestone.dart';

class Task {
  final int? id;
  final String title;
  final String? description;
  final int? dueDate; 
  final bool isCompleted;
  final String? imagePath;
  final int? timerEndTime;
  
  final List<Milestone> milestones; 
  final List<int> categoryIds; 

  Task({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    this.imagePath,
    this.timerEndTime,
    this.milestones = const [],
    this.categoryIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'isCompleted': isCompleted ? 1 : 0,
      'imagePath': imagePath,
      'timerEndTime': timerEndTime,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, {List<Milestone>? milestones, List<int>? catIds}) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'],
      isCompleted: map['isCompleted'] == 1,
      imagePath: map['imagePath'],
      timerEndTime: map['timerEndTime'],
      milestones: milestones ?? [],
      categoryIds: catIds ?? [],
    );
  }

  Task copyWith({
    String? title, 
    String? imagePath, 
    int? dueDate, 
    int? timerEndTime, 
    bool clearTimer = false 
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted,
      imagePath: imagePath ?? this.imagePath,
      timerEndTime: clearTimer ? null : (timerEndTime ?? this.timerEndTime),
      milestones: milestones,
      categoryIds: categoryIds,
    );
  }
}
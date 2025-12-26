class Milestone {
  final int? id;
  final int taskId;
  final String text;
  final bool isCompleted;

  Milestone({
    this.id,
    required this.taskId,
    required this.text,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'text': text,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      id: map['id'],
      taskId: map['taskId'],
      text: map['text'],
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
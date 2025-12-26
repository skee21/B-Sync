class Note {
  final int? id;
  final String content;
  final String title;
  final int? categoryId;  
  final int? taskId;      
  final int? milestoneId; 
  final DateTime updatedAt;

  Note({
    this.id,
    this.title = "",
    required this.content,
    this.categoryId,
    this.taskId,
    this.milestoneId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'categoryId': categoryId,
      'taskId': taskId,
      'milestoneId': milestoneId,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'] ?? "",
      content: map['content'],
      categoryId: map['categoryId'],
      taskId: map['taskId'],
      milestoneId: map['milestoneId'],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
}
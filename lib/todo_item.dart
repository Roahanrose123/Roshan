class TodoItem {
  String task;
  DateTime dueDate;
  bool isCompleted;

  TodoItem({
    required this.task,
    required this.dueDate,
    this.isCompleted = false,
  });

  // Convert TodoItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  // Create TodoItem from JSON
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      task: json['task'],
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'],
    );
  }
}
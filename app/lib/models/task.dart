class Task {
  final String id;
  final String title;
  final String description;
  final String taskType;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      taskType: json['task_type'] ?? 'image',
    );
  }
}

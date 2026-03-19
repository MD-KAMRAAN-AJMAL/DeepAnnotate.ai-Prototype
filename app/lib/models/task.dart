class Task {
  final String id;
  final String title;
  final String description;
  final String taskType;
  final String taskDifficulty;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    required this.taskDifficulty,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      taskType: json['task_type'] ?? 'image',
      taskDifficulty: json['task_difficulty'] ?? '',
    );
  }
}

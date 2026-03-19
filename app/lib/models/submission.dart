class Submission {
  final String id;
  final String taskId;
  final String? taskTitle;
  final String fileUrl;
  final DateTime? createdAt;

  Submission({
    required this.id,
    required this.taskId,
    this.taskTitle,
    required this.fileUrl,
    this.createdAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'],
      taskId: json['task_id'],
      taskTitle: json['task_title'],
      fileUrl: json['file_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'task_title': taskTitle,
      'file_url': fileUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

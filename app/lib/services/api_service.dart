import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../models/task.dart';
import '../models/submission.dart';

class ApiService {
  static final _dio = Dio();

  static String get baseUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:4300' : 'http://localhost:4300';

  static Future<List<Task>> fetchTasks() async {
    try {
      final response = await _dio.get('$baseUrl/tasks');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  static Future<bool> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post(
        '$baseUrl/task',
        data: taskData,
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error creating task: $e');
      return false;
    }
  }

  static Future<List<Submission>> fetchSubmissions() async {
    try {
      final response = await _dio.get('$baseUrl/submissions');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => Submission.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load submissions');
      }
    } catch (e) {
      print('Error fetching submissions: $e');
      return [];
    }
  }

  static Future<bool> uploadSubmission({
    required String taskId,
    required File file,
    Function(double)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'task_id': taskId,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: path.basename(file.path),
        ),
      });

      final response = await _dio.post(
        '$baseUrl/submission',
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1) {
            final progress = sent / total;
            if (onProgress != null) {
              onProgress(progress.clamp(0.0, 1.0));
            }
          } else {
            print('Upload Progress: Total size unknown ($sent bytes sent)');
          }
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error uploading: $e');
      return false;
    }
  }
}

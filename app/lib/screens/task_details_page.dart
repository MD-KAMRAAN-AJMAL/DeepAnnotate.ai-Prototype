import 'package:app/screens/upload_status_page.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/task.dart';

class TaskDetailsPage extends StatefulWidget {
  final Task task;

  const TaskDetailsPage({super.key, required this.task});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailsPage> {
  File? selectedFile;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool isRecording = false;
  bool _isPickerActive = false;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  void captureMedia() async {
    if (_isPickerActive) return;

    if (widget.task.taskType == "audio") {
      handleAudioCapture();
      return;
    }

    setState(() => _isPickerActive = true);

    try {
      XFile? file;
      if (widget.task.taskType == "video") {
        file = await _picker.pickVideo(source: ImageSource.camera);
      } else if (widget.task.taskType == "image") {
        file = await _picker.pickImage(source: ImageSource.camera);
      }

      if (file != null) {
        setState(() {
          selectedFile = File(file!.path);
        });
      }
    } finally {
      setState(() => _isPickerActive = false);
    }
  }

  void handleAudioCapture() async {
    if (isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        isRecording = false;
        if (path != null) {
          selectedFile = File(path);
        }
      });
    } else {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final String path = p.join(
          directory.path,
          'recording_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );

        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          isRecording = true;
          selectedFile = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission denied")),
        );
      }
    }
  }

  void uploadMedia() async {
    if (_isPickerActive) return;

    setState(() => _isPickerActive = true);

    try {
      if (widget.task.taskType == 'audio') {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
        );
        if (result != null) {
          setState(() {
            selectedFile = File(result.files.single.path!);
          });
        }
      } else {
        XFile? file;
        if (widget.task.taskType == 'video') {
          file = await _picker.pickVideo(source: ImageSource.gallery);
        } else {
          file = await _picker.pickImage(source: ImageSource.gallery);
        }

        if (file != null) {
          setState(() {
            selectedFile = File(file!.path);
          });
        }
      }
    } finally {
      setState(() => _isPickerActive = false);
    }
  }

  void submitTask() {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or capture a file")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UploadStatusPage(taskId: widget.task.id, file: selectedFile!),
      ),
    );
  }

  IconData getTaskIcon() {
    switch (widget.task.taskType) {
      case "video":
        return Icons.videocam;
      case "audio":
        return Icons.mic;
      case "image":
        return Icons.image;
      default:
        return Icons.task;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(widget.task.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(getTaskIcon(), size: 28),
                const SizedBox(width: 10),
                Text(
                  widget.task.taskType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isRecording)
              const Row(
                children: [
                  Icon(Icons.circle, color: Colors.red, size: 12),
                  SizedBox(width: 8),
                  Text(
                    "Recording...",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else if (selectedFile != null)
              Text(
                "Selected: ${p.basename(selectedFile!.path)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPickerActive ? null : captureMedia,
                icon: Icon(
                  isRecording
                      ? Icons.stop
                      : (widget.task.taskType == "audio"
                            ? Icons.mic
                            : Icons.camera_alt),
                ),
                label: Text(
                  isRecording
                      ? "Stop Recording"
                      : (widget.task.taskType == "audio"
                            ? "Record Audio"
                            : "Capture"),
                ),
                style: isRecording
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isRecording || _isPickerActive) ? null : uploadMedia,
                icon: const Icon(Icons.upload),
                label: const Text("Upload from Gallery"),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isRecording || _isPickerActive) ? null : submitTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

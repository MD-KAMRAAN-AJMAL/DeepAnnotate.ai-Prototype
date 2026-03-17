import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class UploadStatusPage extends StatefulWidget {
  final String taskId;
  final File file;

  const UploadStatusPage({super.key, required this.taskId, required this.file});

  @override
  State<UploadStatusPage> createState() => _UploadStatusPageState();
}

class _UploadStatusPageState extends State<UploadStatusPage> {
  bool _isUploading = true;
  bool _isSuccess = false;
  String? _errorMessage;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    final success = await ApiService.uploadSubmission(
      taskId: widget.taskId,
      file: widget.file,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _uploadProgress = progress;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isUploading = false;
        _isSuccess = success;
        if (!success) {
          _errorMessage = "Failed to upload file. Please try again.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Status")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isUploading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Uploading... ${(_uploadProgress * 100).toInt()}%",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.file.path.split('/').last,
                  style: const TextStyle(color: Colors.grey),
                ),
              ] else if (_isSuccess) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 24),
                const Text(
                  "Upload Complete",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Submission sent successfully",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text("Back to Task List"),
                ),
              ] else ...[
                const Icon(Icons.error, color: Colors.red, size: 80),
                const SizedBox(height: 24),
                const Text(
                  "Upload Failed",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? "Something went wrong",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isUploading = true;
                      _isSuccess = false;
                      _errorMessage = null;
                    });
                    _startUpload();
                  },
                  child: const Text("Retry"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

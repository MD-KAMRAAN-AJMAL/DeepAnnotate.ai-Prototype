import 'package:flutter/material.dart';
import '../models/submission.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SubmissionsPage extends StatefulWidget {
  const SubmissionsPage({super.key});

  @override
  State<SubmissionsPage> createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  late Future<List<Submission>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _submissionsFuture = ApiService.fetchSubmissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Submissions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Submission>>(
        future: _submissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final submissions = snapshot.data ?? [];

          if (submissions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: Color(0xFF64748B)),
                  const SizedBox(height: 16),
                  Text(
                    'No submissions found.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              return _buildSubmissionCard(submission);
            },
          );
        },
      ),
    );
  }

  Widget _buildSubmissionCard(Submission submission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.taskTitle ?? 'Unknown Task',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(submission.createdAt),
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _launchURL(submission.fileUrl),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('View Original File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(Submission submission) {
    final fileUrl = submission.fileUrl;
    final isImage =
        fileUrl.toLowerCase().contains('.jpg') ||
        fileUrl.toLowerCase().contains('.jpeg') ||
        fileUrl.toLowerCase().contains('.png') ||
        fileUrl.toLowerCase().contains('.webp');

    if (isImage) {
      return Image.network(
        fileUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackIcon(Icons.broken_image_rounded),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    if (fileUrl.toLowerCase().contains('.mp4') ||
        fileUrl.toLowerCase().contains('.mov')) {
      return _buildFallbackIcon(
        Icons.video_collection_rounded,
        color: Colors.amber.shade400,
      );
    }

    if (fileUrl.toLowerCase().contains('.mp3') ||
        fileUrl.toLowerCase().contains('.wav') ||
        fileUrl.toLowerCase().contains('.m4a')) {
      return _buildFallbackIcon(
        Icons.audiotrack_rounded,
        color: Colors.cyan.shade400,
      );
    }

    return _buildFallbackIcon(Icons.insert_drive_file_rounded);
  }

  Widget _buildFallbackIcon(
    IconData icon, {
    Color color = Colors.indigoAccent,
  }) {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.black26,
      child: Center(child: Icon(icon, size: 48, color: color.withOpacity(0.5))),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Application not found to open this file.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('Could not open file: $e')));
      }
    }
  }
}

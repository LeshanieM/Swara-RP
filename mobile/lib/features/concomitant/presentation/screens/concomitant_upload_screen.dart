import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class ConcomitantUploadScreen extends StatefulWidget {
  final String childId;
  const ConcomitantUploadScreen({super.key, required this.childId});

  @override
  State<ConcomitantUploadScreen> createState() => _ConcomitantUploadScreenState();
}

class _ConcomitantUploadScreenState extends State<ConcomitantUploadScreen> {
  bool _hasSelectedVideo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              const Text(
                'Physical Behavior Analysis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDeep,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'ශාරීරික හැසිරීම් විශ්ලේෂණය',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload a speech video to analyze physical behaviors during speaking.',
                style: TextStyle(fontSize: 14, color: AppColors.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'කථනය අතරතුර සිදුවන ශාරීරික හැසිරීම් විශ්ලේෂණය කිරීමට වීඩියෝවක් එක් කරන්න.',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Upload Area
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasSelectedVideo = true;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _hasSelectedVideo ? AppColors.primary : AppColors.divider,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _hasSelectedVideo ? _buildVideoSelectedState() : _buildEmptyUploadState(),
                ),
              ),

              const SizedBox(height: 40),

              if (_hasSelectedVideo)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/c2/ready');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Start Analysis',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'විශ්ලේෂණය ආරම්භ කරන්න',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyUploadState() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryWash,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          'Upload Speech Video',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const Text(
          'වීඩියෝව එක් කරන්න',
          style: TextStyle(fontSize: 14, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        const Text(
          'Supported formats:\nMP4, MOV, WebM',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('වීඩියෝව තෝරන්න', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSelectedState() {
    return Column(
      children: [
        // Mock Video Thumbnail
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage('assets/images/common/user_pic.jpg'), // Mock
              fit: BoxFit.cover,
              opacity: 0.6,
            ),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('child_speech_sample_01.mp4', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text), overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4),
                  Text('14 MB • 01:42', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _hasSelectedVideo = false;
            });
          },
          icon: const Icon(Icons.change_circle_rounded, color: AppColors.error),
          label: const Text('Change Video / වෙනස් කරන්න', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}

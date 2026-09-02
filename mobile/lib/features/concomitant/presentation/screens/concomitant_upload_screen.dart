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
  int _selectedOption = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Soft lavender
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDeep),
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
                'Upload a Video',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'වීඩියෝවක් එක් කරන්න',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pick a video where you are speaking! 🌟',
                style: TextStyle(fontSize: 15, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'ඔබ කතා කරන වීඩියෝවක් තෝරන්න! 🌟',
                style: TextStyle(fontSize: 13, color: AppColors.mutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Input Selector Tabs
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedOption = 0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _selectedOption == 0 ? Colors.white : AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _selectedOption == 0 ? AppColors.primary : Colors.transparent, width: 2),
                          boxShadow: _selectedOption == 0 ? [
                            BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ] : [],
                        ),
                        child: Column(
                          children: [
                            Text('🎤 Option A', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedOption == 0 ? AppColors.primary : AppColors.textLight)),
                            const SizedBox(height: 2),
                            Text('Use Comp 1 Recording', style: TextStyle(fontSize: 11, color: _selectedOption == 0 ? AppColors.primaryDeep : AppColors.textLight)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedOption = 1),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _selectedOption == 1 ? Colors.white : AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _selectedOption == 1 ? AppColors.primary : Colors.transparent, width: 2),
                          boxShadow: _selectedOption == 1 ? [
                            BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ] : [],
                        ),
                        child: Column(
                          children: [
                            Text('📁 Option B', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedOption == 1 ? AppColors.primary : AppColors.textLight)),
                            const SizedBox(height: 2),
                            Text('Upload Video File', style: TextStyle(fontSize: 11, color: _selectedOption == 1 ? AppColors.primaryDeep : AppColors.textLight)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_selectedOption == 0) _buildComponent1VideoState() else _buildUploadVideoState(),

              const SizedBox(height: 40),

              if (_selectedOption == 0 || (_selectedOption == 1 && _hasSelectedVideo))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/c2/ready');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, // Soft lavender primary
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 2,
                      shadowColor: AppColors.primary,
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Start Activity',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ක්‍රියාකාරකම ආරම්භ කරන්න',
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

  Widget _buildUploadVideoState() {
    return GestureDetector(
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
    );
  }

  Widget _buildComponent1VideoState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.video_library, color: AppColors.primaryDeep, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text('Previous Activity Recording', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryWash, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Component 1: Speech Assessment Task', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 13)),
                      SizedBox(height: 4),
                      Text('Recorded today • Duration: 1 min 30 sec', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('This video recording will be automatically used for physical behavior analysis.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
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

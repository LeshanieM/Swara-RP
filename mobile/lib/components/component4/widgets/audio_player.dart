import 'package:flutter/material.dart';
import 'package:swara/core/theme/app_theme.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({Key? key}) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool isPlaying = false;
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                iconSize: 48,
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Slider(
                      value: progress,
                      onChanged: (val) {
                        setState(() {
                          progress = val;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                      inactiveColor: AppColors.divider,
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("00:00", style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                        Text("01:12", style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

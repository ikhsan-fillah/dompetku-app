import 'dart:ui';
import 'package:flutter/material.dart';

class LockOverlay extends StatelessWidget {
  final VoidCallback onUnlockTap;
  final bool hasPin;
  
  const LockOverlay({
    super.key,
    required this.onUnlockTap,
    required this.hasPin
    });
  
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: Colors.black.withValues(alpha: 0.25)),
                ),
            Center(
              child: AbsorbPointer(
                absorbing: false,
                child: ElevatedButton(
                  onPressed: onUnlockTap, 
                  child: Text(hasPin ? 'Buka Aplikasi' : 'Buat PIN dulu'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
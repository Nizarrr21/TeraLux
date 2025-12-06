import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/loadingscreen.mp4');
    
    try {
      await _controller.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      
      // Play video
      _controller.play();
      
      // Navigate to login page setelah video selesai
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          _navigateToLogin();
        }
      });
      
      // Fallback: jika video tidak selesai dalam 10 detik, tetap lanjut
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          _navigateToLogin();
        }
      });
    } catch (e) {
      // Jika video gagal load, langsung ke login page
      print('Error loading video: $e');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToLogin();
        }
      });
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isVideoInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fallback loading indicator
                  Image.asset(
                    'assets/images/icon.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading TeraLux...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

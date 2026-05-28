import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AHP Driver APP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff004182),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _doorAnimation;
  late Animation<double> _textFade;
  late Animation<double> _textScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // pintu buka
    _doorAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.55,
          curve: Curves.easeInOutCubic,
        ),
      ),
    );

    // teks fade
    _textFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.45,
          0.75,
          curve: Curves.easeIn,
        ),
      ),
    );

    // teks scale
    _textScale = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.45,
          0.75,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _start();
  }

  Future<void> _start() async {
    await _controller.forward();

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const LoginPage(),
    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
  ),
);

  
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final halfWidth = MediaQuery.of(context).size.width / 2;

    return Scaffold(
      backgroundColor: const Color(0xff0066cc),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // 0 -> tertutup, 90 -> terbuka
          final angle = _doorAnimation.value * (math.pi / 2);

          return Stack(
            children: [
              // background putih
              Container(color: const Color(0xff0066cc)),

              // kiri
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: halfWidth,
                child: Transform(
                  alignment: Alignment.centerRight,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(-angle),
                  child: Container(
                    color: const Color(0xff0066cc),
                  ),
                ),
              ),

              // kanan
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: halfWidth,
                child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(angle),
                  child: Container(
                    color: const Color(0xff0066cc),
                  ),
                ),
              ),

              // garis tengah
              Opacity(
                opacity: 1 - _doorAnimation.value,
                child: Center(
                  child: Container(
                    width: 3,
                    color: Colors.white,
                  ),
                ),
              ),

              // teks
              Center(
                child: FadeTransition(
                  opacity: _textFade,
                  child: ScaleTransition(
                    scale: _textScale,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Welcome to\nAHP Driver APP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Connecting Industries with Efficiency,\nDriving Excellence in Every Delivery.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
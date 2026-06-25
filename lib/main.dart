import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'core/supabase/supabase_service.dart';
import 'core/utils/location_service.dart';
import 'features/profile/profile_repository.dart';
import 'home_page.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

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

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    // ✅ Jika session masih aktif (buka ulang app), langsung start tracking
    if (SupabaseService.currentSession != null) {
      try {
        final email = SupabaseService.currentUser?.email;
        if (email != null && email.isNotEmpty) {
          final profile = await const ProfileRepository()
              .fetchDriverProfileByEmail(email);
          await LocationService().startTracking(profile.id);
        }
      } catch (_) {
        // Abaikan error, tetap lanjut ke MainNavigation
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SupabaseService.currentSession == null
                ? const LoginPage()
                : const MainNavigation(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          final angle = _doorAnimation.value * (math.pi / 2);

          return Stack(
            children: [
              Container(color: const Color(0xff0066cc)),

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

              Opacity(
                opacity: 1 - _doorAnimation.value,
                child: Center(
                  child: Container(
                    width: 3,
                    color: Colors.white,
                  ),
                ),
              ),

              Center(
                child: FadeTransition(
                  opacity: _textFade,
                  child: ScaleTransition(
                    scale: _textScale,
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'dart:math' as math;

  import '../providers/auth_provider.dart';
  import '../screens/auth/welcome_screen.dart';
  import '../screens/main_screen.dart';
  import '../utils/theme.dart';

  class SplashScreen extends StatefulWidget {
    const SplashScreen({super.key});

    @override
    State<SplashScreen> createState() => _SplashScreenState();
  }

  class _SplashScreenState extends State<SplashScreen>
      with TickerProviderStateMixin {
    late AnimationController _logoController;
    late AnimationController _backgroundController;
    late AnimationController _textController;
    
    late Animation<double> _logoScaleAnimation;
    late Animation<double> _logoRotateAnimation;
    late Animation<double> _logoFadeAnimation;
    late Animation<double> _backgroundAnimation;
    late Animation<double> _textFadeAnimation;
    late Animation<Offset> _textSlideAnimation;

    @override
    void initState() {
      super.initState();
      
      // Logo animations
      _logoController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _logoScaleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ));

      _logoRotateAnimation = Tween<double>(
        begin: 0.0,
        end: 2 * math.pi,
      ).animate(CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ));

      _logoFadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ));

      // Background animation
      _backgroundController = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat(reverse: true);

      _backgroundAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(_backgroundController);

      // Text animations
      _textController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      _textFadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeIn

      ));

      _textSlideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn
      ));

      _startAnimations();
      _navigateToNextScreen();
    }

    void _startAnimations() async {
  // <CHANGE> Add mounted check before starting animations
  await Future.delayed(const Duration(milliseconds: 300));
  if (!mounted) return;
  
  _logoController.forward();
  
  await Future.delayed(const Duration(milliseconds: 800));
  if (!mounted) return;
  
  _textController.forward();
}

void _navigateToNextScreen() async {
  await Future.delayed(const Duration(seconds: 3));
  
  // <CHANGE> Check mounted before navigation
  if (!mounted) return;
  
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  // <CHANGE> Use pushReplacement to prevent back navigation to splash
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => authProvider.isAuthenticated
          ? const MainScreen()
          : const WelcomeScreen(),
    ),
  );
}
    @override
    void dispose() {
      _logoController.dispose();
      _backgroundController.dispose();
      _textController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Stack(
          children: [
            // Animated background
            AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                          AppTheme.darkBackground,
                          AppTheme.primaryPurple.withOpacity(0.3),
                          (_backgroundAnimation.value * 2) % 1,
                        )!,
                        Color.lerp(
                          AppTheme.darkBackground,
                          AppTheme.primaryPink.withOpacity(0.3),
                          ((_backgroundAnimation.value + 0.5) * 2) % 1,
                        )!,
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Floating particles
            ...List.generate(20, (index) {
              return AnimatedBuilder(
                animation: _backgroundAnimation,
                builder: (context, child) {
                  final offset = (_backgroundAnimation.value + (index * 0.05)) % 1;
                  return Positioned(
                    left: (index % 5) * (MediaQuery.of(context).size.width / 5),
                    top: MediaQuery.of(context).size.height * offset,
                    child: Opacity(
                      opacity: 0.1,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: index % 2 == 0 
                              ? AppTheme.primaryPurple 
                              : AppTheme.primaryPink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animations
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _logoRotateAnimation.value,
                          child: FadeTransition(
                            opacity: _logoFadeAnimation,
                            child: SizedBox(
                              width: 200,
                              height: 200,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Glowing circle background
                                  Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryPurple.withOpacity(0.5),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                        BoxShadow(
                                          color: AppTheme.primaryPink.withOpacity(0.3),
                                          blurRadius: 50,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Logo image
                                  Transform.scale(
                                    scale:4,
                                    child: Image.asset(
                                      'assets/logo.png',
                                      width: 200,
                                      height: 100,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // App name with slide animation
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                AppTheme.primaryPurple,
                                AppTheme.primaryPink,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Vape me',
                              // 'Vape Me',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          const Text(
                            'Zdobywaj nagrody, odbieraj kupony',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
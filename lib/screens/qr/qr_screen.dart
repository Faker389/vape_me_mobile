import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:vape_me/models/user_model.dart';
import 'package:vape_me/utils/checkUser.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class QRScreen extends StatefulWidget {
  const QRScreen({super.key});


  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {
  double? _previousBrightness;
  UserModel? user;
  bool isLoadingUser = true;
  Future<void> loadUser() async {
  setState(() {
    isLoadingUser = true;
  });

  final loadedUser = await UserAuthHelper.checkUser(context);
  
  if (mounted) {
    setState(() {
      user = loadedUser;
      isLoadingUser = false;
    });
    
  }
}
  @override
  void initState() {
    loadUser();
    super.initState();
    _setMaxBrightness();
  }

  /// Sets the screen brightness to maximum, saving the previous value.
  Future<void> _setMaxBrightness() async {
    try {
      print("Podjasniono----------------------");
      _previousBrightness = await ScreenBrightness().current; // Save current
      await ScreenBrightness().setScreenBrightness(1.0); // 1.0 = 100%
    } catch (e) {
      debugPrint("Failed to set brightness: $e");
    }
  }

  /// Restore previous brightness when leaving this screen
  @override
  void dispose() {
    if (_previousBrightness != null) {
      ScreenBrightness().setScreenBrightness(_previousBrightness!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingUser || user == null) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackground,
              AppTheme.primaryPurple.withOpacity(0.1),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primaryPurple,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Ładowanie...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Kod QR'),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.cardBackground.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text('Twój kod QR', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Pokaż ten kod przy kasie, aby zdobywać punkty',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: BarcodeWidget(
                        data: "user=${user!.phoneNumber}",
  barcode: Barcode.code128(),
  width: 350,
  height: 120,
  backgroundColor: Colors.white,
  drawText: false,
),
                    ),
                    const SizedBox(height: 32),
                    _buildUserCard(user),
                    const SizedBox(height: 32),
                    _buildInfoCard(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(user) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(user.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(user.phoneNumber, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryPurple, AppTheme.primaryPink]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${user.points} punktów',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info, color: AppTheme.primaryPurple, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Okaz ten kod kasjerowi, aby zebrać punkty za zakupy',
                style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.9), fontSize: 14),
              ),
            ),
          ],
        ),
      );

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkBackground,
            AppTheme.darkBackground,
            AppTheme.primaryPurple.withOpacity(0.05),
            AppTheme.primaryPink.withOpacity(0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.2),
                    AppTheme.primaryPurple.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryPink.withOpacity(0.15),
                    AppTheme.primaryPink.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

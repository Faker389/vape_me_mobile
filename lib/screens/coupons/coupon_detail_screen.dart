import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:vape_me/utils/hive_storage.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../models/coupon_model.dart';
import '../../utils/theme.dart';

class CouponDetailScreen extends StatefulWidget {
  final CouponModel coupon;

  const CouponDetailScreen({super.key, required this.coupon});

  @override
  State<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends State<CouponDetailScreen>
    with SingleTickerProviderStateMixin {
        double? _previousBrightness;

      final user = UserStorage.getUser();
  late AnimationController _backgroundController;
  Future<void> _setMaxBrightness() async {
    try {
      _previousBrightness = await ScreenBrightness().current; // Save current
      await ScreenBrightness().setScreenBrightness(1.0); // 1.0 = 100%
    } catch (e) {
      debugPrint("Failed to set brightness: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _setMaxBrightness();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
     if (_previousBrightness != null) {
      ScreenBrightness().setScreenBrightness(_previousBrightness!);
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Szczegóły Kuponu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // QR Code Card
                  _buildQRCodeCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Coupon Info Card
                  
                  const SizedBox(height: 24),
                  
                  // Details Card
                  _buildDetailsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Terms & Conditions
                  _buildTermsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Use Instructions
                  _buildInstructionsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
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
              stops: [
                0.0,
                0.3 + (_backgroundController.value * 0.2),
                0.6 + (_backgroundController.value * 0.2),
                1.0,
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
      },
    );
  }

  Widget _buildQRCodeCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryPurple, AppTheme.primaryPink],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          
          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
//             child:QrImageView(
//               data: "coupon=${widget.coupon.id}user=${user!.phoneNumber}",
//   version: QrVersions.auto,
//   size: 250.0,
//   backgroundColor: Colors.white,
//   foregroundColor: Colors.black,
// )
          child:  BarcodeWidget(
                        data: "coupon=${widget.coupon.id}user=${user!.phoneNumber}",
  barcode: Barcode.code128(),
  width: 350,
  height: 120,
  backgroundColor: Colors.white,
  drawText: false,
),
          ),
          
          const SizedBox(height: 24),
          
          // Scan instruction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Pokaż ten kod w kasie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }



  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.primaryPink.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Szczegóły',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDetailRow(
            Icons.category,
            'Kategoria',
            widget.coupon.category,
          ),
          _buildDetailRow(
            Icons.stars,
            'Koszt punktów',
            '${widget.coupon.pointsCost} punktów',
          ),
          _buildDetailRow(
            Icons.calendar_today,
            'Odebrano',
            _formatDate(widget.coupon.claimedDate),
          ),
          _buildDetailRow(
            Icons.event,
            'Wygasa',
            _formatDate(widget.coupon.expiryDate),
            showWarning: widget.coupon.daysUntilExpiry <= 7,
          ),
          _buildDetailRow(
            Icons.timer,
            'Pozostało dni',
            '${widget.coupon.daysUntilExpiry} dni',
            showWarning: widget.coupon.daysUntilExpiry <= 7,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {bool showWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: showWarning ? Colors.white : AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: showWarning ? AppTheme.accentRed : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.primaryPink.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Warunki użycia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTermItem('Kupon można użyć tylko raz'),
          _buildTermItem('Nie łączy się z innymi promocjami'),
          _buildTermItem('Ważny tylko w sklepach stacjonarnych'),
          _buildTermItem('Nie podlega zwrotowi ani wymianie na gotówkę'),
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.primaryPink.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppTheme.primaryPurple,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Jak użyć kuponu?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep('1', 'Pokaż kod QR w kasie'),
          _buildInstructionStep('2', 'Kasjer zeskanuje kod'),
          _buildInstructionStep('3', 'Zniżka zostanie automatycznie naliczona'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.primaryPink],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

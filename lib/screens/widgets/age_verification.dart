import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vape_me/screens/home/home_screen.dart';

class AgeVerificationScreen extends StatefulWidget {

  const AgeVerificationScreen({Key? key}) : super(key: key);

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String _errorMessage = '';
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  int _calculateAge(int day, int month, int year) {
    final today = DateTime.now();
    final birthDate = DateTime(year, month, day);
    int age = today.year - birthDate.year;
    
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
  Future<void> _handleSubmit() async {
    setState(() {
      _errorMessage = '';
      _isSubmitting = true;
    });

    final day = int.tryParse(_dayController.text);
    final month = int.tryParse(_monthController.text);
    final year = int.tryParse(_yearController.text);

    // Validation
    if (day == null || month == null || year == null) {
      setState(() {
        _errorMessage = 'Proszę wypełnić wszystkie pola';
        _isSubmitting = false;
      });
      return;
    }

    if (day < 1 || day > 31) {
      setState(() {
        _errorMessage = 'Nieprawidłowy dzień';
        _isSubmitting = false;
      });
      return;
    }

    if (month < 1 || month > 12) {
      setState(() {
        _errorMessage = 'Nieprawidłowy miesiąc';
        _isSubmitting = false;
      });
      return;
    }

    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear) {
      setState(() {
        _errorMessage = 'Nieprawidłowy rok';
        _isSubmitting = false;
      });
      return;
    }

    // Check if date is valid
    try {
      final testDate = DateTime(year, month, day);
      if (testDate.day != day || testDate.month != month || testDate.year != year) {
        setState(() {
          _errorMessage = 'Nieprawidłowa data';
          _isSubmitting = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Nieprawidłowa data';
        _isSubmitting = false;
      });
      return;
    }

    final age = _calculateAge(day, month, year);

    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 800));

    if (age >= 18) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ageVerified', true);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ageVerified', false);
      setState(() {
        _errorMessage = 'Musisz mieć ukończone 18 lat, aby uzyskać dostęp do tej strony';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a0a0f),
              Color(0xFF1a1a2e),
              Color(0xFF0a0a0f),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background blobs
            _AnimatedBlob(
              color: Colors.purple.withOpacity(0.3),
              alignment: Alignment.topLeft,
              size: 300,
            ),
            _AnimatedBlob(
              color: Colors.pink.withOpacity(0.3),
              alignment: Alignment.bottomRight,
              size: 300,
              delay: 1.0,
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple, Colors.pink],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Color(0xFFc084fc),
                                Color(0xFFf9a8d4),
                                Color(0xFFc084fc),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Weryfikacja Wieku',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Aby uzyskać dostęp do tej strony, musisz mieć ukończone 18 lat',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Form
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Data urodzenia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _dayController,
                                  hint: 'DD',
                                  maxLength: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _monthController,
                                  hint: 'MM',
                                  maxLength: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  controller: _yearController,
                                  hint: 'RRRR',
                                  maxLength: 4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Error message
                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red[300], size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.red[300],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: _isSubmitting
                                      ? null
                                      : LinearGradient(
                                          colors: [
                                            Color(0xFF9333ea),
                                            Color(0xFFdb2777),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: _isSubmitting
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Weryfikacja...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.verified_user,
                                                color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Potwierdź wiek',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Footer
                          Text(
                            'Ta strona zawiera produkty przeznaczone wyłącznie dla osób pełnoletnich',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: maxLength,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        counterText: '',
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

class _AnimatedBlob extends StatefulWidget {
  final Color color;
  final Alignment alignment;
  final double size;
  final double delay;

  const _AnimatedBlob({
    required this.color,
    required this.alignment,
    required this.size,
    this.delay = 0.0,
  });

  @override
  State<_AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<_AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.alignment == Alignment.topLeft
              ? _controller.value * 100
              : null,
          right: widget.alignment == Alignment.bottomRight
              ? _controller.value * 100
              : null,
          top: widget.alignment == Alignment.topLeft
              ? _controller.value * 50
              : null,
          bottom: widget.alignment == Alignment.bottomRight
              ? _controller.value * 50
              : null,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
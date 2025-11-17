import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:vape_me/utils/hive_storage.dart';

import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import 'otp_verification_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  final bool isSignUp;

  const PhoneAuthScreen({Key? key, required this.isSignUp}) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late AnimationController _backgroundController;
    late Animation<double> _backgroundAnimation;

  Country _selectedCountry = Country(
    phoneCode: '48',
    countryCode: 'PL',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Poland',
    example: '123456789',
    displayName: 'Poland (PL) [+48]',
    displayNameNoCountryCode: 'Poland (PL)',
    e164Key: '',
  );

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 0.3,
    ).animate(_backgroundController);
  }

  @override
  void dispose() {

    UserStorage.clearUser();
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
      countryListTheme: CountryListThemeData(
        backgroundColor: AppTheme.cardBackground,
        textStyle: const TextStyle(color: AppTheme.textPrimary),
        searchTextStyle: const TextStyle(color: AppTheme.textPrimary),
        inputDecoration: InputDecoration(
          hintText: 'Znajdź państwo',
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
void _sendOTP() async {
  if (!_formKey.currentState!.validate()) return;
  final phoneNumber = '+${_selectedCountry.phoneCode}${_phoneController.text}';
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  bool success = await authProvider.sendOTP(phoneNumber);
  if (!mounted) return;

  if (success) {
    // <CHANGE> Show success message before navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kod weryfikacyjny został wysłany!'),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 1500),
      ),
    );
    
    // <CHANGE> Add delay to let user see the success message
    await Future.delayed(const Duration(milliseconds: 1500));
    if(widget.isSignUp){
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                phoneNumber: phoneNumber,
                name:  _nameController.text ,
                email:  _emailController.text
              ),
            ),
          );
          return;
    }
    final user = await UserStorage.getUserFromDB(phoneNumber);

    if(user==null){
      Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PhoneAuthScreen(isSignUp: true),
      ),
    );
    return;
    }
    // <CHANGE> Now navigate to OTP screen
    
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Nie udało sie wysłać kodu weryfikacyjnego'),
        backgroundColor: AppTheme.accentRed,
      ),
    );
  }
}
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSignUp ? 'Zarejestruj się' : 'Zaloguj się'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated gradient background
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
                        AppTheme.primaryPurple.withOpacity(0.2),
                        (_backgroundAnimation.value * 2) % 1,
                      )!,
                      Color.lerp(
                        AppTheme.darkBackground,
                        AppTheme.primaryPink.withOpacity(0.2),
                        ((_backgroundAnimation.value + 0.5) * 2) % 1,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    Text(
                      widget.isSignUp 
                          ? 'Stwórz konto' 
                          : 'Witamy spowrotem',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'Wysłaliśmy ci kod weryfikacyjny',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    
                    // Name field (only for sign up)
                    if (widget.isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Imie',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Wpisz swoje imie';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Email field (only for sign up)
                    if (widget.isSignUp) ...[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Wpisz swój email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Wpisz poprawny email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Phone number field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nr. telefonu',
                        prefixIcon: GestureDetector(
                          onTap: _selectCountry,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedCountry.flagEmoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+${_selectedCountry.phoneCode}',
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Wpisz swój numer telefonu';
                        }
                        if (value.length < 9) {
                          return 'Wpisz poprawny numer telefonu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Send OTP Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _sendOTP,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Wyślij kod'),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Terms and conditions (for sign up)
                    if (widget.isSignUp)
                      const Text(
                        'Kontynuując akceptujesz nasz regulamin i polityke prywatności',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

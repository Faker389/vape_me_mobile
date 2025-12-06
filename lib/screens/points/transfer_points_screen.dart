import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vape_me/models/user_model.dart';
import 'package:vape_me/utils/checkUser.dart';
import 'package:vape_me/utils/firebase_messaging.dart';

import '../../utils/theme.dart';
import '../../utils/hive_storage.dart';

class TransferPointsScreen extends StatefulWidget {
  const TransferPointsScreen({super.key});

  @override
  State<TransferPointsScreen> createState() => _TransferPointsScreenState();
}

class _TransferPointsScreenState extends State<TransferPointsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _pointsController = TextEditingController();
  bool _isLoading = false;
  bool isLoadingUser = true;

  UserModel? user;
  
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
    super.initState();
    loadUser();
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  void _transferPoints() async {
    if (!_formKey.currentState!.validate()) return;

    // Check internet connection first
    final hasInternet = await _checkInternetConnection();
    
    if (!hasInternet) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak połączenia z internetem. Sprawdź swoje połączenie i spróbuj ponownie.'),
          backgroundColor: AppTheme.accentRed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    int points = int.parse(_pointsController.text.trim());
      String phoneNumber = _phoneController.text.trim();
      if(user?.phoneNumber==phoneNumber){
        return;
      }
    setState(() {
      _isLoading = true;
    });

    try {
      
      if (points <= user!.points) {
        final docSnapshot = await _db.collection('users').doc(phoneNumber).get();
        
        if (docSnapshot.exists) {
          final userfinal = UserModel.fromMap(docSnapshot.data() as Map<String, dynamic>);
          await _db.collection('users').doc(phoneNumber).update({
            'points': userfinal.points + points,
          });
          user!.points = user!.points - points;
          await UserStorage.updateUser(user!);
           try {
      FirebaseMessagingService().sendTransferedPointsNotification(phoneNumber: phoneNumber, points: points.toString());
      } catch (e) {
        print("Błąd wysyłania powiadomienia: $e");
      }
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppTheme.accentGreen,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Transfer udany!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Przekazano $points buszków',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to profile
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: AppTheme.primaryPurple),
                    ),
                  ),
                ],
              ),
            );

            _phoneController.clear();
            _pointsController.clear();
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nie znaleziono użytkownika o podanym numerze telefonu'),
                backgroundColor: AppTheme.accentRed,
              ),
            );
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nie masz wystarczającej liczby buszków'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Błąd podczas transferu buszków. Spróbuj ponownie.'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
      print("Błąd transferu: $e");
    }
   
  }

  @override
  Widget build(BuildContext context) {
    final availablePoints = user?.points ?? 0;
    
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
        title: const Text('Transfer buszków'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Available Points Card - Updated colors
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryPurple,
                            AppTheme.primaryPink,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dostępne punkty',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$availablePoints buszków',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Info Card - Updated colors
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryPurple.withOpacity(0.8),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Przekaż punkty innym użytkownikom podając ich numer telefonu',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.9),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Recipient Phone Number
                    const Text(
                      'Numer telefonu odbiorcy',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withOpacity(0.15),
                        ),
                      ),
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: '+48 123 456 789',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              Icons.phone,
                              color: AppTheme.primaryPurple.withOpacity(0.8),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Podaj numer telefonu odbiorcy';
                          }
                          if (value.replaceAll(RegExp(r'[\s+]'), '').length < 9) {
                            return 'Podaj prawidłowy numer telefonu';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Points Amount
                    const Text(
                      'Liczba buszków',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withOpacity(0.15),
                        ),
                      ),
                      child: TextFormField(
                        controller: _pointsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Wprowadź liczbę buszków',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              Icons.stars,
                              color: AppTheme.primaryPink.withOpacity(0.8),
                            ),
                          ),
                          suffixText: 'pkt',
                          suffixStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Podaj liczbę buszków do przekazania';
                          }
                          final points = int.tryParse(value);
                          if (points == null || points <= 0) {
                            return 'Podaj prawidłową liczbę buszków';
                          }
                          if (points > availablePoints) {
                            return 'Nie masz wystarczającej liczby buszków';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Quick amount buttons - Updated colors
                    Row(
                      children: [
                        _buildQuickAmountButton(context, 10),
                        const SizedBox(width: 8),
                        _buildQuickAmountButton(context, 25),
                        const SizedBox(width: 8),
                        _buildQuickAmountButton(context, 50),
                        const SizedBox(width: 8),
                        _buildQuickAmountButton(context, 100),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // Transfer Button - Updated gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: _isLoading 
                            ? null 
                            : const LinearGradient(
                                colors: [
                                  AppTheme.primaryPurple,
                                  AppTheme.primaryPink,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _isLoading 
                            ? null 
                            : [
                                BoxShadow(
                                  color: AppTheme.primaryPurple.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _transferPoints,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: _isLoading 
                              ? AppTheme.textSecondary.withOpacity(0.3)
                              : Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Przekaż punkty',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildQuickAmountButton(BuildContext context, int amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pointsController.text = amount.toString();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple.withOpacity(0.1),
                AppTheme.primaryPink.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primaryPurple.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            '$amount',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryPurple.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
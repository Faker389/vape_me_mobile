import 'package:flutter/material.dart';
import 'package:vape_me/providers/auth_provider.dart';
import 'package:vape_me/screens/auth/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:vape_me/utils/hive_storage.dart';

import '../../utils/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
static Future<bool> checkUser(AuthProvider authProvider)async{
          final user = UserStorage.getUser();
         if (user == null) {
          final isUserAuthenticated = authProvider.isAuthenticated;
          if(!isUserAuthenticated)return false;
          final phoneNumber = authProvider.user?.phoneNumber;
          await UserStorage.getUserFromDB(phoneNumber!);
          return true;
    }else{
      return true;
    }
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (checkUser(authProvider) == false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
        );
      });
      return Container();
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Polityka prywatności'),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Header
                  Container(
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
                        color: AppTheme.primaryPurple.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppTheme.primaryPurple,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Twoja prywatność',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ostatnia aktualizacja: 10.10.2025',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Sections
                  _buildSection(
                    '1. Wprowadzenie',
                    'Niniejsza Polityka Prywatności opisuje, w jaki sposób gromadzimy, wykorzystujemy, przechowujemy i chronimy Twoje dane osobowe podczas korzystania z aplikacji Żappka.',
                  ),
                  
                  _buildSection(
                    '2. Zbierane dane',
                    'Gromadzimy następujące rodzaje danych:\n\n'
                    '• Dane rejestracyjne (imię, email, numer telefonu)\n'
                    '• Dane transakcyjne (historia punktów i zakupów)\n'
                    '• Dane techniczne (adres IP, typ urządzenia)\n'
                    '• Preferencje użytkownika',
                  ),
                  
                  _buildSection(
                    '3. Cel przetwarzania danych',
                    'Twoje dane wykorzystywane są w celu:\n\n'
                    '• Świadczenia usług programu lojalnościowego\n'
                    '• Personalizacji oferty i nagród\n'
                    '• Komunikacji z użytkownikami\n'
                    '• Poprawy jakości aplikacji\n'
                    '• Zapewnienia bezpieczeństwa',
                  ),
                  
                  _buildSection(
                    '4. Bezpieczeństwo danych',
                    'Stosujemy zaawansowane środki techniczne i organizacyjne w celu ochrony Twoich danych osobowych przed nieuprawnionym dostępem, utratą lub zniszczeniem. Wszystkie dane są przechowywane na zabezpieczonych serwerach.',
                  ),
                  
                  _buildSection(
                    '5. Udostępnianie danych',
                    'Twoje dane nie są sprzedawane osobom trzecim. Możemy udostępniać dane wyłącznie:\n\n'
                    '• Zaufanym partnerom technologicznym\n'
                    '• W przypadku wymogów prawnych\n'
                    '• Za Twoją wyraźną zgodą',
                  ),
                  
                  _buildSection(
                    '6. Twoje prawa',
                    'Masz prawo do:\n\n'
                    '• Dostępu do swoich danych\n'
                    '• Poprawiania nieprawidłowych danych\n'
                    '• Usunięcia danych\n'
                    '• Ograniczenia przetwarzania\n'
                    '• Przenoszenia danych\n'
                    '• Wniesienia sprzeciwu',
                  ),
                  
                  _buildSection(
                    '7. Cookies i technologie śledzące',
                    'Aplikacja wykorzystuje cookies i podobne technologie w celu zapewnienia prawidłowego działania, analizy użytkowania oraz personalizacji treści.',
                  ),
                  
                  _buildSection(
                    '8. Zmiany w polityce',
                    'Zastrzegamy sobie prawo do wprowadzania zmian w niniejszej Polityce Prywatności. O wszelkich istotnych zmianach zostaniesz powiadomiony za pośrednictwem aplikacji.',
                  ),
                  
                  _buildSection(
                    '9. Kontakt',
                    'W razie pytań dotyczących Polityki Prywatności, skontaktuj się z nami:\n\n'
                    'Email: vapeme123321@gmail.coml\n'
                    'Telefon: +48 123 456 789',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.textSecondary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryPurple,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Korzystając z aplikacji, akceptujesz warunki niniejszej Polityki Prywatności.',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textSecondary.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

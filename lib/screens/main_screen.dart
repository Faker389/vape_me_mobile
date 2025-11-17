import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vape_me/models/reward_model.dart';

import '../providers/user_provider.dart';
import '../providers/rewards_provider.dart';
import '../utils/theme.dart';
import 'home/home_screen.dart';
import 'rewards/rewards_screen.dart';
import 'qr/qr_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int? initialIndex;
  final RewardModel? rewardModel;
  final VoidCallback? onRewardRedeemed;
  
  const MainScreen({
    Key? key, 
    this.initialIndex,
    this.rewardModel,
    this.onRewardRedeemed,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();

    if (widget.initialIndex != null) {
      _currentIndex = widget.initialIndex!;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadTransactions();
      Provider.of<RewardsProvider>(context, listen: false).loadRewards();
    });
  }

  void _onRewardRedeemedInternal() {
    // Refresh home screen if it exists
    _homeScreenKey.currentState?.refreshData();
    
    // Call parent callback if provided (for when MainScreen is opened from HomeScreen)
    widget.onRewardRedeemed?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Create the screens list
    final screens = [
      HomeScreen(key: _homeScreenKey),
      RewardsScreen(
        reward: widget.rewardModel,
        onRewardRedeemed: _onRewardRedeemedInternal,
      ),
      const QRScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.cardBackground,
          selectedItemColor: AppTheme.primaryPurple,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: 'Kupony',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code),
              label: 'QR Kode',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
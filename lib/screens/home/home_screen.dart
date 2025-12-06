import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vape_me/models/user_model.dart';
import 'package:vape_me/screens/home/rewardCard.dart';
import 'package:vape_me/screens/widgets/points_card.dart';
import 'package:vape_me/screens/widgets/recent_transactions.dart';
import 'package:vape_me/utils/AppVersionHolder.dart';
import 'package:vape_me/utils/checkUser.dart';
import 'package:vape_me/utils/firebase_messaging.dart';
import 'package:vape_me/screens/UpdateScreen.dart';

import '../../providers/user_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../utils/theme.dart';
import '../main_screen.dart';
import '../../utils/hive_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  UserModel? user;
  bool isLoadingUser = true;

  Future<void> refreshData() async {
    await _refreshAllData();
  }
 
  Future<void> checkAndUpdateToken() async {
    final currentUser = UserStorage.getUser();
    if (currentUser == null) return;
    
    String? token = await FirebaseMessagingService().getToken();
    if (currentUser.token != token) {
      await _db.collection("users").doc(currentUser.phoneNumber).update({
        "token": token
      });
    }
  }

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
    
    if (user != null) {
      checkAndUpdateToken();
    }
  }
}
void _checkVersion() {
  if (AppVersionHolder.firestoreVersion > AppVersionHolder.appVersion && mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => UpdateScreen()),
    );
  }
}
  @override
  void initState() {
    super.initState();
    loadUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).startUserListener();
        Provider.of<RewardsProvider>(context, listen: false).loadRewards();
        _checkVersion();
      }
    });
    
  }

  

  Future<void> _refreshAllData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
  _checkVersion();
    await Future.wait([
      userProvider.refreshUserData(),
      userProvider.loadTransactions(),
      rewardsProvider.loadRewards(),
    ]);
   
    // Reload user from storage after refresh
    final refreshedUser = UserStorage.getUser();
    if (mounted) {
      setState(() {
        user = refreshedUser;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  // Show loading indicator while user is being loaded

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
    body: Stack(
      children: [
        _buildAnimatedBackground(), // ← Add background here
        SafeArea(
          child: RefreshIndicator(
            key: _refreshKey,
            onRefresh: _refreshAllData,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 24),
                          PointsCard(points: user!.points),
                          const SizedBox(height: 24),
                          _buildFeaturedRewards(context),
                          const SizedBox(height: 24),
                          const RecentTransactions(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Witaj,',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    user!.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
           
          ],
        );
      },
    );
  }

  Widget _buildFeaturedRewards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Zgarniaj nagrody',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => MainScreen(
                      initialIndex: 1,
                      onRewardRedeemed: _refreshAllData,
                    ),
                  ),
                );
              },
              child: const Text(
                'Zobacz wszystkie',
                style: TextStyle(color: AppTheme.primaryPurple),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer2<RewardsProvider, UserProvider>(
          builder: (context, rewardsProvider, userProvider, child) {
            if (rewardsProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryPurple,
                  ),
                ),
              );
            }
            final redeemedIds = user?.coupons?.map((c) => c.rewardID).toList() ?? [];
            final featuredRewards = rewardsProvider.rewards
                .where((r) => !redeemedIds.contains(r.id))
                .take(5)
                .toList();

            if (featuredRewards.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        size: 48,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Brak dostępnych nagród',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                itemCount: featuredRewards.length,
                itemBuilder: (context, index) {
                  final reward = featuredRewards[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FuturisticRewardCard(reward: reward,onTap:  () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              initialIndex: 1,
              rewardModel: reward,
              onRewardRedeemed: _refreshAllData,
            ),
          ),
        );

        // If a reward was redeemed, refresh home screen
        if (result == true && mounted) {
          await _refreshAllData();
        }
      },),
                  );
                },
              ),
            );
          },
        ),
      ],
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

}
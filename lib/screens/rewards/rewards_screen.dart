import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vape_me/models/coupon_model.dart';
import 'package:vape_me/models/reward_model.dart';
import 'package:vape_me/models/transaction_model.dart';
import 'package:vape_me/models/user_model.dart';
import 'package:vape_me/providers/auth_provider.dart';
import 'package:vape_me/screens/rewards/discountTemp.dart';
import 'package:vape_me/utils/checkUser.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../../utils/hive_storage.dart';
import '../widgets/category_filter.dart';

Future<bool> _checkInternetConnection() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  } catch (e) {
    return false;
  }
}

void _redeemRewardHelper(
  BuildContext context, 
  UserProvider userProvider, 
  RewardModel reward,
  VoidCallback onSuccess,
) async {
  // Check internet connection first
  final hasInternet = await _checkInternetConnection();
  
  if (!hasInternet) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Brak połączenia z internetem. Sprawdź swoje połączenie i spróbuj ponownie.'),
        backgroundColor: AppTheme.accentRed,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  final user = UserStorage.getUser()!;
  CouponModel coupon = CouponModel(
      id: Uuid().v4(),
      rewardID: reward.id,
      title: reward.name,
      description: reward.description,
      pointsCost: reward.pointsCost,
      claimedDate: DateTime.now(),
      isDiscount:reward.isDiscount,
      expiryDate: DateTime.parse(reward.expiryDate),
      discountAmount: reward.discountamount,
      isUsed: false,
      usedDate: null,
      category: reward.category,
      imageUrl: reward.imageUrl
  );
  TransactionModel transaction = TransactionModel(
      id: Uuid().v4(),
      type: TransactionType.redeem,
      points: reward.pointsCost,
      description: reward.name,
      timestamp: DateTime.now(),
      rewardId: reward.id,
      imageUrl: reward.imageUrl,
  );

  user.addTransaction(transaction);
  user.addCoupon(coupon);
  user.points -= reward.pointsCost;

  late bool success;
  try {
    await UserStorage.updateUser(user);
    success = true;
  } catch (e) {
    success = false;
  }

  if (!context.mounted) return;

  if (success) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.accentGreen,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sukces!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pomyślnie odebrano kupon ${reward.name}',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () async {
      if (context.mounted) {
        Navigator.of(context).pop(); // close dialog
        Navigator.of(context).pop(true); // close reward modal
        
        // Trigger refresh callback
        onSuccess();
      }
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nie udało się odebrać kuponu. Spróbuj ponownie.'),
        backgroundColor: AppTheme.accentRed,
      ),
    );
  }
}

class RewardsScreen extends StatefulWidget {
  final RewardModel? reward;
  final VoidCallback? onRewardRedeemed; // New callback for home screen

  const RewardsScreen({
    Key? key, 
    this.reward,
    this.onRewardRedeemed,
  }) : super(key: key);

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  UserModel? user;
  bool _rewardModalOpened = false;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
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

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    
    userProvider.startUserListener();
    
    // Load rewards and wait for completion
    await rewardsProvider.loadRewards();
    
    // Show reward modal if needed
    if (widget.reward != null && !_rewardModalOpened) {
      _rewardModalOpened = true;
      await _preloadRewardImage(widget.reward!);
      if (mounted) {
        _showRewardDetails(widget.reward!);
      }
    }
  });
}

  Future<void> _preloadRewardImage(RewardModel reward) async {
    try {
      await precacheImage(
        CachedNetworkImageProvider(reward.imageUrl),
        context,
      );
    } catch (_) {}
  }

 Future<void> _refreshData() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
  
  await Future.wait([
    userProvider.refreshUserData(),
    rewardsProvider.loadRewards(),
  ]);
  
  // ADD THESE LINES ↓
  final refreshedUser = UserStorage.getUser();
  if (mounted) {
    setState(() {
      user = refreshedUser;
    });
  }
}

  void _onRewardRedeemed() {
    // Refresh rewards screen
    _refreshData();
    
    // Notify parent (home screen or main screen) if callback exists
    widget.onRewardRedeemed?.call();
  }

  void _showRewardDetails(RewardModel reward) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: RewardModalContent(
            reward: reward,
            onRedeemSuccess: _onRewardRedeemed,
          ),
        ),
      ),
    );
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
        title: const Text('Kupony'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Consumer2<RewardsProvider, UserProvider>(
            builder: (context, rewardsProvider, userProvider, child) {
             
           final redeemedIds = user?.coupons?.map((c) => c.rewardID).toList() ?? [];

final availableRewards = rewardsProvider.rewards
    .where((r) {
      if (redeemedIds.contains(r.id)) return false;

      DateTime expiry;
      try {
        expiry = DateTime.parse(r.expiryDate);  // <-- string → DateTime
      } catch (_) {
        return false; // invalid date, hide reward
      }

      return DateTime.now().isBefore(expiry);
    })
    .take(5)
    .toList();



              if (rewardsProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryPurple),
                );
              }

              return SafeArea(
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: _refreshData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: CategoryFilter()),
                      availableRewards.isEmpty
                          ? _buildEmptyState()
                          : SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final reward = availableRewards[index];
                                    return GestureDetector(
                                      onTap: () => _showRewardDetails(reward),
                                      child: RewardCardSimple(reward: reward),
                                    );
                                  },
                                  childCount: availableRewards.length,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.card_giftcard,
                  size: 64,
                  color: AppTheme.primaryPurple.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Brak dostępnych kuponów',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
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

class RewardCardSimple extends StatelessWidget {
  final RewardModel reward;
  const RewardCardSimple({Key? key, required this.reward}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: reward.isDiscount==false? CachedNetworkImage(
                    imageUrl: reward.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.white),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.image, size: 48),
                  ):DiscountBox(percentage: reward.discountamount??0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryPurple, AppTheme.primaryPink],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${reward.pointsCost} buszków',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

class RewardModalContent extends StatelessWidget {
  final RewardModel reward;
  final VoidCallback onRedeemSuccess;
  
  const RewardModalContent({
    Key? key, 
    required this.reward,
    required this.onRedeemSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: reward.imageUrl,
                fit: BoxFit.fill,
                placeholder: (context, url) => Container(
                  color: AppTheme.surfaceColor,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.image, size: 64),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(reward.name, style: Theme.of(context).textTheme.headlineMedium),
                   Text(
            "Opis:",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            reward.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.primaryPink],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Wymagane buszki',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text('${reward.pointsCost} buszków',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Consumer2<AuthProvider, UserProvider>(
            builder: (context, authProvider, userProvider, child) {
              final user = UserStorage.getUser()!;
              final canRedeem = user.points >= reward.pointsCost;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canRedeem
                      ? () => _redeemRewardHelper(
                            context, 
                            userProvider, 
                            reward,
                            onRedeemSuccess,
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRedeem
                        ? AppTheme.primaryPink
                        : AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(canRedeem
                      ? 'Odbierz teraz'
                      : 'Brak wystarczającej liczby buszków (${user.points}/${reward.pointsCost})'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
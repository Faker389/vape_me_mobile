import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vape_me/models/user_model.dart';
import 'package:vape_me/utils/checkUser.dart';
import '../../models/coupon_model.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import 'coupon_detail_screen.dart';

class ActiveCouponsScreen extends StatefulWidget {
  const ActiveCouponsScreen({Key? key}) : super(key: key);

  @override
  State<ActiveCouponsScreen> createState() => _ActiveCouponsScreenState();
}

class _ActiveCouponsScreenState extends State<ActiveCouponsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _backgroundController;
  final FirebaseAuth userFirebase = FirebaseAuth.instance;
  bool _isLoading = true;
  List<CouponModel> _coupons = [];
  UserModel? user;
  bool isLoadingUser = true;
  

  List<CouponModel> get activeCoupons =>
      _coupons.where((c) => c.isActive).toList();

  List<CouponModel> get usedCoupons => _coupons.where((c) => c.isUsed).toList();

  List<CouponModel> get expiredCoupons =>
      _coupons.where((c) => c.isExpired && !c.isUsed).toList();
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
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _initializeData();
  }

  Future<void> _initializeData() async {
    // Check user authentication

    // Load fresh data from database
    await _refreshCoupons();
  }

  Future<void> _refreshCoupons() async {
    setState(() => _isLoading = true);

    try {
      // Get UserProvider and refresh data from database
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshUserData();

      // Get updated user from Hive (which was just synced from DB)
      
      if (mounted) {
        setState(() {
          _coupons = user?.coupons ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing coupons: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się załadować kuponów'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Moje Kupony'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
        ],
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryPurple,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshCoupons,
                    child: activeCoupons.isEmpty &&
                            usedCoupons.isEmpty &&
                            expiredCoupons.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (activeCoupons.isNotEmpty) ...[
                                  _buildSectionHeader(
                                      'Aktywne Kupony', activeCoupons.length),
                                  const SizedBox(height: 12),
                                  ...activeCoupons
                                      .map((coupon) => _buildCouponCard(coupon)),
                                  const SizedBox(height: 24),
                                ],
                                if (usedCoupons.isNotEmpty) ...[
                                  _buildSectionHeader(
                                      'Wykorzystane', usedCoupons.length),
                                  const SizedBox(height: 12),
                                  ...usedCoupons
                                      .map((coupon) => _buildCouponCard(coupon)),
                                  const SizedBox(height: 24),
                                ],
                                if (expiredCoupons.isNotEmpty) ...[
                                  _buildSectionHeader(
                                      'Wygasłe', expiredCoupons.length),
                                  const SizedBox(height: 12),
                                  ...expiredCoupons
                                      .map((coupon) => _buildCouponCard(coupon)),
                                ],
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

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryPurple, AppTheme.primaryPink],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.2),
            ),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponCard(CouponModel coupon) {
    final isActive = coupon.isActive;
    final isExpired = coupon.isExpired;
    final isUsed = coupon.isUsed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryPurple.withOpacity(0.3)
              : AppTheme.textSecondary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isActive
              ? () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CouponDetailScreen(coupon: coupon),
                    ),
                  );

                  // If coupon was used, refresh the list
                  if (result == true && mounted) {
                    await _refreshCoupons();
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon/Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [
                              AppTheme.primaryPurple,
                              AppTheme.primaryPink
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              AppTheme.textSecondary.withOpacity(0.3),
                              AppTheme.textSecondary.withOpacity(0.1),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              coupon.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          if (isUsed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.textSecondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Użyty',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isExpired && !isUsed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentRed.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Wygasły',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.accentRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          if (isActive) ...[
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: coupon.daysUntilExpiry <= 7
                                  ? AppTheme.accentRed
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${coupon.daysUntilExpiry} dni',
                              style: TextStyle(
                                fontSize: 11,
                                color: coupon.daysUntilExpiry <= 7
                                    ? AppTheme.accentRed
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryPurple.withOpacity(0.2),
                            AppTheme.primaryPink.withOpacity(0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        size: 60,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Brak Kuponów',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Odbierz kupony z sekcji nagród aby zobaczyć je tutaj',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
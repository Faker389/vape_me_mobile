import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vape_me/models/reward_model.dart';
import 'package:vape_me/screens/rewards/discountTemp.dart';

class FuturisticRewardCard extends StatelessWidget {
  final RewardModel reward;
  final VoidCallback onTap;

  const FuturisticRewardCard({
    super.key,
    required this.reward,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        // 1. HEIGHT: Keep this matched with your ListView height or slightly smaller
        height: 220, 
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E).withOpacity(0.95),
                const Color(0xFF16213E).withOpacity(0.95),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2CBF).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Glow effect overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF7B2CBF).withOpacity(0.1),
                        const Color(0xFFE91E63).withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          height: 130,
                          width: double.infinity,
                          color: const Color(0xFF0F1419),
                          child: reward.isDiscount
                              ? DiscountBox(
                                  percentage: reward.discountAmount ?? 0)
                              : CachedNetworkImage(
                                  imageUrl: reward.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: const Color(0xFF16213E),
                                    child: Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 48,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: const Color(0xFF16213E),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 48,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                        ),
                        // Gradient overlay for depth
                        Container(
                          height: 130,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12), // Reduced padding slightly to give more room
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 2. TITLE FIX: Changed to maxLines: 1 to fit in the box
                          Text(
                            reward.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1, // ✅ Changed from 2 to 1 to prevent overflow
                            overflow: TextOverflow.ellipsis, // ✅ Adds "..."
                          ),
                          
                          // Points badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7B2CBF),
                                  Color(0xFFE91E63),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF7B2CBF).withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${reward.pointsCost} pkt', // Shortened text slightly
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Corner accent
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE91E63).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
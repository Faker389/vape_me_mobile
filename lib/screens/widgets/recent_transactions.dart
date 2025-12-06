import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vape_me/utils/hive_storage.dart';

import '../../providers/user_provider.dart';
import '../../models/transaction_model.dart';
import '../../utils/theme.dart';
import '../../screens/profile/points_history_screen.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ostatnie zakupy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PointsHistoryScreen(),
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
        
        Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryPurple,
                  ),
                ),
              );
            }

            final recentTransactions = UserStorage.getUser()?.transactions!.take(3).toList()??[];

            if (recentTransactions.isEmpty) {
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
                        Icons.receipt_long,
                        size: 48,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Brak transakcji',
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

            return Column(
              children: recentTransactions.map((transaction) {
                return _buildTransactionItem(transaction);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isEarned = transaction.type == TransactionType.earn;
    final dateFormat = DateFormat('dd MMM, HH:mm');
    final productImage = transaction.imageUrl!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (isEarned ? AppTheme.accentGreen : AppTheme.primaryPink)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CachedNetworkImage(
                          imageUrl: productImage,
                          fit: BoxFit.fill,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(
                              Icons.image,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(transaction.timestamp),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isEarned ? '+' : '-'}${transaction.points}',
                style: TextStyle(
                  color: isEarned ? AppTheme.accentGreen : AppTheme.primaryPink,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'pkt.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

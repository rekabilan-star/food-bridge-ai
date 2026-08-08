import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DonorBadgesCard extends StatelessWidget {
  final int totalMeals;

  const DonorBadgesCard({super.key, required this.totalMeals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.military_tech_rounded, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Donor Achievements & Badges",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    Text(
                      "Earn badges by listing & sharing surplus food",
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadgeItem("Hunger Hero", Icons.verified_rounded, Colors.purple, true),
              _buildBadgeItem("Zero Waste", Icons.eco_rounded, Colors.green, true),
              _buildBadgeItem("50+ Rescued", Icons.workspace_premium_rounded, Colors.amber, totalMeals >= 50),
              _buildBadgeItem("Legend", Icons.stars_rounded, Colors.blue, totalMeals >= 200),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(String label, IconData icon, Color color, bool unlocked) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: unlocked ? color.withValues(alpha: 0.12) : Colors.grey[100],
            shape: BoxShape.circle,
            border: Border.all(
              color: unlocked ? color : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: unlocked ? color : Colors.grey[400],
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: unlocked ? AppColors.textPrimary : Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

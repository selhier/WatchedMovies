import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Rating selector widget (1-10 scale) with interactive dots
class RatingWidget extends StatelessWidget {
  final int? currentRating;
  final ValueChanged<int> onRatingChanged;
  final bool readOnly;
  final double size;

  const RatingWidget({
    super.key,
    this.currentRating,
    required this.onRatingChanged,
    this.readOnly = false,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score display
        if (currentRating != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  currentRating.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.scoreColor(currentRating!),
                  ),
                ),
                const Text(
                  '/10',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _ratingLabel(currentRating!),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.scoreColor(currentRating!),
                  ),
                ),
              ],
            ),
          ),

        // Rating dots
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(10, (index) {
            final value = index + 1;
            final isSelected = currentRating != null && value <= currentRating!;

            return GestureDetector(
              onTap: readOnly ? null : () => onRatingChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? _dotColor(value)
                      : AppColors.surfaceLight,
                  border: Border.all(
                    color: isSelected
                        ? _dotColor(value)
                        : AppColors.divider,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _dotColor(value).withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _dotColor(int value) {
    if (value >= 8) return AppColors.ratingHigh;
    if (value >= 5) return AppColors.ratingMedium;
    return AppColors.ratingLow;
  }

  String _ratingLabel(int score) {
    switch (score) {
      case 10:
        return 'Masterpiece';
      case 9:
        return 'Excellent';
      case 8:
        return 'Great';
      case 7:
        return 'Very Good';
      case 6:
        return 'Good';
      case 5:
        return 'Average';
      case 4:
        return 'Below Avg';
      case 3:
        return 'Poor';
      case 2:
        return 'Bad';
      case 1:
        return 'Terrible';
      default:
        return '';
    }
  }
}

/// Compact inline rating badge (read-only)
class RatingBadge extends StatelessWidget {
  final int score;
  final double fontSize;

  const RatingBadge({
    super.key,
    required this.score,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.scoreColor(score).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.scoreColor(score).withOpacity(0.3),
        ),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.scoreColor(score),
        ),
      ),
    );
  }
}

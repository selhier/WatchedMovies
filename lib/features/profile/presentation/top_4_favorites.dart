import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/movie_entry.dart';
import '../../../core/models/user_profile.dart';
import '../data/user_profile_repository.dart';
import 'top_4_selection_sheet.dart';

class Top4Favorites extends ConsumerWidget {
  final UserProfile profile;
  final List<MovieEntry> allEntries;

  const Top4Favorites({
    super.key,
    required this.profile,
    required this.allEntries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Map IDs to actual movie entries if available
    final top4Entries = profile.top4MovieIds.map((id) {
      try {
        return allEntries.firstWhere((e) => e.tmdbId == id);
      } catch (_) {
        return null;
      }
    }).toList();

    // Pad to always have 4 slots
    while (top4Entries.length < 4) {
      top4Entries.add(null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top 4 Favorites',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => Top4SelectionSheet(
                    uid: profile.uid,
                    currentTop4: profile.top4MovieIds,
                    allEntries: allEntries,
                  ),
                );
              },
              child: const Text(
                'Edit',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            final entry = top4Entries[index];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 3 ? 8.0 : 0),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: entry?.posterPath != null
                        ? CachedNetworkImage(
                            imageUrl: ApiConstants.imageUrl(entry!.posterPath!),
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(Icons.add_rounded, color: AppColors.textTertiary),
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
}

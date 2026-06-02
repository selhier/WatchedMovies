import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../my_lists/data/list_repository.dart';
import '../data/shared_list_repository.dart';

/// Screen to create a new shared recommendation list
class CreateSharedListScreen extends ConsumerStatefulWidget {
  final SharedList? existingList;
  const CreateSharedListScreen({super.key, this.existingList});

  @override
  ConsumerState<CreateSharedListScreen> createState() =>
      _CreateSharedListScreenState();
}

class _CreateSharedListScreenState
    extends ConsumerState<CreateSharedListScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final Set<int> _selectedMovieIds = {};
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingList != null) {
      _titleController.text = widget.existingList!.title;
      _descController.text = widget.existingList!.description;
      _selectedMovieIds.addAll(widget.existingList!.movieIds);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(movieEntriesStreamProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.existingList == null ? 'Create Shared List' : 'Edit Shared List'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'List title...',
                hintStyle: TextStyle(color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descController,
              style: const TextStyle(color: AppColors.textSecondary),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Description (optional)...',
                hintStyle: TextStyle(color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 24),

            // Select movies
            const Text(
              'Select Movies',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            entries.when(
              data: (movieEntries) {
                if (movieEntries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Add movies to your list first!',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  );
                }

                return Column(
                  children: movieEntries.map((entry) {
                    final isSelected =
                        _selectedMovieIds.contains(entry.tmdbId);
                    return Card(
                      color: isSelected
                          ? AppColors.primarySurface
                          : AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.divider,
                        ),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (_) {
                            setState(() {
                              if (isSelected) {
                                _selectedMovieIds.remove(entry.tmdbId);
                              } else {
                                _selectedMovieIds.add(entry.tmdbId);
                              }
                            });
                          },
                          activeColor: AppColors.primary,
                          checkColor: AppColors.textOnPrimary,
                        ),
                        title: Text(
                          entry.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${entry.status.icon} ${entry.status.label}${entry.score != null ? ' • ${entry.score}/10' : ''}',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMovieIds.remove(entry.tmdbId);
                            } else {
                              _selectedMovieIds.add(entry.tmdbId);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const Text('Error loading your movies',
                  style: TextStyle(color: AppColors.textTertiary)),
            ),

            const SizedBox(height: 24),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isCreating ||
                        _titleController.text.isEmpty ||
                        _selectedMovieIds.isEmpty
                    ? null
                    : () => _createList(user),
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(_isCreating
                    ? 'Saving...'
                    : (widget.existingList == null
                        ? 'Create & Share (${_selectedMovieIds.length} movies)'
                        : 'Save Changes (${_selectedMovieIds.length} movies)')),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _createList(dynamic user) async {
    if (user == null) return;
    setState(() => _isCreating = true);

    try {
      if (widget.existingList != null) {
        await ref
            .read(sharedListRepositoryProvider)
            .updateList(
              widget.existingList!.id,
              title: _titleController.text,
              description: _descController.text,
              movieIds: _selectedMovieIds.toList(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shared list updated!')),
          );
          context.pop();
        }
      } else {
        await ref
            .read(sharedListRepositoryProvider)
            .createList(
              ownerId: user.uid,
              ownerName: user.displayName ?? 'Anonymous',
              title: _titleController.text,
              description: _descController.text,
              movieIds: _selectedMovieIds.toList(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shared list created!')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}

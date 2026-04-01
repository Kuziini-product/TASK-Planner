import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/kuziini_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../tasks/presentation/widgets/task_card.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
        ),
        title: KuziiniTextField(
          controller: _searchController,
          focusNode: _focusNode,
          hint: 'Search tasks...',
          prefixIcon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
          suffixIcon: query.isNotEmpty
              ? PhosphorIcons.x(PhosphorIconsStyle.regular)
              : null,
          onSuffixTap: () {
            _searchController.clear();
            ref.read(searchQueryProvider.notifier).state = '';
          },
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              final current = ref.read(recentSearchesProvider);
              if (!current.contains(value.trim())) {
                ref.read(recentSearchesProvider.notifier).state = [
                  value.trim(),
                  ...current.take(9),
                ];
              }
            }
          },
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppSpacing.radiusFull,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        titleSpacing: 0,
      ),
      body: query.isEmpty
          ? _buildRecentSearches(context, recentSearches)
          : resultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return EmptyState.search();
                }

                return ListView.builder(
                  padding: AppSpacing.paddingLg,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    return TaskCard(
                      task: results[index],
                      animationIndex: index,
                      showDate: true,
                    );
                  },
                );
              },
              loading: () =>
                  const LoadingIndicator(message: 'Searching...'),
              error: (error, _) => Center(
                child: Text('Error: $error'),
              ),
            ),
    );
  }

  Widget _buildRecentSearches(
      BuildContext context, List<String> recentSearches) {
    final theme = Theme.of(context);

    if (recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.light),
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            AppSpacing.vGapLg,
            Text(
              'Search for tasks',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
      );
    }

    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(recentSearchesProvider.notifier).state = [];
              },
              child: const Text('Clear'),
            ),
          ],
        ),
        ...recentSearches.map(
          (search) => ListTile(
            leading: Icon(
              PhosphorIcons.clockCounterClockwise(
                  PhosphorIconsStyle.regular),
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(search),
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () {
              _searchController.text = search;
              ref.read(searchQueryProvider.notifier).state = search;
            },
            trailing: IconButton(
              onPressed: () {
                final current = ref.read(recentSearchesProvider);
                ref.read(recentSearchesProvider.notifier).state =
                    current.where((s) => s != search).toList();
              },
              icon: Icon(
                PhosphorIcons.x(PhosphorIconsStyle.regular),
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

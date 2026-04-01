import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/data/task_repository.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsNotifier, List<TaskModel>>(
  SearchResultsNotifier.new,
);

class SearchResultsNotifier extends AsyncNotifier<List<TaskModel>> {
  Timer? _debounceTimer;

  @override
  Future<List<TaskModel>> build() async {
    final query = ref.watch(searchQueryProvider);

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    if (query.trim().isEmpty) {
      return [];
    }

    // Debounce search
    final completer = Completer<List<TaskModel>>();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () async {
        try {
          final repo = TaskRepository();
          final results = await repo.searchTasks(query.trim());
          if (!completer.isCompleted) {
            completer.complete(results);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
    );

    return completer.future;
  }
}

final recentSearchesProvider = StateProvider<List<String>>((ref) => []);

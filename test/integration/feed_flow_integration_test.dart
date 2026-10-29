import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bok_mai_mobile/features/feed/models/incident_model.dart';
import 'package:bok_mai_mobile/features/feed/providers/feed_provider.dart';

void main() {
  group('Integration Tests: Feed Provider & Incident Upvote Flow', () {
    test('StateNotifier toggles upvote and updates count reactively', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify initial state
      final initialList = container.read(incidentFeedProvider);
      expect(initialList, isNotEmpty);
      final first = initialList.first;
      final initialCount = first.upvoteCount;
      final initialVoted = first.hasUpvoted;

      // Trigger Upvote
      container.read(incidentFeedProvider.notifier).toggleUpvote(first.id);

      // Verify updated state
      final updatedList = container.read(incidentFeedProvider);
      final updatedFirst = updatedList.firstWhere((i) => i.id == first.id);

      expect(updatedFirst.hasUpvoted, !initialVoted);
      expect(
        updatedFirst.upvoteCount,
        initialVoted ? initialCount - 1 : initialCount + 1,
      );

      // Trigger Toggle back
      container.read(incidentFeedProvider.notifier).toggleUpvote(first.id);
      final revertedList = container.read(incidentFeedProvider);
      final revertedFirst = revertedList.firstWhere((i) => i.id == first.id);
      expect(revertedFirst.hasUpvoted, initialVoted);
      expect(revertedFirst.upvoteCount, initialCount);
    });

    test('Filter provider switches categories correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedCategoryFilterProvider), isNull);

      container.read(selectedCategoryFilterProvider.notifier).state =
          IncidentCategory.electricity;
      expect(
        container.read(selectedCategoryFilterProvider),
        IncidentCategory.electricity,
      );

      container.read(selectedCategoryFilterProvider.notifier).state = null;
      expect(container.read(selectedCategoryFilterProvider), isNull);
    });
  });
}

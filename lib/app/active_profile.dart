import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which CV the page is currently telling: the Flutter one or the AI one.
/// Stored as an index into `PortfolioData.profiles`.
class ActiveProfileController extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
  void cycle(int count) => state = count == 0 ? 0 : (state + 1) % count;
}

final activeProfileProvider =
    NotifierProvider<ActiveProfileController, int>(ActiveProfileController.new);

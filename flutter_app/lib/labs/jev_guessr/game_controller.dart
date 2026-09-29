import 'dart:math';
import 'package:flutter/foundation.dart';
import 'domain.dart';
import 'provider.dart';

/// One evaluated attempt in the current round, kept for the UI timeline.
class AttemptRecord {
  final String description;
  final GameStatus status;
  final GuessObject choice;
  final double probability;
  const AttemptRecord(
      this.description, this.status, this.choice, this.probability);
}

class GameController extends ChangeNotifier {
  final SemanticDecisionProvider provider;
  final Random random;
  GuessCategory category = GuessCategory.fruit;
  late GuessObject target;
  GameStatus status = GameStatus.ready;
  int attempts = 0;
  int points = 0;
  String? message;
  GuessState? sentState;
  SemanticDecision? decision;
  int? totalLatencyMs;

  /// Session-only tallies; never transported.
  int sessionScore = 0;
  int roundsWon = 0;
  int streak = 0;
  final List<AttemptRecord> history = [];
  bool _disposed = false;
  GameController(this.provider, {Random? random})
      : random = random ?? Random() {
    target = category.pick(this.random);
  }
  void nextRound([GuessCategory? newCategory]) {
    if (status == GameStatus.evaluating) return;
    // Skipping an unsolved round that already had evaluated attempts breaks
    // the streak; switching category on a fresh round does not.
    if (status != GameStatus.success && attempts > 0) streak = 0;
    category = newCategory ?? category;
    // Never serve the same word twice in a row.
    final options = category.targets.where((t) => t != target).toList();
    target = options[random.nextInt(options.length)];
    history.clear();
    status = GameStatus.ready;
    attempts = 0;
    points = 0;
    message = null;
    decision = null;
    sentState = null;
    totalLatencyMs = null;
    notifyListeners();
  }

  Future<void> submit(String description) async {
    if (status == GameStatus.evaluating || status == GameStatus.success) return;
    message = GamePolicy.validate(description, target);
    decision = null;
    sentState = null;
    totalLatencyMs = null;
    if (message != null) {
      status = GameStatus.invalidDescription;
      notifyListeners();
      return;
    }
    sentState = GuessState(category, description.trim());
    status = GameStatus.evaluating;
    notifyListeners();
    final timer = Stopwatch()..start();
    try {
      final result = await provider.evaluate(sentState!);
      if (_disposed) return;
      decision = result;
      attempts++;
      status = GamePolicy.decide(result, target);
      points = status == GameStatus.success
          ? GamePolicy.points(result, attempts, sentState!.description.length)
          : 0;
      if (status == GameStatus.success) {
        sessionScore += points;
        roundsWon++;
        streak++;
      }
      history.add(AttemptRecord(sentState!.description, status,
          result.identity.choice, result.identity.probability));
    } catch (error) {
      if (_disposed) return;
      status = GameStatus.upstreamFailure;
      message = error is DecisionFailure
          ? error.message
          : 'The decision service is unavailable. Please retry.';
    }
    totalLatencyMs = timer.elapsedMilliseconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    provider.dispose();
    super.dispose();
  }
}

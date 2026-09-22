import 'dart:math';
import 'package:flutter/foundation.dart';
import 'domain.dart';
import 'provider.dart';

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
  bool _disposed = false;
  GameController(this.provider, {Random? random})
      : random = random ?? Random() {
    target = category.pick(this.random);
  }
  void nextRound([GuessCategory? newCategory]) {
    if (status == GameStatus.evaluating) return;
    category = newCategory ?? category;
    target = category.pick(random);
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

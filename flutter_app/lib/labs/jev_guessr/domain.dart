import 'dart:math';

enum GuessCategory { fruit, animal }

enum GuessObject { apple, pear, orange, banana, dog, cat, rabbit, horse, other }

extension GuessCategoryObjects on GuessCategory {
  List<GuessObject> get targets => switch (this) {
        GuessCategory.fruit => const [
            GuessObject.apple,
            GuessObject.pear,
            GuessObject.orange,
            GuessObject.banana
          ],
        GuessCategory.animal => const [
            GuessObject.dog,
            GuessObject.cat,
            GuessObject.rabbit,
            GuessObject.horse
          ],
      };
  GuessObject pick(Random random) => targets[random.nextInt(targets.length)];
}

class GuessState {
  final GuessCategory category;
  final String description;
  const GuessState(this.category, this.description);
  Map<String, String> toJson() =>
      {'category': category.name.toUpperCase(), 'description': description};
}

class ChoiceDecision {
  final GuessObject choice;
  final Map<GuessObject, double> probabilities;
  final double? confidence;
  ChoiceDecision(this.choice, Map<GuessObject, double> probabilities,
      {this.confidence})
      : probabilities = Map.unmodifiable(probabilities);
  double get probability => probabilities[choice]!;
}

class NoulDecision {
  final double probability;
  const NoulDecision(this.probability);
}

class ScoreDecision {
  final double score;
  final double? confidence;
  final Map<int, double>? probabilities;
  ScoreDecision(this.score, {this.confidence, Map<int, double>? probabilities})
      : probabilities =
            probabilities == null ? null : Map.unmodifiable(probabilities);
}

class SemanticDecision {
  final ChoiceDecision identity;
  final NoulDecision sufficiency;
  final ScoreDecision ambiguity;
  final String? model;
  final int? apiLatencyMs;
  const SemanticDecision(this.identity, this.sufficiency, this.ambiguity,
      {this.model, this.apiLatencyMs});
}

enum GameStatus {
  ready,
  evaluating,
  success,
  invalidDescription,
  insufficientDescription,
  modelUncertain,
  incorrectGuess,
  upstreamFailure
}

class GamePolicy {
  static const maxLength = 500;
  static const choiceThreshold = 0.80;
  static const sufficiencyThreshold = 0.80;
  static String normalized(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  static String? validate(String description, GuessObject target) {
    if (description.trim().isEmpty) return 'Add a description first.';
    if (description.length > maxLength) {
      return 'Use at most $maxLength characters.';
    }
    if (RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(description)) {
      return 'Remove control characters.';
    }
    if (normalized(description).contains(target.name)) {
      return 'Describe it without using the target word.';
    }
    return null;
  }

  static GameStatus decide(SemanticDecision d, GuessObject target) {
    if (d.sufficiency.probability < sufficiencyThreshold) {
      return GameStatus.insufficientDescription;
    }
    if (d.identity.probability < choiceThreshold) {
      return GameStatus.modelUncertain;
    }
    if (d.identity.choice == GuessObject.other || d.identity.choice != target) {
      return GameStatus.incorrectGuess;
    }
    return GameStatus.success;
  }

  static int points(SemanticDecision d, int attempts, int length) => (1000 -
          (attempts - 1) * 100 -
          d.ambiguity.score * 100 -
          max(0, length - 120))
      .round()
      .clamp(100, 1000);
}

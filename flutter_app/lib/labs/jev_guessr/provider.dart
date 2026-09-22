import 'dart:convert';
import 'package:http/http.dart' as http;
import 'domain.dart';

abstract interface class SemanticDecisionProvider {
  Future<SemanticDecision> evaluate(GuessState state);
  void dispose();
}

class DecisionFailure implements Exception {
  final String message;
  const DecisionFailure(
      [this.message = 'The decision service is unavailable. Please retry.']);
}

class JevSemanticDecisionProvider implements SemanticDecisionProvider {
  final http.Client _client;
  final Uri endpoint;
  JevSemanticDecisionProvider({http.Client? client, Uri? endpoint})
      : _client = client ?? http.Client(),
        endpoint = endpoint ?? Uri.base.resolve('/api/jev-guessr');

  @override
  Future<SemanticDecision> evaluate(GuessState state) async {
    try {
      final response = await _client
          .post(endpoint,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(state.toJson()))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 429) {
        throw const DecisionFailure(
            'Too many requests. Wait a moment, then retry.');
      }
      if (response.statusCode != 200) throw const DecisionFailure();
      return mapDecision(
          jsonDecode(response.body) as Map<String, dynamic>, state.category);
    } on DecisionFailure {
      rethrow;
    } catch (_) {
      throw const DecisionFailure();
    }
  }

  @override
  void dispose() => _client.close();
}

double _bounded(dynamic value, [double max = 1]) {
  if (value is! num || !value.isFinite || value < 0 || value > max) {
    throw const FormatException('Invalid number');
  }
  return value.toDouble();
}

Map<String, double> _distribution(dynamic value, List<String> keys) {
  final map = value as Map<String, dynamic>;
  if (map.length != keys.length || !keys.every(map.containsKey)) {
    throw const FormatException('Invalid options');
  }
  final result = map.map((k, v) => MapEntry(k, _bounded(v)));
  if ((result.values.fold(0.0, (a, b) => a + b) - 1).abs() > .02) {
    throw const FormatException('Invalid distribution');
  }
  return result;
}

SemanticDecision mapDecision(
    Map<String, dynamic> json, GuessCategory category) {
  final c = json['identity'] as Map<String, dynamic>;
  final n = json['sufficiency'] as Map<String, dynamic>;
  final s = json['ambiguity'] as Map<String, dynamic>;
  final options = [...category.targets, GuessObject.other];
  final probabilities = _distribution(
      c['probabilities'], options.map((x) => x.name.toUpperCase()).toList());
  final choice = options.firstWhere((x) => x.name.toUpperCase() == c['choice']);
  final selected = probabilities[c['choice']]!;
  if (selected != _bounded(c['probability']) ||
      probabilities.values.any((p) => p > selected)) {
    throw const FormatException('Invalid choice');
  }
  final model = json['model'];
  final latency = json['apiLatencyMs'];
  if (model is! String ||
      !RegExp(r'^jev-[a-zA-Z0-9._-]{1,64}$').hasMatch(model) ||
      latency is! int ||
      latency < 0) {
    throw const FormatException('Invalid metadata');
  }
  return SemanticDecision(
    ChoiceDecision(choice,
        {for (final o in options) o: probabilities[o.name.toUpperCase()]!},
        confidence: c['confidence'] == null ? null : _bounded(c['confidence'])),
    NoulDecision(_bounded(n['probability'])),
    ScoreDecision(_bounded(s['score'], 3),
        confidence: s['confidence'] == null ? null : _bounded(s['confidence']),
        probabilities: s['probabilities'] == null
            ? null
            : _distribution(s['probabilities'], ['0', '1', '2', '3'])
                .map((k, v) => MapEntry(int.parse(k), v))),
    model: model,
    apiLatencyMs: latency,
  );
}

/// Deliberately synthetic fixtures, never presented as model inference.
class MockSemanticDecisionProvider implements SemanticDecisionProvider {
  static const clues = {
    GuessObject.apple: 'pie',
    GuessObject.pear: 'bell',
    GuessObject.orange: 'citrus',
    GuessObject.banana: 'peel',
    GuessObject.dog: 'bark',
    GuessObject.cat: 'purr',
    GuessObject.rabbit: 'hop',
    GuessObject.horse: 'hoof',
  };
  @override
  Future<SemanticDecision> evaluate(GuessState state) async {
    final matches = state.category.targets
        .where((o) => state.description.toLowerCase().contains(clues[o]!))
        .toList();
    final clear = matches.length == 1;
    final choice = clear ? matches.single : GuessObject.other;
    final options = [...state.category.targets, GuessObject.other];
    return SemanticDecision(
        ChoiceDecision(choice, {
          for (final o in options) o: clear ? (o == choice ? .92 : .02) : .2
        }),
        NoulDecision(clear ? .95 : .25),
        ScoreDecision(clear ? .2 : 3));
  }

  @override
  void dispose() {}
}

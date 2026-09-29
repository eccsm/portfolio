import 'dart:convert';
import 'package:http/http.dart' as http;
import 'domain.dart';

abstract interface class SemanticDecisionProvider {
  Future<SemanticDecision> evaluate(GuessState state);
  void dispose();
}

/// Implemented by providers backed by a metered service.
abstract interface class QuotaSource {
  Future<DailyQuota?> fetchQuota();
}

class DecisionFailure implements Exception {
  final String message;

  /// Set when the failure is a quota refusal rather than an outage.
  final DailyQuota? quota;
  final bool limitReached;
  const DecisionFailure(
      [this.message = 'The decision service is unavailable. Please retry.',
      this.quota,
      this.limitReached = false]);
}

DailyQuota? parseQuota(dynamic json) {
  if (json is! Map<String, dynamic>) return null;
  final limit = json['limit'], remaining = json['remaining'];
  final resetAt = json['resetAt'];
  if (limit is! int || remaining is! int || limit < 0 || remaining < 0) {
    return null;
  }
  return DailyQuota(
      limit,
      remaining,
      resetAt is int
          ? DateTime.fromMillisecondsSinceEpoch(resetAt, isUtc: true)
          : null);
}

class JevSemanticDecisionProvider
    implements SemanticDecisionProvider, QuotaSource {
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
        final body = _tryJson(response.body);
        final quota = parseQuota(body?['quota']);
        switch (body?['error']) {
          case 'dailyLimit':
            throw DecisionFailure(
                'You have used all ${quota?.limit ?? ''} live guesses for now.',
                quota,
                true);
          case 'busy':
            throw DecisionFailure(
                'Jev has reached its daily budget for all visitors. Try again tomorrow.',
                quota,
                true);
        }
        throw const DecisionFailure(
            'Too many requests. Wait a moment, then retry.');
      }
      if (response.statusCode != 200) throw const DecisionFailure();
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return mapDecision(json, state.category,
          quota: parseQuota(json['quota']));
    } on DecisionFailure {
      rethrow;
    } catch (_) {
      throw const DecisionFailure();
    }
  }

  @override
  Future<DailyQuota?> fetchQuota() async {
    try {
      final response =
          await _client.get(endpoint).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return parseQuota(_tryJson(response.body)?['quota']);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() => _client.close();
}

Map<String, dynamic>? _tryJson(String body) {
  try {
    final value = jsonDecode(body);
    return value is Map<String, dynamic> ? value : null;
  } catch (_) {
    return null;
  }
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

SemanticDecision mapDecision(Map<String, dynamic> json, GuessCategory category,
    {DailyQuota? quota}) {
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
    quota: quota,
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

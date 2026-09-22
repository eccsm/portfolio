import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cc_resume_app/labs/lab_registry.dart';
import 'package:cc_resume_app/labs/jev_guessr/domain.dart';
import 'package:cc_resume_app/labs/jev_guessr/game_controller.dart';
import 'package:cc_resume_app/labs/jev_guessr/provider.dart';
import 'package:cc_resume_app/labs/jev_guessr/jev_guessr_page.dart';

SemanticDecision decision(
        {GuessObject choice = GuessObject.apple,
        double probability = .9,
        double sufficient = .9,
        double ambiguity = 0}) =>
    SemanticDecision(ChoiceDecision(choice, {choice: probability}),
        NoulDecision(sufficient), ScoreDecision(ambiguity));

class PendingProvider implements SemanticDecisionProvider {
  final completer = Completer<SemanticDecision>();
  int calls = 0;
  @override
  Future<SemanticDecision> evaluate(GuessState state) {
    calls++;
    return completer.future;
  }

  @override
  void dispose() {}
}

void main() {
  test('normalization detects direct words and obvious punctuation', () {
    for (final input in [
      ' APPLE ',
      'a.p.p.l.e',
      'ApPlE!',
      'apples',
      'a p p l e'
    ]) {
      expect(GamePolicy.validate(input, GuessObject.apple), isNotNull);
    }
    expect(GamePolicy.validate('red fruit used in pies', GuessObject.apple),
        isNull);
    expect(GamePolicy.validate(' ', GuessObject.apple), isNotNull);
    expect(GamePolicy.validate('a' * 501, GuessObject.apple), isNotNull);
  });
  test('target generation covers only category objects, never OTHER', () {
    for (final category in GuessCategory.values) {
      final rng = Random(42);
      final picks = List.generate(200, (_) => category.pick(rng)).toSet();
      expect(picks, category.targets.toSet());
    }
  });
  test('application thresholds, mismatch, OTHER and scoring', () {
    expect(
        GamePolicy.decide(
            decision(probability: .8, sufficient: .8), GuessObject.apple),
        GameStatus.success);
    expect(GamePolicy.decide(decision(probability: .799), GuessObject.apple),
        GameStatus.modelUncertain);
    expect(GamePolicy.decide(decision(sufficient: .799), GuessObject.apple),
        GameStatus.insufficientDescription);
    expect(
        GamePolicy.decide(
            decision(choice: GuessObject.other), GuessObject.apple),
        GameStatus.incorrectGuess);
    expect(
        GamePolicy.decide(
            decision(choice: GuessObject.pear), GuessObject.apple),
        GameStatus.incorrectGuess);
    expect(GamePolicy.points(decision(), 1, 80), 1000);
    expect(GamePolicy.points(decision(ambiguity: 1), 2, 140), 780);
    expect(GamePolicy.points(decision(ambiguity: 3), 20, 500), 100);
  });
  test('feature flag removes navigation and invalid providers fail closed', () {
    for (final config in [
      const LabConfig(enableJev: false),
      const LabConfig(enableJev: true, provider: 'invalid')
    ]) {
      expect(
          labRegistry((_) => const SizedBox(), config: config).map((e) => e.id),
          ['local-intelligence']);
    }
    expect(
        labRegistry((_) => const SizedBox(),
                config: const LabConfig(enableJev: true))
            .length,
        2);
  });
  test('controller validates before evaluation and blocks duplicate requests',
      () async {
    final provider = PendingProvider();
    final game = GameController(provider, random: Random(1));
    await game.submit(game.target.name);
    expect(provider.calls, 0);
    final pending = game.submit('a discriminating clue');
    final target = game.target;
    game.nextRound();
    await game.submit('another clue');
    expect(game.target, target);
    expect(provider.calls, 1);
    provider.completer.complete(decision(choice: target));
    await pending;
    expect(game.status, GameStatus.success);
    await game.submit('a further clue');
    expect(provider.calls, 1);
    expect(game.sentState!.toJson().keys, ['category', 'description']);
    game.dispose();
  });
  test('failure keeps target and allows retry without consuming attempt',
      () async {
    var calls = 0;
    final provider = JevSemanticDecisionProvider(
        endpoint: Uri.parse('https://example.test/api/jev-guessr'),
        client: MockClient((request) async {
          calls++;
          expect(jsonDecode(request.body).keys, ['category', 'description']);
          expect(request.headers.containsKey('Authorization'), false);
          return http.Response('private details', 502);
        }));
    final game = GameController(provider);
    final target = game.target;
    await game.submit('a descriptive clue');
    expect(game.status, GameStatus.upstreamFailure);
    expect(game.message, isNot(contains('private details')));
    await game.submit('a descriptive clue');
    expect(calls, 2);
    expect(game.target, target);
    expect(game.attempts, 0);
    game.dispose();
  });
  test('mock is deterministic and returns all category options', () async {
    final provider = MockSemanticDecisionProvider();
    final a = await provider
        .evaluate(const GuessState(GuessCategory.fruit, 'used in pie'));
    final b = await provider
        .evaluate(const GuessState(GuessCategory.fruit, 'used in pie'));
    expect(a.identity.probabilities, b.identity.probabilities);
    expect(a.identity.choice, GuessObject.apple);
    expect(a.model, isNull);
    expect(a.apiLatencyMs, isNull);
    expect(a.identity.probabilities.length, 5);
  });
  test('live transport maps a valid response and rejects corrupt probabilities',
      () async {
    final body = <String, dynamic>{
      'model': 'jev-1.13.0',
      'apiLatencyMs': 123,
      'identity': {
        'choice': 'APPLE',
        'probability': .92,
        'confidence': .9,
        'probabilities': {
          'APPLE': .92,
          'PEAR': .02,
          'ORANGE': .02,
          'BANANA': .02,
          'OTHER': .02
        }
      },
      'sufficiency': {'probability': .95},
      'ambiguity': {
        'score': .2,
        'confidence': .8,
        'probabilities': {'0': .8, '1': .2, '2': 0, '3': 0}
      },
    };
    final provider = JevSemanticDecisionProvider(
        endpoint: Uri.parse('https://example.test/api/jev-guessr'),
        client: MockClient((_) async => http.Response(jsonEncode(body), 200)));
    final decision = await provider
        .evaluate(const GuessState(GuessCategory.fruit, 'used in pie'));
    expect(decision.identity.choice, GuessObject.apple);
    expect(decision.identity.probability, .92);
    expect(decision.ambiguity.probabilities![0], .8);
    expect(decision.model, 'jev-1.13.0');
    (body['identity'] as Map<String, dynamic>)['probabilities']['APPLE'] = 2.0;
    await expectLater(
        provider.evaluate(const GuessState(GuessCategory.fruit, 'used in pie')),
        throwsA(isA<DecisionFailure>()));
    provider.dispose();
  });
  test('disposing a pending controller does not notify after disposal',
      () async {
    final provider = PendingProvider();
    final game = GameController(provider);
    final request = game.submit('a descriptive clue');
    game.dispose();
    provider.completer.complete(decision());
    await request;
  });
  testWidgets('registry builders navigate into both experiments',
      (tester) async {
    final experiments = labRegistry(
        (_) => const Scaffold(body: Text('Local experiment')),
        config: const LabConfig(enableJev: true));
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                    body: Column(
                  children: [
                    for (final e in experiments)
                      TextButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: e.builder)),
                          child: Text(e.id))
                  ],
                )))));
    await tester.tap(find.text('local-intelligence'));
    await tester.pumpAndSettle();
    expect(find.text('Local experiment'), findsOneWidget);
    Navigator.of(tester.element(find.text('Local experiment'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('jev-guessr'));
    await tester.pumpAndSettle();
    expect(find.text('Jev Guessr'), findsOneWidget);
  });
  testWidgets('mock UI validates, displays result and resets rounds',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: JevGuessrPage(mock: true)));
    expect(find.textContaining('MOCK MODE'), findsOneWidget);
    await tester.tap(find.text('Let Jev Guess'));
    await tester.pump();
    expect(find.text('Add a description first.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'used in pie');
    await tester.tap(find.text('Let Jev Guess'));
    await tester.pumpAndSettle();
    expect(find.text('SYNTHETIC DECISION'), findsOneWidget);
    await tester.tap(find.text('Next Round'));
    await tester.pump();
    expect(find.text('SYNTHETIC DECISION'), findsNothing);
  });
}

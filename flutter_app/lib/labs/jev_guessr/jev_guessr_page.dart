import 'dart:convert';
import 'package:flutter/material.dart';
import 'domain.dart';
import 'game_controller.dart';
import 'provider.dart';

class JevGuessrPage extends StatefulWidget {
  final bool mock;
  const JevGuessrPage({super.key, required this.mock});
  @override
  State<JevGuessrPage> createState() => _JevGuessrPageState();
}

class _JevGuessrPageState extends State<JevGuessrPage> {
  late final game = GameController(widget.mock
      ? MockSemanticDecisionProvider()
      : JevSemanticDecisionProvider());
  final input = TextEditingController();
  @override
  void dispose() {
    game.dispose();
    input.dispose();
    super.dispose();
  }

  String get resultText =>
      game.message ??
      switch (game.status) {
        GameStatus.ready => 'Describe it without using the word itself.',
        GameStatus.evaluating =>
          'Evaluating three independent semantic questions…',
        GameStatus.success => 'Correct! Round score: ${game.points}',
        GameStatus.insufficientDescription =>
          'Add a more discriminating clue, then try again.',
        GameStatus.modelUncertain =>
          'The decision is uncertain. Try a more specific clue.',
        GameStatus.incorrectGuess =>
          'The description points elsewhere. Refine it and try again.',
        _ => 'Please retry.',
      };
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Jev Guessr')),
        body: ListenableBuilder(
            listenable: game,
            builder: (context, _) {
              final busy = game.status == GameStatus.evaluating;
              final d = game.decision;
              return Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text('A Real-Time Semantic Decision Game',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 12),
                          Text(widget.mock
                              ? 'MOCK MODE · Synthetic fixtures, no AI requests.'
                              : 'LIVE · Your description is sent to TypeSafe for evaluation. Avoid personal information.'),
                          if (widget.mock)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                    'Fixture clues: pie, bell, citrus, peel · bark, purr, hop, hoof. Other descriptions produce uncertainty.')),
                          const SizedBox(height: 20),
                          Wrap(spacing: 12, children: [
                            for (final c in GuessCategory.values)
                              ChoiceChip(
                                label: Text(
                                    c.name == 'fruit' ? 'Fruits' : 'Animals'),
                                selected: game.category == c,
                                onSelected: busy
                                    ? null
                                    : (_) {
                                        game.nextRound(c);
                                        input.clear();
                                      },
                              )
                          ]),
                          const SizedBox(height: 20),
                          const Text('Secret target · stays in your browser'),
                          Text(game.target.name.toUpperCase(),
                              style: Theme.of(context).textTheme.headlineLarge),
                          const SizedBox(height: 12),
                          TextField(
                              controller: input,
                              enabled:
                                  !busy && game.status != GameStatus.success,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: GamePolicy.maxLength,
                              decoration: const InputDecoration(
                                  labelText: 'Your description',
                                  border: OutlineInputBorder())),
                          const SizedBox(height: 12),
                          Wrap(spacing: 12, runSpacing: 12, children: [
                            FilledButton(
                                style: FilledButton.styleFrom(
                                    foregroundColor: Colors.black87),
                                onPressed:
                                    busy || game.status == GameStatus.success
                                        ? null
                                        : () => game.submit(input.text),
                                child: Text(
                                    game.status == GameStatus.upstreamFailure
                                        ? 'Retry'
                                        : 'Let Jev Guess')),
                            OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                                onPressed: busy
                                    ? null
                                    : () {
                                        game.nextRound();
                                        input.clear();
                                      },
                                child: const Text('Next Round')),
                          ]),
                          const SizedBox(height: 16),
                          if (busy) const LinearProgressIndicator(),
                          Semantics(
                              liveRegion: true,
                              child: Text(resultText,
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                          Text('Evaluated attempts: ${game.attempts}'),
                          if (d != null) ...[
                            const SizedBox(height: 24),
                            Text(
                                widget.mock
                                    ? 'SYNTHETIC DECISION'
                                    : 'JEV DECISION',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            for (final entry
                                in d.identity.probabilities.entries)
                              _bar(entry.key.name.toUpperCase(), entry.value),
                            const SizedBox(height: 12),
                            Text(
                                'Description sufficient: ${(d.sufficiency.probability * 100).toStringAsFixed(1)}%'),
                            Text(
                                'Ambiguity: ${d.ambiguity.score.toStringAsFixed(2)} / 3 (0 = clear, 3 = extremely ambiguous)'),
                          ],
                          const SizedBox(height: 20),
                          ExpansionTile(
                              title: const Text('Developer view'),
                              childrenPadding: const EdgeInsets.all(12),
                              children: [
                                const Text(
                                    'Jev produces bounded semantic judgments. Flutter owns validation, thresholds, game state and final behavior. Choice, Noul and Score evaluate the same state independently.'),
                                const SizedBox(height: 12),
                                const Text(
                                    'STATE → Choice + Noul + Score → APPLICATION POLICY'),
                                if (game.sentState != null)
                                  SelectableText(
                                      const JsonEncoder.withIndent('  ')
                                          .convert(game.sentState!.toJson()))
                                else
                                  const Text(
                                      'No state sent. Validation runs before evaluation.'),
                                if (d != null) ...[
                                  Text(
                                      'Choice: ${d.identity.choice.name.toUpperCase()} · probability ${d.identity.probability}'),
                                  if (d.identity.confidence != null)
                                    Text(
                                        'Choice confidence: ${d.identity.confidence}'),
                                  Text(
                                      'Noul: descriptionSufficient = ${d.sufficiency.probability}'),
                                  Text(
                                      'Score: ambiguity = ${d.ambiguity.score}'),
                                  if (d.ambiguity.confidence != null)
                                    Text(
                                        'Score confidence: ${d.ambiguity.confidence}'),
                                  if (d.ambiguity.probabilities != null)
                                    for (final e
                                        in d.ambiguity.probabilities!.entries)
                                      _bar('Level ${e.key}', e.value),
                                  if (d.model != null)
                                    Text('Returned model: ${d.model}'),
                                  if (d.apiLatencyMs != null)
                                    Text(
                                        'API round-trip latency (server measured): ${d.apiLatencyMs} ms'),
                                ],
                                if (game.totalLatencyMs != null)
                                  Text(
                                      '${widget.mock ? 'Mock evaluation' : 'Total request'} latency: ${game.totalLatencyMs} ms'),
                                const Text(
                                    'Win: matching choice, choice probability ≥ ${GamePolicy.choiceThreshold}, sufficiency ≥ ${GamePolicy.sufficiencyThreshold}.'),
                                const Text(
                                    'Points on a win: 1000 − 100 per extra evaluated attempt − 100 × ambiguity − characters beyond 120; clamped to 100–1000. Invalid input and failed requests do not consume attempts.'),
                              ]),
                        ],
                      )));
            }),
      );
  Widget _bar(String label, double probability) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label  ${(probability * 100).toStringAsFixed(1)}%'),
        LinearProgressIndicator(
            value: probability,
            semanticsLabel: label,
            semanticsValue: (probability * 100).toStringAsFixed(1)),
      ]));
}

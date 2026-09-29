import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'domain.dart';
import 'game_controller.dart';
import 'jev_widgets.dart';
import 'provider.dart';

class JevGuessrPage extends StatefulWidget {
  final bool mock;
  final bool embedded;
  const JevGuessrPage({super.key, required this.mock, this.embedded = false});
  @override
  State<JevGuessrPage> createState() => _JevGuessrPageState();
}

class _JevGuessrPageState extends State<JevGuessrPage>
    with SingleTickerProviderStateMixin {
  late final game = GameController(widget.mock
      ? MockSemanticDecisionProvider()
      : JevSemanticDecisionProvider());
  final input = TextEditingController();

  /// Drives the pipeline glow; only runs while a request is in flight so
  /// idle pages (and pumpAndSettle in tests) settle.
  late final AnimationController pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  final inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    game.addListener(_syncPulse);
    // A global handler, because on web the text field's own shortcuts stop
    // Enter from ever reaching an ancestor Shortcuts widget.
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  bool _onKey(KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    if (event is KeyDownEvent &&
        inputFocus.hasFocus &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
        (keyboard.isControlPressed || keyboard.isMetaPressed)) {
      _submit();
      return true;
    }
    return false;
  }

  void _syncPulse() {
    if (game.status == GameStatus.evaluating) {
      if (!pulse.isAnimating) pulse.repeat();
    } else if (pulse.isAnimating) {
      pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    game.removeListener(_syncPulse);
    game.dispose();
    input.dispose();
    inputFocus.dispose();
    pulse.dispose();
    super.dispose();
  }

  String get resultText {
    if (game.status == GameStatus.limitReached) {
      final resetAt = game.quota?.resetAt;
      final base =
          game.message ?? 'You have used all your live guesses for now.';
      return resetAt == null
          ? base
          : '$base More in ${formatTimeUntil(resetAt)}.';
    }
    return _statusText;
  }

  String get _statusText =>
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

  bool get _busy => game.status == GameStatus.evaluating;
  bool get _canSubmit =>
      !_busy && game.status != GameStatus.success && !game.limitReached;

  void _submit() {
    if (_canSubmit) game.submit(input.text);
  }

  void _nextRound([GuessCategory? category]) {
    game.nextRound(category);
    input.clear();
  }

  void _appendClue(String clue) {
    final text = input.text.trimRight();
    input.text = text.isEmpty ? clue : '$text $clue';
    input.selection = TextSelection.collapsed(offset: input.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final content = ListenableBuilder(
      listenable: game,
      builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final play = _buildPlay(context);
        final insights = _buildInsights(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JevHeader(mock: widget.mock, showTitle: widget.embedded),
            const SizedBox(height: 20),
            ScoreStrip(game: game),
            const SizedBox(height: 16),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 11, child: play),
                  const SizedBox(width: 16),
                  Expanded(flex: 9, child: insights),
                ],
              )
            else ...[
              play,
              const SizedBox(height: 16),
              insights,
            ],
            const SizedBox(height: 12),
            _buildDeveloperView(context),
          ],
        );
      }),
    );

    if (widget.embedded) return _EmbeddedChrome(child: content);
    return Scaffold(
      appBar: AppBar(title: const Text('Jev Guessr')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlay(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final clues = widget.mock
        ? [
            for (final o in game.category.targets)
              MockSemanticDecisionProvider.clues[o]!
          ]
        : const <String>[];

    return JevPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('01 · CATEGORY', style: eyebrowStyle(context)),
              CategoryToggle(
                selected: game.category,
                onChanged: _busy ? null : _nextRound,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TargetCard(
            category: game.category,
            target: game.target,
            solved: game.status == GameStatus.success,
          ),
          const SizedBox(height: 20),
          Text('02 · DESCRIBE IT — WITHOUT SAYING IT',
              style: eyebrowStyle(context)),
          const SizedBox(height: 10),
          TextField(
            controller: input,
            focusNode: inputFocus,
            enabled: _canSubmit,
            minLines: 3,
            maxLines: 5,
            maxLength: GamePolicy.maxLength,
            style: TextStyle(fontSize: 15, height: 1.5, color: colors.text),
            decoration: InputDecoration(
              labelText: 'Your description',
              hintText: game.category == GuessCategory.fruit
                  ? 'e.g. Grows on trees, has a thin skin and a sweet core'
                  : 'e.g. A loyal companion that greets you at the door',
              hintStyle:
                  TextStyle(color: colors.textSecondary.withValues(alpha: 0.7)),
              filled: true,
              fillColor: colors.text.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryColor, width: 1.6)),
            ),
          ),
          // Live hint before the user spends an attempt.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: input,
            builder: (context, value, _) {
              final leaks =
                  GamePolicy.normalized(value.text).contains(game.target.name);
              return AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: leaks
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          const Icon(Icons.visibility_off_rounded,
                              size: 16, color: AppTheme.accentRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Your clue contains the secret word — rephrase it.',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.accentRed
                                        .withValues(alpha: 0.95))),
                          ),
                        ]),
                      )
                    : const SizedBox(width: double.infinity),
              );
            },
          ),
          if (clues.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Mock clues:',
                    style:
                        TextStyle(fontSize: 12, color: colors.textSecondary)),
                for (final clue in clues)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.add_rounded, size: 14),
                    label: Text(clue, style: const TextStyle(fontSize: 12)),
                    onPressed: _canSubmit ? () => _appendClue(clue) : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: colors.border),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (game.quota != null) ...[
            QuotaMeter(quota: game.quota!),
            const SizedBox(height: 14),
          ],
          if (!widget.mock) ...[
            Row(children: [
              Icon(Icons.shield_outlined,
                  size: 14, color: colors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    'Your description is sent to TypeSafe for evaluation. Avoid personal information.',
                    style:
                        TextStyle(fontSize: 12, color: colors.textSecondary)),
              ),
            ]),
            const SizedBox(height: 14),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GlowButton(
                label: game.status == GameStatus.upstreamFailure
                    ? 'Retry'
                    : 'Let Jev Guess',
                icon: game.status == GameStatus.upstreamFailure
                    ? Icons.refresh_rounded
                    : Icons.auto_awesome_rounded,
                busy: _busy,
                onPressed: _canSubmit ? _submit : null,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.text,
                  side: BorderSide(color: colors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _busy ? null : () => _nextRound(),
                icon: Icon(
                    game.status == GameStatus.success
                        ? Icons.arrow_forward_rounded
                        : Icons.shuffle_rounded,
                    size: 18),
                label: const Text('Next Round'),
              ),
              Text('Ctrl + Enter to submit',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: colors.textSecondary.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 16),
          StatusBanner(
              status: game.status, text: resultText, points: game.points),
        ],
      ),
    );
  }

  Widget _buildInsights(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final d = game.decision;
    return JevPanel(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (d == null) ...[
              Text('HOW JEV DECIDES', style: eyebrowStyle(context)),
              const SizedBox(height: 14),
              DecisionPipeline(pulse: pulse, active: _busy),
              const SizedBox(height: 16),
              Text(
                'Three independent semantic questions are asked about the same '
                'description in one request. Jev returns probabilities; '
                'deterministic Dart rules turn them into a verdict and a score.',
                style: TextStyle(
                    fontSize: 12.5, height: 1.55, color: colors.textSecondary),
              ),
            ] else ...[
              Row(children: [
                Icon(
                    widget.mock
                        ? Icons.science_outlined
                        : Icons.psychology_alt_rounded,
                    size: 16,
                    color: readable(context, AppTheme.primaryColor)),
                const SizedBox(width: 8),
                Text(widget.mock ? 'SYNTHETIC DECISION' : 'JEV DECISION',
                    style: eyebrowStyle(context, color: AppTheme.primaryColor)),
              ]),
              const SizedBox(height: 14),
              ProbabilityBars(identity: d.identity, target: game.target),
              const SizedBox(height: 6),
              Text(
                  'Marker = ${(GamePolicy.choiceThreshold * 100).round()}% '
                  'win threshold',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RadialGauge(
                    label: 'Sufficiency',
                    caption: 'enough info',
                    value: d.sufficiency.probability,
                    max: 1,
                    threshold: GamePolicy.sufficiencyThreshold,
                    format: (v) => '${(v * 100).round()}%',
                  ),
                  RadialGauge(
                    label: 'Ambiguity',
                    caption: 'out of 3',
                    value: d.ambiguity.score,
                    max: 3,
                    higherIsBetter: false,
                    format: (v) => v.toStringAsFixed(1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: colors.border),
              const SizedBox(height: 6),
              Text('POLICY CHECKS', style: eyebrowStyle(context)),
              const SizedBox(height: 6),
              PolicyChecklist(decision: d, target: game.target),
            ],
            if (game.history.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: colors.border),
              const SizedBox(height: 6),
              Text('THIS ROUND', style: eyebrowStyle(context)),
              const SizedBox(height: 6),
              AttemptTimeline(history: game.history),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperView(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final d = game.decision;
    final small = TextStyle(fontSize: 12.5, height: 1.5, color: colors.text);
    Widget kv(String k, Object v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 190,
                child: Text(k,
                    style: small.copyWith(color: colors.textSecondary))),
            Expanded(child: SelectableText('$v', style: small)),
          ]),
        );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: JevPanel(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          leading: Icon(Icons.code_rounded, color: colors.textSecondary),
          title: Text('Developer view',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.text)),
          subtitle: Text('Request payload, raw judgments and scoring rules',
              style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          shape: const Border(),
          collapsedShape: const Border(),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Jev produces bounded semantic judgments. Flutter owns validation, thresholds, game state and final behavior. Choice, Noul and Score evaluate the same state independently.',
                style: small),
            const SizedBox(height: 12),
            Text('STATE SENT', style: eyebrowStyle(context)),
            const SizedBox(height: 6),
            CodeBlock(
                text: game.sentState != null
                    ? const JsonEncoder.withIndent('  ')
                        .convert(game.sentState!.toJson())
                    : '// No state sent. Validation runs before evaluation.'),
            if (d != null) ...[
              const SizedBox(height: 12),
              Text('RAW JUDGMENTS', style: eyebrowStyle(context)),
              const SizedBox(height: 6),
              kv('Choice',
                  '${d.identity.choice.name.toUpperCase()} · probability ${d.identity.probability}'),
              if (d.identity.confidence != null)
                kv('Choice confidence', d.identity.confidence!),
              kv('Noul · descriptionSufficient', d.sufficiency.probability),
              kv('Score · ambiguity', d.ambiguity.score),
              if (d.ambiguity.confidence != null)
                kv('Score confidence', d.ambiguity.confidence!),
              if (d.ambiguity.probabilities != null)
                for (final e in d.ambiguity.probabilities!.entries)
                  kv('Ambiguity level ${e.key}',
                      '${(e.value * 100).toStringAsFixed(1)}%'),
              if (d.model != null) kv('Returned model', d.model!),
              if (d.apiLatencyMs != null)
                kv('API latency (server)', '${d.apiLatencyMs} ms'),
            ],
            if (game.totalLatencyMs != null)
              kv(widget.mock ? 'Mock evaluation' : 'Total request latency',
                  '${game.totalLatencyMs} ms'),
            const SizedBox(height: 12),
            Text('RULES', style: eyebrowStyle(context)),
            const SizedBox(height: 6),
            Text(
                'Win: matching choice, choice probability ≥ ${GamePolicy.choiceThreshold}, sufficiency ≥ ${GamePolicy.sufficiencyThreshold}.',
                style: small),
            Text(
                'Points on a win: 1000 − 100 per extra evaluated attempt − 100 × ambiguity − characters beyond 120; clamped to 100–1000. Invalid input and failed requests do not consume attempts.',
                style: small),
          ],
        ),
      ),
    );
  }
}

/// Card chrome for the embedded variant: gradient hairline border and a soft
/// accent glow, so the game reads as the lab's centrepiece.
class _EmbeddedChrome extends StatelessWidget {
  final Widget child;
  const _EmbeddedChrome({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.7),
            colors.border.withValues(alpha: 0.4),
            AppTheme.secondaryColor.withValues(alpha: 0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.primaryColor.withValues(alpha: isDark ? 0.10 : 0.12),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(narrow ? 16 : 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          color: isDark
              ? colors.card.withValues(alpha: 0.94)
              : colors.card.withValues(alpha: 0.96),
        ),
        child: child,
      ),
    );
  }
}

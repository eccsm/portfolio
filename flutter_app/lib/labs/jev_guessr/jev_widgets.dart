import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'domain.dart';
import 'game_controller.dart';

// Presentation-only building blocks for Jev Guessr. No game rules live here:
// every verdict shown is read from GameController / GamePolicy.

const _green = AppTheme.accentGreen;
const _red = AppTheme.accentRed;
const _amber = AppTheme.primaryColor;
const _indigo = AppTheme.secondaryColor;

IconData categoryIcon(GuessCategory c) => switch (c) {
      GuessCategory.fruit => Icons.eco_rounded,
      GuessCategory.animal => Icons.pets_rounded,
    };

String categoryLabel(GuessCategory c) => switch (c) {
      GuessCategory.fruit => 'Fruits',
      GuessCategory.animal => 'Animals',
    };

/// Readable tint of [color] for small text: amber is too light on light
/// surfaces (fails WCAG AA), so it darkens to the Astro light-theme accent.
Color readable(BuildContext context, Color color) =>
    Theme.of(context).brightness == Brightness.light && color == _amber
        ? AppTheme.primaryDark
        : color;

TextStyle eyebrowStyle(BuildContext context, {Color? color}) => TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: color == null
          ? AppTheme.getColors(context).textSecondary
          : readable(context, color),
    );

/// Rounded panel with a hairline border, used for the play and insight
/// columns.
class JevPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const JevPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final narrow = MediaQuery.sizeOf(context).width < 480;
    return Container(
      padding: narrow && padding != EdgeInsets.zero
          ? const EdgeInsets.all(14)
          : padding,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.025)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: child,
    );
  }
}

class JevHeader extends StatelessWidget {
  final bool mock;
  final bool showTitle;
  const JevHeader({super.key, required this.mock, required this.showTitle});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final compact = MediaQuery.sizeOf(context).width < 520;
    final pill = ModePill(mock: mock);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Text('Jev Guessr',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: colors.text)),
        const SizedBox(height: 4),
        Text(
          'Describe the secret word without saying it. '
          'Jev judges the meaning — Flutter decides the verdict.',
          style:
              TextStyle(fontSize: 14, height: 1.5, color: colors.textSecondary),
        ),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _JevMark(),
        const SizedBox(width: 16),
        Expanded(
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [text, const SizedBox(height: 10), pill])
              : text,
        ),
        if (!compact) ...[const SizedBox(width: 16), pill],
      ],
    );
  }
}

class _JevMark extends StatelessWidget {
  const _JevMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_amber, Color(0xFFD9785B), _indigo],
        ),
        boxShadow: [
          BoxShadow(
              color: _amber.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: const Icon(Icons.psychology_alt_rounded,
          color: Colors.white, size: 28),
    );
  }
}

/// MOCK / LIVE indicator. Live mode shows a softly pulsing dot.
class ModePill extends StatefulWidget {
  final bool mock;
  const ModePill({super.key, required this.mock});

  @override
  State<ModePill> createState() => _ModePillState();
}

class _ModePillState extends State<ModePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dot = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (!widget.mock) _dot.repeat(reverse: true);
  }

  @override
  void dispose() {
    _dot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.mock ? _amber : _green;
    return Tooltip(
      message: widget.mock
          ? 'Synthetic fixtures, no AI requests.'
          : 'Descriptions are evaluated by TypeSafe Jev.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween(begin: 0.35, end: 1.0).animate(_dot),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.6), blurRadius: 6)
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.mock ? 'MOCK MODE' : 'LIVE · TypeSafe Jev',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: readable(context, color))),
          ],
        ),
      ),
    );
  }
}

/// Session score / streak / wins / attempts.
class ScoreStrip extends StatelessWidget {
  final GameController game;
  const ScoreStrip({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
          icon: Icons.stars_rounded,
          label: 'Session score',
          value: game.sessionScore,
          color: _amber),
      _StatTile(
          icon: Icons.local_fire_department_rounded,
          label: 'Streak',
          value: game.streak,
          color: const Color(0xFFFB7185)),
      _StatTile(
          icon: Icons.emoji_events_rounded,
          label: 'Rounds won',
          value: game.roundsWon,
          color: _green),
      _StatTile(
          icon: Icons.replay_rounded,
          label: 'Attempts',
          value: game.attempts,
          color: _indigo),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 560) {
        return Row(children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: tiles[i]),
          ]
        ]);
      }
      final w = (constraints.maxWidth - 12) / 2;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (final t in tiles) SizedBox(width: w, child: t),
      ]);
    });
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: value.toDouble()),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    v.round().toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11.5, color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-option segmented control for the category.
class CategoryToggle extends StatelessWidget {
  final GuessCategory selected;
  final ValueChanged<GuessCategory>? onChanged;
  const CategoryToggle({super.key, required this.selected, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.text.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in GuessCategory.values)
            Semantics(
              button: true,
              selected: c == selected,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onChanged == null ? null : () => onChanged!(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: c == selected ? _amber : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: c == selected
                          ? [
                              BoxShadow(
                                  color: _amber.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3))
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon(c),
                            size: 17,
                            color: c == selected
                                ? AppTheme.onPrimary
                                : colors.textSecondary),
                        const SizedBox(width: 8),
                        Text(categoryLabel(c),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: c == selected
                                  ? AppTheme.onPrimary
                                  : colors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The secret-word card with the option set Jev chooses from.
class TargetCard extends StatelessWidget {
  final GuessCategory category;
  final GuessObject target;
  final bool solved;
  const TargetCard(
      {super.key,
      required this.category,
      required this.target,
      required this.solved});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final accent = solved ? _green : _amber;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.20),
            _indigo.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -30,
            child: Icon(categoryIcon(category),
                size: 150, color: accent.withValues(alpha: 0.10)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(solved ? Icons.lock_open_rounded : Icons.lock_rounded,
                      size: 14, color: accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                        MediaQuery.sizeOf(context).width < 480
                            ? 'SECRET WORD · PRIVATE'
                            : 'SECRET WORD · STAYS IN YOUR BROWSER',
                        overflow: TextOverflow.ellipsis,
                        style: eyebrowStyle(context, color: accent)),
                  ),
                ]),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: ScaleTransition(
                        scale: Tween(begin: 0.92, end: 1.0).animate(a),
                        child: child),
                  ),
                  child: FittedBox(
                    key: ValueKey(target),
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      target.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        height: 1.1,
                        color: colors.text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Jev chooses between',
                    style:
                        TextStyle(fontSize: 12, color: colors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final o in [...category.targets, GuessObject.other])
                    _OptionPill(
                        label: o.name.toUpperCase(), highlighted: o == target),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  final String label;
  final bool highlighted;
  const _OptionPill({required this.label, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? _amber.withValues(alpha: 0.22)
            : colors.text.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: highlighted
                ? _amber.withValues(alpha: 0.6)
                : colors.border.withValues(alpha: 0.6)),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: highlighted ? colors.text : colors.textSecondary,
          )),
    );
  }
}

/// Gradient primary action with an inline progress indicator.
class GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onPressed;
  const GlowButton(
      {super.key,
      required this.label,
      required this.icon,
      this.busy = false,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || busy ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient:
              const LinearGradient(colors: [_amber, AppTheme.primaryLight]),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: _amber.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 5)),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.onPrimary),
                    )
                  else
                    Icon(icon, size: 18, color: AppTheme.onPrimary),
                  const SizedBox(width: 10),
                  Text(busy ? 'Jev is thinking…' : label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onPrimary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Tone { info, working, good, warn, bad }

_Tone _toneFor(GameStatus s) => switch (s) {
      GameStatus.ready => _Tone.info,
      GameStatus.evaluating => _Tone.working,
      GameStatus.success => _Tone.good,
      GameStatus.insufficientDescription ||
      GameStatus.modelUncertain ||
      GameStatus.incorrectGuess =>
        _Tone.warn,
      GameStatus.invalidDescription || GameStatus.upstreamFailure => _Tone.bad,
    };

/// Live-region banner that explains the current game state.
class StatusBanner extends StatelessWidget {
  final GameStatus status;
  final String text;
  final int points;
  const StatusBanner(
      {super.key,
      required this.status,
      required this.text,
      required this.points});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final tone = _toneFor(status);
    final (color, icon) = switch (tone) {
      _Tone.info => (colors.textSecondary, Icons.lightbulb_outline_rounded),
      _Tone.working => (_indigo, Icons.hourglass_top_rounded),
      _Tone.good => (_green, Icons.emoji_events_rounded),
      _Tone.warn => (_amber, Icons.tips_and_updates_outlined),
      _Tone.bad => (_red, Icons.error_outline_rounded),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      // Only the incoming banner is laid out, so two messages never overlap.
      layoutBuilder: (current, _) => current ?? const SizedBox.shrink(),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
                .animate(a),
            child: child),
      ),
      child: Container(
        key: ValueKey('$status$text'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(text,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: colors.text)),
              ),
            ),
            if (tone == _Tone.good)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: points.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text('+${v.round()}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _green,
                        fontFeatures: [FontFeature.tabularFigures()])),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Description → Choice + Noul + Score → Policy" flow. Nodes pulse while a
/// request is in flight.
class DecisionPipeline extends StatelessWidget {
  final Animation<double> pulse;
  final bool active;
  const DecisionPipeline(
      {super.key, required this.pulse, required this.active});

  static const _nodes = [
    (Icons.ads_click_rounded, 'Choice', 'Which object?'),
    (Icons.fact_check_outlined, 'Noul', 'Enough information?'),
    (Icons.tune_rounded, 'Score', 'How ambiguous?'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    Widget endpoint(IconData icon, String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: colors.text.withValues(alpha: 0.05),
            border: Border.all(color: colors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: colors.textSecondary),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.text)),
          ]),
        );
    Widget arrow() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Icon(Icons.south_rounded,
              size: 16, color: colors.textSecondary.withValues(alpha: 0.6)),
        );

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => Column(
        children: [
          endpoint(Icons.edit_note_rounded, 'Your description'),
          arrow(),
          Row(
            children: [
              for (var i = 0; i < _nodes.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _PipelineNode(
                    icon: _nodes[i].$1,
                    title: _nodes[i].$2,
                    subtitle: _nodes[i].$3,
                    glow: active
                        ? (math.sin((pulse.value - i / 3) * 2 * math.pi) + 1) /
                            2
                        : 0,
                  ),
                ),
              ]
            ],
          ),
          arrow(),
          endpoint(Icons.gavel_rounded, 'Flutter policy → verdict'),
        ],
      ),
    );
  }
}

class _PipelineNode extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final double glow;
  const _PipelineNode(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.glow});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color.lerp(_indigo.withValues(alpha: 0.08),
            _amber.withValues(alpha: 0.22), glow),
        border: Border.all(
            color: Color.lerp(_indigo.withValues(alpha: 0.35), _amber, glow)!),
        boxShadow: glow > 0
            ? [
                BoxShadow(
                    color: _amber.withValues(alpha: 0.35 * glow),
                    blurRadius: 16)
              ]
            : null,
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Color.lerp(_indigo, _amber, glow)),
          const SizedBox(height: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.text)),
          const SizedBox(height: 2),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: colors.textSecondary)),
        ],
      ),
    );
  }
}

/// Animated distribution over the options, with the 80% win threshold.
class ProbabilityBars extends StatelessWidget {
  final ChoiceDecision identity;
  final GuessObject target;
  const ProbabilityBars(
      {super.key, required this.identity, required this.target});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    return Column(
      children: [
        for (final e in identity.probabilities.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _bar(context, colors, e.key, e.value),
          ),
      ],
    );
  }

  Widget _bar(
      BuildContext context, ThemeColors colors, GuessObject option, double p) {
    final chosen = option == identity.choice;
    final isTarget = option == target;
    final color = !chosen
        ? colors.textSecondary.withValues(alpha: 0.45)
        : (isTarget ? _green : _amber);
    return Semantics(
      label: option.name,
      value: '${(p * 100).toStringAsFixed(1)}%',
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Row(children: [
              Flexible(
                child: Text(option.name.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: chosen ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0.6,
                        color: chosen ? colors.text : colors.textSecondary)),
              ),
              if (isTarget) ...[
                const SizedBox(width: 4),
                const Icon(Icons.gps_fixed_rounded, size: 11, color: _amber),
              ],
            ]),
          ),
          Expanded(
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colors.text.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: p),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => FractionallySizedBox(
                      widthFactor: v.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(colors: [
                            color.withValues(alpha: chosen ? 0.75 : 1),
                            color,
                          ]),
                          boxShadow: chosen
                              ? [
                                  BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 8)
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  // Win threshold.
                  Align(
                    alignment: Alignment(GamePolicy.choiceThreshold * 2 - 1, 0),
                    child: Container(
                        width: 2, color: colors.text.withValues(alpha: 0.35)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text('${(p * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: chosen ? colors.text : colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ],
      ),
    );
  }
}

/// Radial gauge with a threshold tick.
class RadialGauge extends StatelessWidget {
  final String label;
  final String caption;
  final double value;
  final double max;
  final double? threshold;
  final bool higherIsBetter;
  final String Function(double) format;
  const RadialGauge({
    super.key,
    required this.label,
    required this.caption,
    required this.value,
    required this.max,
    required this.format,
    this.threshold,
    this.higherIsBetter = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final ratio = (value / max).clamp(0.0, 1.0);
    final good = threshold == null
        ? (higherIsBetter ? ratio >= 0.5 : ratio <= 0.34)
        : (higherIsBetter ? value >= threshold! : value <= threshold!);
    final color =
        good ? _green : (ratio > 0.66 && !higherIsBetter ? _red : _amber);
    return Column(
      children: [
        SizedBox(
          width: 112,
          height: 96,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(
              painter: _GaugePainter(
                value: v,
                threshold: threshold == null ? null : threshold! / max,
                color: color,
                track: colors.text.withValues(alpha: 0.08),
                tick: colors.text.withValues(alpha: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 34),
                child: Column(
                  children: [
                    Text(format(v * max),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: colors.text,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ])),
                    Text(caption,
                        style: TextStyle(
                            fontSize: 10, color: colors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colors.text)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double? threshold;
  final Color color, track, tick;
  _GaugePainter(
      {required this.value,
      required this.threshold,
      required this.color,
      required this.track,
      required this.tick});

  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final radius = math.min(size.width, size.height * 1.15) / 2 - stroke;
    final center = Offset(size.width / 2, radius + stroke);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, base..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        _start,
        _sweep * value,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: _start,
            endAngle: _start + _sweep,
            colors: [color.withValues(alpha: 0.55), color],
            transform: const GradientRotation(0),
          ).createShader(rect),
      );
    }
    if (threshold != null) {
      final a = _start + _sweep * threshold!;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (radius - stroke),
        center + dir * (radius + stroke),
        Paint()
          ..color = tick
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Shows the three policy conditions in the order GamePolicy checks them.
class PolicyChecklist extends StatelessWidget {
  final SemanticDecision decision;
  final GuessObject target;
  const PolicyChecklist(
      {super.key, required this.decision, required this.target});

  @override
  Widget build(BuildContext context) {
    String pct(double v) => '${(v * 100).toStringAsFixed(0)}%';
    final threshold = pct(GamePolicy.sufficiencyThreshold);
    final rows = [
      (
        decision.sufficiency.probability >= GamePolicy.sufficiencyThreshold,
        'Description is sufficient',
        '${pct(decision.sufficiency.probability)} ≥ $threshold'
      ),
      (
        decision.identity.probability >= GamePolicy.choiceThreshold,
        'Jev is confident',
        '${pct(decision.identity.probability)} ≥ ${pct(GamePolicy.choiceThreshold)}'
      ),
      (
        decision.identity.choice == target,
        'Jev picked the secret word',
        decision.identity.choice.name.toUpperCase()
      ),
    ];
    final colors = AppTheme.getColors(context);
    return Column(
      children: [
        for (final (ok, title, detail) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 18, color: ok ? _green : _red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: TextStyle(fontSize: 13, color: colors.text)),
                ),
                Text(detail,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
      ],
    );
  }
}

/// Evaluated attempts in the current round.
class AttemptTimeline extends StatelessWidget {
  final List<AttemptRecord> history;
  const AttemptTimeline({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    return Column(
      children: [
        for (var i = history.length - 1; i >= 0; i--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (history[i].status == GameStatus.success
                            ? _green
                            : _amber)
                        .withValues(alpha: 0.16),
                  ),
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: history[i].status == GameStatus.success
                              ? _green
                              : _amber)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('“${history[i].description}”',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: colors.text)),
                ),
                const SizedBox(width: 8),
                Text(
                    '${history[i].choice.name.toUpperCase()} '
                    '${(history[i].probability * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Monospace-looking code surface for the developer view.
class CodeBlock extends StatelessWidget {
  final String text;
  const CodeBlock({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppTheme.getColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFF1A1D26).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: SelectableText(text,
          style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: colors.text,
              fontFamily: 'monospace',
              fontFamilyFallback: const ['Courier New', 'Courier'])),
    );
  }
}

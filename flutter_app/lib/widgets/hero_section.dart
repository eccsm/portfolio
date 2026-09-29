import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/resume.dart';
import '../theme/app_theme.dart';
import 'social_icons_row.dart';

/// One experiment advertised in the hero; tapping it jumps to the section.
class HeroFeature {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const HeroFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

/// Landing hero of the Interactive Lab: name, rotating role line, calls to
/// action and a row of experiment tiles.
class HeroSection extends StatefulWidget {
  final VoidCallback onDownloadCv;
  final VoidCallback onOpenChat;
  final VoidCallback onPrimaryAction;
  final String primaryActionLabel;
  final List<HeroFeature> features;

  /// Social icons live in the side nav on desktop; show them here only when
  /// the nav is collapsed into a drawer (mobile) to avoid duplication.
  final bool showSocialIcons;

  const HeroSection({
    super.key,
    required this.onDownloadCv,
    required this.onOpenChat,
    required this.onPrimaryAction,
    this.primaryActionLabel = 'Play Jev Guessr',
    this.features = const [],
    this.showSocialIcons = false,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  // Rotating role line, derived from the resume.json title
  // ("Software Architect & Senior Java Engineer" -> two entries).
  late final List<String> _roles = Resume.I.title
      .split(RegExp(r'\s*&\s*'))
      .map((r) => r.trim())
      .where((r) => r.isNotEmpty)
      .toList();

  int _roleIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (mounted) {
        setState(() => _roleIndex = (_roleIndex + 1) % _roles.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNarrow = MediaQuery.sizeOf(context).width < 700;
    final roleHeight = isNarrow ? 28.0 : 34.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 22 : 40,
        vertical: isNarrow ? 30 : 48,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.card.withValues(alpha: isDark ? 0.62 : 0.78),
            AppTheme.secondaryColor.withValues(alpha: isDark ? 0.10 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.glassStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(isDark ? 30 : 22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withAlpha(isDark ? 80 : 60),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.science_rounded,
                    size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  'INTERACTIVE LAB',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Name with gradient accent
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [colors.text, AppTheme.primaryColor],
              stops: const [0.55, 1.0],
            ).createShader(bounds),
            child: Text(
              Resume.I.name,
              style: GoogleFonts.inter(
                fontSize: isNarrow ? 36 : 54,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.6,
                height: 1.05,
                color: Colors.white, // masked by the shader
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Rotating role line. Clipped so the outgoing line slides out of
          // view instead of overlapping the incoming one.
          SizedBox(
            height: roleHeight,
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                ),
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(_roleIndex);
                  final offset = Tween<Offset>(
                    begin: Offset(0, incoming ? 1 : -1),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                    position: offset,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Text(
                  _roles[_roleIndex],
                  key: ValueKey(_roleIndex),
                  style: GoogleFonts.inter(
                    fontSize: isNarrow ? 19 : 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'Hands-on experiments behind the résumé: a semantic guessing '
              'game powered by TypeSafe Jev, an AI assistant that runs '
              'entirely in your browser, and live open-source activity.',
              style: GoogleFonts.inter(
                fontSize: isNarrow ? 14 : 16,
                height: 1.6,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 26),

          // CTAs
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: widget.onPrimaryAction,
                icon: const Icon(Icons.sports_esports_rounded, size: 18),
                label: Text(widget.primaryActionLabel),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  textStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: widget.onOpenChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Ask the on-device AI'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.text,
                  side: BorderSide(
                    color: AppTheme.primaryColor.withAlpha(isDark ? 120 : 160),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  textStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: widget.onDownloadCv,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download CV'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                  textStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (widget.features.isNotEmpty) ...[
            const SizedBox(height: 32),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720
                  ? widget.features.length
                  : (constraints.maxWidth >= 440 ? 2 : 1);
              final w = (constraints.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final f in widget.features)
                    SizedBox(width: w, child: _FeatureTile(feature: f)),
                ],
              );
            }),
          ],
          if (widget.showSocialIcons) ...[
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: SocialIconsRow(useCircularBackground: true),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureTile extends StatefulWidget {
  final HeroFeature feature;
  const _FeatureTile({required this.feature});

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final f = widget.feature;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: f.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: f.color.withValues(alpha: _hover ? 0.14 : 0.08),
            border: Border.all(
                color: f.color.withValues(alpha: _hover ? 0.55 : 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: f.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(f.icon, color: f.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.text)),
                    const SizedBox(height: 2),
                    Text(f.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                offset: Offset(_hover ? 0.2 : 0, 0),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

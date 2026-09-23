import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BadgeGalleryWidget extends StatefulWidget {
  const BadgeGalleryWidget({
    super.key,
    this.huggingFaceUsername = 'eccsm',
    this.githubUsername = 'eccsm',
    this.showSkillBadges = true,
    this.showTitle = true,
    this.repository,
  });

  final String huggingFaceUsername;
  final String githubUsername;
  final bool showSkillBadges;
  final bool showTitle;
  final BadgeRepository? repository;

  @override
  State<BadgeGalleryWidget> createState() => _BadgeGalleryWidgetState();
}

class _BadgeGalleryWidgetState extends State<BadgeGalleryWidget> {
  late final BadgeRepository _repo =
      widget.repository ?? ManifestBadgeRepository();

  late Future<List<BadgeData>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchAll(
      hfUser: widget.huggingFaceUsername,
      ghUser: widget.githubUsername,
      withSkills: widget.showSkillBadges,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.fetchAll(
        hfUser: widget.huggingFaceUsername,
        ghUser: widget.githubUsername,
        withSkills: widget.showSkillBadges,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Text(
            'Productivity',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
        ],
        RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<BadgeData>>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const _SkeletonGrid();
              }
              if (snap.hasError) {
                return _ErrorCard(
                  message: "Couldn't load badges: ${snap.error}",
                  onRetry: _refresh,
                );
              }
              final badges = snap.data ?? [];
              return _BadgeGrid(badges: badges);
            },
          ),
        ),
      ],
    );
  }
}

abstract class BadgeRepository {
  Future<List<BadgeData>> fetchAll({
    required String hfUser,
    required String ghUser,
    required bool withSkills,
  });
}

class ManifestBadgeRepository implements BadgeRepository {
  @override
  Future<List<BadgeData>> fetchAll({
    required String hfUser,
    required String ghUser,
    required bool withSkills,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const [
      BadgeData.asset(
        'assets/images/huggingface.png',
        url: 'https://huggingface.co/eccsm',
        palette: BadgePalette.huggingFace,
        label: 'Hugging Face',
      ),
      BadgeData.asset(
        'assets/images/harmonova.png',
        url: 'https://github.com/harmonova',
        palette: BadgePalette.harmonova,
        label: 'Harmonova',
      ),
      BadgeData.asset(
        'assets/images/linguana_app_logo.png',
        url: 'https://play.google.com/store/apps/details?id=net.casim.linguana',
        palette: BadgePalette.linguana,
        label: 'Linguana',
      ),
    ];
  }
}

class BadgeData {
  const BadgeData._({
    this.assetPath,
    required this.url,
    required this.palette,
    this.label,
  });

  const BadgeData.asset(
    String assetPath, {
    required String url,
    required BadgePalette palette,
    String? label,
  }) : this._(
          assetPath: assetPath,
          url: url,
          palette: palette,
          label: label,
        );

  final String? assetPath;
  final String url;
  final BadgePalette palette;
  final String? label;
}

class BadgePalette {
  const BadgePalette(this.border, this.shadow);

  final Color border;
  final Color shadow;

  static const huggingFace = BadgePalette(
    Color(0xFFFFD21E),
    Color(0xFFFFD21E),
  );
  static const harmonova = BadgePalette(Color(0xFF1A4B71), Color(0xFF1A4B71));
  static const linguana = BadgePalette(Color(0xFF6746B9), Color(0xFF6746B9));
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges});

  final List<BadgeData> badges;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final gridWidth = c.maxWidth > 1560 ? 1560.0 : c.maxWidth;
        final columns = gridWidth >= 1320
            ? 4
            : gridWidth >= 980
                ? 3
                : gridWidth >= 640
                    ? 2
                    : 1;
        final childAspectRatio = columns == 1
            ? 1.85
            : columns == 2
                ? 1.62
                : 1.45;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: gridWidth,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: badges.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (ctx, i) => _BadgeCard(data: badges[i]),
            ),
          ),
        );
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.data});

  final BadgeData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final side = BorderSide(color: data.palette.border, width: 1.4);
    final shape = RoundedRectangleBorder(borderRadius: _r, side: side);

    final picture = Image.asset(
      data.assetPath!,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
    );

    return Material(
      color: isDark
          ? Colors.grey.shade800.withAlpha(58)
          : Colors.white.withValues(alpha: 0.72),
      elevation: 1.5,
      shadowColor: data.palette.shadow.withAlpha(isDark ? 25 : 50),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        splashColor: data.palette.border.withAlpha(40),
        onTap: () => launchUrl(
          Uri.parse(data.url),
          mode: LaunchMode.externalApplication,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final previewWidth = (constraints.maxWidth * 0.48).clamp(
                84.0,
                220.0,
              );
              final previewHeight = (constraints.maxHeight * 0.5).clamp(
                72.0,
                165.0,
              );

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: previewWidth,
                        height: previewHeight,
                        child: picture,
                      ),
                    ),
                  ),
                  if (data.label != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      data.label!,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final hi = Colors.grey.shade100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth =
            constraints.maxWidth > 1560 ? 1560.0 : constraints.maxWidth;
        final columns = gridWidth >= 1320
            ? 4
            : gridWidth >= 980
                ? 3
                : gridWidth >= 640
                    ? 2
                    : 1;
        final childAspectRatio = columns == 1
            ? 1.85
            : columns == 2
                ? 1.62
                : 1.45;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: gridWidth,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 6,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, __) => _Shimmer(base: base, highlight: hi),
            ),
          ),
        );
      },
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.base, required this.highlight});

  final Color base;
  final Color highlight;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final color = Color.lerp(widget.base, widget.highlight, _c.value)!;
          return Container(
            decoration: const BoxDecoration(
              borderRadius: _r,
            ).copyWith(color: color),
          );
        },
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: t.textTheme.bodyMedium?.copyWith(
                color: t.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

const _r = BorderRadius.all(Radius.circular(8));

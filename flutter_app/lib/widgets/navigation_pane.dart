import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../theme/app_theme.dart';
import 'profile_picture.dart';
import 'social_icons_row.dart';

class NavigationPane extends StatefulWidget {
  final bool isDrawer;
  final VoidCallback? onPdfExport;
  final Function(String)? onNavigate;
  final String activeSection;
  final List<Widget>? extraWidgets;

  const NavigationPane({
    super.key,
    this.isDrawer = false,
    this.onPdfExport,
    this.onNavigate,
    this.activeSection = '',
    this.extraWidgets,
  });

  @override
  State<NavigationPane> createState() => _NavigationPaneState();
}

class _NavigationPaneState extends State<NavigationPane> {
  Widget _buildNavLink(
      BuildContext context, String title, IconData icon, String section) {
    bool isActive = section == widget.activeSection;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final activeTextColor = isDark ? Colors.white : const Color(0xFF1A1D26);
    final inactiveTextColor =
        isDark ? Colors.white.withAlpha(180) : const Color(0xFF555B67);
    final activeIconColor = AppTheme.primaryColor;
    final inactiveIconColor =
        isDark ? Colors.white.withAlpha(140) : const Color(0xFF8993A4);
    final activeBgColor = isDark
        ? Colors.white.withAlpha(15)
        : AppTheme.primaryColor.withAlpha(15);
    final hoverColor = isDark
        ? Colors.white.withAlpha(8)
        : const Color(0xFF1A1D26).withAlpha(8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isActive ? activeBgColor : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: hoverColor,
          splashColor: AppTheme.primaryColor.withAlpha(20),
          onTap: () {
            if (widget.isDrawer && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            if (widget.onNavigate != null) {
              widget.onNavigate!(section);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? activeIconColor : inactiveIconColor,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? activeTextColor : inactiveTextColor,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware text/badge colors
    final nameColor = isDark ? Colors.white : const Color(0xFF1A1D26);
    final titleColor =
        isDark ? AppTheme.primaryColor.withAlpha(220) : AppTheme.primaryDark;
    final locationTextColor =
        isDark ? Colors.white.withAlpha(160) : const Color(0xFF555B67);
    final locationBadgeBg = isDark
        ? Colors.white.withAlpha(10)
        : const Color(0xFF1A1D26).withAlpha(8);
    final locationBadgeBorder =
        isDark ? Colors.white.withAlpha(15) : const Color(0xFFD0D5E0);
    final locationIconColor =
        isDark ? Colors.white.withAlpha(140) : const Color(0xFF8993A4);
    final footerBorderColor =
        isDark ? Colors.white.withAlpha(10) : const Color(0xFFD0D5E0);
    final dividerAccent = isDark
        ? AppTheme.primaryColor.withAlpha(40)
        : AppTheme.primaryColor.withAlpha(60);

    final List<Map<String, dynamic>> navLinks = [
      {
        'title': 'Jev Guessr',
        'icon': Icons.account_tree_outlined,
        'section': 'jev_guessr'
      },
      {
        'title': 'GitHub Contributions',
        'icon': Icons.grid_on_rounded,
        'section': 'github_contributions'
      },
      {
        'title': 'Productivity',
        'icon': Icons.auto_awesome_rounded,
        'section': 'productivity'
      },
    ];

    Widget contentWidget = Column(
      children: [
        const SizedBox(height: 40),

        // Profile picture with glow
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withAlpha(isDark ? 30 : 20),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const ProfilePicture(),
        ),

        const SizedBox(height: 20),

        // Name & Title from resume.json
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text(
                Resume.I.name,
                style: TextStyle(
                  color: nameColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                Resume.I.title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 13,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Location badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: locationBadgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: locationBadgeBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: locationIconColor),
                    const SizedBox(width: 4),
                    Text(
                      Resume.I.location,
                      style: TextStyle(
                        color: locationTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Gradient divider
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                dividerAccent,
                Colors.transparent,
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Nav links
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: navLinks
                .map((link) => _buildNavLink(
                      context,
                      link['title'],
                      link['icon'],
                      link['section'],
                    ))
                .toList(),
          ),
        ),

        // Extra widgets (Theme Toggle)
        if (widget.extraWidgets != null && widget.extraWidgets!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(children: widget.extraWidgets!),
          ),

        // Footer with social icons
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: footerBorderColor,
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SocialIconsRow(
              includePdfExport: widget.onPdfExport != null,
              onPdfExport: widget.onPdfExport,
            ),
          ),
        ),
      ],
    );

    // Light mode: clean white sidebar with subtle border
    // Dark mode: deep navy gradient sidebar
    final BoxDecoration lightDecoration = BoxDecoration(
      color: const Color(0xFFFBFCFE),
      border: Border(
        right: BorderSide(
          color: colors.border,
          width: 1,
        ),
      ),
    );

    final BoxDecoration darkDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.navSurface,
          colors.navBackground,
        ],
      ),
    );

    final decoration = isDark ? darkDecoration : lightDecoration;

    return widget.isDrawer
        ? Drawer(
            elevation: 0,
            child: Container(
              decoration: decoration,
              child: contentWidget,
            ),
          )
        : Container(
            width: 280,
            decoration: isDark
                ? decoration.copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: const Offset(4, 0),
                      ),
                    ],
                    border: Border(
                      right: BorderSide(
                        color: colors.border.withAlpha(40),
                        width: 1,
                      ),
                    ),
                  )
                : decoration,
            child: contentWidget,
          );
  }
}

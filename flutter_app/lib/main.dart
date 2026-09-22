import 'dart:ui' show FlutterView;
import 'labs/lab_page.dart';
import 'labs/local_intelligence_page.dart';

import 'package:cc_resume_app/data/resume_repository.dart';
import 'package:cc_resume_app/models/resume.dart';
import 'package:cc_resume_app/service/webllm_service.dart';
import 'package:cc_resume_app/theme/app_theme.dart';
import 'package:cc_resume_app/theme/theme_provider.dart';
import 'package:cc_resume_app/widgets/navigation_pane.dart';
import 'package:cc_resume_app/widgets/pinned_git_repos_widget.dart';
import 'package:cc_resume_app/widgets/timeline_experience_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'pdf/pdf_config.dart';
import 'widgets/badge_gallery_widget.dart';
import 'widgets/certification_carousel_widget.dart';
import 'widgets/github_activity_calendar_widget.dart';
import 'widgets/hero_section.dart';
import 'widgets/reveal_on_scroll.dart';
import 'widgets/section_card.dart';
import 'widgets/skills_section.dart';
import 'widgets/theme_toggle_widget.dart';
import 'widgets/chat_widget.dart';

void main() {
  // Multi-view: the host page (Astro shell) adds/removes views at will, so
  // the widget tree is rendered per FlutterView instead of runApp's implicit
  // single view. Running standalone (flutter run) works the same — there is
  // exactly one implicit view.
  runWidget(MultiViewApp(
      viewBuilder: (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => WebLLMService()),
            ],
            child: const ResumeApp(),
          )));
}

/// Renders one widget subtree per active [FlutterView], following the
/// pattern from flutter.dev/go/multi-view-embedding.
class MultiViewApp extends StatefulWidget {
  const MultiViewApp({super.key, required this.viewBuilder});

  final WidgetBuilder viewBuilder;

  @override
  State<MultiViewApp> createState() => _MultiViewAppState();
}

class _MultiViewAppState extends State<MultiViewApp>
    with WidgetsBindingObserver {
  Map<Object, Widget> _views = <Object, Widget>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateViews();
  }

  @override
  void didUpdateWidget(MultiViewApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    _views.clear();
    _updateViews();
  }

  @override
  void didChangeMetrics() {
    _updateViews();
  }

  void _updateViews() {
    final newViews = <Object, Widget>{};
    for (final FlutterView view
        in WidgetsBinding.instance.platformDispatcher.views) {
      newViews[view.viewId] = _views[view.viewId] ?? _createViewWidget(view);
    }
    setState(() {
      _views = newViews;
    });
  }

  Widget _createViewWidget(FlutterView view) {
    return View(
      view: view,
      child: Builder(builder: widget.viewBuilder),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewCollection(views: _views.values.toList(growable: false));
  }
}

/// Gates the app on the resume.json fetch: loading spinner while it's in
/// flight, error + retry when it fails, the full app once [Resume.I] is set.
class ResumeBootstrap extends StatefulWidget {
  const ResumeBootstrap({super.key});

  @override
  State<ResumeBootstrap> createState() => _ResumeBootstrapState();
}

class _ResumeBootstrapState extends State<ResumeBootstrap> {
  late Future<Resume> _resume = ResumeRepository.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Resume>(
      future: _resume,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => WebLLMService()),
            ],
            child: const ResumeApp(),
          );
        }

        return MaterialApp(
          title: 'Resume',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          home: Scaffold(
            body: Center(
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 40),
                        const SizedBox(height: 12),
                        const Text('Could not load resume data.'),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '${snapshot.error}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => setState(() {
                            _resume = ResumeRepository.retry();
                          }),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class ResumeApp extends StatelessWidget {
  const ResumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Interactive Lab',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      builder: (context, widget) => ResponsiveBreakpoints.builder(
        child: widget!,
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: 800, name: TABLET),
          Breakpoint(start: 801, end: 1920, name: DESKTOP),
          Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: LabPage(localIntelligence: (_) => const LocalIntelligencePage()),
    );
  }
}

class ResumePage extends StatefulWidget {
  const ResumePage({super.key});

  @override
  State<ResumePage> createState() => _ResumePageState();
}

class _ResumePageState extends State<ResumePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Chat state — no longer initializes WebLLM here
  bool _chatOpen = false;

  final Map<String, GlobalKey> _sectionKeys = {
    'professional_summary': GlobalKey(),
    'experience': GlobalKey(),
    'skills': GlobalKey(),
    'certifications': GlobalKey(),
    'languages': GlobalKey(),
    'education': GlobalKey(),
    'online_presence': GlobalKey(),
  };

  final ScrollController _scrollController = ScrollController();
  String _activeSection = 'professional_summary';

  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeInOut,
    );

    // Scroll-spy: highlight the section currently in view in the nav pane.
    _scrollController.addListener(_updateActiveSectionOnScroll);
  }

  void _updateActiveSectionOnScroll() {
    String current = 'professional_summary';
    double best = double.negativeInfinity;
    for (final entry in _sectionKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final render = ctx.findRenderObject();
      if (render is! RenderBox || !render.attached) continue;
      final top = render.localToGlobal(Offset.zero).dy;
      // The section whose top edge is closest above the reading line wins.
      if (top <= 160 && top > best) {
        best = top;
        current = entry.key;
      }
    }
    if (current != _activeSection) {
      setState(() => _activeSection = current);
    }
  }

  void _toggleChat() {
    setState(() {
      _chatOpen = !_chatOpen;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _scrollToSection(String section) {
    setState(() {
      _activeSection = section;
    });
    final key = _sectionKeys[section];
    if (key != null) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  Widget _buildAnimatedBackground() {
    final colors = AppTheme.getColors(context);

    return AnimatedBuilder(
      animation: _bgAnimation,
      // The static photo is passed as `child` so only the gradient overlay
      // rebuilds each frame.
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.gradientStart.withValues(alpha: 0.82),
                    colors.background.withValues(alpha: 0.88),
                    colors.gradientEnd.withValues(alpha: 0.82),
                  ],
                  stops: [
                    0.0,
                    0.4 + (_bgAnimation.value * 0.2),
                    1.0,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumeContent() {
    bool isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final colors = AppTheme.getColors(context);
    const accentColor = AppTheme.primaryColor;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        isLargeScreen ? 24 : 16,
        isLargeScreen ? 24 : 86,
        isLargeScreen ? 24 : 16,
        24,
      ),
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height - (isLargeScreen ? 100 : 180),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero landing block. Social icons only on small screens —
            // the desktop side nav already shows them.
            HeroSection(
              onDownloadCv: () => PdfConfig.exportResumePdf(context),
              onOpenChat: () {
                if (!_chatOpen) _toggleChat();
              },
              onViewProjects: () => _scrollToSection('online_presence'),
              showSocialIcons: !isLargeScreen,
            ),

            // About section — data from resume.json
            RevealOnScroll(
              child: Container(
                key: _sectionKeys['professional_summary'],
                child: SectionCard(
                  title: 'About',
                  icon: Icons.person_outline_rounded,
                  accentColor: accentColor,
                  content: Text(
                    Resume.I.profileIntro,
                    style: const TextStyle(fontSize: 15, height: 1.65),
                  ),
                ),
              ),
            ),

            // Experience section — data from resume.json
            RevealOnScroll(
              child: Container(
                key: _sectionKeys['experience'],
                child: _buildExperienceSection(),
              ),
            ),

            // Technical Skills — data from resume.json
            RevealOnScroll(
              child: Container(
                key: _sectionKeys['skills'],
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SkillsSection(),
                ),
              ),
            ),

            // Certifications — data from resume.json
            RevealOnScroll(
              child: Container(
                key: _sectionKeys['certifications'],
                child: SectionCard(
                  title: 'Certifications',
                  icon: Icons.workspace_premium_rounded,
                  accentColor: accentColor,
                  content: CertificationCarouselWidget(
                    certifications: Resume.I.certifications,
                  ),
                ),
              ),
            ),

            // Languages — data from resume.json
            RevealOnScroll(
              child: Container(
                key: _sectionKeys['languages'],
                child: SectionCard(
                  title: 'Languages',
                  icon: Icons.language_rounded,
                  accentColor: accentColor,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final lang in Resume.I.languageEntries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.translate_rounded,
                                  size: 18, color: AppTheme.primaryColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${lang.language} — ${lang.level}',
                                  style: const TextStyle(
                                      fontSize: 15, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Education — data from resume.json
            RevealOnScroll(
              child: Container(
                key: _sectionKeys['education'],
                child: SectionCard(
                  title: 'Education',
                  icon: Icons.school_rounded,
                  accentColor: accentColor,
                  content: Text(
                    Resume.I.educationSummary,
                    style: const TextStyle(fontSize: 15, height: 1.65),
                  ),
                ),
              ),
            ),

            // Online Presence
            RevealOnScroll(
              child: Container(
                key: _sectionKeys['online_presence'],
                child: SectionCard(
                  title: 'Online Presence & Projects',
                  icon: Icons.public_rounded,
                  accentColor: accentColor,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GitHub Projects',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PinnedGithubReposWidget(
                        onReposLoaded: _onReposLoaded,
                      ),
                      const SizedBox(height: 32),
                      Divider(color: colors.divider),
                      const SizedBox(height: 32),
                      GithubRealContributionGraph(
                        username: 'eccsm',
                        refreshInterval: const Duration(hours: 24),
                      ),
                      const SizedBox(height: 32),
                      Divider(color: colors.divider),
                      const SizedBox(height: 32),
                      const BadgeGalleryWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceSection() {
    final colors = AppTheme.getColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_rounded,
                    color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Experience',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < Resume.I.experiences.length; i++)
          TimelineExperienceCard(
            title: Resume.I.experiences[i].company,
            role: Resume.I.experiences[i].role,
            location: Resume.I.experiences[i].location,
            period: Resume.I.experiences[i].periodLabel,
            points: Resume.I.experiences[i].points,
            accentColor: AppTheme.primaryColor,
            isFirst: i == 0,
          ),
      ],
    );
  }

  Widget _buildChatButton() {
    final colors = AppTheme.getColors(context);
    final webLLMService = Provider.of<WebLLMService>(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _chatOpen
                ? AppTheme.primaryColor.withAlpha(60)
                : AppTheme.secondaryColor.withAlpha(30),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _toggleChat,
        backgroundColor: _chatOpen ? AppTheme.primaryColor : colors.card,
        elevation: 0,
        tooltip: 'Chat with AI Assistant',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _chatOpen ? Icons.close_rounded : Icons.chat_bubble_rounded,
                key: ValueKey(_chatOpen),
                color: _chatOpen ? Colors.white : AppTheme.primaryColor,
                size: 24,
              ),
            ),
            // Status dot
            if (webLLMService.isFallbackMode && !_chatOpen)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.card,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Feeds fetched GitHub repos into the chatbot's system prompt so the
  /// AI assistant can talk about live projects.
  void _onReposLoaded(List<Map<String, dynamic>> repos) {
    final summaries = repos.map((r) {
      final desc = (r['description'] ?? '').toString();
      final lang = (r['language'] ?? '').toString();
      return '${r['name']}'
          '${lang.isNotEmpty ? ' ($lang)' : ''}'
          '${desc.isNotEmpty ? ': $desc' : ''}';
    }).toList();
    context.read<WebLLMService>().updateSystemPrompt(pinnedRepos: summaries);
  }

  Widget _buildChatWidget() {
    final webLLMService = Provider.of<WebLLMService>(context);

    return ChatContainer(
      onClose: () => _toggleChat(),
      webLLMService: webLLMService,
      onNavigateToSection: _scrollToSection,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: isLargeScreen
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              elevation: 0,
              scrolledUnderElevation: 4,
              toolbarHeight: 56,
              titleSpacing: 0,
              actions: const [
                ThemeToggleWidget(isCompact: true),
                SizedBox(width: 8),
              ],
            ),
      drawer: isLargeScreen
          ? null
          : NavigationPane(
              isDrawer: true,
              onPdfExport: () => PdfConfig.exportResumePdf(context),
              onNavigate: _scrollToSection,
              activeSection: _activeSection,
            ),
      floatingActionButton: _buildChatButton(),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildAnimatedBackground(),
                Row(
                  children: [
                    if (isLargeScreen)
                      SizedBox(
                        width: 280,
                        child: NavigationPane(
                          isDrawer: false,
                          onPdfExport: () => PdfConfig.exportResumePdf(context),
                          onNavigate: _scrollToSection,
                          activeSection: _activeSection,
                          extraWidgets: const [
                            ThemeToggleWidget(isCompact: true),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildResumeContent(),
                          // Chat Overlay
                          if (_chatOpen)
                            Positioned(
                              bottom: 80,
                              right: 20,
                              width: MediaQuery.of(context).size.width < 500
                                  ? MediaQuery.of(context).size.width * 0.92
                                  : 380,
                              height: MediaQuery.of(context).size.height < 600
                                  ? MediaQuery.of(context).size.height * 0.75
                                  : 520,
                              child: _buildChatWidget(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

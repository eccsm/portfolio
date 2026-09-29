/* -------------------------------------------------------------------------
   Unified Chat UI & Logic (v4 - Modernized, No Blocking Loading Screen)
   -------------------------------------------------------------------------
   • No blocking loading screen on page open
   • WebLLM check runs in background; chat is immediately usable in fallback
   • Glassmorphic design with premium animations
   -------------------------------------------------------------------------*/

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:cc_resume_app/service/webllm_service.dart';
import '../data/resume_knowledge.dart';
import '../pdf/pdf_generator.dart';
import '../theme/app_theme.dart';

/// Main chat widget container — no blocking loading screen
class ChatContainer extends StatefulWidget {
  final VoidCallback onClose;
  final WebLLMService webLLMService;

  /// Lets the chatbot scroll the resume page to a section
  /// (e.g. "show me his projects" → Online Presence).
  final void Function(String section)? onNavigateToSection;

  const ChatContainer({
    super.key,
    required this.onClose,
    required this.webLLMService,
    this.onNavigateToSection,
  });

  @override
  State<ChatContainer> createState() => _ChatContainerState();
}

class _ChatContainerState extends State<ChatContainer> {
  bool _supportAvailable = false;
  bool _browserSupportsWebLLM = false;
  bool _useWebLLM = false;
  bool _modelDownloaded = false;
  bool _isInitializing = false;
  String _requirementsStatus = '';
  String _lastError = '';
  bool _buttonLoading = false;

  @override
  void initState() {
    super.initState();
    widget.webLLMService.addListener(_onServiceUpdate);
    // Don't force fallback here — the service constructor already handles
    // browser capability check and sets fallback if needed.
    // Check availability in background — no blocking
    _checkWebLLMAvailability();
  }

  @override
  void dispose() {
    widget.webLLMService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    final svc = widget.webLLMService;

    if (svc.isInitialized && !svc.isFallbackMode) {
      setState(() {
        _modelDownloaded = true;
        _isInitializing = false;
        _buttonLoading = false;
        _useWebLLM = true;
      });
    } else if (_isInitializing && svc.isFallbackMode) {
      setState(() {
        _isInitializing = false;
        _buttonLoading = false;
      });
      if (svc.lastErrorMessage.isNotEmpty) {
        _lastError = svc.lastErrorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WebLLM error: $_lastError'),
            action: SnackBarAction(
                label: 'Try Again', onPressed: _retryWithSmallerModel),
          ),
        );
      }
    }
  }

  Future<void> _checkWebLLMAvailability() async {
    // Wait for the service to finish its browser capability check. A timeout
    // guards against the helper script never resolving (offline CDN etc.).
    await widget.webLLMService.capabilityChecked
        .timeout(const Duration(seconds: 10), onTimeout: () {});
    if (!mounted) return;
    final svc = widget.webLLMService;
    // If service ended up in fallback mode after its own init, browser doesn't support WebLLM
    final browserOk = !svc.isFallbackMode;
    setState(() {
      _browserSupportsWebLLM = browserOk;
      _supportAvailable = browserOk;
      _requirementsStatus = browserOk
          ? 'WebLLM support is available.'
          : 'Browser requirements not met for WebLLM.';
    });
    // If browser doesn't support WebLLM, ensure we're in fallback mode
    if (!browserOk && !svc.isFallbackMode) {
      svc.enableFallbackMode();
    }
  }

  void _showRequirementsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('WebLLM Requirements'),
        content: SingleChildScrollView(child: Text(_requirementsStatus)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))
        ],
      ),
    );
  }

  Future<void> _onToggleMode() async {
    if (_buttonLoading) return;
    setState(() => _buttonLoading = true);

    if (!_supportAvailable) {
      setState(() => _buttonLoading = false);
      _showRequirementsDialog();
      return;
    }

    if (_useWebLLM) {
      try {
        await widget.webLLMService.setFallbackMode(true);
        if (!mounted) return;
        setState(() {
          _useWebLLM = false;
          _buttonLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _buttonLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to switch: $e')));
      }
      return;
    }

    if (_modelDownloaded) {
      try {
        await widget.webLLMService.setFallbackMode(false);
        if (!mounted) return;
        setState(() {
          _useWebLLM = true;
          _buttonLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _buttonLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
      return;
    }

    setState(() => _isInitializing = true);
    _prepareModels();

    const String selectedModel = WebLLMService.defaultModel;
    widget.webLLMService.setSelectedModel(selectedModel);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Loading $selectedModel… This may take some time.')),
    );

    try {
      await widget.webLLMService.initializeEngine();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _buttonLoading = false;
        _lastError = e.toString();
        widget.webLLMService.setError(_lastError);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model load failed: $e'),
          action: SnackBarAction(
              label: 'Try Fallback',
              onPressed: () {
                widget.webLLMService.enableFallbackMode();
              }),
        ),
      );
      widget.webLLMService.enableFallbackMode();
    }
  }

  void _prepareModels() {
    final svc = widget.webLLMService;
    svc.clearModels();
    svc.addAvailableModel(WebLLMService.defaultModel);
    svc.addAvailableModel(WebLLMService.largerModel);
  }

  void _retryWithSmallerModel() => _onToggleMode();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // NO blocking loading screen — go straight to chat
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 100 : 40),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(isDark ? 15 : 5),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
        border: Border.all(
          color: isDark ? colors.border : colors.border.withAlpha(120),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _useWebLLM
              ? WebLLMChatWidget(
                  key: const ValueKey('web'),
                  service: widget.webLLMService,
                  onClose: widget.onClose,
                  onToggleMode: _onToggleMode,
                  isLoading: _buttonLoading,
                  onNavigate: widget.onNavigateToSection,
                )
              : FallbackChatWidget(
                  key: const ValueKey('fallback'),
                  webLLMService: widget.webLLMService,
                  onClose: widget.onClose,
                  onToggleMode: _onToggleMode,
                  webLLMAvailable: _browserSupportsWebLLM,
                  modelDownloaded: _modelDownloaded,
                  isLoading: _buttonLoading,
                  onNavigate: widget.onNavigateToSection,
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WebLLM Chat Widget
// ═══════════════════════════════════════════════════════════════════
class WebLLMChatWidget extends StatefulWidget {
  final WebLLMService service;
  final VoidCallback onClose;
  final VoidCallback onToggleMode;
  final bool isLoading;
  final void Function(String section)? onNavigate;

  const WebLLMChatWidget({
    super.key,
    required this.service,
    required this.onClose,
    required this.onToggleMode,
    this.isLoading = false,
    this.onNavigate,
  });

  @override
  State<WebLLMChatWidget> createState() => _WebLLMChatWidgetState();
}

class _WebLLMChatWidgetState extends State<WebLLMChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _current = '';
  bool _first = true;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onService);
  }

  @override
  void dispose() {
    widget.service.removeListener(_onService);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onService() => setState(() {});

  void _sendSuggested(String query) {
    _controller.text = query;
    _send();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.service.isGenerating) return;
    _controller.clear();
    // If the question maps to a resume section, scroll the page there too.
    final section = ResumeKnowledge.sectionForQuery(text);
    if (section != null) widget.onNavigate?.call(section);
    try {
      final stream = await widget.service.sendMessage(text);
      _current = '';
      _first = false;
      await for (final chunk in stream) {
        if (!mounted) return;
        _current += chunk;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
        setState(() {});
      }
      if (!mounted) return;
      setState(() => _current = '');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(
            title: 'WebLLM Chat',
            onToggle: widget.onToggleMode,
            onClose: widget.onClose,
            isLoading: widget.isLoading),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            children: [
              if (_first && _current.isEmpty) ...[
                const _WelcomeBubble(
                    subtitle: 'Runs locally in your browser using WebLLM'),
                _SuggestionChips(onTap: _sendSuggested),
              ] else
                ...widget.service.messages
                    .skip(1)
                    .map((m) => _MessageBubble(role: m.role, text: m.content)),
              if (_current.isNotEmpty)
                _MessageBubble(
                    role: 'assistant', text: _current, isTyping: true),
            ],
          ),
        ),
        _InputArea(
            controller: _controller,
            onSend: _send,
            isGenerating: widget.service.isGenerating),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Fallback Chat Widget
// ═══════════════════════════════════════════════════════════════════
class FallbackChatWidget extends StatefulWidget {
  final WebLLMService webLLMService;
  final VoidCallback onClose;
  final VoidCallback onToggleMode;
  final bool webLLMAvailable;
  final bool modelDownloaded;
  final bool isLoading;
  final void Function(String section)? onNavigate;

  const FallbackChatWidget({
    super.key,
    required this.webLLMService,
    required this.onClose,
    required this.onToggleMode,
    required this.webLLMAvailable,
    required this.modelDownloaded,
    this.isLoading = false,
    this.onNavigate,
  });

  @override
  State<FallbackChatWidget> createState() => _FallbackChatWidgetState();
}

class _FallbackChatWidgetState extends State<FallbackChatWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _processing = false;
  bool _typing = false;
  Timer? _timer;
  String _current = '';
  int _idx = 0;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _addGreeting();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _addGreeting() {
    final greetings = [
      "Hello! I'm the assistant for Ekincan's resume.",
      "Welcome! Ask me about Ekincan's skills or experience.",
      "Hi there! I can share Ekincan's career highlights.",
    ];
    _messages.add(ChatMessage(
        message: greetings[Random().nextInt(greetings.length)], isUser: false));
    setState(() {});
  }

  Future<void> _downloadPdf() async {
    _messages
        .add(ChatMessage(message: "Preparing resume PDF...", isUser: false));
    setState(() => _downloading = true);
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final data = await PdfGenerator.generateResumePdf();
      await Printing.sharePdf(
          bytes: data, filename: 'Ekincan_Casim_Resume.pdf');
      _messages
          .add(ChatMessage(message: "Resume PDF downloaded!", isUser: false));
    } catch (_) {
      _messages.add(
          ChatMessage(message: "Error downloading resume.", isUser: false));
    } finally {
      setState(() => _downloading = false);
    }
  }

  void _sendSuggested(String query) {
    _ctrl.text = query;
    _send();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _processing) return;
    _ctrl.clear();
    _messages.add(ChatMessage(message: text, isUser: true));
    setState(() => _processing = true);
    _scroll.jumpTo(_scroll.position.maxScrollExtent);

    if (_downloading) return;
    if (ResumeKnowledge.wantsPdf(text)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _downloadPdf());
      _typeResponse("I'll prepare the resume PDF now.");
      return;
    }
    // Scroll the page to the matching section while answering.
    final section = ResumeKnowledge.sectionForQuery(text);
    if (section != null) widget.onNavigate?.call(section);
    _typeResponse(ResumeKnowledge.keywordResponse(text));
  }

  void _typeResponse(String response) {
    _messages.add(ChatMessage(message: '', isUser: false));
    _current = '';
    _idx = 0;
    _typing = true;
    _timer = Timer.periodic(const Duration(milliseconds: 40), (t) {
      if (_idx < response.length) {
        _current += response[_idx++];
        _messages.last = ChatMessage(message: _current, isUser: false);
        setState(() {});
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        t.cancel();
        setState(() {
          _typing = false;
          _processing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(
          title: 'AI Assistant',
          onToggle: widget.onToggleMode,
          onClose: widget.onClose,
          isLoading: widget.isLoading,
          showToggle: widget.webLLMAvailable,
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (int i = 0; i < _messages.length; i++)
                _MessageBubble(
                  role: _messages[i].isUser ? 'user' : 'assistant',
                  text: _messages[i].message,
                  isTyping: _typing && i == _messages.length - 1,
                ),
              // Show suggested questions until the visitor asks something.
              if (!_messages.any((m) => m.isUser))
                _SuggestionChips(onTap: _sendSuggested),
            ],
          ),
        ),
        _InputArea(
            controller: _ctrl,
            onSend: _send,
            isGenerating: _processing || _downloading),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Shared UI Components
// ═══════════════════════════════════════════════════════════════════

/// Tappable suggested-question chips shown under the welcome message
class _SuggestionChips extends StatelessWidget {
  final void Function(String query) onTap;

  const _SuggestionChips({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final q in ResumeKnowledge.suggestedQuestions)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onTap(q.query),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(isDark ? 25 : 15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withAlpha(isDark ? 70 : 50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(q.icon, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        q.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Premium header with gradient
class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onToggle;
  final VoidCallback onClose;
  final bool isLoading;
  final bool showToggle;

  const _Header({
    required this.title,
    required this.onToggle,
    required this.onClose,
    this.isLoading = false,
    this.showToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardHeader,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withAlpha(isDark ? 40 : 20),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.text,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (showToggle)
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : _HeaderButton(
                    icon: Icons.swap_horiz_rounded,
                    onTap: onToggle,
                    tooltip: 'Switch mode',
                  ),
          const SizedBox(width: 4),
          _HeaderButton(
            icon: Icons.close_rounded,
            onTap: onClose,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Welcome bubble
class _WelcomeBubble extends StatelessWidget {
  final String subtitle;
  const _WelcomeBubble({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withAlpha(isDark ? 20 : 10),
              AppTheme.secondaryColor.withAlpha(isDark ? 15 : 8),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primaryColor.withAlpha(isDark ? 30 : 15),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.waving_hand_rounded,
                    size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Hello!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium message bubble
class _MessageBubble extends StatelessWidget {
  final String role;
  final String text;
  final bool isTyping;

  const _MessageBubble({
    required this.role,
    required this.text,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.secondaryColor : colors.chatBubbleBot,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 8),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text.isEmpty && isTyping ? '...' : text,
          style: GoogleFonts.inter(
            color: isUser ? Colors.white : colors.text,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

/// Premium input area
class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isGenerating;

  const _InputArea({
    required this.controller,
    required this.onSend,
    this.isGenerating = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardHeader,
        border: Border(
          top: BorderSide(
            color: colors.border.withAlpha(isDark ? 60 : 40),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? colors.card : colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.border.withAlpha(isDark ? 80 : 50),
                ),
              ),
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colors.text,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withAlpha(140),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: isGenerating
                ? colors.textSecondary.withAlpha(30)
                : AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isGenerating ? null : onSend,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: isGenerating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple model for fallback chat messages
class ChatMessage {
  final String message;
  final bool isUser;
  ChatMessage({required this.message, required this.isUser});
}

/// Helper function to build the chat widget
Widget buildChatWidget({
  required VoidCallback onClose,
  required WebLLMService webLLMService,
}) {
  return ChatContainer(onClose: onClose, webLLMService: webLLMService);
}

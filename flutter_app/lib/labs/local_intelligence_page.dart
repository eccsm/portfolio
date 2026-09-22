import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/resume_repository.dart';
import '../models/resume.dart';
import '../service/webllm_service.dart';
import '../widgets/chat_widget.dart';

class LocalIntelligencePage extends StatefulWidget {
  const LocalIntelligencePage({super.key});
  @override
  State<LocalIntelligencePage> createState() => _LocalIntelligencePageState();
}

class _LocalIntelligencePageState extends State<LocalIntelligencePage> {
  late Future<Resume> resume = ResumeRepository.load();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar:
            AppBar(title: const Text('Local Intelligence · WebGPU + MLC LLM')),
        body: FutureBuilder<Resume>(
            future: resume,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: FilledButton(
                  onPressed: () => setState(() {
                    resume = ResumeRepository.retry();
                  }),
                  child: const Text('Could not load portfolio context. Retry'),
                ));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: ChatContainer(
                          onClose: () => Navigator.of(context).pop(),
                          webLLMService: context.read<WebLLMService>())));
            }),
      );
}

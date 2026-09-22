import 'package:flutter/material.dart';
import 'lab_registry.dart';

class LabPage extends StatelessWidget {
  final WidgetBuilder localIntelligence;
  const LabPage({super.key, required this.localIntelligence});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Interactive Lab')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('How do these engineering ideas behave?',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    const Text(
                        'Run AI experiments and inspect the boundaries between models and application code. Close the lab to return to the professional portfolio.'),
                    const SizedBox(height: 24),
                    for (final experiment in labRegistry(localIntelligence))
                      Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(experiment.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge),
                                      const SizedBox(height: 12),
                                      Text(experiment.description),
                                      const SizedBox(height: 12),
                                      Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            for (final technology
                                                in experiment.technologies)
                                              Chip(label: Text(technology))
                                          ]),
                                      const SizedBox(height: 16),
                                      FilledButton(
                                          style: FilledButton.styleFrom(
                                              foregroundColor: Colors.black87),
                                          onPressed: () => Navigator.of(context)
                                              .push(MaterialPageRoute<void>(
                                                  builder: experiment.builder)),
                                          child: Text(
                                              'Open ${experiment.title.substring(5)}')),
                                    ])),
                          )),
                  ],
                ))),
      );
}

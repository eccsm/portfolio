import 'package:flutter/material.dart';
import 'jev_guessr/jev_guessr_page.dart';

class LabConfig {
  final bool enableJev;
  final String provider;
  const LabConfig(
      {this.enableJev =
          const bool.fromEnvironment('ENABLE_JEV_GUESSR', defaultValue: false),
      this.provider =
          const String.fromEnvironment('JEV_PROVIDER', defaultValue: 'mock')});
}

class LabExperiment {
  final String id, title, description;
  final List<String> technologies;
  final WidgetBuilder builder;
  const LabExperiment(
      this.id, this.title, this.description, this.technologies, this.builder);
}

List<LabExperiment> labRegistry(WidgetBuilder localIntelligence,
        {LabConfig config = const LabConfig()}) =>
    [
      LabExperiment(
          'local-intelligence',
          '01 · Local Intelligence',
          'Explore generative inference in your browser with the portfolio assistant.',
          ['WebGPU', 'MLC LLM'],
          localIntelligence),
      if (config.enableJev && ['mock', 'typesafe'].contains(config.provider))
        LabExperiment(
            'jev-guessr',
            '02 · Semantic Decisions',
            'Jev Guessr: describe a target, inspect bounded judgments, and see application rules decide the result.',
            [
              'TypeSafe Jev',
              'Choice',
              'Noul',
              'Score',
              if (config.provider == 'mock') 'Mock'
            ],
            (_) => JevGuessrPage(mock: config.provider == 'mock')),
    ];

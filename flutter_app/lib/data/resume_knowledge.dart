// lib/data/resume_knowledge.dart
//
// Single source of truth for everything the chatbot knows.
// Both the keyword fallback and the WebLLM system prompt are built from the
// fetched resume.json (Resume.I), so resume facts only ever need updating in
// site/src/data/resume.ts.

import '../models/resume.dart';

/// A suggested question rendered as a tappable chip in the chat UI.
class SuggestedQuestion {
  final String label;
  final String query;
  const SuggestedQuestion(this.label, this.query);
}

class ResumeKnowledge {
  ResumeKnowledge._();

  // ────────────────────────────────────────────────────────────────
  //  LLM system prompt (grounded in ResumeConstants)
  // ────────────────────────────────────────────────────────────────

  /// Builds the system prompt for the on-device LLM. [pinnedRepos] is an
  /// optional list of GitHub repo summaries fetched at runtime, so the model
  /// can talk about live projects too.
  static String buildSystemPrompt({List<String> pinnedRepos = const []}) {
    final buffer = StringBuffer()
      ..writeln(
          'You are the AI assistant on the resume website of ${Resume.I.name} '
          '(${Resume.I.title}, based in ${Resume.I.location}).')
      ..writeln('Answer questions about his professional background concisely '
          '(2-4 sentences), in a friendly, professional tone. Only use the '
          'facts below; if you are asked something not covered here, say so '
          'and suggest a related topic you can answer.')
      ..writeln()
      ..writeln('## Summary')
      ..writeln(Resume.I.profileIntro)
      ..writeln()
      ..writeln('## Experience');

    for (final exp in Resume.I.experiences) {
      buffer.writeln('- ${exp.role} at ${exp.company} (${exp.periodLabel}, '
          '${exp.location}): ${exp.points.first}');
    }

    buffer
      ..writeln()
      ..writeln('## Core skills')
      ..writeln(_skillsOneLiner())
      ..writeln()
      ..writeln('## Education')
      ..writeln(Resume.I.educationSummary.replaceAll('\n', ' '))
      ..writeln()
      ..writeln('## Certifications')
      ..writeln(Resume.I.certificates.replaceAll('\n', '; '))
      ..writeln()
      ..writeln('## Languages')
      ..writeln(Resume.I.languages)
      ..writeln()
      ..writeln('## Contact')
      ..writeln('Email: ${Resume.I.contactEmail} | '
          'LinkedIn: ${Resume.I.contactLinkedIn} | '
          'GitHub: ${Resume.I.contactGitHub}');

    if (pinnedRepos.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Pinned GitHub projects');
      for (final repo in pinnedRepos) {
        buffer.writeln('- $repo');
      }
    }

    return buffer.toString();
  }

  static String _skillsOneLiner() {
    final parts = <String>[];
    Resume.I.skills.forEach((category, subcats) {
      final items = subcats.values.expand((v) => v).take(6).join(', ');
      parts.add('$category: $items');
    });
    return parts.join('. ');
  }

  // ────────────────────────────────────────────────────────────────
  //  Suggested questions (chat chips)
  // ────────────────────────────────────────────────────────────────

  static const List<SuggestedQuestion> suggestedQuestions = [
    SuggestedQuestion('🏗 Architecture', 'What architecture experience does Ekincan have?'),
    SuggestedQuestion('☕ Java & Spring', 'How deep is his Java and Spring Boot expertise?'),
    SuggestedQuestion('🤖 AI projects', 'Has he built anything with AI or LLMs?'),
    SuggestedQuestion('📂 Projects', 'Show me his projects'),
    SuggestedQuestion('📄 Download CV', 'Can I download his resume as PDF?'),
  ];

  // ────────────────────────────────────────────────────────────────
  //  Navigation intents (chatbot can scroll the page)
  // ────────────────────────────────────────────────────────────────

  /// Returns a page section id when the query clearly refers to a resume
  /// section, so the chat can scroll the page there. Null when no match.
  static String? sectionForQuery(String query) {
    final q = query.toLowerCase();
    if (q.contains('project') || q.contains('github') || q.contains('repo')) {
      return 'online_presence';
    }
    if (q.contains('experience') || q.contains('career') || q.contains('work history')) {
      return 'experience';
    }
    if (q.contains('skill') || q.contains('stack') || q.contains('technolog')) {
      return 'skills';
    }
    if (q.contains('certif')) return 'certifications';
    if (q.contains('educat') || q.contains('degree') || q.contains('university')) {
      return 'education';
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────────
  //  Keyword fallback (no LLM available)
  // ────────────────────────────────────────────────────────────────

  static String keywordResponse(String query) {
    final q = query.toLowerCase();

    if (q.contains('architect') ||
        q.contains('design') ||
        q.contains('pattern') ||
        q.contains('ddd') ||
        q.contains('bounded')) {
      return 'Ekincan is a Software Architect with hands-on architecture '
          'ownership. He led the Allianz enterprise architecture transformation '
          '(Oracle ADF → Spring Boot 3.x), designed the Allianz Architectural '
          'Framework adopted across multiple teams, and decomposed overloaded '
          'insurance domains into bounded microservices at Medisa using DDD principles.';
    }

    if (q.contains('java') ||
        q.contains('spring') ||
        q.contains('boot') ||
        q.contains('jpa') ||
        q.contains('hibernate')) {
      return "Java is Ekincan's primary language with 10+ years of depth. He "
          'works with Java 17/21, Spring Boot 3.x, Spring Cloud, JPA/Hibernate, '
          'and has extensive experience with Oracle and PostgreSQL in enterprise '
          'insurance and banking platforms.';
    }

    if (q.contains('kafka') ||
        q.contains('event') ||
        q.contains('messaging') ||
        q.contains('rabbitmq') ||
        q.contains('stream')) {
      return 'Ekincan designed Kafka-backed event-driven architectures at Medisa '
          'for policy issuance, claims handling, and real-time customer '
          'notifications. He uses Redis for caching layers alongside Kafka '
          'streams and has also worked with RabbitMQ.';
    }

    if (q.contains('cloud') ||
        q.contains('kubernetes') ||
        q.contains('docker') ||
        q.contains('aws') ||
        q.contains('devops') ||
        q.contains('ci/cd')) {
      return 'Ekincan is experienced with cloud-native deployments on AWS, Azure, '
          'and GCP. He manages Kubernetes/Rancher container orchestration, Jenkins '
          'and GitLab CI/CD pipelines, Terraform, and Ansible. He migrated '
          'observability from ELK to Graylog at Medisa.';
    }

    if (q.contains('ai') ||
        q.contains('llm') ||
        q.contains('genai') ||
        q.contains('chatbot') ||
        q.contains('gpt')) {
      return 'Ekincan designed and delivered an GenAI-powered HR chatbot for '
          'Pegasus Airlines using Spring Boot 3.x. He implemented Redis-based '
          'intelligent caching, minute-based rate limiting, and cost-optimized '
          'token management strategies to reduce API costs significantly. This '
          'site\'s chat can even run a local LLM in your browser via WebLLM.';
    }

    if (q.contains('insurance') ||
        q.contains('bank') ||
        q.contains('fintech') ||
        q.contains('allianz') ||
        q.contains('domain')) {
      return 'Ekincan has deep insurance and banking domain expertise. He was '
          "architect for Allianz's core system transformation at NTT DATA, and "
          "currently leads architecture at Medisa's enterprise insurance platform. "
          'Previous experience includes Yapı Kredi (banking) and the Harmoni '
          'insurance framework modernization.';
    }

    if (q.contains('project') || q.contains('github') || q.contains('repo')) {
      return 'You can find his projects in the Online Presence section below — '
          'pinned GitHub repositories, contribution activity, and platform badges. '
          'This portfolio and Interactive Lab is one of his Flutter projects.';
    }

    if (q.contains('experience') ||
        q.contains('career') ||
        q.contains('work') ||
        q.contains('job') ||
        q.contains('history')) {
      return _experienceSummary();
    }

    if (q.contains('skill') ||
        q.contains('tech') ||
        q.contains('stack') ||
        q.contains('language')) {
      return 'Core stack: Java 17/21, Spring Boot 3.x, Kafka, Redis, PostgreSQL, '
          'Oracle, MongoDB, Kubernetes, Docker, AWS. Also experienced with Python, '
          'Angular, React, TypeScript, GenAI APIs, Terraform, and Ansible.';
    }

    if (q.contains('reloc') ||
        q.contains('move') ||
        q.contains('availab') ||
        q.contains('hire') ||
        q.contains('contact') ||
        q.contains('email')) {
      return 'Ekincan is based in ${Resume.I.location} and is open to '
          'senior architect and tech lead opportunities. You can reach him at '
          '${Resume.I.contactEmail} or via LinkedIn at '
          '${Resume.I.contactLinkedIn}.';
    }

    if (q.contains('educat') ||
        q.contains('degree') ||
        q.contains('university') ||
        q.contains('master') ||
        q.contains('bachelor')) {
      return "Ekincan holds a Master's Degree in Engineering and Technology "
          "Management from Doğuş University (2017–2019) and a Bachelor's Degree "
          'in Computer Engineering from Maltepe University (2011–2015).';
    }

    if (q.contains('certif')) {
      return 'Certifications: ${Resume.I.certificates.replaceAll('\n', ' and ')}.';
    }

    return "I'm Ekincan's resume assistant. You can ask me about his "
        'architecture experience, Java/Spring skills, Kafka and event-driven '
        'systems, cloud & DevOps practices, AI/LLM projects, or his career '
        'history. What would you like to know?';
  }

  static String _experienceSummary() {
    final buffer = StringBuffer('Ekincan has 10+ years of experience: ');
    final entries = Resume.I.experiences
        .map((e) => '${e.role} at ${e.company} (${e.periodLabel})')
        .toList();
    buffer.write(entries.join(', '));
    buffer.write('.');
    return buffer.toString();
  }

  /// True when the query asks for the resume PDF.
  static bool wantsPdf(String query) {
    final q = query.toLowerCase();
    return q.contains('resume') ||
        q.contains('cv') ||
        q.contains('pdf') ||
        q.contains('download');
  }
}

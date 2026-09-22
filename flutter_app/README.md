# Flutter Interactive Lab

Executable experiments inside the Astro portfolio's lazy multi-view overlay:

- **Local Intelligence:** existing WebGPU + MLC LLM portfolio assistant, model downloads and browser capability fallback.
- **Semantic Decisions / Jev Guessr:** a description game using independent Choice, Noul and Score judgments, followed by deterministic Dart policy.

Experiments are registered in lib/labs/lab_registry.dart. The game uses explicit domain types and replaceable live/mock providers. No TypeSafe credential is compiled into Flutter.

See [the lab guide](../docs/interactive-lab.md) for integrated development commands, mock fixtures, flags, deployment and security boundaries. Resume content remains in site/src/data/resume.ts; Local Intelligence fetches its generated JSON.

From this directory, run flutter pub get, flutter analyze and flutter test. Run the root node scripts/build.mjs pipeline for a web build, then serve the Astro host as described in the guide. The custom bootstrap expects a multi-view host rather than starting a standalone browser view.

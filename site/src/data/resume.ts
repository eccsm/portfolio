/**
 * Single source of truth for all site content.
 * Converted from the Flutter app's lib/pdf/resume_constants.dart.
 *
 * NOTE: this repo is public - never add a phone number or other PII here.
 */

export interface Profile {
  name: string;
  title: string;
  location: string;
  /** One-paragraph professional summary shown in the hero. */
  intro: string;
  /** Short tagline for meta descriptions and the og-image. */
  tagline: string;
}

export const canonicalOrigin = "https://ekincan.casim.net";
export const homepageCaseStudiesHref = "/#case-studies";
export const homepageProjectsHref = "/#projects";

export interface ExperienceEntry {
  company: string;
  role: string;
  location: string;
  /** ISO date (YYYY-MM) for <time datetime> and JSON-LD. */
  start: string;
  /** ISO date (YYYY-MM), or null while the role is current. */
  end: string | null;
  /** Human-readable range, e.g. "Jul 2025 - Present". */
  periodLabel: string;
  points: string[];
  tags: string[];
}

export interface CaseStudy {
  slug: string;
  title: string;
  client: string;
  /** Where this work happened, matching an ExperienceEntry company. */
  employer: string;
  summary: string;
  challenge: string;
  approach: string[];
  outcome: string;
  stack: string[];
  seoTitle?: string;
  seoDescription?: string;
}

export interface CaseStudyRouteChange {
  fromSlug: string;
  toSlug: string | null;
}


export interface ProjectLink {
  label: string;
  url: string;
}

export interface ProjectModule {
  name: string;
  summary: string;
}

export interface ProjectBullet {
  title: string;
  detail: string;
}

export interface ProjectDecision {
  title: string;
  detail: string;
}

export interface Project {
  id: string;
  slug: string;
  name: string;
  tagline: string;
  supportingMessage?: string;
  shortSummary: string;
  role: string;
  executiveSummary: string[];
  problem: string[];
  solution: string[];
  differentiators: string[];
  architecture: string[];
  keyDecisions: ProjectDecision[];
  tradeoffs: ProjectDecision[];
  modules: ProjectModule[];
  technologies: string[];
  privacyOrSecurityTitle?: string;
  privacyOrSecurity?: string[];
  capabilities: ProjectBullet[];
  repositoryLinks?: ProjectLink[];
  documentationLinks?: ProjectLink[];
  relatedCaseStudySlugs: string[];
  seoTitle?: string;
  seoDescription?: string;
  namingNote?: string;
}

export interface ProjectRouteChange {
  fromSlug: string;
  toSlug: string | null;
}

export interface SkillCategory {
  category: string;
  groups: { name: string; items: string[] }[];
}

export interface EducationEntry {
  institution: string;
  degree: string;
  location: string;
  start: string;
  end: string;
  periodLabel: string;
}

export interface Certification {
  name: string;
  issuer: string;
  year: number;
  url: string;
}

export interface Contact {
  email: string;
  linkedin: string;
  github: string;
  huggingface: string;
  website: string;
}

export const profile: Profile = {
  name: "Ekincan Casim",
  title: "Software Architect & Senior Java Engineer",
  location: "Istanbul, Turkey",
  intro:
    "Software Architect and Senior Java Engineer with 10+ years designing and " +
    "delivering enterprise-scale platforms in insurance, banking, and retail. " +
    "Track record of leading legacy-to-modern transformations (monolith -> " +
    "microservices, Oracle ADF -> Spring Boot 3.x), designing event-driven " +
    "architectures on Kafka, and embedding regulatory compliance (data " +
    "protection, auditability) into system design. Hands-on leader: architect " +
    "who still writes production code, mentors engineers, and drives decisions " +
    "through design reviews. Expert in Java 21, Spring Boot 3.x, domain-driven " +
    "design, and cloud-native delivery on Kubernetes.",
  tagline:
    "Enterprise platforms in insurance, banking, and retail - Java 21, Spring Boot 3.x, Kafka, Kubernetes.",
};

export const experiences: ExperienceEntry[] = [
  {
    company: "Medisa",
    role: "Software Architect & Lead Engineer",
    location: "Istanbul, Turkey",
    start: "2025-07",
    end: null,
    periodLabel: "Jul 2025 - Present",
    points: [
      "Architect and hands-on lead for an enterprise insurance platform built on Java 17/21 and Spring Boot 3.x, serving core policy and claims operations.",
      "Decomposed overloaded insurance domains into bounded contexts and independent microservices using domain-driven design, improving deployability and team ownership.",
      "Designed event-driven policy issuance and claims flows on Kafka with Redis caching, improving real-time notification throughput.",
      "Implemented data-protection compliance (KVKK) at the architecture level - response-layer masking, data classification, and audit trails - in collaboration with legal and security stakeholders.",
      "Built high-volume batch processing pipelines (hundreds of thousands of records) with proper transaction isolation, chunking, and index optimization.",
      "Established engineering standards: microservice templates, SonarQube quality gates, and code review practices, cutting onboarding time and technical debt.",
      "Migrated observability from ELK to Graylog and operate Dynatrace-based monitoring; investigate and resolve production incidents.",
      "Manage Rancher-orchestrated Kubernetes deployments with Jenkins CI/CD, reducing release cycle duration.",
    ],
    tags: [
      "Java 17/21",
      "Spring Boot 3",
      "Kafka",
      "Kubernetes",
      "DDD",
      "Graylog",
      "Dynatrace",
    ],
  },
  {
    company: "NTT DATA Business Solutions",
    role: "Business Applications Foundation Lead",
    location: "Istanbul, Turkey",
    start: "2022-08",
    end: "2025-07",
    periodLabel: "Aug 2022 - Jul 2025",
    points: [
      "Architect of record for Allianz's core system transformation from legacy Oracle ADF to Spring Boot 3.x, improving performance, maintainability, and scalability.",
      "Designed the Allianz Architectural Framework - a reusable enterprise architecture blueprint adopted across multiple teams as the standard development pattern.",
      "Built a GenAI-powered HR chatbot for Pegasus Airlines: Spring Boot microservices with Redis-based intelligent caching, rate limiting, and token-cost optimization for production LLM usage.",
      "Delivered microservices across multiple client engagements (Java 17, Spring Boot, Kafka, Angular); oversaw PostgreSQL and MongoDB implementations.",
      "Introduced CI/CD practices with Jenkins and GitLab pipelines, accelerating delivery cycles across teams.",
    ],
    tags: ["Java 17", "Spring Boot", "GenAI", "Redis", "Kafka", "Allianz"],
  },
  {
    company: "Yapi Kredi Teknoloji",
    role: "External Software Consultant",
    location: "Istanbul, Turkey",
    start: "2021-03",
    end: "2022-08",
    periodLabel: "Mar 2021 - Aug 2022",
    points: [
      "Re-architected the Harmoni insurance framework (Java 6/JSP/Oracle) at one of Turkey's largest banks into modular, microservice-ready components.",
      "Migrated the backend to Java 8 + Spring Boot, replaced JSP frontends with React, and tuned Oracle database performance in a regulated financial environment.",
      "Worked in Agile delivery cycles with code reviews and continuous integration.",
    ],
    tags: ["Java 8", "Spring Boot", "React", "Oracle", "Microservices"],
  },
  {
    company: "Toshiba Global Commerce Solutions",
    role: "Software Developer & Technical Team Leader",
    location: "Istanbul, Turkey",
    start: "2018-01",
    end: "2021-03",
    periodLabel: "Jan 2018 - Mar 2021",
    points: [
      "Led a development team delivering retail self-checkout (CHEC) and real-time monitoring (REMS) applications on Java and Spring.",
      "Managed implementations for global clients across France, Morocco, India, Singapore, and Korea, coordinating with distributed teams.",
      "Directed technology migrations including Java 11 and PostgreSQL upgrades, improving reliability.",
    ],
    tags: ["Java", "Spring", "PostgreSQL", "Global rollouts"],
  },
  {
    company: "Smartiks & BAYPM",
    role: "Software Developer - Earlier Roles",
    location: "Istanbul, Turkey",
    start: "2015-09",
    end: "2018-01",
    periodLabel: "Sep 2015 - Jan 2018",
    points: [
      "Developed Python forecasting libraries for a TUBITAK-supported Big Data project; optimized MS SQL and Elasticsearch workloads (Smartiks).",
      "Delivered enterprise workflow applications (e-contract management, supplier portals) on Java and low-code platforms (BAYPM).",
    ],
    tags: ["Python", "MS SQL", "Elasticsearch", "OutSystems", "Java"],
  },
];

export const caseStudies: CaseStudy[] = validateCaseStudies([
  {
    slug: "allianz-core-transformation",
    title: "Allianz core system transformation",
    client: "Allianz",
    employer: "NTT DATA Business Solutions",
    summary:
      "Modernizing Allianz's core insurance stack from Oracle ADF to Spring Boot 3.x and packaging the resulting patterns into a reusable architectural framework.",
    challenge:
      "A legacy Oracle ADF core insurance system had become slow to change and hard to scale, and every team was solving the same architectural problems independently.",
    approach: [
      "Served as architect of record for the migration from Oracle ADF to Spring Boot 3.x, replacing the monolithic presentation-and-logic coupling with layered, testable services.",
      "Designed the Allianz Architectural Framework - a reusable enterprise blueprint covering project structure, cross-cutting concerns, and integration patterns.",
      "Drove adoption through design reviews and reference implementations rather than mandates.",
    ],
    outcome:
      "The framework was adopted across multiple teams as the standard development pattern, and the modernized stack improved performance, maintainability, and scalability of core systems.",
    stack: [
      "Java 17",
      "Spring Boot 3.x",
      "Oracle ADF (legacy)",
      "Kafka",
      "PostgreSQL",
    ],
    seoDescription:
      "How Allianz's core insurance platform moved from Oracle ADF to Spring Boot 3.x, with a reusable architecture framework for multiple delivery teams.",
  },
  {
    slug: "insurance-ddd-kafka",
    title: "Insurance platform modernization with DDD and Kafka",
    client: "Medisa",
    employer: "Medisa",
    summary:
      "Breaking a policy-and-claims platform into bounded contexts and Kafka-driven flows while baking KVKK compliance into the architecture.",
    challenge:
      "An enterprise insurance platform with overloaded domains: policy, claims, and notification logic tangled together, slowing releases and blurring team ownership - all under KVKK data-protection obligations.",
    approach: [
      "Decomposed the domain into bounded contexts and independent microservices using domain-driven design.",
      "Designed event-driven policy issuance and claims flows on Kafka with Redis caching for real-time notifications.",
      "Embedded compliance into the architecture itself: response-layer masking, data classification, and audit trails designed with legal and security stakeholders.",
      "Built high-volume batch pipelines (hundreds of thousands of records) with transaction isolation, chunking, and index optimization.",
    ],
    outcome:
      "Improved deployability and team ownership, higher notification throughput, and KVKK compliance enforced by design rather than by convention - plus shorter release cycles via Rancher-orchestrated Kubernetes and Jenkins CI/CD.",
    stack: [
      "Java 21",
      "Spring Boot 3.x",
      "Kafka",
      "Redis",
      "Kubernetes",
      "Graylog",
      "Dynatrace",
    ],
    seoDescription:
      "A case study in decomposing an insurance platform with domain-driven design, Kafka event flows, and architecture-level KVKK compliance.",
  },
  {
    slug: "genai-hr-chatbot",
    title: "GenAI-powered HR chatbot for Pegasus Airlines",
    client: "Pegasus Airlines",
    employer: "NTT DATA Business Solutions",
    summary:
      "Building a production HR chatbot with caching, rate limiting, and cost controls around real-world LLM usage.",
    challenge:
      "HR needed a conversational assistant for employees, but naive LLM integration would have meant unpredictable API costs and no protection against traffic spikes.",
    approach: [
      "Built the chatbot as Spring Boot microservices with a clean boundary between conversation logic and the LLM provider.",
      "Implemented Redis-based intelligent caching so repeated questions never hit the LLM twice.",
      "Added rate limiting and token-cost optimization strategies tuned for production LLM usage.",
    ],
    outcome:
      "A production GenAI service with controlled, predictable API costs and stable behavior under load - one of the earliest LLM systems shipped to production in the company's portfolio.",
    stack: ["Java 17", "Spring Boot", "GenAI APIs", "Redis", "Rate limiting"],
    seoDescription:
      "How a production HR chatbot for Pegasus Airlines balanced Spring Boot microservices, Redis caching, rate limiting, and predictable LLM cost control.",
  },
  {
    slug: "harmoni-modernization",
    title: "Harmoni insurance framework re-architecture",
    client: "Yapi Kredi",
    employer: "Yapi Kredi Teknoloji",
    summary:
      "Re-architecting a Java 6/JSP/Oracle insurance framework into modular, Spring Boot-ready components for a regulated banking environment.",
    challenge:
      "A Java 6/JSP/Oracle insurance framework at one of Turkey's largest banks had reached the end of its maintainable life, inside a heavily regulated financial environment.",
    approach: [
      "Analyzed and modularized the monolith into microservice-ready components.",
      "Migrated the backend to Java 8 + Spring Boot and replaced JSP frontends with React.",
      "Tuned Oracle database performance and worked in Agile cycles with code reviews and CI.",
    ],
    outcome:
      "A modular, testable codebase ready for incremental microservice extraction, delivered without disrupting a regulated production banking environment.",
    stack: ["Java 8", "Spring Boot", "React", "Oracle"],
    seoDescription:
      "A case study in re-architecting the Harmoni insurance framework from Java 6 and JSP into modular Spring Boot-ready services for a regulated bank.",
  },
]);

export const caseStudyRouteChanges: CaseStudyRouteChange[] =
  validateCaseStudyRouteChanges(caseStudies, []);

export const projects: Project[] = validateProjects([
  {
    id: "rigoryn",
    slug: "archmet",
    name: "Rigoryn",
    tagline: "Deterministic software intelligence for architecture governance",
    supportingMessage: "Measure architecture. Govern change.",
    shortSummary:
      "A deterministic software-intelligence platform for analyzing architecture, dependencies, structural risks, and technical debt across multi-language systems, with AI reserved for explaining verified findings.",
    role: "Creator, software architect, deterministic analysis design, optional AI interpretation strategy",
    executiveSummary: [
      "Rigoryn is a deterministic software-intelligence platform for architecture analysis, dependency intelligence, and technical-debt governance across multiple programming languages.",
      "Its analysis engine is designed to produce evidence-backed findings from shared models, metrics, and graph relationships. Archimet is the optional AI layer that explains those findings without replacing deterministic analysis.",
    ],
    problem: [
      "Architecture drift rarely shows up as a single lint error. The harder problems are structural: coupling hotspots, dependency cycles, layering erosion, N+1 patterns, and slow technical-debt accumulation across services and modules.",
      "Rigoryn is designed to make those issues measurable and reviewable while keeping the source of truth in deterministic analysis rather than opaque model output.",
    ],
    solution: [
      "The platform is designed around a unified analysis model that can normalize multiple languages into one dependency and architecture view.",
      "Deterministic rules, shared metrics, and framework-aware classification provide the evidence. The AI layer remains optional and is intended to explain verified findings, summarize risk, and support remediation workflows.",
    ],
    differentiators: [
      "Deterministic engine first, optional LLM second.",
      "One normalized language model instead of separate per-language reports.",
      "Evidence-backed findings with metrics, thresholds, and graph paths attached.",
      "Self-hosted-first deployment with BYO-LLM as an explicit choice rather than a requirement.",
    ],
    architecture: [
      "The architecture separates language-specific parsers from a shared class and dependency model so findings can be scored consistently across ecosystems.",
      "The analysis model is designed to capture metrics such as WMC, LCOM, CBO, RFC, fan-in/fan-out, and cyclomatic complexity, alongside higher-level detections like god classes, coupling hotspots, circular dependencies, and N+1 query patterns.",
      "The design separates a scanner/CLI, server-side reporting, and the optional Archimet interpretation layer.",
    ],
    keyDecisions: [
      {
        title: "Deterministic findings before LLM commentary",
        detail:
          "The deterministic engine is the source of truth so reports remain reproducible, CI-friendly, and reviewable without trusting model output.",
      },
      {
        title: "Unified multi-language model",
        detail:
          "Normalizing multiple ecosystems into one model enables cross-language scoring and governance instead of producing isolated parser-specific reports.",
      },
      {
        title: "Optional graph and queue infrastructure",
        detail:
          "Neo4j and Kafka are kept optional so teams can adopt graph exploration or queue-backed analysis jobs without making them mandatory for every deployment.",
      },
      {
        title: "Validate evidence before explanation",
        detail:
          "LLM recommendations are intended to stay grounded in already-validated metrics and paths rather than inventing unsupported remediation advice.",
      },
    ],
    tradeoffs: [
      {
        title: "Higher implementation complexity than lint-only tooling",
        detail:
          "A calibrated, graph-aware, multi-language engine is more expensive to build and maintain than isolated rule packs, but it targets architecture problems that simpler tooling often misses.",
      },
      {
        title: "Optional platform services add operational weight",
        detail:
          "Server, dashboard, graph storage, and queueing broaden the product surface, which creates more deployment choices and more system ownership overhead.",
      },
      {
        title: "LLM value depends on evidence quality",
        detail:
          "Keeping the LLM layer optional protects determinism, but it also means the usefulness of natural-language guidance depends entirely on the fidelity of the underlying engine.",
      },
    ],
    modules: [
      {
        name: "Scanner / CLI",
        summary:
          "The scanner/CLI is designed as the deterministic analysis entry point for local runs, CI, and report generation.",
      },
      {
        name: "Server REST API",
        summary:
          "The service layer is designed to separate report persistence and analysis jobs from the analysis engine.",
      },
      {
        name: "Archimet optional LLM layer",
        summary:
          "Archimet is the optional AI interpretation layer for grounded explanations, refactoring guidance, and natural-language interaction around deterministic findings.",
      },
    ],
    technologies: [
      "Java",
      "Kotlin",
      "Gradle",
      "Eclipse JDT",
      "Kotlin compiler PSI",
      "Roslyn",
      "Python ast",
      "SWC",
      "Spring Boot",
      "PostgreSQL",
      "Redis",
      "Neo4j",
      "Kafka",
      "Next.js",
      "Docker",
      "Ollama",
      "llama.cpp",
      "OpenAI-compatible providers",
    ],
    privacyOrSecurityTitle: "Privacy and deployment",
    privacyOrSecurity: [
      "Rigoryn is positioned as self-hosted first so source code and findings can stay inside the team infrastructure.",
      "The AI layer is designed around BYO-LLM support, including local model options such as Ollama or llama.cpp when teams want deterministic analysis without mandatory cloud inference.",
      "That separation keeps deterministic analysis useful on its own while AI-assisted interpretation remains an explicit deployment choice.",
    ],
    capabilities: [
      {
        title: "Deterministic architecture analysis",
        detail:
          "The analysis design combines deterministic parsing, dependency graphs, and architecture-aware rules for evidence-backed findings.",
      },
      {
        title: "Unified multi-language analysis model",
        detail:
          "The platform is designed around a shared analysis model, with language adapters feeding one governance-oriented view instead of isolated parser reports.",
      },
      {
        title: "Evidence-backed risk scoring",
        detail:
          "Metrics, thresholds, and graph paths are intended to stay attached to each finding so architectural decisions can be reviewed and defended.",
      },
      {
        title: "Optional LLM interpretation",
        detail:
          "Archimet is designed as an explanation layer that works from verified findings rather than generating them.",
      },
    ],
    relatedCaseStudySlugs: [
      "allianz-core-transformation",
      "insurance-ddd-kafka",
    ],
    seoTitle: "Rigoryn - Deterministic Software Intelligence | Ekincan Casim",
    seoDescription:
      "Rigoryn is a deterministic software-intelligence platform for architecture analysis, technical-debt governance, multi-language code intelligence, and optional AI-assisted interpretation.",
    namingNote:
      "Rigoryn is the product name. Archimet names the optional AI interpretation layer, and the original AMF codename remains in machine-facing identifiers for compatibility.",
  },
  {
    id: "harmonova",
    slug: "harmonova",
    name: "Harmonova",
    tagline: "Production-oriented intelligent music-system architecture",
    shortSummary:
      "An intelligent music-system architecture that combines a deterministic music-theory core with Spring AI orchestration, MCP service boundaries, retrieval, and isolated audio analysis.",
    role: "Creator, software architect, deterministic domain modeling, Spring AI orchestration, MCP boundary design",
    executiveSummary: [
      "Harmonova explores how deterministic domain models, retrieval, AI orchestration, and specialized analysis services can work together in a production-oriented intelligent system.",
      "Music theory stays inside a pure Java core, while AI components handle interpretation, planning, and recommendations around verified facts instead of becoming the source of musical truth.",
    ],
    problem: [
      "LLMs are helpful for conversational composition workflows, but they are unreliable for exact scale spelling, chord progressions, or deterministic beat-generation rules on their own.",
      "At the same time, audio, DSP, and ML workloads can quickly pollute an otherwise clean domain core unless their boundaries are enforced deliberately.",
    ],
    solution: [
      "Harmonova keeps theory and beat logic inside a deterministic domain core, then exposes that core through MCP tools and service APIs where orchestration is useful.",
      "A Spring Boot layer coordinates tutor and beat-maker flows with retrieval, provider routing, and tool use, while a separate Python service handles audio-analysis workloads behind a narrow boundary.",
    ],
    differentiators: [
      "Deterministic work stays in the core; LLMs are reserved for natural language and orchestration.",
      "Dependencies point inward: web and MCP depend on core, but core depends on neither.",
      "Deterministic endpoints can bypass MCP and LLM layers when conversational orchestration is unnecessary.",
      "Audio bytes, DSP, and ML remain isolated in Python instead of leaking into the Java core.",
    ],
    architecture: [
      "The system is organized around four codebases: harmonova-core, harmonova-mcp-server, harmonova, and harmonova-audio-analysis-service.",
      "The web application and MCP server depend on harmonova-core, while the Python audio-analysis service stays outside that dependency graph and is reached through a thin HTTP boundary.",
      "Agent workflows are designed around a PLAN -> FACTS -> RAG -> COMPOSE -> VERIFY -> EMIT pipeline so model output can be checked against deterministic tools and retrieved context.",
    ],
    keyDecisions: [
      {
        title: "Deterministic core versus probabilistic orchestration",
        detail:
          "Music theory, beat composition parameters, and fact verification remain in the pure Java core so the AI layer cannot invent exact musical facts.",
      },
      {
        title: "MCP boundary instead of direct tool coupling",
        detail:
          "Tool definitions stay in the MCP server, which makes the domain core reusable without dragging web or AI concerns into it.",
      },
      {
        title: "RAG grounding for conversational flows",
        detail:
          "The tutor and beat-maker flows use retrieved material to ground prompts rather than relying on unconstrained model generation.",
      },
      {
        title: "Python ML isolation",
        detail:
          "Keeping audio analysis outside the Java core reduces domain pollution at the cost of another service boundary.",
      },
    ],
    tradeoffs: [
      {
        title: "More moving parts than a single app",
        detail:
          "Polyrepo ownership, MCP transport, vector storage, and the Python service make the system more modular, but also more operationally involved.",
      },
      {
        title: "Local-first options still require infrastructure",
        detail:
          "Ollama, pgvector, reranking, and observability can stay self-hosted, but that local-first posture still brings setup overhead that a simpler demo would avoid.",
      },
      {
        title: "Deterministic boundaries limit shortcutting",
        detail:
          "The design deliberately prevents the LLM from becoming the source of musical truth, which improves correctness but can slow down rapid prototyping.",
      },
    ],
    modules: [
      {
        name: "harmonova-core",
        summary:
          "The deterministic music-theory and beat-generation core is the center of the system and is kept free of Spring, AI, and audio dependencies.",
      },
      {
        name: "harmonova-mcp-server",
        summary:
          "The MCP server wraps deterministic core operations so model-facing orchestration can use tools without polluting the domain layer.",
      },
      {
        name: "harmonova",
        summary:
          "The Spring Boot application carries REST endpoints, agents, retrieval, provider routing, and the user-facing orchestration layer.",
      },
      {
        name: "harmonova-audio-analysis-service",
        summary:
          "The Python and FastAPI audio-analysis service contains the DSP and ML workload that intentionally sits outside the pure domain core.",
      },
    ],
    technologies: [
      "Java",
      "Spring Boot",
      "Spring AI",
      "MCP",
      "Ollama",
      "PostgreSQL",
      "pgvector",
      "Infinity reranker",
      "Python",
      "FastAPI",
      "librosa",
      "PyTorch",
      "MERT",
      "OpenTelemetry",
      "Langfuse",
      "Prometheus",
      "Loki",
      "Grafana",
      "Docker Compose",
    ],
    privacyOrSecurityTitle: "Local-first and boundary choices",
    privacyOrSecurity: [
      "Harmonova favors local-first AI components where that supports control and experimentation, including local model, embedding, and reranking options.",
      "The architecture keeps audio bytes, DSP, and ML behind a single HTTP boundary instead of letting those concerns spread through the rest of the Java system.",
      "Provider routing stays explicit so deterministic domain logic can remain stable even as AI components evolve.",
    ],
    capabilities: [
      {
        title: "Deterministic music theory in core",
        detail:
          "The domain design centers on a pure Java core for scales, chord progressions, melody analysis, seeded beat composition, and MIDI-oriented domain operations.",
      },
      {
        title: "Agent orchestration over deterministic facts",
        detail:
          "The tutor and beat-maker flows are designed so Spring AI agents plan and explain around deterministic tools instead of inventing theory facts.",
      },
      {
        title: "Retrieval and tool integration",
        detail:
          "RAG, local retrieval components, and MCP tools provide the grounding layer around the core domain model.",
      },
      {
        title: "Isolated audio analysis service",
        detail:
          "The architecture isolates audio-analysis and ML workloads in a separate Python service so the core and orchestration layers stay focused.",
      },
    ],
    repositoryLinks: [
      {
        label: "harmonova-core repository",
        url: "https://github.com/harmonova/core",
      },
      {
        label: "harmonova-mcp-server repository",
        url: "https://github.com/harmonova/mcp-server",
      },
      {
        label: "harmonova web repository",
        url: "https://github.com/harmonova/base",
      },
      {
        label: "harmonova-audio-analysis-service repository",
        url: "https://github.com/harmonova/audio-analysis",
      },
    ],
    relatedCaseStudySlugs: ["genai-hr-chatbot"],
    seoTitle: "Harmonova - Deterministic Music AI Architecture | Ekincan Casim",
    seoDescription:
      "Harmonova explores intelligent music-system architecture combining deterministic music theory, Spring AI orchestration, MCP tools, retrieval, and isolated audio analysis.",
  },
]);

export const projectRouteChanges: ProjectRouteChange[] =
  validateProjectRouteChanges(projects, []);

export function validateCaseStudies(records: CaseStudy[]): CaseStudy[] {
  const seen = new Set<string>();

  for (const record of records) {
    if (!record.slug.trim()) {
      throw new Error("Case studies must have a non-empty slug.");
    }
    if (seen.has(record.slug)) {
      throw new Error(`Duplicate case study slug: ${record.slug}`);
    }
    seen.add(record.slug);

    const requiredFields = [
      ["title", record.title],
      ["client", record.client],
      ["employer", record.employer],
      ["summary", record.summary],
      ["challenge", record.challenge],
      ["outcome", record.outcome],
    ] as const;

    for (const [field, value] of requiredFields) {
      if (!value.trim()) {
        throw new Error(`Case study "${record.slug}" is missing ${field}.`);
      }
    }

    if (record.approach.length === 0) {
      throw new Error(
        `Case study "${record.slug}" must have at least one approach item.`,
      );
    }
    if (record.stack.length === 0) {
      throw new Error(
        `Case study "${record.slug}" must have at least one technology.`,
      );
    }
  }

  return records;
}

export function validateCaseStudyRouteChanges(
  records: CaseStudy[],
  changes: CaseStudyRouteChange[],
): CaseStudyRouteChange[] {
  const activeSlugs = new Set(records.map((record) => record.slug));
  const seen = new Set<string>();

  for (const change of changes) {
    if (!change.fromSlug.trim()) {
      throw new Error(
        "Legacy case study routes must have a non-empty fromSlug.",
      );
    }
    if (seen.has(change.fromSlug)) {
      throw new Error(`Duplicate legacy case study route: ${change.fromSlug}`);
    }
    if (activeSlugs.has(change.fromSlug)) {
      throw new Error(
        `Legacy case study route conflicts with active slug: ${change.fromSlug}`,
      );
    }
    seen.add(change.fromSlug);

    if (change.toSlug !== null) {
      if (!change.toSlug.trim()) {
        throw new Error(
          `Legacy case study route "${change.fromSlug}" must use null or a non-empty toSlug.`,
        );
      }
      if (change.toSlug === change.fromSlug) {
        throw new Error(
          `Legacy case study route "${change.fromSlug}" cannot redirect to itself.`,
        );
      }
      if (!activeSlugs.has(change.toSlug)) {
        throw new Error(
          `Legacy case study route "${change.fromSlug}" points to unknown slug: ${change.toSlug}`,
        );
      }
    }
  }

  return changes;
}

export function validateProjects(records: Project[]): Project[] {
  const seen = new Set<string>();

  for (const record of records) {
    if (!record.slug.trim()) {
      throw new Error("Projects must have a non-empty slug.");
    }
    if (seen.has(record.slug)) {
      throw new Error(`Duplicate project slug: ${record.slug}`);
    }
    seen.add(record.slug);

    const requiredFields = [
      ["id", record.id],
      ["name", record.name],
      ["tagline", record.tagline],
      ["shortSummary", record.shortSummary],
      ["role", record.role],
    ] as const;

    for (const [field, value] of requiredFields) {
      if (!value.trim()) {
        throw new Error(`Project "${record.slug}" is missing ${field}.`);
      }
    }

    if (record.executiveSummary.length === 0) {
      throw new Error(
        `Project "${record.slug}" must have an executive summary.`,
      );
    }
    if (record.problem.length === 0) {
      throw new Error(`Project "${record.slug}" must describe a problem.`);
    }
    if (record.solution.length === 0) {
      throw new Error(`Project "${record.slug}" must describe a solution.`);
    }
    if (record.modules.length === 0) {
      throw new Error(
        `Project "${record.slug}" must describe at least one module.`,
      );
    }
    if (!record.capabilities.length) {
      throw new Error(`Project "${record.slug}" must describe engineering capabilities.`);
    }
    if (record.technologies.length === 0) {
      throw new Error(`Project "${record.slug}" must list technologies.`);
    }
  }

  return records;
}

export function validateProjectRouteChanges(
  records: Project[],
  changes: ProjectRouteChange[],
): ProjectRouteChange[] {
  const activeSlugs = new Set(records.map((record) => record.slug));
  const seen = new Set<string>();

  for (const change of changes) {
    if (!change.fromSlug.trim()) {
      throw new Error("Legacy project routes must have a non-empty fromSlug.");
    }
    if (seen.has(change.fromSlug)) {
      throw new Error(`Duplicate legacy project route: ${change.fromSlug}`);
    }
    if (activeSlugs.has(change.fromSlug)) {
      throw new Error(
        `Legacy project route conflicts with active slug: ${change.fromSlug}`,
      );
    }
    seen.add(change.fromSlug);

    if (change.toSlug !== null) {
      if (!change.toSlug.trim()) {
        throw new Error(
          `Legacy project route "${change.fromSlug}" must use null or a non-empty toSlug.`,
        );
      }
      if (change.toSlug === change.fromSlug) {
        throw new Error(
          `Legacy project route "${change.fromSlug}" cannot redirect to itself.`,
        );
      }
      if (!activeSlugs.has(change.toSlug)) {
        throw new Error(
          `Legacy project route "${change.fromSlug}" points to unknown slug: ${change.toSlug}`,
        );
      }
    }
  }

  return changes;
}

export function getCaseStudyPath(caseStudyOrSlug: CaseStudy | string): string {
  const slug =
    typeof caseStudyOrSlug === "string"
      ? caseStudyOrSlug
      : caseStudyOrSlug.slug;
  return `/case-studies/${slug}/`;
}

export function getCaseStudyCanonicalUrl(
  caseStudyOrSlug: CaseStudy | string,
): string {
  return new URL(getCaseStudyPath(caseStudyOrSlug), canonicalOrigin).toString();
}

export function getLegacyCaseStudyPath(
  routeChangeOrSlug: CaseStudyRouteChange | string,
): string {
  const slug =
    typeof routeChangeOrSlug === "string"
      ? routeChangeOrSlug
      : routeChangeOrSlug.fromSlug;
  return getCaseStudyPath(slug);
}

export function getLegacyCaseStudyCanonicalUrl(
  routeChangeOrSlug: CaseStudyRouteChange | string,
): string {
  return new URL(
    getLegacyCaseStudyPath(routeChangeOrSlug),
    canonicalOrigin,
  ).toString();
}

export function getCaseStudySeoTitle(caseStudy: CaseStudy): string {
  return caseStudy.seoTitle ?? `${caseStudy.title} | ${profile.name}`;
}

export function getCaseStudySeoDescription(caseStudy: CaseStudy): string {
  return caseStudy.seoDescription ?? caseStudy.summary;
}

export function getCaseStudyContext(caseStudy: CaseStudy): string {
  return `${caseStudy.client} · via ${caseStudy.employer}`;
}

export function getCaseStudyExperience(
  caseStudy: CaseStudy,
): ExperienceEntry | undefined {
  return experiences.find(
    (experience) => experience.company === caseStudy.employer,
  );
}

export function getCaseStudyPeriodLabel(caseStudy: CaseStudy): string | null {
  return getCaseStudyExperience(caseStudy)?.periodLabel ?? null;
}

export function getCaseStudyBySlug(slug: string): CaseStudy | undefined {
  return caseStudies.find((caseStudy) => caseStudy.slug === slug);
}

export function getCaseStudyPages(records: CaseStudy[] = caseStudies) {
  validateCaseStudies(records);
  return records.map((caseStudy, index) => ({
    caseStudy,
    previous: index > 0 ? records[index - 1] : null,
    next: index < records.length - 1 ? records[index + 1] : null,
  }));
}

export function getProjectPath(projectOrSlug: Project | string): string {
  const slug =
    typeof projectOrSlug === "string" ? projectOrSlug : projectOrSlug.slug;
  return `/projects/${slug}/`;
}

export function getProjectCanonicalUrl(
  projectOrSlug: Project | string,
): string {
  return new URL(getProjectPath(projectOrSlug), canonicalOrigin).toString();
}

export function getLegacyProjectPath(
  routeChangeOrSlug: ProjectRouteChange | string,
): string {
  const slug =
    typeof routeChangeOrSlug === "string"
      ? routeChangeOrSlug
      : routeChangeOrSlug.fromSlug;
  return getProjectPath(slug);
}

export function getLegacyProjectCanonicalUrl(
  routeChangeOrSlug: ProjectRouteChange | string,
): string {
  return new URL(
    getLegacyProjectPath(routeChangeOrSlug),
    canonicalOrigin,
  ).toString();
}

export function getProjectSeoTitle(project: Project): string {
  return project.seoTitle ?? `${project.name} | ${profile.name}`;
}

export function getProjectSeoDescription(project: Project): string {
  return project.seoDescription ?? project.shortSummary;
}

export function getProjectBySlug(slug: string): Project | undefined {
  return projects.find((project) => project.slug === slug);
}

export function getProjectPages(records: Project[] = projects) {
  validateProjects(records);
  return records.map((project, index) => ({
    project,
    previous: index > 0 ? records[index - 1] : null,
    next: index < records.length - 1 ? records[index + 1] : null,
  }));
}

export const skills: SkillCategory[] = [
  {
    category: "Languages",
    groups: [
      {
        name: "Programming",
        items: [
          "Java (11-21)",
          "Kotlin",
          "Python",
          "JavaScript/TypeScript",
          "SQL",
        ],
      },
    ],
  },
  {
    category: "Backend & Architecture",
    groups: [
      { name: "Frameworks", items: ["Spring Boot 3.x", "Spring Cloud"] },
      {
        name: "Architecture",
        items: [
          "Microservices",
          "Domain-Driven Design",
          "Event-Driven Architecture",
        ],
      },
      {
        name: "APIs & Messaging",
        items: ["REST", "GraphQL", "gRPC", "Kafka", "RabbitMQ", "Redis"],
      },
    ],
  },
  {
    category: "Data",
    groups: [
      {
        name: "Databases",
        items: ["Oracle", "PostgreSQL", "MS SQL", "MongoDB", "Elasticsearch"],
      },
      {
        name: "Performance",
        items: ["JPA/Hibernate tuning", "Batch processing at scale"],
      },
    ],
  },
  {
    category: "Cloud & DevOps",
    groups: [
      {
        name: "Containers & Orchestration",
        items: ["Kubernetes", "Docker", "Helm", "Rancher"],
      },
      { name: "Platforms", items: ["Azure", "AWS", "GCP"] },
      {
        name: "CI/CD & IaC",
        items: ["Jenkins", "GitLab CI/CD", "GitHub Actions", "Terraform"],
      },
    ],
  },
  {
    category: "Quality & Observability",
    groups: [
      { name: "Testing", items: ["TDD", "JUnit", "JMeter", "Gatling"] },
      {
        name: "Quality Gates & Monitoring",
        items: ["SonarQube", "Dynatrace", "Graylog", "ELK"],
      },
    ],
  },
  {
    category: "Frontend (working knowledge)",
    groups: [{ name: "Frameworks", items: ["React", "Angular"] }],
  },
  {
    category: "Practices",
    groups: [
      {
        name: "Ways of Working",
        items: [
          "Agile/Scrum",
          "Technical mentorship",
          "RFC-driven design reviews",
          "Compliance-aware engineering (KVKK/GDPR)",
        ],
      },
    ],
  },
];

export const education: EducationEntry[] = [
  {
    institution: "Dogus University",
    degree: "Master's Degree in Engineering and Technology Management",
    location: "Istanbul, Turkey",
    start: "2017-09",
    end: "2019-06",
    periodLabel: "Sep 2017 - Jun 2019",
  },
  {
    institution: "Maltepe University",
    degree: "Bachelor's Degree in Computer Engineering",
    location: "Istanbul, Turkey",
    start: "2011-09",
    end: "2015-06",
    periodLabel: "Sep 2011 - Jun 2015",
  },
];

export const certifications: Certification[] = [
  {
    name: "Cplace Certified Procode Developer",
    issuer: "Cplace",
    year: 2023,
    url: "https://www.cplace.com/en/academy/pro-code-training/",
  },
  {
    name: "OutSystems ODC Associate Developer",
    issuer: "OutSystems",
    year: 2016,
    url: "https://www.outsystems.com/certifications/academy-certifications/odc-developer",
  },
];

export const languages: { language: string; level: string }[] = [
  { language: "Turkish", level: "Native" },
  {
    language: "English",
    level: "Fluent - Maltepe University Proficiency Exam 80/100",
  },
];

// Phone number is intentionally absent - public repo (see repo policy).
export const contact: Contact = {
  email: "ekincan@casim.net",
  linkedin: "https://www.linkedin.com/in/eccsm",
  github: "https://github.com/eccsm",
  huggingface: "https://huggingface.co/eccsm",
  website: canonicalOrigin,
};

/** Self-assessed depth per area (0-10) for the Flutter radar chart. */
export const skillLevels: { name: string; value: number }[] = [
  { name: "Java / Spring Boot", value: 9.5 },
  { name: "Cloud & DevOps", value: 8.5 },
  { name: "System Architecture", value: 8.5 },
  { name: "Databases", value: 8.0 },
  { name: "Event-Driven (Kafka)", value: 8.0 },
  { name: "Frontend (React/Angular)", value: 6.5 },
  { name: "ML / LLM Integration", value: 6.5 },
];

/** Flat skill list for JSON-LD knowsAbout and the og-image. */
export const knowsAbout: string[] = [
  "Java",
  "Spring Boot",
  "Software Architecture",
  "Domain-Driven Design",
  "Event-Driven Architecture",
  "Apache Kafka",
  "Microservices",
  "Kubernetes",
  "PostgreSQL",
  "Oracle Database",
  "Redis",
  "CI/CD",
  "GenAI / LLM Integration",
];

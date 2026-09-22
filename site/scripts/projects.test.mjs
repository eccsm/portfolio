import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { loadResumeModuleFromFile } from "./resume-data.mjs";

const projectRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const {
  caseStudies,
  getProjectCanonicalUrl,
  getProjectPath,
  homepageProjectsHref,
  projectRouteChanges,
  projects,
  validateProjectRouteChanges,
  validateProjects,
} = await loadResumeModuleFromFile();

const expectedRoutes = ["/projects/archmet/", "/projects/harmonova/"];

test("Rigoryn keeps its inbound route and portfolio data excludes live status", () => {
  assert.equal(projects[0].name, "Rigoryn");
  assert.equal(projects[0].id, "rigoryn");
  assert.equal(getProjectPath(projects[0]), "/projects/archmet/");
  for (const project of projects) {
    assert.ok(!Object.hasOwn(project, "status"));
    assert.ok(!Object.hasOwn(project, "plannedCapabilities"));
    assert.doesNotMatch(JSON.stringify(project), /Current Status|In development|Experimental learning project|roadmap|Archmet/);
  }
});

test("every project has a unique non-empty slug and required content", () => {
  assert.equal(projects.length, expectedRoutes.length);
  validateProjects(projects);

  for (const project of projects) {
    assert.ok(project.slug.length > 0);
    assert.ok(project.name.length > 0);
    assert.ok(project.shortSummary.length > 0);
    assert.ok(project.executiveSummary.length > 0);
    assert.ok(project.problem.length > 0);
    assert.ok(project.solution.length > 0);
    assert.ok(project.modules.length > 0);
    assert.ok(project.capabilities.length > 0);
    assert.ok(project.technologies.length > 0);
    assert.ok(project.seoTitle?.length > 0);
    assert.ok(project.seoDescription?.length > 0);
  }
});

test("duplicate project slugs fail validation", () => {
  assert.throws(
    () =>
      validateProjects([
        projects[0],
        { ...projects[1], slug: projects[0].slug },
      ]),
    /Duplicate project slug/,
  );
});

test("each project produces the expected static route and canonical URL", () => {
  const routes = projects.map((project) => getProjectPath(project));
  assert.deepEqual(routes, expectedRoutes);

  const canonicals = projects.map((project) => getProjectCanonicalUrl(project));
  assert.deepEqual(
    canonicals,
    expectedRoutes.map((route) => `https://ekincan.casim.net${route}`),
  );
});

test("homepage projects anchor, nav link, and cards are wired to valid routes", async () => {
  assert.equal(homepageProjectsHref, "/#projects");

  const [siteNavSource, indexSource, projectsSource] = await Promise.all([
    readFile(join(projectRoot, "src", "components", "SiteNav.astro"), "utf8"),
    readFile(join(projectRoot, "src", "pages", "index.astro"), "utf8"),
    readFile(join(projectRoot, "src", "components", "Projects.astro"), "utf8"),
  ]);

  assert.match(siteNavSource, /#projects/);
  assert.match(indexSource, /<Projects \/>/);
  assert.match(projectsSource, /id="projects"/);
  assert.match(projectsSource, /Read the \{project\.name\} project page/);
});

test("related case study slugs point at real case-study records", () => {
  const caseStudySlugs = new Set(
    caseStudies.map((caseStudy) => caseStudy.slug),
  );

  for (const project of projects) {
    for (const slug of project.relatedCaseStudySlugs) {
      assert.equal(
        caseStudySlugs.has(slug),
        true,
        `Unknown case study slug: ${slug}`,
      );
    }
  }
});

test("legacy project route changes remain valid and collision-free", async () => {
  validateProjectRouteChanges(projects, projectRouteChanges);

  const firebase = JSON.parse(
    await readFile(join(projectRoot, "..", "firebase.json"), "utf8"),
  );
  const redirects = Array.isArray(firebase.hosting?.redirects)
    ? firebase.hosting.redirects
    : [];

  for (const routeChange of projectRouteChanges.filter(
    (change) => change.toSlug !== null,
  )) {
    const expectedSource = `/projects/${routeChange.fromSlug}`;
    const expectedDestination = `/projects/${routeChange.toSlug}/`;
    const match = redirects.find(
      (redirect) =>
        redirect.source === expectedSource &&
        redirect.destination === expectedDestination &&
        redirect.type === 301,
    );

    assert.ok(match, `Missing Firebase 301 redirect for ${expectedSource}`);
  }
});

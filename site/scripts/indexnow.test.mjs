import assert from 'node:assert/strict';
import { resolve } from 'node:path';
import test from 'node:test';

import {
  MAX_URLS_PER_BATCH,
  chunkUrls,
  diffRemovedCaseStudyUrls,
  diffRemovedProjectUrls,
  deriveRoutesFromChangedFiles,
  getCaseStudyUrlsFromResume,
  getIndexNowKeyLocation,
  getLegacyCaseStudyUrlsFromResume,
  getLegacyProjectUrlsFromResume,
  getProjectUrlsFromResume,
  loadSitemapUrls,
  normalizeIndexNowUrl,
  normalizeIndexableUrls,
  parseSitemap,
  shouldFallbackToSitemap,
  validateIndexNowKey,
} from './indexnow-lib.mjs';

test('validateIndexNowKey accepts safe keys and rejects invalid ones', () => {
  assert.equal(validateIndexNowKey('abc12345-KEY'), 'abc12345-KEY');
  assert.throws(() => validateIndexNowKey('short'), /INDEXNOW_KEY/);
  assert.throws(() => validateIndexNowKey('bad key value'), /INDEXNOW_KEY/);
});

test('normalizeIndexNowUrl forces https, strips fragments, and rejects non-canonical hosts', () => {
  const url = normalizeIndexNowUrl('/#experience');
  assert.equal(url.toString(), 'https://ekincan.casim.net/');

  const absolute = normalizeIndexNowUrl('http://ekincan.casim.net/projects?x=1#top');
  assert.equal(absolute.toString(), 'https://ekincan.casim.net/projects?x=1');

  assert.throws(() => normalizeIndexNowUrl('https://casim.net/'), /ekincan\.casim\.net/);
  assert.throws(() => normalizeIndexNowUrl('https://localhost:4321/'), /ekincan\.casim\.net/);
});

test('normalizeIndexableUrls deduplicates URLs and filters assets and verification files', () => {
  const urls = normalizeIndexableUrls([
    '/',
    'https://ekincan.casim.net/#case-studies',
    'https://ekincan.casim.net/assets/flutter/hash/index.html',
    'https://ekincan.casim.net/robots.txt',
    'https://ekincan.casim.net/about/',
    'https://ekincan.casim.net/about/',
  ]);

  assert.deepEqual(urls, ['https://ekincan.casim.net/', 'https://ekincan.casim.net/about/']);
});

test('chunkUrls batches well below the IndexNow limit', () => {
  const urls = Array.from({ length: MAX_URLS_PER_BATCH * 2 + 1 }, (_, index) =>
    `https://ekincan.casim.net/page-${index}/`
  );
  const batches = chunkUrls(urls);

  assert.equal(batches.length, 3);
  assert.equal(batches[0].length, MAX_URLS_PER_BATCH);
  assert.equal(batches[1].length, MAX_URLS_PER_BATCH);
  assert.equal(batches[2].length, 1);
});

test('parseSitemap and loadSitemapUrls support sitemap indexes and urlsets', async () => {
  const indexXml =
    '<?xml version="1.0"?><sitemapindex><sitemap><loc>https://ekincan.casim.net/sitemap-0.xml</loc></sitemap></sitemapindex>';
  const pageXml =
    '<?xml version="1.0"?><urlset><url><loc>https://ekincan.casim.net/</loc></url><url><loc>https://ekincan.casim.net/about/</loc></url></urlset>';

  assert.deepEqual(parseSitemap(pageXml), {
    type: 'urlset',
    locs: ['https://ekincan.casim.net/', 'https://ekincan.casim.net/about/'],
  });

  const loadText = async (source) => {
    if (source === 'https://ekincan.casim.net/sitemap-index.xml') return indexXml;
    if (source === 'https://ekincan.casim.net/sitemap-0.xml') return pageXml;
    throw new Error(`Unexpected sitemap source: ${source}`);
  };

  const urls = await loadSitemapUrls('https://ekincan.casim.net/sitemap-index.xml', { loadText });
  assert.deepEqual(urls, ['https://ekincan.casim.net/', 'https://ekincan.casim.net/about/']);
});

test('loadSitemapUrls resolves nested sitemap files locally during dry runs', async () => {
  const indexPath = resolve('dist', 'sitemap-index.xml');
  const pagePath = resolve('dist', 'sitemap-0.xml');
  const files = new Map([
    [
      indexPath,
      '<?xml version="1.0"?><sitemapindex><sitemap><loc>https://ekincan.casim.net/sitemap-0.xml</loc></sitemap></sitemapindex>',
    ],
    [
      pagePath,
      '<?xml version="1.0"?><urlset><url><loc>https://ekincan.casim.net/</loc></url><url><loc>https://ekincan.casim.net/case-studies/allianz-core-transformation/</loc></url></urlset>',
    ],
  ]);

  const urls = await loadSitemapUrls(indexPath, {
    loadText: async (source) => {
      const match = files.get(source);
      if (!match) {
        throw new Error(`Unexpected sitemap source: ${source}`);
      }
      return match;
    },
  });

  assert.deepEqual(urls, [
    'https://ekincan.casim.net/',
    'https://ekincan.casim.net/case-studies/allianz-core-transformation/',
  ]);
});

test('current sitemap-style URL sets remain homepage plus canonical project and case-study pages only', () => {
  const resume = {
    caseStudies: [
      { slug: 'allianz-core-transformation' },
      { slug: 'insurance-ddd-kafka' },
      { slug: 'genai-hr-chatbot' },
      { slug: 'harmoni-modernization' },
    ],
    projects: [{ slug: 'archmet' }, { slug: 'harmonova' }],
  };

  assert.deepEqual(getCaseStudyUrlsFromResume(resume), [
    'https://ekincan.casim.net/case-studies/allianz-core-transformation/',
    'https://ekincan.casim.net/case-studies/insurance-ddd-kafka/',
    'https://ekincan.casim.net/case-studies/genai-hr-chatbot/',
    'https://ekincan.casim.net/case-studies/harmoni-modernization/',
  ]);
  assert.deepEqual(getProjectUrlsFromResume(resume), [
    'https://ekincan.casim.net/projects/archmet/',
    'https://ekincan.casim.net/projects/harmonova/',
  ]);

  assert.deepEqual(
    normalizeIndexableUrls([
      'https://ekincan.casim.net/',
      'https://ekincan.casim.net/#experience',
      'https://ekincan.casim.net/#projects',
      'https://ekincan.casim.net/#case-studies',
      'https://ekincan.casim.net/assets/flutter/2b9f573/index.html',
      ...getProjectUrlsFromResume(resume),
      ...getCaseStudyUrlsFromResume(resume),
      'https://ekincan.casim.net/BingSiteAuth.xml',
    ]),
    [
      'https://ekincan.casim.net/',
      ...getProjectUrlsFromResume(resume),
      ...getCaseStudyUrlsFromResume(resume),
    ]
  );
});

test('deriveRoutesFromChangedFiles maps static Astro pages and falls back for site-wide changes', () => {
  assert.deepEqual(
    deriveRoutesFromChangedFiles([
      'site/src/pages/index.astro',
      'site/src/pages/about.astro',
      'site/src/pages/blog/index.astro',
      'site/src/pages/[slug].astro',
      'site/src/pages/404.astro',
    ]),
    ['/', '/about/', '/blog/']
  );

  assert.equal(
    shouldFallbackToSitemap(['site/src/components/Hero.astro', 'README.md']),
    true
  );
  assert.equal(shouldFallbackToSitemap(['site/src/pages/case-studies/[slug].astro']), true);
  assert.equal(shouldFallbackToSitemap(['site/src/pages/about.astro']), true);
});

test('getIndexNowKeyLocation builds the canonical verification URL', () => {
  assert.equal(
    getIndexNowKeyLocation('abc12345-KEY'),
    'https://ekincan.casim.net/abc12345-KEY.txt'
  );
});

test('legacy case-study URLs are preserved for notifications after slug changes', () => {
  const previousResume = {
    caseStudies: [
      { slug: 'legacy-allianz' },
      { slug: 'insurance-ddd-kafka' },
    ],
  };
  const currentResume = {
    caseStudies: [
      { slug: 'allianz-core-transformation' },
      { slug: 'insurance-ddd-kafka' },
    ],
    caseStudyRouteChanges: [{ fromSlug: 'legacy-allianz', toSlug: 'allianz-core-transformation' }],
  };

  assert.deepEqual(diffRemovedCaseStudyUrls(previousResume, currentResume), [
    'https://ekincan.casim.net/case-studies/legacy-allianz/',
  ]);
  assert.deepEqual(getLegacyCaseStudyUrlsFromResume(currentResume), [
    'https://ekincan.casim.net/case-studies/legacy-allianz/',
  ]);
});

test('legacy project URLs are preserved for notifications after slug changes', () => {
  const previousResume = {
    projects: [{ slug: 'legacy-archmet' }, { slug: 'harmonova' }],
  };
  const currentResume = {
    projects: [{ slug: 'archmet' }, { slug: 'harmonova' }],
    projectRouteChanges: [{ fromSlug: 'legacy-archmet', toSlug: 'archmet' }],
  };

  assert.deepEqual(diffRemovedProjectUrls(previousResume, currentResume), [
    'https://ekincan.casim.net/projects/legacy-archmet/',
  ]);
  assert.deepEqual(getLegacyProjectUrlsFromResume(currentResume), [
    'https://ekincan.casim.net/projects/legacy-archmet/',
  ]);
});

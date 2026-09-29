// Generates public/ekincan-casim-cv.pdf from resume data at build time, so the
// downloadable CV can never drift from the site. Runs in `prebuild` next to
// generate-og.mjs. Public repo: the PDF carries only what the site already
// shows (no phone number).
//
// Uses the PDF standard Helvetica fonts rather than embedding Inter: some
// viewers reject pdfkit's TrueType subsets and substitute a wider font, which
// pushed lines past the right margin. Standard fonts render with identical
// metrics everywhere and are the safest choice for ATS parsers. The content
// must therefore stay within WinAnsi (checked below).
import { createWriteStream } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import PDFDocument from 'pdfkit';

import { loadResumeModuleFromFile } from './resume-data.mjs';

const project = join(dirname(fileURLToPath(import.meta.url)), '..');
const data = await loadResumeModuleFromFile();
const CV_FILENAME = data.cvPath.replace(/^\//, '');
const { profile, contact, experiences, coreSkills, skills, education, certifications, languages } = data;

const REGULAR = 'Helvetica';
const BOLD = 'Helvetica-Bold';
const INK = '#1a1a1a';
const MUTED = '#5a5f6a';
const ACCENT = '#96610b';
const RULE = '#dcdcd6';
const MARGIN = 50;

// Type scale (pt).
const SIZE = { name: 26, title: 13, contact: 9, section: 11, role: 11.5, meta: 9.5, body: 9.75 };
const LINE_GAP = 2;

const doc = new PDFDocument({
  size: 'A4',
  margins: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN },
  info: { Title: `${profile.name} - CV`, Author: profile.name, Subject: profile.title },
});

await mkdir(join(project, 'public'), { recursive: true });
const out = createWriteStream(join(project, 'public', CV_FILENAME));
doc.pipe(out);

const left = MARGIN;
const width = doc.page.width - MARGIN * 2;
const bottom = () => doc.page.height - MARGIN;

/** Helvetica only covers WinAnsi; fail the build instead of printing boxes. */
function checked(text) {
  const bad = [...text].filter((ch) => ch.codePointAt(0) > 0xff && !'•·—–’“”'.includes(ch));
  if (bad.length) throw new Error(`CV text needs characters outside WinAnsi: ${[...new Set(bad)].join(' ')}`);
  return text;
}

/** Starts a new page when fewer than `needed` points remain. */
function keep(needed) {
  if (doc.y + needed > bottom()) doc.addPage();
}

function section(title) {
  keep(70);
  doc.moveDown(1.1);
  doc.font(BOLD).fontSize(SIZE.section).fillColor(ACCENT)
    .text(title.toUpperCase(), left, doc.y, { characterSpacing: 1.1 });
  const y = doc.y + 2;
  doc.moveTo(left, y).lineTo(left + width, y).lineWidth(0.75).strokeColor(RULE).stroke();
  doc.y = y + 8;
}

function paragraph(text, options = {}) {
  doc.font(REGULAR).fontSize(SIZE.body).fillColor(INK)
    .text(checked(text), left, doc.y, { width, lineGap: LINE_GAP, ...options });
}

function bullet(text) {
  const indent = 13;
  keep(26);
  const y = doc.y;
  doc.font(REGULAR).fontSize(SIZE.body).fillColor(ACCENT).text('•', left + 2, y);
  doc.fillColor(INK).text(checked(text), left + indent, y, { width: width - indent, lineGap: LINE_GAP });
  doc.moveDown(0.3);
}

/** Bold title with a right-aligned date, plus a muted organisation line. */
function entryHeader(title, period, org) {
  keep(70);
  const y = doc.y;
  const dateWidth = 120;
  doc.font(REGULAR).fontSize(SIZE.meta).fillColor(MUTED)
    .text(period, left + width - dateWidth, y + 1.5, { width: dateWidth, align: 'right' });
  doc.font(BOLD).fontSize(SIZE.role).fillColor(INK)
    .text(checked(title), left, y, { width: width - dateWidth - 10 });
  doc.moveDown(0.15);
  doc.font(REGULAR).fontSize(SIZE.meta).fillColor(MUTED).text(checked(org), left, doc.y, { width });
}

// ── Header ────────────────────────────────────────────────────────────
doc.font(BOLD).fontSize(SIZE.name).fillColor(INK).text(profile.name, left, MARGIN);
doc.moveDown(0.1);
doc.font(REGULAR).fontSize(SIZE.title).fillColor(ACCENT).text(profile.title);
doc.moveDown(0.5);
const links = [
  [contact.email, `mailto:${contact.email}`],
  [contact.website.replace(/^https?:\/\//, ''), contact.website],
  [contact.linkedin.replace(/^https?:\/\/(www\.)?/, ''), contact.linkedin],
  [contact.github.replace(/^https?:\/\//, ''), contact.github],
];
doc.font(REGULAR).fontSize(SIZE.contact).fillColor(MUTED).text(`${profile.location}   ·   `, { continued: true });
links.forEach(([label, url], i) => {
  const last = i === links.length - 1;
  doc.fillColor(INK).text(label, { link: url, continued: !last });
  if (!last) doc.fillColor(MUTED).text('   ·   ', { link: null, continued: true });
});

// ── Summary ───────────────────────────────────────────────────────────
section('Summary');
paragraph(profile.intro);

// ── Experience ────────────────────────────────────────────────────────
section('Experience');
experiences.forEach((exp, i) => {
  if (i > 0) doc.moveDown(0.8);
  entryHeader(exp.role, exp.periodLabel, `${exp.company} · ${exp.location}`);
  doc.moveDown(0.4);
  exp.points.forEach(bullet);
});

// ── Skills ────────────────────────────────────────────────────────────
section('Skills');
const core = new Set(coreSkills);
const skillLine = (label, items) => {
  keep(30);
  doc.font(BOLD).fontSize(SIZE.body).fillColor(INK)
    .text(`${label}: `, left, doc.y, { width, continued: true, lineGap: LINE_GAP });
  doc.font(REGULAR).text(checked(items.join(', ')));
  doc.moveDown(0.3);
};
skillLine('Core', coreSkills);
for (const { category, groups } of skills) {
  const rest = groups.flatMap((g) => g.items).filter((item) => !core.has(item));
  if (rest.length) skillLine(category, rest);
}

// ── Education & more ──────────────────────────────────────────────────
section('Education');
education.forEach((entry, i) => {
  if (i > 0) doc.moveDown(0.6);
  entryHeader(entry.degree, entry.periodLabel, `${entry.institution} · ${entry.location}`);
});

section('Certifications');
for (const cert of certifications) bullet(`${cert.name} — ${cert.issuer}, ${cert.year}`);

section('Languages');
for (const { language, level } of languages) bullet(`${language} — ${level}`);

doc.end();
await new Promise((resolve, reject) => {
  out.on('finish', resolve);
  out.on('error', reject);
});
console.log(`${CV_FILENAME} generated`);

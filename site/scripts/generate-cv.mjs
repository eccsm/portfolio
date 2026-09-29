// Generates public/ekincan-casim-cv.pdf from resume data at build time, so the
// downloadable CV can never drift from the site. Runs in `prebuild` next to
// generate-og.mjs. Public repo: the PDF carries only what the site already
// shows (no phone number).
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

const INK = '#1a1a1a';
const MUTED = '#5a5f6a';
const ACCENT = '#96610b';
const MARGIN = 48;

const doc = new PDFDocument({
  size: 'A4',
  margins: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN },
  info: { Title: `${profile.name} - CV`, Author: profile.name, Subject: profile.title },
});
doc.registerFont('Regular', join(project, 'assets/fonts/Inter-Regular.ttf'));
doc.registerFont('Bold', join(project, 'assets/fonts/Inter-Bold.ttf'));

await mkdir(join(project, 'public'), { recursive: true });
const out = createWriteStream(join(project, 'public', CV_FILENAME));
doc.pipe(out);

const left = MARGIN;
const width = doc.page.width - MARGIN * 2;
const bottom = () => doc.page.height - MARGIN;

/** Starts a new page when fewer than `needed` points remain. */
function keep(needed) {
  if (doc.y + needed > bottom()) doc.addPage();
}

function section(title) {
  keep(60);
  doc.moveDown(0.9);
  doc.font('Bold').fontSize(10).fillColor(ACCENT).text(title.toUpperCase(), left, doc.y, { characterSpacing: 1.2 });
  const y = doc.y + 3;
  doc.moveTo(left, y).lineTo(left + width, y).lineWidth(0.6).strokeColor('#e2e2dd').stroke();
  doc.y = y + 7;
}

function bullet(text) {
  const indent = 12;
  keep(24);
  const y = doc.y;
  doc.font('Regular').fontSize(9.5).fillColor(ACCENT).text('•', left + 2, y);
  doc.fillColor(INK).text(text, left + indent, y, { width: width - indent, lineGap: 1.5 });
  doc.moveDown(0.25);
}

/** Bold title with a right-aligned muted date on the same line. */
function titleRow(title, period) {
  keep(56);
  const y = doc.y;
  const dateWidth = 130;
  doc.font('Regular').fontSize(9).fillColor(MUTED).text(period, left + width - dateWidth, y + 1, { width: dateWidth, align: 'right' });
  doc.font('Bold').fontSize(11).fillColor(INK).text(title, left, y, { width: width - dateWidth - 8 });
}

// ── Header ────────────────────────────────────────────────────────────
doc.font('Bold').fontSize(24).fillColor(INK).text(profile.name, left, MARGIN);
doc.font('Regular').fontSize(12).fillColor(ACCENT).text(profile.title);
doc.moveDown(0.4);
const links = [
  [contact.email, `mailto:${contact.email}`],
  [contact.website.replace(/^https?:\/\//, ''), contact.website],
  [contact.linkedin.replace(/^https?:\/\/(www\.)?/, ''), contact.linkedin],
  [contact.github.replace(/^https?:\/\//, ''), contact.github],
];
doc.font('Regular').fontSize(9).fillColor(MUTED).text(`${profile.location}  ·  `, { continued: true });
links.forEach(([label, url], i) => {
  doc.fillColor(INK).text(label, { link: url, underline: false, continued: i < links.length - 1 });
  if (i < links.length - 1) doc.fillColor(MUTED).text('  ·  ', { continued: true });
});

// ── Summary ───────────────────────────────────────────────────────────
section('Summary');
doc.font('Regular').fontSize(9.5).fillColor(INK).text(profile.intro, left, doc.y, { width, lineGap: 1.5 });

// ── Experience ────────────────────────────────────────────────────────
section('Experience');
experiences.forEach((exp, i) => {
  if (i > 0) doc.moveDown(0.6);
  titleRow(exp.role, exp.periodLabel);
  doc.font('Regular').fontSize(9.5).fillColor(MUTED).text(`${exp.company} · ${exp.location}`, left, doc.y, { width });
  doc.moveDown(0.3);
  exp.points.forEach(bullet);
});

// ── Skills ────────────────────────────────────────────────────────────
section('Skills');
const core = new Set(coreSkills);
const skillLine = (label, items) => {
  keep(28);
  doc.font('Bold').fontSize(9.5).fillColor(INK).text(`${label}: `, left, doc.y, { width, continued: true, lineGap: 1.5 });
  doc.font('Regular').text(items.join(', '));
  doc.moveDown(0.25);
};
skillLine('Core', coreSkills);
for (const { category, groups } of skills) {
  const rest = groups.flatMap((g) => g.items).filter((item) => !core.has(item));
  if (rest.length) skillLine(category, rest);
}

// ── Education & more ──────────────────────────────────────────────────
section('Education');
education.forEach((entry, i) => {
  if (i > 0) doc.moveDown(0.4);
  titleRow(entry.degree, entry.periodLabel);
  doc.font('Regular').fontSize(9.5).fillColor(MUTED).text(`${entry.institution} · ${entry.location}`, left, doc.y, { width });
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

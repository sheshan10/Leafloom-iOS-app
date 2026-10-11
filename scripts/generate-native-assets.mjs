#!/usr/bin/env node
/**
 * Generates native-ios/LeafLoom/Resources/Assets.xcassets (and plantKnowledge.json) from the shared
 * source-of-truth assets in windows-preview/. Run from windows-preview with:  npm run native-assets
 *
 * - Colour sets (light + dark) for every semantic token used by LeafColor.swift
 * - Sample plant photos as image sets
 * - Illustrations as vector (SVG) image sets
 * - Category icons as template-rendered SVG image sets built from categoryIcons.json
 * - AppIcon: app-icon.svg rasterised to a 1024×1024 PNG with Playwright's Chromium
 */
import { copyFile, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const preview = path.join(root, 'windows-preview');
const resources = path.join(root, 'native-ios', 'LeafLoom', 'Resources');
const catalog = path.join(resources, 'Assets.xcassets');

const info = { author: 'xcode', version: 1 };
const json = (o) => JSON.stringify(o, null, 2) + '\n';

async function writeSet(dir, contents, files = []) {
  await mkdir(dir, { recursive: true });
  await writeFile(path.join(dir, 'Contents.json'), json({ ...contents, info }));
  for (const [src, name] of files) await copyFile(src, path.join(dir, name));
}

// Keep in sync with windows-preview/src/styles/tokens.css and docs/UI_DESIGN_SYSTEM.md.
const colors = {
  AccentColor: ['#214E3D', '#8FC495'],
  LeafBackground: ['#F7F5EF', '#0E1A16'],
  LeafSurface: ['#FFFFFF', '#15251F'],
  LeafSurfaceAlt: ['#EEF2EA', '#1C3029'],
  LeafSurfaceRaised: ['#FFFFFF', '#213830'],
  LeafText: ['#242B27', '#ECF1EA'],
  LeafTextSecondary: ['#5E6A61', '#A9B8AC'],
  LeafTextTertiary: ['#646F67', '#84958A'],
  LeafBorder: ['#E1E6DD', '#2A4037'],
  LeafPrimary: ['#214E3D', '#8FC495'],
  LeafPrimaryPressed: ['#17382E', '#A6D3AB'],
  LeafOnPrimary: ['#FFFFFF', '#0E1A16'],
  LeafPrimarySoft: ['#E3ECE2', '#1F3A2F'],
  LeafAccent: ['#75A77A', '#75A77A'],
  LeafAccentSoft: ['#DCEADB', '#23402F'],
  LeafAmber: ['#DDAA52', '#E2B566'],
  LeafAmberSoft: ['#F7EAD0', '#3A3020'],
  LeafAmberText: ['#7A5410', '#F0CD8C'],
  LeafDanger: ['#B3261E', '#F2726B'],
  LeafDangerSoft: ['#F9E3E1', '#3C2220'],
  LeafSuccess: ['#24653D', '#7CCB91'],
  LeafSuccessSoft: ['#DFF0E3', '#1D3A28'],
  LeafInfo: ['#2F5F8A', '#8DB8E0'],
  LeafInfoSoft: ['#E1EBF4', '#1D2D3C'],
  LeafTerracotta: ['#C7794F', '#D38D66'],
  LeafSage: ['#B8CDB6', '#5E7A63'],
};

const colorEntry = (hex, dark) => {
  const [r, g, b] = [1, 3, 5].map((i) => (parseInt(hex.slice(i, i + 2), 16) / 255).toFixed(3));
  return {
    idiom: 'universal',
    ...(dark ? { appearances: [{ appearance: 'luminosity', value: 'dark' }] } : {}),
    color: { 'color-space': 'srgb', components: { red: r, green: g, blue: b, alpha: '1.000' } },
  };
};

const photos = {
  monstera: 'monstera.jpg',
  'snake-plant': 'snake-plant.jpg',
  pothos: 'pothos.jpg',
  'fiddle-leaf-fig': 'fiddle-leaf-fig.jpg',
  'peace-lily': 'peace-lily.jpg',
  'aloe-vera': 'aloe-vera.jpg',
  basil: 'basil.jpg',
  calathea: 'calathea.jpg',
};

const illustrations = {
  BrandMark: 'brand-mark.svg',
  OnboardingCollection: 'onboarding-collection.svg',
  OnboardingIdentify: 'onboarding-identify.svg',
  OnboardingReminders: 'onboarding-reminders.svg',
  EmptyPlants: 'empty-plants.svg',
  EmptyTasks: 'empty-tasks.svg',
  EmptyJournal: 'empty-journal.svg',
  EmptySearch: 'empty-search.svg',
  EmptyInsights: 'empty-insights.svg',
};

const pascal = (s) => s.replace(/(^|-)(\w)/g, (_, __, c) => c.toUpperCase());

function iconSvg(shapes) {
  const body = shapes
    .map(({ tag, ...attrs }) => `<${tag} ${Object.entries(attrs).map(([k, v]) => `${k}="${v}"`).join(' ')}/>`)
    .join('');
  return `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#000000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${body}</svg>\n`;
}

async function rasteriseAppIcon(target) {
  const requireFromPreview = createRequire(path.join(preview, 'package.json'));
  const { chromium } = requireFromPreview('@playwright/test');
  const svg = await readFile(path.join(preview, 'public', 'illustrations', 'app-icon.svg'), 'utf8');
  const browser = await chromium.launch();
  try {
    const page = await browser.newPage({ viewport: { width: 1024, height: 1024 }, deviceScaleFactor: 1 });
    await page.setContent(`<html><body style="margin:0;background:#214E3D;line-height:0">${svg}</body></html>`);
    // App Store icons must be opaque and square; iOS applies the corner mask itself.
    await page.screenshot({ path: target, clip: { x: 0, y: 0, width: 1024, height: 1024 }, omitBackground: false });
  } finally {
    await browser.close();
  }
}

async function main() {
  await rm(catalog, { recursive: true, force: true });
  await mkdir(catalog, { recursive: true });
  await writeFile(path.join(catalog, 'Contents.json'), json({ info }));

  for (const [name, [light, dark]] of Object.entries(colors)) {
    const dir = name === 'AccentColor' ? catalog : path.join(catalog, 'Colors');
    await writeSet(path.join(dir, `${name}.colorset`), { colors: [colorEntry(light, false), colorEntry(dark, true)] });
  }
  await writeFile(path.join(catalog, 'Colors', 'Contents.json'), json({ info, properties: { 'provides-namespace': false } }));

  const photoDir = path.join(catalog, 'SamplePhotos');
  await mkdir(photoDir, { recursive: true });
  await writeFile(path.join(photoDir, 'Contents.json'), json({ info }));
  for (const [key, file] of Object.entries(photos)) {
    await writeSet(
      path.join(photoDir, `Sample${pascal(key)}.imageset`),
      { images: [{ idiom: 'universal', filename: file }] },
      [[path.join(preview, 'public', 'images', 'plants', file), file]],
    );
  }

  const illDir = path.join(catalog, 'Illustrations');
  await mkdir(illDir, { recursive: true });
  await writeFile(path.join(illDir, 'Contents.json'), json({ info }));
  for (const [name, file] of Object.entries(illustrations)) {
    await writeSet(
      path.join(illDir, `${name}.imageset`),
      { images: [{ idiom: 'universal', filename: file }], properties: { 'preserves-vector-representation': true } },
      [[path.join(preview, 'public', 'illustrations', file), file]],
    );
  }

  const icons = JSON.parse(await readFile(path.join(preview, 'src', 'data', 'categoryIcons.json'), 'utf8'));
  const iconDir = path.join(catalog, 'CategoryIcons');
  await mkdir(iconDir, { recursive: true });
  await writeFile(path.join(iconDir, 'Contents.json'), json({ info }));
  for (const [category, shapes] of Object.entries(icons)) {
    const name = `Category${pascal(category)}`;
    const dir = path.join(iconDir, `${name}.imageset`);
    await writeSet(dir, {
      images: [{ idiom: 'universal', filename: `${name}.svg` }],
      properties: { 'preserves-vector-representation': true, 'template-rendering-intent': 'template' },
    });
    await writeFile(path.join(dir, `${name}.svg`), iconSvg(shapes));
  }

  const iconSet = path.join(catalog, 'AppIcon.appiconset');
  await writeSet(iconSet, {
    images: [{ filename: 'AppIcon-1024.png', idiom: 'universal', platform: 'ios', size: '1024x1024' }],
  });
  await rasteriseAppIcon(path.join(iconSet, 'AppIcon-1024.png'));

  await copyFile(path.join(preview, 'src', 'data', 'plantKnowledge.json'), path.join(resources, 'plantKnowledge.json'));

  console.log(`Generated ${path.relative(root, catalog)}:`);
  console.log(`  ${Object.keys(colors).length} colour sets, ${Object.keys(photos).length} photos, ${Object.keys(illustrations).length} illustrations, ${Object.keys(icons).length} category icons, AppIcon`);
  console.log(`  + ${path.relative(root, path.join(resources, 'plantKnowledge.json'))}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

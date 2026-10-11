#!/usr/bin/env node
/**
 * Builds docs/LeafLoom_Documentation.pdf: a themed, illustrated guide to every LeafLoom feature.
 *
 *   cd windows-preview
 *   npx playwright test e2e/phone-shots.spec.ts   # refresh docs/screenshots/phone/ (optional)
 *   npm run docs-pdf
 *
 * Content mirrors the Markdown docs in docs/; screenshots are real captures of the browser preview.
 */
import { mkdir, readFile, writeFile, readdir, rm } from 'node:fs/promises';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const docs = path.join(root, 'docs');
const preview = path.join(root, 'windows-preview');
const requireFromPreview = createRequire(path.join(preview, 'package.json'));
const { chromium } = requireFromPreview('@playwright/test');

const url = (...p) => pathToFileURL(path.join(...p)).href;
const shot = (name) => url(docs, 'screenshots', 'phone', `${name}.png`);
const art = (name) => url(preview, 'public', 'illustrations', `${name}.svg`);
const photo = (name) => url(preview, 'public', 'images', 'plants', `${name}.jpg`);

const phoneShots = new Set((await readdir(path.join(docs, 'screenshots', 'phone'))).map((f) => f.replace(/\.png$/, '')));
const brandMark = await readFile(path.join(preview, 'public', 'illustrations', 'brand-mark.svg'), 'utf8');

// ───────────────────────── building blocks ─────────────────────────

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function phones(items, size = 'md') {
  return `<div class="phones phones--${size}">${items
    .map(([name, caption]) => {
      if (!phoneShots.has(name)) throw new Error(`Missing screenshot ${name}.png — run e2e/phone-shots.spec.ts`);
      return `<figure class="phone"><img src="${shot(name)}" alt="${esc(caption)}"/><figcaption>${caption}</figcaption></figure>`;
    })
    .join('')}</div>`;
}

const bullets = (items) => `<ul class="ticks">${items.map((i) => `<li>${i}</li>`).join('')}</ul>`;

const table = (head, rows, cls = '') =>
  `<table class="${cls}"><thead><tr>${head.map((h) => `<th>${h}</th>`).join('')}</tr></thead><tbody>${rows
    .map((r) => `<tr>${r.map((c) => `<td>${c}</td>`).join('')}</tr>`)
    .join('')}</tbody></table>`;

const pill = (text, tone = 'green') => `<span class="pill pill--${tone}">${text}</span>`;

const callout = (title, body, tone = 'info') => `<div class="callout callout--${tone}"><strong>${title}</strong><p>${body}</p></div>`;

function chapter(num, title, lead) {
  return `<section class="chapter"><div class="chapter__num">${num}</div><h1>${title}</h1><p class="lead">${lead}</p></section>`;
}

function feature({ id, title, eyebrow, intro, points, shots, note }) {
  const extra = note ? callout(note[0], note[1], note[2] ?? 'info') : '';
  const head = `<p class="eyebrow">${eyebrow}</p><h2>${title}</h2><p>${intro}</p>`;
  // One or two screenshots sit beside the text; three or four run full width above it.
  if (shots.length <= 2) {
    return `<section class="feature feature--split" id="${id}">
      <div class="feature__text">${head}${bullets(points)}${extra}</div>
      ${phones(shots, 'side')}
    </section>`;
  }
  return `<section class="feature" id="${id}">
    ${head}
    ${phones(shots, shots.length === 3 ? 'three' : 'four')}
    <div class="feature__body">${bullets(points)}${extra}</div>
  </section>`;
}

// ───────────────────────── content ─────────────────────────

const today = new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

const cover = `
<section class="cover">
  <div class="cover__glow"></div>
  <div class="cover__brand">
    <div class="cover__mark">${brandMark}</div>
    <div>
      <p class="cover__name">LeafLoom</p>
      <p class="cover__tag">Grow with confidence.</p>
    </div>
  </div>
  <h1 class="cover__title">AI Plant Care &amp;<br/>Smart Gardening</h1>
  <p class="cover__sub">Product, design and technical documentation — every feature, screen and decision in one place.</p>
  <div class="cover__phones">
    <img src="${shot('07-collection-grid')}" alt=""/>
    <img src="${shot('05-home')}" alt=""/>
    <img src="${shot('31-dark-home')}" alt=""/>
  </div>
  <div class="cover__meta">
    <div><span>Course</span>SE4041 Mobile Application Design &amp; Development — Assignment 02</div>
    <div><span>Platforms</span>iOS 17 (SwiftUI) · visionOS 2 (Part B) · Windows browser preview</div>
    <div><span>Edition</span>${today}</div>
  </div>
</section>`;

const contents = `
<section class="toc">
  <p class="eyebrow">Inside this guide</p>
  <h1>Contents</h1>
  <ol class="toc__list">
    <li><b>Overview</b><span>Problem, solution, audience, deliverables</span></li>
    <li><b>Design language</b><span>Colour, type, illustration, photography</span></li>
    <li><b>Feature tour</b><span>Onboarding, Home, My Plants, details, forms, Care, Identify, Journal, Insights, Settings, Dark Mode</span></li>
    <li><b>Accessibility &amp; privacy</b><span>VoiceOver, Dynamic Type, Reduce Motion, local-first data</span></li>
    <li><b>Architecture</b><span>Layers, navigation, Core Data, Core ML, scheduling</span></li>
    <li><b>Part B — LeafLoom Spatial</b><span>visionOS concept, competitors, pitch</span></li>
    <li><b>Testing &amp; quality</b><span>Verified results, defects fixed, native test suites</span></li>
    <li><b>Running the project</b><span>Windows preview, moving to a Mac, verification</span></li>
    <li><b>Limitations &amp; roadmap</b><span>Honest status and what comes next</span></li>
  </ol>
  ${callout('About the screenshots', 'All screenshots are real captures of the LeafLoom browser preview, which mirrors the native SwiftUI screens, data model and rules. In the preview, plant identification and reminders are simulated and clearly labelled. The native iOS and visionOS code has been written but not yet compiled — that needs Xcode on a Mac.', 'amber')}
</section>`;

const overview = `
${chapter('01', 'Overview', 'LeafLoom is a calm, private iPhone companion for houseplant owners. It brings plant records, identification help, scheduled care and a growth journal together — on device, with no account.')}
<section>
  <div class="grid2">
    <div class="card">
      <p class="eyebrow">The problem</p>
      <h3>Plant care is scattered</h3>
      <p>Owners struggle to identify plants, understand each one's light, water, humidity and soil needs, remember recurring care, and notice change over time. The information lives across labels, search engines, notes and calendar reminders.</p>
    </div>
    <div class="card card--soft">
      <p class="eyebrow">The solution</p>
      <h3>One local-first home for every plant</h3>
      <p>A structured collection with photos, care tasks that repeat sensibly and remind you, on-device identification with Core ML, a growth journal with before/after photos, and insights computed from your own records.</p>
    </div>
  </div>
  <h3>Objectives</h3>
  ${table(['#', 'Objective', 'Measured by'], [
    ['O1', 'Keep a structured, searchable plant collection', 'Plant CRUD, search, sort, filter and favourites all persist'],
    ['O2', 'Assist identification with on-device ML', 'Core ML/Vision behind a protocol; clearly labelled demo mode without a model'],
    ['O3', 'Make recurring care easy to remember', 'Care tasks with recurrence, completion history and local notifications'],
    ['O4', 'Make change visible over time', 'Growth journal with photos, heights and a timeline'],
    ['O5', 'Show collection health at a glance', 'Dashboard and Insights computed from stored records'],
    ['O6', 'Be accessible and pleasant', 'Dynamic Type, Dark Mode, VoiceOver labels, Reduce Motion'],
  ])}
  <h3>Who it is for</h3>
  ${table(['Segment', 'Need', 'How LeafLoom helps'], [
    ['Indoor plant owners', 'Remember watering; keep plants alive', 'Recurring reminders and a "needs attention" dashboard'],
    ['Beginner gardeners', 'Learn what a plant is and needs', 'Identification with care information; guided add-plant form'],
    ['Students into sustainability', 'Low-cost, approachable start', 'Free, offline, no account'],
    ['Enthusiasts with big collections', 'Organise and monitor many plants', 'Search, filters, tags, locations and insights'],
  ])}
  <h3>Deliverables</h3>
  ${table(['Deliverable', 'Folder', 'Status'], [
    ['Native SwiftUI app (iOS 17)', '<code>native-ios/</code>', pill('Source complete · needs Mac to compile', 'amber')],
    ['Windows browser preview (React + TypeScript)', '<code>windows-preview/</code>', pill('Verified on Windows')],
    ['Part B — LeafLoom Spatial (visionOS 2)', '<code>partB-visionos/</code>', pill('Source &amp; docs complete · needs Mac', 'amber')],
    ['Documentation set', '<code>docs/</code>', pill('Complete')],
  ])}
</section>`;

const swatch = (name, hex, dark) => `<div class="swatch"><div class="swatch__chip" style="background:${hex}"></div><div class="swatch__chip swatch__chip--dark" style="background:${dark}"></div><b>${name}</b><span>${hex} · ${dark}</span></div>`;

const design = `
${chapter('02', 'Design language', 'Calm and botanical: a deep forest green with sage, amber and terracotta accents, rounded cards on warm cream surfaces, editorial serif headlines and original illustrations.')}
<section>
  <h3>Colour — light and dark</h3>
  <p>Every colour is a semantic token with a designed dark variant (deep botanical surfaces, not an inversion). The browser preview's tokens are the source of truth; a script generates the 26 colour sets in the iOS asset catalog from them.</p>
  <div class="swatches">
    ${swatch('Primary', '#214e3d', '#8fc495')}
    ${swatch('Accent', '#75a77a', '#75a77a')}
    ${swatch('Background', '#f7f5ef', '#0e1a16')}
    ${swatch('Surface', '#ffffff', '#15251f')}
    ${swatch('Surface alt', '#eef2ea', '#1c3029')}
    ${swatch('Text', '#242b27', '#ecf1ea')}
    ${swatch('Amber', '#ddaa52', '#e2b566')}
    ${swatch('Danger', '#b3261e', '#f2726b')}
    ${swatch('Success', '#24653d', '#7ccb91')}
    ${swatch('Info', '#2f5f8a', '#8db8e0')}
  </div>
  <div class="grid2">
    <div class="card">
      <h3>Typography</h3>
      <p class="type-sample type-sample--title">Good morning</p>
      <p class="muted small">Large titles — New York serif (Georgia fallback)</p>
      <p class="type-sample type-sample--head">This week's care</p>
      <p class="muted small">Headlines and body — SF Pro (system) at Dynamic Type sizes: 34 / 28 / 22 / 20 / 17 / 15 / 13 / 12 pt</p>
    </div>
    <div class="card">
      <h3>Shape &amp; spacing</h3>
      ${bullets(['4-pt spacing scale: 4, 8, 12, 16, 24, 32, 48', 'Radii 8 / 12 / 18 / 26 pt and pill', '44 × 44 pt minimum touch targets', 'Soft, low-contrast card shadows', 'Motion 150–420 ms, removed under Reduce Motion'])}
    </div>
  </div>
  <div class="keep"><h3>Original illustrations</h3>
  <p>Drawn for LeafLoom as SVG and shipped as vector assets — used for onboarding and every empty state.</p>
  <div class="art-row">
    ${['onboarding-collection', 'onboarding-identify', 'onboarding-reminders', 'empty-plants', 'empty-tasks', 'empty-journal', 'empty-insights', 'empty-search']
      .map((n) => `<figure><img src="${art(n)}" alt=""/><figcaption>${n.replace(/-/g, ' ')}</figcaption></figure>`)
      .join('')}
  </div></div>
  <div class="grid2 grid2--icon">
    <div class="app-icon"><img src="${art('app-icon')}" alt="LeafLoom app icon"/><p class="small muted">App icon — rasterised to 1024 px for the asset catalog</p></div>
    <div>
      <h3>Sample photography</h3>
      <p>Eight AI-generated plant photographs illustrate the sample collection. They are listed with their origin in <code>ASSET_ATTRIBUTION.md</code>.</p>
      <div class="photo-row">${['monstera', 'snake-plant', 'pothos', 'fiddle-leaf-fig', 'peace-lily', 'aloe-vera', 'basil', 'calathea'].map((p) => `<img src="${photo(p)}" alt=""/>`).join('')}</div>
    </div>
  </div>
</section>`;

const tour = `
${chapter('03', 'Feature tour', 'A walk through every screen of LeafLoom, from first launch to settings. Five tabs — Home, My Plants, Identify, Care and Insights — each keep their own navigation stack; re-tapping a tab returns to its first screen.')}

${feature({
  id: 'onboarding', eyebrow: 'First launch', title: 'Onboarding',
  intro: 'Four short pages welcome the user and explain the three pillars of the app. Notification permission is only requested here, from the reminders page, after the benefit is explained.',
  shots: [['01-onboarding-welcome', 'Welcome'], ['02-onboarding-collection', 'Your collection'], ['03-onboarding-identify', 'Identify from a photo'], ['04-onboarding-reminders', 'Reminders']],
  points: ['Skip at any time; progress dots show where you are', 'The identify page states plainly that a demo mode is used without a Core ML model', 'Completion is remembered; replay from Settings', 'Starts with eight labelled sample plants so there is something to explore'],
})}

${feature({
  id: 'home', eyebrow: 'Home tab', title: 'Dashboard',
  intro: 'A personal, glanceable summary. Every number is calculated from stored records — nothing is decorative.',
  shots: [['05-home', 'Greeting, weekly ring, quick actions'], ['06-home-lower', 'Today, attention, coming up']],
  points: ['Greeting with today\'s date and a sample-data banner', 'Weekly care ring: completed ÷ (completed + open tasks due this week, including overdue); weeks start on Monday', 'Quick actions: Add plant and Identify', 'Statistic cards: plants, needing attention, favourites', '<b>Today</b> list with one-tap completion and <b>Undo</b>', 'Needs attention, Coming up (next 7 days) and Recently added', 'Gear button opens Settings'],
})}

${feature({
  id: 'collection', eyebrow: 'My Plants tab', title: 'Your collection',
  intro: 'A searchable, filterable collection shown as a photo grid or a compact list.',
  shots: [['07-collection-grid', 'Grid layout'], ['08-collection-filters', 'Filters panel'], ['09-collection-list', 'List layout']],
  points: ['Search by name, common name, scientific name or tag (case- and accent-insensitive)', 'Sort: Recently added, A–Z, Next care', 'Filter by category, location and favourites; Clear filters', 'Heart a plant to favourite it from the card', 'Grid/list toggle, also a setting', 'Designed empty and no-results states'],
})}

${feature({
  id: 'details', eyebrow: 'Plant details', title: 'Everything about one plant',
  intro: 'A hero photo with the plant\'s identity, followed by care, journal and history.',
  shots: [['10-details-hero', 'Hero, status and next care'], ['11-details-care', 'Care profile and journal'], ['12-details-journal', 'Notes, tags and history']],
  points: ['Sample badge and favourite button on the hero', 'Next care with <b>Add task</b>', 'Care profile: watering, fertilising, light, humidity, soil, date added', 'Growth journal preview with <b>Open</b>', 'Notes, tags and collapsible care history', '<b>Edit</b> and <b>Delete plant</b> — deletion confirms and states how many tasks and entries go with it'],
})}

${feature({
  id: 'forms', eyebrow: 'Create &amp; edit', title: 'Adding a plant, with validation',
  intro: 'One form for adding and editing. Mistakes are explained under the field they belong to.',
  shots: [['15-add-plant', 'Add plant form'], ['16-add-plant-validation', 'Inline validation']],
  points: ['Required: name (1–60 characters after trimming) and category', 'Optional: names, photo (library or camera), location, acquisition date (not in the future), light, humidity, soil, notes, tags', 'Watering/fertilising intervals of 1–365 days create repeating care tasks automatically', 'Tags are normalised: lower-cased, de-duplicated and capped', 'Closing with unsaved changes asks before discarding'],
})}

${feature({
  id: 'care', eyebrow: 'Care tab', title: 'Care tasks that repeat sensibly',
  intro: 'Watering, fertilising, pruning, repotting, cleaning, inspection or custom tasks — grouped by day, with overdue work surfaced first.',
  shots: [['17-care-upcoming', 'Upcoming'], ['18-care-overdue', 'Overdue'], ['19-task-details', 'Task details'], ['20-task-form', 'New task']],
  points: ['Segments for upcoming, overdue and completed, with live counts', 'Complete, undo, edit and delete (with confirmation); swipe actions natively', '<b>Recurrence:</b> the next occurrence is due at the start of the completion day + interval, at the original time of day — late care never creates a backlog', '<b>Undo</b> removes the spawned occurrence only if it is still untouched', 'Task details show the whole repeating series', 'Suggested titles follow the category until you type your own'],
})}

${feature({
  id: 'reminders', eyebrow: 'Notifications', title: 'Reminders',
  intro: 'Local notifications at a time the user chooses. LeafLoom works fully without them.',
  shots: [['29-reminders', 'Reminder settings']],
  points: ['One reminder per open task on its due date, at the preferred hour (6:00–22:00)', 'Edits reschedule; completion and deletion cancel', 'Clear permission states, with a shortcut to system Settings when denied', 'In the browser preview, reminders are simulated in-app and labelled as such'],
})}

${feature({
  id: 'identify', eyebrow: 'Identify tab · Core ML', title: 'Identify a plant from a photo',
  intro: 'On device, with Core ML and Vision. Without a bundled model a clearly labelled demo mode shows how it works — and never pretends to be confident.',
  shots: [['21-identify', 'Choose a photo'], ['22-identify-selected', 'Photo selected'], ['23-identify-result', 'Labelled demo result'], ['24-identify-result-lower', 'Care, alternatives, save']],
  points: ['Photo library (no permission needed), camera on real devices, or bundled samples', 'Analysis runs off the main thread on a 1024-px downsampled image', 'Top suggestion, general care guidance and up to four alternatives', 'Confidence appears only from a real model; below 40% a low-confidence warning is shown', '<b>Save to My Plants</b> opens a prefilled form for review; identification history is kept', 'No disease diagnosis claims'],
  note: ['Honest AI', 'No plant model is included and no accuracy is claimed. Demo results carry a "Demo identification" banner and never show a percentage. <code>CORE_ML_GUIDE.md</code> explains how to train <code>LeafLoomPlantClassifier</code> with Create ML and drop it in.', 'amber'],
})}

${feature({
  id: 'journal', eyebrow: 'Growth journal', title: 'See growth over time',
  intro: 'Dated notes with optional photos and heights, shown as a timeline.',
  shots: [['13-journal', 'Timeline and before/after'], ['14-journal-form', 'New entry']],
  points: ['Notes required; photo and height (cm) optional; dates cannot be in the future', 'Before/after slider compares the earliest and latest photos (adjustable with VoiceOver)', 'Growth summary such as "Grew 26 cm across 3 measurements"', 'Edit and delete entries, with confirmation'],
})}

${feature({
  id: 'insights', eyebrow: 'Insights tab', title: 'Insights',
  intro: 'Charts built from the user\'s own records, each with a spoken summary for VoiceOver.',
  shots: [['25-insights', 'Stats and completion trend'], ['26-insights-lower', 'Care mix'], ['27-insights-bottom', 'Categories and additions']],
  points: ['Statistic cards for the collection and this week', 'Care completion trend over the last eight Monday-start weeks', 'Mix of completed care by type', 'Plants by category and plants added per month (last six months)', 'Charts stop animating under Reduce Motion', 'Copy is careful: "on schedule" describes task status, not botanical health'],
})}

${feature({
  id: 'settings', eyebrow: 'Settings', title: 'Settings &amp; About',
  intro: 'Appearance, reminders, help, privacy and data controls in one place.',
  shots: [['28-settings', 'Settings'], ['30-about', 'About LeafLoom']],
  points: ['Theme: System, Light or Dark — applied app-wide', 'Default collection layout: grid or list', 'Notifications &amp; reminders', 'Replay the introduction', '<b>Reset to sample data</b> and <b>Erase all data</b>, each behind a confirmation', 'About: privacy, how identification works, care disclaimer, credits, version and identification mode'],
})}

${feature({
  id: 'dark', eyebrow: 'Appearance', title: 'Dark Mode',
  intro: 'A designed dark theme with deep botanical surfaces and lifted greens — every colour token has a dark counterpart.',
  shots: [['31-dark-home', 'Home'], ['32-dark-collection', 'My Plants'], ['33-dark-details', 'Plant details'], ['35-dark-care', 'Care']],
  points: ['Follows the system or can be forced in Settings', 'Text keeps WCAG AA contrast on dark surfaces', 'Photos sit on dark cards without harsh borders'],
})}`;

const a11y = `
${chapter('04', 'Accessibility &amp; privacy', 'Accessibility and privacy are defaults, not settings.')}
<section>
  <div class="grid2">
    <div class="card">
      <h3>Accessibility</h3>
      ${bullets(['<b>VoiceOver:</b> meaningful labels and hints on every control; charts have spoken summaries; the before/after slider is adjustable', '<b>Dynamic Type:</b> text styles throughout, layouts reflow up to the largest accessibility sizes', '<b>Not colour alone:</b> overdue, due and fit states always pair text with an icon', '<b>Reduce Motion:</b> decorative animation and chart animation are removed', '<b>Targets:</b> at least 44 × 44 pt', '<b>Dark Mode:</b> designed, not inverted'])}
    </div>
    <div class="card card--soft">
      <h3>Privacy by design</h3>
      ${bullets(['Plants, photos and journal entries are stored only on the device', 'No account, no analytics, no server, no network calls', 'Identification runs entirely on device', 'Photos are downsampled JPEG files in Application Support', 'Notification permission is asked in context, and the app works fully without it'])}
      ${callout('Care disclaimer', 'Care tips are general guidance. Identification suggestions can be wrong — never use them to decide whether a plant is safe to eat or safe for pets.', 'amber')}
    </div>
  </div>
</section>`;

const archBox = (title, items, tone = '') => `<div class="arch__box ${tone}"><b>${title}</b>${items.map((i) => `<span>${i}</span>`).join('')}</div>`;

const architecture = `
${chapter('05', 'Architecture', 'A layered SwiftUI app: views read reactively, repositories own every write, domain rules are pure Swift, and framework services sit behind protocols.')}
<section>
  <h3>Technology</h3>
  ${table(['Concern', 'Choice', 'Notes'], [
    ['UI', 'SwiftUI, iOS 17', '<code>NavigationStack</code>, <code>@Observable</code>, <code>ContentUnavailableView</code>, sensory feedback'],
    ['Persistence', 'Core Data', 'Four entities, typed accessors over <code>…Raw</code> attributes, lightweight migration'],
    ['Machine learning', 'Core ML + Vision', '<code>VNCoreMLRequest</code>, centre crop, top-5 results off the main actor'],
    ['Photos', 'PhotosUI <code>PhotosPicker</code>', 'Out-of-process picker, no library permission'],
    ['Camera', '<code>UIImagePickerController</code>', 'Only UIKit interop; shown when a camera exists'],
    ['Notifications', 'UserNotifications', 'Calendar triggers; identifier = task UUID'],
    ['Charts', 'Swift Charts', 'Line, area, bar and sector marks'],
    ['Tests', 'XCTest / XCUITest', 'In-memory store; launch arguments for deterministic UI tests'],
  ])}
  <h3>Layers</h3>
  <div class="arch">
    ${archBox('Presentation', ['Feature views', 'Components &amp; modifiers', '@FetchRequest reads'], 'arch__box--a')}
    ${archBox('State', ['AppRouter (tab + stacks + sheet)', 'Form &amp; flow view models', 'AppPreferences'], 'arch__box--b')}
    ${archBox('Domain — pure Swift', ['PlantValidator', 'RecurrenceCalculator', 'PlantQuery', 'InsightsCalculator'], 'arch__box--c')}
    ${archBox('Services', ['@MainActor repositories', 'ImageStore', 'PlantIdentifying', 'ReminderScheduling'], 'arch__box--d')}
    ${archBox('Apple frameworks', ['Core Data', 'Core ML + Vision', 'UserNotifications', 'File system'], 'arch__box--e')}
  </div>
  <p class="small muted">Views never call <code>save()</code>. <code>AppEnvironment</code> is the dependency container; <code>router</code>, <code>toasts</code> and <code>preferences</code> are injected separately.</p>

  <h3>Core Data model</h3>
  <div class="entities">
    <div class="entity"><b>Plant</b><span>id · name · commonName · scientificName</span><span>categoryRaw · location · tagsRaw · notes</span><span>imageFilename · sampleAssetName</span><span>wateringIntervalRaw · fertilizingIntervalRaw</span><span>sunlightRaw · humidityRaw · soilPreference</span><span>isFavorite · isSample · identificationStatusRaw</span><span>dateAdded · acquisitionDate · createdAt · updatedAt</span></div>
    <div class="entity"><b>CareTask</b><span>id · seriesID · spawnedTaskID</span><span>title · descriptionText · categoryRaw</span><span>dueDate · completedAt · isCompleted</span><span>recurrenceIntervalRaw · notes · isSample</span><span>createdAt · updatedAt</span><em>Plant → tasks: cascade</em></div>
    <div class="entity"><b>JournalEntry</b><span>id · entryDate · notes</span><span>imageFilename · heightRaw</span><span>createdAt · updatedAt</span><em>Plant → entries: cascade</em></div>
    <div class="entity"><b>IdentificationRecord</b><span>id · dateCreated · imageFilename</span><span>predictedLabel · confidenceRaw</span><span>modelIdentifier · isDemoResult</span><em>Plant → records: nullify</em></div>
  </div>
  <p class="small muted">Interval 0 means "not set"; height and confidence −1 mean "not supplied" — the Swift accessors expose them as optionals. Images live on disk, not in the store. Deleting a plant also cancels its notifications and removes image files.</p>

  <div class="grid2">
    <div class="card">
      <h3>Identification pipeline</h3>
      <ol class="steps">
        <li>Pick a photo (PhotosPicker, camera or sample)</li>
        <li>Validate and downsample to 1024 px</li>
        <li><code>PlantIdentifying.identify</code> — Core ML if <code>LeafLoomPlantClassifier.mlmodelc</code> is bundled, otherwise demo</li>
        <li><code>LabelMapper</code> maps labels to the 14-entry knowledge base</li>
        <li>Result shown; history saved; optional prefilled plant form</li>
      </ol>
    </div>
    <div class="card">
      <h3>Navigation</h3>
      ${bullets(['<code>AppRouter</code> holds the selected tab, one <code>NavigationPath</code> per tab and one optional sheet', 'Push routes: plant details, task details, journal, settings, reminders, about', 'Sheets: add/edit plant, task and journal entry — the sheet host passes the saved record in', 'Saving from Identify switches to My Plants and opens the new plant'])}
    </div>
  </div>
</section>`;

const partB = `
${chapter('06', 'Part B — LeafLoom Spatial', 'A visionOS 2 prototype that answers the question phone apps cannot: will this plant thrive <i>there</i>? Arrange your own plants life-size in your room and see each spot\'s light fit before you move a pot.')}
<section>
  <img class="wide-shot" src="${shot('36-spatial-simulation')}" alt="LeafLoom Spatial 2D simulation"/>
  <p class="small muted center">The browser preview's 2D simulation of the concept: window, room floor plan with light zones, and a spatial care card.</p>
  ${table(['Scene', 'visionOS type', 'What it does'], [
    ['Garden window', '<code>WindowGroup</code>', 'Plant list with light-fit badges, care card with advice and next watering, "View in 3D", "Watered today"; an ornament holds Arrange in my room and Reset layout'],
    ['Planter volume', 'Volumetric <code>WindowGroup</code>', 'One plant on a turntable — drag to spin, pinch to zoom, adjustable with VoiceOver'],
    ['Room', '<code>ImmersiveSpace</code> (mixed)', 'Plants on the real floor: drag, rotate, scale (0.5–2×), tap to select; a draggable window marker and floor rings show light zones'],
  ])}
  <div class="grid2">
    <div class="card">
      <h3>Light estimate</h3>
      ${table(['Distance from window', 'Zone'], [['&lt; 0.6 m', 'Full sun'], ['0.6 – 1.5 m', 'Bright indirect'], ['1.5 – 3.0 m', 'Medium'], ['≥ 3.0 m', 'Low']], 'compact')}
      <p class="small">Same zone = great match, one step = acceptable, further = poor — with "move closer / further" advice. It is a distance heuristic, labelled as an estimate.</p>
    </div>
    <div class="card">
      <h3>Built with</h3>
      ${bullets(['Procedural plants from RealityKit primitives — no third-party 3D assets', 'Shapes seeded from each plant\'s UUID, stable every launch', 'Targeted drag, rotate, magnify and tap gestures; layout saved once per gesture', 'Billboarded attachments; accessibility components on entities', 'Same eight sample plants as the iPhone app; 12 unit tests'])}
    </div>
  </div>
  <h3>Similar apps</h3>
  ${table(['App', 'Known for', 'Gap LeafLoom Spatial targets'], [
    ['PictureThis', 'Photo identification, care guides, reminders', 'No in-room placement'],
    ['Planta', 'Adaptive schedules; camera light meter', 'Light is read one spot at a time on a phone'],
    ['Pl@ntNet · iNaturalist/Seek', 'Free, research-backed identification', 'Identification only'],
    ['IKEA / Houzz AR', 'True-scale placement in your room', 'Fit, not plant health'],
  ])}
  <p class="small muted">Written from general product knowledge — check current App Store listings before submission (see <code>COMPETITORS.md</code>).</p>
  <h3>Pitch</h3>
  <div class="grid3">
    <div class="card card--soft"><p class="eyebrow">Value</p><p>See where every plant will thrive before you move a single pot. Fewer losses, less guesswork, one collection everywhere.</p></div>
    <div class="card card--soft"><p class="eyebrow">Revenue (proposal)</p><p><b>Free</b> up to 5 plants · <b>Plus</b> unlimited plants, rooms, sync · <b>Pro</b> for designers and shops. No ads, no data selling.</p></div>
    <div class="card card--soft"><p class="eyebrow">Go-to-market</p><p>Prototype → TestFlight beta with plant and Vision Pro communities → App Store launch with the iPhone app → plant-shop pilots.</p></div>
  </div>
</section>`;

const testing = `
${chapter('07', 'Testing &amp; quality', 'Only commands that were actually run are reported as results. Native suites are written and waiting for a Mac.')}
<section>
  <h3>Verified on Windows — final code</h3>
  ${table(['Check', 'Result'], [
    ['ESLint', pill('Pass') + ' no problems'],
    ['Vitest unit &amp; component tests', pill('Pass') + ' 58 / 58 across 8 files'],
    ['Type-check + production build', pill('Pass') + ' index 364.6 kB (112.2 kB gzip), charts 413.2 kB (119.5 kB gzip)'],
    ['Playwright end-to-end flows (Chromium)', pill('Pass') + ' 5 / 5'],
    ['Screenshot capture', pill('Pass') + ' preview and phone captures, inspected'],
  ])}
  <h3>Defects found by testing — all fixed</h3>
  ${table(['Found by', 'Defect', 'Fix'], [
    ['Playwright', 'Crash after onboarding: an effect returned the Promise from <code>scrollTo</code> (jsdom hid it)', 'Block-bodied effects'],
    ['Screenshots', 'Filter panel always visible — CSS overrode <code>hidden</code>', 'Global <code>[hidden]</code> rule'],
    ['Playwright', 'Only 6 of 8 sample photos on Identify', 'Show every sample'],
    ['Screenshots', 'Charts captured mid-animation, ignoring Reduce Motion', 'Disable chart animation'],
    ['Build', 'Empty manual chunk', 'Removed'],
    ['Asset script', 'Lost named export from an ESM import', '<code>createRequire</code>'],
  ])}
  <div class="keep"><h3>Native suites — written, not yet run</h3>
  ${table(['Suite', 'Tests', 'Covers', 'Status'], [
    ['LeafLoomTests', '84', 'Validation, recurrence and status, queries, insights, identification and label mapping, reminders, images, all repositories, maintenance, form view models', pill('Needs Mac', 'amber')],
    ['LeafLoomUITests', '7', 'Onboarding skip, tabs, add plant with validation, undo, labelled demo identification, empty state, delete confirmation', pill('Needs Mac', 'amber')],
    ['LeafLoomSpatialTests', '12', 'Light zones and fit, sample data, procedural seed, store layout and persistence', pill('Needs Mac', 'amber')],
  ])}
  </div><p class="small">User acceptance tests (eight scripted scenarios) and a manual accessibility checklist are in <code>TEST_PLAN.md</code>, ready for real participants.</p>
</section>`;

const running = `
${chapter('08', 'Running the project', 'Try LeafLoom on Windows today; build the native apps on a Mac with one script.')}
<section>
  <div class="grid2">
    <div class="card">
      <h3>Browser preview (any OS)</h3>
<pre>cd windows-preview
npm install
npm run dev        # http://localhost:5173
npm run lint
npm test
npm run build
npm run e2e</pre>
      <p class="small">The tools panel switches device size, theme, text size and Reduce Motion, jumps between screens, resets data and opens the Spatial simulation.</p>
    </div>
    <div class="card">
      <h3>On a Mac (Xcode 16+)</h3>
      <ol class="steps">
        <li>Copy the folder via OneDrive, zip or USB — no git needed (<code>WINDOWS_TO_MAC_GUIDE.md</code>)</li>
        <li><code>chmod +x scripts/verify-native.sh</code></li>
        <li><code>./scripts/verify-native.sh</code> — builds and tests iOS, then visionOS</li>
        <li>Open <code>native-ios/LeafLoom.xcodeproj</code> and press ⌘R</li>
        <li>Record real results in <code>TEST_PLAN.md</code> and the checklist</li>
      </ol>
      <p class="small">Launch arguments: <code>-skipOnboarding</code>, <code>-resetData</code>, <code>-emptyState</code>, <code>-uiTesting</code>.</p>
    </div>
  </div>
  <h3>Project map</h3>
  ${table(['Folder', 'Contents'], [
    ['<code>native-ios/</code>', 'LeafLoom.xcodeproj (synchronized folders), project.yml; App, Core, Data, Features, Services, Resources; unit and UI tests'],
    ['<code>windows-preview/</code>', 'React 19 + TypeScript + Vite; IndexedDB repository; Vitest and Playwright'],
    ['<code>partB-visionos/</code>', 'LeafLoomSpatial.xcodeproj, project.yml, sources, tests, CONCEPT / COMPETITORS / PITCH'],
    ['<code>docs/</code>', 'Requirements, architecture, design system, Core ML guide, test plan, user guide, Mac guide, report, AI log, attribution, checklist'],
    ['<code>scripts/</code>', 'verify-native.sh, generate-native-assets.mjs, build-docs-pdf.mjs'],
  ])}
</section>`;

const limits = `
${chapter('09', 'Limitations &amp; roadmap', 'An honest status, and what comes next.')}
<section>
  <div class="grid2">
    <div class="card">
      <h3>Current limitations</h3>
      ${bullets(['Native iOS and visionOS code is not yet compiled — expect fixes on the first Xcode build', 'No Core ML model is bundled, so identification runs in labelled demo mode', 'Reminders fire at a fixed preferred hour; no weather or season awareness', 'No iCloud sync between devices or between the iPhone and Vision Pro apps', 'The spatial light estimate uses distance only', 'Competitor details and market sizing need checking against current sources'])}
    </div>
    <div class="card card--soft">
      <h3>Roadmap</h3>
      <ol class="steps">
        <li>Train and evaluate a Create ML model on a licensed dataset; publish real metrics</li>
        <li>Core Data + CloudKit sync shared by iPhone and Vision Pro</li>
        <li>Widgets and Live Activities for today's care</li>
        <li>ARKit plane detection and light estimation in LeafLoom Spatial</li>
      </ol>
    </div>
  </div>
  <div class="closing">
    <div class="closing__mark">${brandMark}</div>
    <p class="closing__name">LeafLoom</p>
    <p class="closing__tag">Grow with confidence.</p>
  </div>
</section>`;

// ───────────────────────── styles ─────────────────────────

const css = `
@page {
  size: A4; margin: 18mm 16mm 20mm;
  @bottom-left { content: 'LeafLoom  ·  Grow with confidence.'; font: 600 7.5pt 'Segoe UI', sans-serif; color: #214e3d; vertical-align: top; padding-top: 6mm; }
  @bottom-right { content: counter(page) ' / ' counter(pages); font: 7.5pt 'Segoe UI', sans-serif; color: #5e6a61; vertical-align: top; padding-top: 6mm; }
}
@page :first { margin: 0; @bottom-left { content: none; } @bottom-right { content: none; } }
* { box-sizing: border-box; }
html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
body { margin: 0; font-family: 'Segoe UI Variable Text', 'Segoe UI', -apple-system, system-ui, sans-serif; color: #242b27; font-size: 10.2pt; line-height: 1.5; background: #fff; }
h1, h2, h3 { font-family: 'New York', 'Iowan Old Style', Georgia, serif; color: #17382e; letter-spacing: -0.01em; }
h1 { font-size: 30pt; margin: 0 0 6pt; line-height: 1.1; }
h2 { font-size: 20pt; margin: 0 0 6pt; }
h3 { font-size: 13.5pt; margin: 16pt 0 6pt; break-after: avoid; page-break-after: avoid; }
h2, .eyebrow { break-after: avoid; page-break-after: avoid; }
.keep { break-inside: avoid; page-break-inside: avoid; }
p { margin: 0 0 8pt; }
code { font-family: 'Cascadia Code', Consolas, monospace; font-size: 8.6pt; background: #eef2ea; color: #17382e; padding: 0.5pt 3pt; border-radius: 4pt; }
pre { font-family: 'Cascadia Code', Consolas, monospace; font-size: 8.6pt; background: #17382e; color: #dceadb; padding: 10pt 12pt; border-radius: 10pt; margin: 0 0 8pt; }
.eyebrow { text-transform: uppercase; letter-spacing: 0.14em; font-size: 7.6pt; font-weight: 700; color: #75a77a; margin: 0 0 4pt; }
.lead { font-size: 12.5pt; color: #5e6a61; max-width: 150mm; }
.muted { color: #5e6a61; } .small { font-size: 8.6pt; } .center { text-align: center; }

/* cover */
.cover { position: relative; height: 297mm; width: 210mm; overflow: hidden; background: linear-gradient(160deg, #2a5d49 0%, #17382e 55%, #0e1a16 100%); color: #f7f5ef; padding: 22mm 18mm; page-break-after: always; }
.cover__glow { position: absolute; width: 170mm; height: 170mm; right: -50mm; top: -40mm; border-radius: 50%; background: radial-gradient(circle, rgba(117,167,122,0.45), rgba(117,167,122,0) 70%); }
.cover__brand { display: flex; align-items: center; gap: 12pt; position: relative; }
.cover__mark { width: 52pt; height: 52pt; background: #f7f5ef; border-radius: 14pt; padding: 7pt; }
.cover__mark svg { width: 100%; height: 100%; }
.cover__name { font-family: Georgia, serif; font-size: 24pt; margin: 0; font-weight: 700; }
.cover__tag { margin: 0; color: #b8cdb6; font-style: italic; }
.cover__title { color: #f7f5ef; font-size: 40pt; margin: 18mm 0 8pt; position: relative; }
.cover__sub { color: #b8cdb6; font-size: 13pt; max-width: 130mm; position: relative; }
.cover__phones { position: absolute; left: 0; right: 0; bottom: 52mm; height: 128mm; display: flex; justify-content: center; align-items: flex-end; gap: 6mm; }
.cover__phones img { height: 112mm; filter: drop-shadow(0 12pt 24pt rgba(0,0,0,0.45)); }
.cover__phones img:nth-child(2) { height: 128mm; }
.cover__meta { position: absolute; left: 18mm; right: 18mm; bottom: 16mm; display: grid; gap: 4pt; border-top: 1px solid rgba(184,205,182,0.35); padding-top: 10pt; font-size: 9.5pt; }
.cover__meta span { display: inline-block; width: 28mm; color: #ddaa52; text-transform: uppercase; letter-spacing: 0.12em; font-size: 7.5pt; font-weight: 700; }

/* contents */
.toc { page-break-after: always; }
.toc__list { list-style: none; counter-reset: toc; padding: 0; margin: 12pt 0 18pt; }
.toc__list li { counter-increment: toc; display: grid; grid-template-columns: 16mm 1fr; grid-template-rows: auto auto; padding: 8pt 0; border-bottom: 1px solid #e1e6dd; }
.toc__list li::before { content: counter(toc, decimal-leading-zero); grid-row: span 2; font-family: Georgia, serif; font-size: 18pt; color: #75a77a; }
.toc__list b { font-family: Georgia, serif; font-size: 13pt; color: #17382e; }
.toc__list span { color: #5e6a61; font-size: 9pt; }

/* chapters */
.chapter { page-break-before: always; background: linear-gradient(135deg, #e3ece2, #f7f5ef); border-radius: 18pt; padding: 18pt 20pt 14pt; margin-bottom: 14pt; position: relative; overflow: hidden; }
.chapter::after { content: ''; position: absolute; right: -18mm; top: -18mm; width: 60mm; height: 60mm; border-radius: 50%; background: radial-gradient(circle, rgba(117,167,122,0.35), rgba(117,167,122,0) 70%); }
.chapter__num { font-family: Georgia, serif; font-size: 11pt; font-weight: 700; color: #f7f5ef; background: #214e3d; display: inline-block; padding: 2pt 9pt; border-radius: 999px; margin-bottom: 8pt; }
.chapter .lead { margin: 0; }

/* features */
.feature { break-inside: avoid; page-break-inside: avoid; border-top: 1px solid #e1e6dd; padding-top: 12pt; margin-top: 12pt; }
.chapter + .feature { border-top: 0; margin-top: 0; padding-top: 0; }
.feature__body { margin-top: 4pt; }
.phones { display: flex; gap: 5mm; justify-content: center; margin: 8pt 0 6pt; }
.phone { margin: 0; text-align: center; }
.phone img { display: block; filter: drop-shadow(0 4pt 8pt rgba(23,56,46,0.18)); }
.phones--three .phone img { height: 84mm; }
.phones--four .phone img { height: 74mm; }
.phones--side { margin: 0; gap: 4mm; }
.phones--side .phone img { height: 92mm; }
.feature--split { display: grid; grid-template-columns: 1fr auto; gap: 7mm; align-items: start; }
.feature--split .ticks { columns: 1; }
.phone figcaption { font-size: 8pt; color: #5e6a61; margin-top: 4pt; font-weight: 600; }

.ticks { list-style: none; padding: 0; margin: 0 0 8pt; columns: 2; column-gap: 8mm; }
.card .ticks, .grid2 .ticks { columns: 1; }
.ticks li { position: relative; padding-left: 14pt; margin-bottom: 4pt; break-inside: avoid; }
.ticks li::before { content: ''; position: absolute; left: 0; top: 4.5pt; width: 7pt; height: 7pt; border-radius: 2pt 7pt; background: #75a77a; }

.steps { margin: 0; padding-left: 16pt; } .steps li { margin-bottom: 4pt; } .steps li::marker { color: #75a77a; font-weight: 700; }

/* cards & layout */
.card { background: #fff; border: 1px solid #e1e6dd; border-radius: 14pt; padding: 12pt 14pt; box-shadow: 0 1px 2px rgba(23,56,46,0.06), 0 4px 14px rgba(23,56,46,0.06); break-inside: avoid; }
.card--soft { background: #eef2ea; border-color: #dceadb; box-shadow: none; }
.card h3 { margin-top: 0; }
.grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 6mm; margin: 10pt 0; }
.grid3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 5mm; margin: 10pt 0; }
.grid3 .card p:last-child { margin: 0; font-size: 9pt; }

.callout { border-radius: 12pt; padding: 9pt 12pt; margin: 8pt 0; break-inside: avoid; }
.callout strong { display: block; font-size: 9pt; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 2pt; }
.callout p { margin: 0; font-size: 9pt; }
.callout--info { background: #e1ebf4; color: #1d3c58; }
.callout--amber { background: #f7ead0; color: #7a5410; }

.pill { display: inline-block; font-size: 7.6pt; font-weight: 700; padding: 1.5pt 7pt; border-radius: 999px; white-space: nowrap; }
.pill--green { background: #dff0e3; color: #24653d; }
.pill--amber { background: #f7ead0; color: #7a5410; }

table { width: 100%; border-collapse: separate; border-spacing: 0; margin: 6pt 0 10pt; font-size: 8.8pt; break-inside: auto; border: 1px solid #e1e6dd; border-radius: 10pt; overflow: hidden; }
thead th { background: #214e3d; color: #f7f5ef; text-align: left; font-weight: 600; padding: 6pt 8pt; }
tbody td { padding: 5pt 8pt; border-top: 1px solid #e1e6dd; vertical-align: top; }
tbody tr:nth-child(even) td { background: #f7f5ef; }
tr { break-inside: avoid; }
table.compact { font-size: 8.6pt; }

/* design */
.swatches { display: grid; grid-template-columns: repeat(5, 1fr); gap: 4mm; margin: 8pt 0 12pt; }
.swatch { font-size: 8pt; }
.swatch__chip { height: 13mm; border-radius: 10pt 10pt 0 0; border: 1px solid rgba(0,0,0,0.06); }
.swatch__chip--dark { height: 7mm; border-radius: 0 0 10pt 10pt; margin-bottom: 4pt; }
.swatch b { display: block; color: #17382e; } .swatch span { color: #5e6a61; font-size: 7pt; }
.type-sample { margin: 6pt 0 0; color: #17382e; }
.type-sample--title { font-family: Georgia, serif; font-size: 26pt; font-weight: 700; }
.type-sample--head { font-size: 14pt; font-weight: 600; }
.art-row { display: grid; grid-template-columns: repeat(8, 1fr); gap: 3mm; margin: 6pt 0 10pt; }
.art-row figure { margin: 0; background: #eef2ea; border-radius: 10pt; padding: 4pt; text-align: center; }
.art-row img { width: 100%; height: 18mm; object-fit: contain; }
.art-row figcaption { font-size: 6.5pt; color: #5e6a61; text-transform: capitalize; }
.grid2--icon { grid-template-columns: 44mm 1fr; align-items: start; }
.app-icon img { width: 40mm; border-radius: 9mm; box-shadow: 0 6pt 16pt rgba(23,56,46,0.25); }
.photo-row { display: grid; grid-template-columns: repeat(8, 1fr); gap: 2mm; }
.photo-row img { width: 100%; aspect-ratio: 1; object-fit: cover; border-radius: 8pt; }

/* architecture */
.arch { display: grid; gap: 3mm; margin: 6pt 0; }
.arch__box { display: flex; flex-wrap: wrap; align-items: center; gap: 4pt 6pt; border-radius: 10pt; padding: 7pt 10pt; }
.arch__box b { width: 40mm; font-family: Georgia, serif; font-size: 10.5pt; }
.arch__box span { background: rgba(255,255,255,0.75); border-radius: 999px; padding: 1.5pt 8pt; font-size: 8.4pt; }
.arch__box--a { background: #dceadb; } .arch__box--b { background: #e3ece2; } .arch__box--c { background: #f7ead0; }
.arch__box--d { background: #e1ebf4; } .arch__box--e { background: #eef2ea; border: 1px dashed #c9d2c5; }
.entities { display: grid; grid-template-columns: repeat(4, 1fr); gap: 3mm; margin: 6pt 0; }
.entity { border: 1px solid #c9d2c5; border-radius: 10pt; overflow: hidden; font-size: 7.6pt; break-inside: avoid; }
.entity b { display: block; background: #214e3d; color: #f7f5ef; padding: 5pt 7pt; font-family: Georgia, serif; font-size: 9.5pt; }
.entity span { display: block; padding: 2.5pt 7pt; border-top: 1px solid #eef2ea; }
.entity em { display: block; padding: 4pt 7pt; background: #f7ead0; color: #7a5410; font-style: normal; font-weight: 600; }

.wide-shot { width: 100%; height: 104mm; object-fit: cover; object-position: top; border-radius: 14pt; margin-top: 4pt; }

.closing { text-align: center; margin-top: 18mm; }
.closing__mark { width: 40pt; height: 40pt; margin: 0 auto 6pt; }
.closing__mark svg { width: 100%; height: 100%; }
.closing__name { font-family: Georgia, serif; font-size: 18pt; font-weight: 700; color: #17382e; margin: 0; }
.closing__tag { color: #75a77a; font-style: italic; }
`;

const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"/><title>LeafLoom — Documentation</title><style>${css}</style></head>
<body>${cover}${contents}${overview}${design}${tour}${a11y}${architecture}${partB}${testing}${running}${limits}</body></html>`;

// ───────────────────────── render ─────────────────────────

const tmp = path.join(docs, '.pdf-build');
await mkdir(tmp, { recursive: true });
const htmlPath = path.join(tmp, 'LeafLoom_Documentation.html');
await writeFile(htmlPath, html);

const browser = await chromium.launch();
try {
  const page = await browser.newPage();
  await page.goto(pathToFileURL(htmlPath).href, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  const output = path.join(docs, 'LeafLoom_Documentation.pdf');
  await page.pdf({
    path: output,
    format: 'A4',
    printBackground: true,
    preferCSSPageSize: true,
  });
  console.log(`Wrote ${path.relative(root, output)}`);
  if (process.argv.includes('--keep-html')) console.log(`HTML kept at ${path.relative(root, htmlPath)}`);
} finally {
  await browser.close();
  if (!process.argv.includes('--keep-html')) await rm(tmp, { recursive: true, force: true });
}

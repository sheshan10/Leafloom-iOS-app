/**
 * Builds docs/LeafLoom_Documentation.pdf from the phone UI screenshots.
 * Run: node scripts/build-documentation-pdf.mjs
 */
import { execFile } from 'node:child_process';
import { mkdir, readFile, writeFile, rm } from 'node:fs/promises';
import { promisify } from 'node:util';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const execFileAsync = promisify(execFile);
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const docs = path.join(root, 'docs');
const shotsDir = path.resolve(root, '..', 'kept-locally', 'docs', 'screenshots', 'phone');
const preview = path.resolve(root, '..', 'kept-locally', 'windows-preview');

const shot = (name) => pathToFileURL(path.join(shotsDir, `${name}.png`)).href;
const brandMark = await readFile(path.join(preview, 'public', 'illustrations', 'brand-mark.svg'), 'utf8');
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function phones(items) {
  const size = items.length <= 2 ? 'side' : items.length === 3 ? 'three' : 'four';
  return `<div class="phones phones--${size}">${items
    .map(([name, caption]) => `<figure class="phone"><img src="${shot(name)}" alt="${esc(caption)}"/><figcaption>${esc(caption)}</figcaption></figure>`)
    .join('')}</div>`;
}
const bullets = (items) => `<ul class="ticks">${items.map((i) => `<li>${i}</li>`).join('')}</ul>`;
const table = (head, rows) =>
  `<table><thead><tr>${head.map((h) => `<th>${h}</th>`).join('')}</tr></thead><tbody>${rows
    .map((r) => `<tr>${r.map((c) => `<td>${c}</td>`).join('')}</tr>`)
    .join('')}</tbody></table>`;
function chapter(num, title, lead) {
  return `<section class="chapter"><div class="chapter__num">${num}</div><h1>${title}</h1><p class="lead">${lead}</p></section>`;
}
function feature(title, intro, points, shots) {
  return `<section class="feature feature--split"><div class="feature__text"><h2>${title}</h2><p>${intro}</p>${bullets(points)}</div>${phones(shots)}</section>`;
}

const today = new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"/><title>LeafLoom documentation</title><style>
@page { size: A4; margin: 16mm 14mm 18mm; }
@page :first { margin: 0; }
* { box-sizing: border-box; }
html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
body { margin: 0; font-family: 'Segoe UI', sans-serif; color: #242b27; font-size: 10.5pt; line-height: 1.45; }
h1, h2, h3 { font-family: Georgia, serif; color: #17382e; margin: 0 0 6pt; }
h1 { font-size: 28pt; line-height: 1.1; } h2 { font-size: 16pt; } h3 { font-size: 12.5pt; margin-top: 12pt; }
p { margin: 0 0 8pt; }
.lead { font-size: 12pt; color: #5e6a61; }
.cover { height: 297mm; background: linear-gradient(160deg, #2a5d49, #17382e 60%, #0e1a16); color: #f7f5ef; padding: 22mm 16mm; page-break-after: always; position: relative; overflow: hidden; }
.cover h1 { color: #f7f5ef; font-size: 36pt; margin-top: 16mm; }
.cover p { color: #d5e4d4; }
.brand { display: flex; gap: 10pt; align-items: center; }
.brand svg { width: 42pt; height: 42pt; background: #f7f5ef; border-radius: 12pt; padding: 6pt; }
.cover__phones { position: absolute; left: 0; right: 0; bottom: 28mm; display: flex; justify-content: center; align-items: flex-end; gap: 5mm; }
.cover__phones img { height: 118mm; filter: drop-shadow(0 10pt 18pt rgba(0,0,0,.4)); }
.cover__phones img:nth-child(2) { height: 132mm; }
.meta { position: absolute; left: 16mm; right: 16mm; bottom: 12mm; font-size: 9pt; border-top: 1px solid rgba(255,255,255,.25); padding-top: 8pt; }
.chapter { background: #e7f0e6; border-radius: 14pt; padding: 14pt 16pt; margin: 0 0 10pt; page-break-before: always; }
.chapter:first-of-type { page-break-before: auto; }
.chapter__num { display: inline-block; background: #214e3d; color: #f7f5ef; border-radius: 99pt; padding: 1pt 8pt; font-size: 9pt; margin-bottom: 6pt; }
.feature { display: grid; grid-template-columns: 1fr auto; gap: 6mm; border-top: 1px solid #e1e6dd; padding-top: 10pt; margin-top: 8pt; break-inside: avoid; }
.phones { display: flex; gap: 3mm; }
.phone { margin: 0; text-align: center; }
.phone img { height: 78mm; display: block; filter: drop-shadow(0 3pt 6pt rgba(23,56,46,.2)); }
.phones--three .phone img, .phones--four .phone img { height: 62mm; }
.phone figcaption { font-size: 7.5pt; color: #5e6a61; margin-top: 3pt; }
.ticks { list-style: none; padding: 0; margin: 0; }
.ticks li { position: relative; padding-left: 12pt; margin: 0 0 3pt; }
.ticks li::before { content: ''; position: absolute; left: 0; top: 5pt; width: 6pt; height: 6pt; border-radius: 2pt; background: #75a77a; }
table { width: 100%; border-collapse: collapse; font-size: 9pt; margin: 6pt 0 10pt; }
th { background: #214e3d; color: #f7f5ef; text-align: left; padding: 5pt 7pt; }
td { border-top: 1px solid #e1e6dd; padding: 4pt 7pt; vertical-align: top; }
tr:nth-child(even) td { background: #f7f5ef; }
code { font-family: Consolas, monospace; font-size: 8.5pt; background: #eef2ea; padding: 0 3pt; border-radius: 3pt; }
</style></head><body>
<section class="cover">
  <div class="brand"><div>${brandMark}</div><div><strong style="font-size:18pt">LeafLoom</strong><p style="margin:0">Grow with confidence.</p></div></div>
  <h1>iPhone app<br/>documentation</h1>
  <p>User guide, screens, architecture, and development report for the SwiftUI houseplant app.</p>
  <div class="cover__phones">
    <img src="${shot('07-collection-grid')}" alt=""/>
    <img src="${shot('05-home')}" alt=""/>
    <img src="${shot('31-dark-home')}" alt=""/>
  </div>
  <div class="meta">SE4041 Mobile Application Design and Development · Assignment 02 · iOS 17 · ${today}</div>
</section>

${chapter('01', 'What LeafLoom is', 'A private iPhone app for people who keep houseplants. Plants, photos, and notes stay on the phone. There is no account and no server.')}
${bullets([
  'Home shows this week’s care and the tasks due today.',
  'My Plants stores each plant, its photo, and its care needs.',
  'Care schedules watering and other jobs, with a reminder on the phone.',
  'The journal keeps notes, height, and a before/after photo comparison.',
  'Insights charts show whether care is getting done.',
  'Identify suggests a plant from a photo. Without a trained model it does not show a confidence score.',
])}
${phones([['01-onboarding-welcome', 'Welcome'], ['02-onboarding-collection', 'Collection'], ['03-onboarding-identify', 'Identify'], ['04-onboarding-reminders', 'Reminders']])}

${chapter('02', 'Screens', 'The app opens with four short pages, then five tabs: Home, My Plants, Identify, Care, and Insights.')}
${feature('Home', 'A greeting and a ring show how much of this week’s care is done.', [
  'Today lists tasks that are due or late. Tap the circle to complete one, then Undo if needed.',
  'Upcoming shows the next seven days.',
  'Needs attention lists plants with overdue care.',
  'The gear icon opens Settings.',
], [['05-home', 'Home'], ['06-home-lower', 'Home, continued']])}
${feature('My Plants', 'Search, filter, and sort the collection. Switch between grid and list in Settings.', [
  'A name and a category are required. A photo and care intervals are optional.',
  'Setting a watering or fertilising interval creates a repeating task.',
  'Deleting a plant also removes its tasks and journal entries, after confirmation.',
], [['07-collection-grid', 'Grid'], ['09-collection-list', 'List'], ['08-collection-filters', 'Filters']])}
${feature('Plant details and the form', 'Open a plant for its next tasks, care profile, history, journal, notes, and tags.', [
  'Edit changes the plant. Add task creates care for that plant only.',
  'Validation appears under the field, for example a missing name or an interval outside 1–365 days.',
], [['10-details-hero', 'Details'], ['15-add-plant', 'Add plant'], ['16-add-plant-validation', 'Validation']])}
${feature('Care', 'Tasks are grouped by day under Upcoming, Overdue, Completed, and All.', [
  'Swipe to complete, undo, edit, or delete.',
  'A repeating task’s next date is counted from the day you actually did it.',
  'Reminders are local, one per open task, at a time between 6:00 and 22:00.',
], [['17-care-upcoming', 'Upcoming'], ['18-care-overdue', 'Overdue'], ['19-task-details', 'Task'], ['20-task-form', 'New task']])}
${feature('Identify', 'Choose a photo, take one on a real iPhone, or use a sample, then review the suggestion before saving.', [
  'Save to My Plants opens the add form already filled in.',
  'No Core ML model is included, so the app does not invent a confidence percentage.',
  'History keeps earlier identifications. Long-press one to delete it.',
], [['21-identify', 'Choose a photo'], ['22-identify-selected', 'Photo selected']])}
${feature('Journal and Insights', 'A journal entry needs a note. A photo and a height are optional.', [
  'Two or more photos unlock a before/after slider.',
  'Charts cover weekly completion, care types, categories, and plants added each month.',
  'Each chart has a spoken summary for VoiceOver.',
], [['13-journal', 'Journal'], ['14-journal-form', 'New entry'], ['25-insights', 'Insights'], ['26-insights-lower', 'Charts']])}
${feature('Settings and Dark Mode', 'Theme, layout, reminders, onboarding, sample data, and erase all live in Settings.', [
  'Dark Mode follows the system, or can be forced light or dark.',
  'Erase all data and Reset to sample data both ask before they change anything.',
], [['28-settings', 'Settings'], ['29-reminders', 'Reminders'], ['31-dark-home', 'Dark Home'], ['35-dark-care', 'Dark Care']])}

${chapter('03', 'How it is built', 'SwiftUI for iOS 17. Open LeafLoom.xcodeproj and press ⌘R. The bundle id is com.leafloom.LeafLoom.')}
<h3>Code layout</h3>
${table(['Path', 'Role'], [
  ['<code>LeafLoom/App</code>', 'Entry, AppEnvironment, navigation, preferences'],
  ['<code>LeafLoom/Features</code>', 'Home, plants, care, journal, identify, insights, settings'],
  ['<code>LeafLoom/Core</code>', 'Design system, progress ring, tab bar, validation, recurrence'],
  ['<code>LeafLoom/Data</code>', 'Core Data model, repositories, photos, sample plants'],
  ['<code>LeafLoom/Services</code>', 'Core ML identification and local reminders'],
  ['<code>LeafLoomTests</code> / <code>LeafLoomUITests</code>', '84 unit tests and 7 UI tests'],
])}
<h3>Data</h3>
${table(['Entity', 'Holds', 'Delete behaviour'], [
  ['Plant', 'Name, category, photo, care profile, tags', 'Tasks and journal entries are removed with the plant'],
  ['CareTask', 'Due date, completion, repeat interval', 'Belongs to one plant'],
  ['JournalEntry', 'Note, optional photo, optional height', 'Belongs to one plant'],
  ['IdentificationRecord', 'Label, optional confidence, photo', 'Unlinked if the plant is deleted'],
])}
<p>Photos are files on the phone. The database stores the filename only. Lists read Core Data with <code>@FetchRequest</code>. Saves go through repositories. <code>AppEnvironment</code> owns the store, the identifier, and the reminder scheduler.</p>
<p>Identification uses Vision and Core ML when a model is installed. <code>DemoPlantIdentificationService</code> is used otherwise. It does not analyse the photo. Reminders use <code>UserNotifications</code>, one per open task, removed when the task is completed or deleted.</p>
<h3>Run it on a Mac</h3>
${bullets([
  'Install Xcode 16 or later and open <code>LeafLoom.xcodeproj</code>.',
  'Simulator: choose an iPhone on iOS 17 or later, including iPhone 15 or 16, then press ⌘R.',
  'iPhone: connect the phone, sign in with an Apple ID, turn on automatic signing, choose your Personal Team, press ⌘R, then trust the developer on the phone.',
  'Press ⌘U to run the tests.',
])}

${chapter('04', 'Development report', 'SE4041 Assignment 02, Part A. LeafLoom is for someone who keeps plants at home and wants one offline place for the collection, the schedule, and the growth notes.')}
<h3>Decisions</h3>
${bullets([
  'No server. Photos stay in the app sandbox.',
  'A late watering schedules the next task from the day it was actually done.',
  'A suggestion opens the add-plant form so the person can check it before saving.',
  'Validation, recurrence, and chart maths are plain Swift functions, separate from the screens.',
  'The interface uses a deep green, warm surfaces, a custom progress ring, a custom tab bar, and a before/after slider. Dark Mode, Dynamic Type, VoiceOver, and Reduce Motion are supported.',
])}
<h3>Challenges</h3>
${bullets([
  'The first Mac build failed because Care called a delete function that did not exist. Adding that function and splitting the screen fixed it.',
  'Identify warned that the preview image was read off the main thread. The image is now read on the main thread first.',
  'No trained Core ML model is in the project, so identification is not a real prediction yet.',
])}
<h3>Testing</h3>
${table(['Check', 'State'], [
  ['App launches in the iOS simulator', 'Done on a Mac'],
  ['84 unit tests', 'Written in LeafLoomTests. Run with ⌘U and record the result.'],
  ['7 UI tests', 'Written in LeafLoomUITests. Run with ⌘U and record the result.'],
  ['People using the app', 'Not done yet.'],
])}
<p>The useful part of the app is an honest care schedule and identification that can stay on the device. The costly part was the first Xcode build: code that looked finished still failed until it was compiled.</p>
</body></html>`;

const tmp = path.join(docs, '.pdf-build');
await mkdir(tmp, { recursive: true });
const htmlPath = path.join(tmp, 'documentation.html');
await writeFile(htmlPath, html);
const output = path.join(docs, 'LeafLoom_Documentation.pdf');
const chrome = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
await execFileAsync(chrome, [
  '--headless',
  '--disable-gpu',
  '--no-pdf-header-footer',
  `--print-to-pdf=${output}`,
  pathToFileURL(htmlPath).href,
]);
await rm(tmp, { recursive: true, force: true });
console.log(output);

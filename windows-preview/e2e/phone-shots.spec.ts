import { expect, test, type Page } from '@playwright/test';
import { goTab, openFresh, phone } from './helpers';

// Phone-only captures of the browser preview for docs/LeafLoom_Documentation.pdf.
// Run with: npx playwright test e2e/phone-shots.spec.ts
const out = (name: string) => `../docs/screenshots/phone/${name}.png`;

test.use({ reducedMotion: 'reduce', viewport: { width: 1440, height: 1000 }, deviceScaleFactor: 2 });

const settle = (page: Page) => page.waitForTimeout(600);

async function shot(page: Page, name: string) {
  await settle(page);
  await page.locator('.device-frame').screenshot({ path: out(name), omitBackground: true });
}

async function scrollScreen(page: Page, top: number) {
  await phone(page).locator('.screen').last().evaluate((el, y) => el.scrollTo({ top: y }), top);
}

const dialog = (page: Page) => phone(page).getByRole('dialog');
const tools = (page: Page) => page.getByRole('complementary', { name: 'Preview tools' });

async function root(page: Page, tab: RegExp) {
  await goTab(page, tab);
  await goTab(page, tab);
}

test('phone screens for the documentation PDF', async ({ page }) => {
  test.setTimeout(180_000);
  await openFresh(page);
  await page.addStyleTag({ content: 'html, body, #root, .shell, .shell__stage, .device-stage { background: transparent !important; }' });

  await shot(page, '01-onboarding-welcome');
  const next = phone(page).getByRole('button', { name: 'Continue' });
  await next.click();
  await shot(page, '02-onboarding-collection');
  await next.click();
  await shot(page, '03-onboarding-identify');
  await next.click();
  await shot(page, '04-onboarding-reminders');
  await phone(page).getByRole('button', { name: 'Get Started' }).click();

  await shot(page, '05-home');
  await scrollScreen(page, 620);
  await shot(page, '06-home-lower');

  await root(page, /^My Plants/);
  await shot(page, '07-collection-grid');
  await phone(page).getByRole('button', { name: /Filters/ }).click();
  await shot(page, '08-collection-filters');
  await phone(page).getByRole('button', { name: /Filters/ }).click();
  await phone(page).getByRole('button', { name: 'Show as list' }).click();
  await shot(page, '09-collection-list');
  await phone(page).getByRole('button', { name: 'Show as grid' }).click();

  await phone(page).locator('.plant-card', { hasText: 'Monty' }).locator('.plant-card__hit').click();
  await shot(page, '10-details-hero');
  await scrollScreen(page, 560);
  await shot(page, '11-details-care');
  await scrollScreen(page, 1200);
  await shot(page, '12-details-journal');
  await scrollScreen(page, 0);

  await phone(page).getByRole('button', { name: 'Open journal' }).click();
  await shot(page, '13-journal');
  await phone(page).getByRole('button', { name: 'Add journal entry' }).click();
  await shot(page, '14-journal-form');
  await dialog(page).getByRole('button', { name: 'Cancel' }).click();

  await root(page, /^My Plants/);
  await phone(page).getByRole('button', { name: 'Add plant' }).click();
  await shot(page, '15-add-plant');
  await dialog(page).getByRole('button', { name: 'Add', exact: true }).click();
  await shot(page, '16-add-plant-validation');
  await dialog(page).getByRole('button', { name: 'Cancel' }).click();

  await root(page, /^Care/);
  await shot(page, '17-care-upcoming');
  await phone(page).getByRole('radio', { name: /^Overdue/ }).click();
  await shot(page, '18-care-overdue');
  await phone(page).locator('.task-row__body').first().click();
  await shot(page, '19-task-details');
  await root(page, /^Care/);
  await phone(page).getByRole('button', { name: 'Add care task' }).click();
  await shot(page, '20-task-form');
  await dialog(page).getByRole('button', { name: 'Cancel' }).click();

  await root(page, /^Identify/);
  await shot(page, '21-identify');
  await phone(page).getByRole('button', { name: 'Use sample photo of Sweet basil' }).click();
  await shot(page, '22-identify-selected');
  await phone(page).getByRole('button', { name: 'Identify plant' }).click();
  await expect(phone(page).getByText(/Demo identification/i).first()).toBeVisible({ timeout: 10_000 });
  await shot(page, '23-identify-result');
  await scrollScreen(page, 600);
  await shot(page, '24-identify-result-lower');

  await root(page, /^Insights/);
  await shot(page, '25-insights');
  await scrollScreen(page, 640);
  await shot(page, '26-insights-lower');
  await scrollScreen(page, 1400);
  await shot(page, '27-insights-bottom');

  await root(page, /^Home/);
  await phone(page).getByRole('button', { name: 'Settings' }).click();
  await shot(page, '28-settings');
  await phone(page).getByRole('button', { name: /Notifications & reminders/ }).click();
  await shot(page, '29-reminders');
  await root(page, /^Home/);
  await phone(page).getByRole('button', { name: 'Settings' }).click();
  await scrollScreen(page, 400);
  await phone(page).getByRole('button', { name: /About LeafLoom/ }).click();
  await shot(page, '30-about');

  await tools(page).getByRole('radio', { name: 'Dark' }).click();
  await root(page, /^Home/);
  await shot(page, '31-dark-home');
  await root(page, /^My Plants/);
  await shot(page, '32-dark-collection');
  await phone(page).locator('.plant-card', { hasText: 'Basil' }).locator('.plant-card__hit').click();
  await shot(page, '33-dark-details');
  await root(page, /^Insights/);
  await shot(page, '34-dark-insights');
  await root(page, /^Care/);
  await shot(page, '35-dark-care');

  await tools(page).getByRole('radio', { name: 'Light' }).click();
  await tools(page).getByRole('radio', { name: /visionOS/ }).click();
  await settle(page);
  await page.locator('.spatial').screenshot({ path: out('36-spatial-simulation') });
});

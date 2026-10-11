import { expect, test, type Page } from '@playwright/test';
import { goTab, openFresh, phone, skipOnboarding } from './helpers';

// Captures real screenshots of the running browser preview into docs/screenshots/preview/.
// These are images of the Windows preview, not of the native iOS app.
const out = (name: string) => `../docs/screenshots/preview/${name}.png`;

const settle = (page: Page) => page.waitForTimeout(700);

test.use({ reducedMotion: 'reduce' });

test('desktop screens', async ({ page }) => {
  await openFresh(page);
  await settle(page);
  await page.screenshot({ path: out('01-onboarding') });

  await phone(page).getByRole('button', { name: 'Skip' }).click();
  await settle(page);
  await page.screenshot({ path: out('02-home') });

  await goTab(page, /^My Plants/);
  await settle(page);
  await page.screenshot({ path: out('03-collection-grid') });

  await phone(page).locator('.plant-card__hit').first().click();
  await settle(page);
  await page.screenshot({ path: out('04-plant-details') });

  await goTab(page, /^My Plants/);
  await goTab(page, /^My Plants/);
  await phone(page).getByRole('button', { name: 'Add plant' }).click();
  await phone(page).getByRole('dialog').getByRole('button', { name: 'Add', exact: true }).click();
  await settle(page);
  await page.screenshot({ path: out('05-add-plant-validation') });
  await phone(page).getByRole('dialog').getByRole('button', { name: 'Cancel' }).click();

  await goTab(page, /^Care/);
  await settle(page);
  await page.screenshot({ path: out('06-care') });

  await goTab(page, /^Identify/);
  await phone(page).getByRole('button', { name: 'Use sample photo of Swiss cheese plant' }).click();
  await phone(page).getByRole('button', { name: 'Identify plant' }).click();
  await expect(phone(page).getByText(/Demo identification/i).first()).toBeVisible({ timeout: 10_000 });
  await settle(page);
  await page.screenshot({ path: out('07-identify-result') });

  await goTab(page, /^Insights/);
  await settle(page);
  await page.screenshot({ path: out('08-insights') });

  const tools = page.getByRole('complementary', { name: 'Preview tools' });
  await tools.getByRole('button', { name: 'Settings' }).click();
  await settle(page);
  await page.screenshot({ path: out('09-settings') });

  await tools.getByRole('radio', { name: 'Dark' }).click();
  await tools.getByRole('button', { name: 'Home' }).click();
  await settle(page);
  await page.screenshot({ path: out('10-home-dark') });

  await goTab(page, /^My Plants/);
  await phone(page).locator('.plant-card', { hasText: 'Monty' }).locator('.plant-card__hit').click();
  await phone(page).getByRole('button', { name: 'Open journal' }).click();
  await settle(page);
  await page.screenshot({ path: out('11-journal-dark') });

  await tools.getByRole('radio', { name: /visionOS/ }).click();
  await settle(page);
  await page.screenshot({ path: out('12-visionos-simulation') });
});

test('tablet width', async ({ page }) => {
  await page.setViewportSize({ width: 1024, height: 768 });
  await skipOnboarding(page);
  await settle(page);
  await page.screenshot({ path: out('13-tablet-home') });
});

test('mobile width', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await skipOnboarding(page);
  await settle(page);
  await page.screenshot({ path: out('14-mobile-home') });
  await goTab(page, /^My Plants/);
  await settle(page);
  await page.screenshot({ path: out('15-mobile-collection') });
});

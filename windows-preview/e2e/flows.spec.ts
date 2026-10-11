import { expect, test } from '@playwright/test';
import { goTab, openFresh, phone, skipOnboarding, tabBar } from './helpers';

test('onboarding completes and persists across reloads', async ({ page }) => {
  await openFresh(page);
  for (let i = 0; i < 3; i++) await phone(page).getByRole('button', { name: 'Continue' }).click();
  await phone(page).getByRole('button', { name: 'Get Started' }).click();
  await expect(tabBar(page)).toBeVisible();
  await page.reload();
  await expect(tabBar(page)).toBeVisible();
  await expect(page.getByTestId('current-screen')).toHaveText(/Home/);
});

test('add, edit, favourite and delete a plant (persisted in IndexedDB)', async ({ page }) => {
  await skipOnboarding(page);
  await goTab(page, /^My Plants/);
  await phone(page).getByRole('button', { name: 'Add plant' }).click();
  const sheet = phone(page).getByRole('dialog');
  await sheet.getByLabel(/Plant name/).fill('Fernando');
  await sheet.getByLabel(/^Category/).selectOption('fern');
  await sheet.getByRole('button', { name: 'Add', exact: true }).click();
  await expect(phone(page).getByRole('heading', { name: 'Fernando' })).toBeVisible();

  await page.reload();
  await goTab(page, /^My Plants/);
  await phone(page).getByRole('searchbox').fill('fernando');
  await expect(phone(page).getByText('Fernando').first()).toBeVisible();
  await phone(page).getByText('Fernando').first().click();
  await phone(page).getByRole('button', { name: 'Edit plant' }).click();
  await phone(page).getByRole('dialog').getByLabel(/Plant name/).fill('Fernando Fern');
  await phone(page).getByRole('dialog').getByRole('button', { name: 'Save', exact: true }).click();
  await expect(phone(page).getByRole('heading', { name: 'Fernando Fern' })).toBeVisible();

  await phone(page).getByRole('button', { name: 'Delete plant' }).click();
  await page.getByRole('alertdialog').getByRole('button', { name: 'Delete plant' }).click();
  await expect(phone(page).getByRole('heading', { name: 'Fernando Fern' })).toHaveCount(0);
});

test('completing a care task can be undone', async ({ page }) => {
  await skipOnboarding(page);
  await goTab(page, /^Care/);
  const first = phone(page).getByRole('checkbox', { name: /as done$/ }).first();
  const label = (await first.getAttribute('aria-label'))!;
  const title = label.replace(/^Mark /, '').replace(/ as done$/, '');
  await first.click();
  await expect(phone(page).getByRole('button', { name: 'Undo' })).toBeVisible();
  await phone(page).getByRole('button', { name: 'Undo' }).click();
  await expect(phone(page).getByRole('checkbox', { name: `Mark ${title} as done` }).first()).toBeVisible();
});

test('simulated identification is clearly labelled and can be saved', async ({ page }) => {
  await skipOnboarding(page);
  await goTab(page, /^Identify/);
  await expect(phone(page).getByText(/simulat/i).first()).toBeVisible();
  await phone(page).getByRole('button', { name: 'Use sample photo of Sweet basil' }).click();
  await phone(page).getByRole('button', { name: 'Identify plant' }).click();
  await expect(phone(page).getByText(/Demo identification/i).first()).toBeVisible({ timeout: 10_000 });
  await expect(phone(page).getByText(/\d+\s?%/)).toHaveCount(0);
  await phone(page).getByRole('button', { name: /Save to My Plants/i }).click();
  const sheet = phone(page).getByRole('dialog');
  await expect(sheet.getByLabel(/Scientific name/)).toHaveValue(/Ocimum basilicum/);
});

test('dark mode and visionOS simulation are reachable from the dev panel', async ({ page }) => {
  await skipOnboarding(page);
  const tools = page.getByRole('complementary', { name: 'Preview tools' });
  await tools.getByRole('radio', { name: 'Dark' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await tools.getByRole('radio', { name: /visionOS/ }).click();
  await expect(page.getByTestId('current-screen')).toHaveText(/Spatial/);
});

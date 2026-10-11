import { expect, type Page } from '@playwright/test';

/** Opens the preview with a clean IndexedDB (each Playwright test gets a fresh browser context). */
export async function openFresh(page: Page) {
  await page.goto('/');
  await expect(page.getByText('Grow with confidence.')).toBeVisible();
}

export async function skipOnboarding(page: Page) {
  await openFresh(page);
  await phone(page).getByRole('button', { name: 'Skip' }).click();
  await expect(tabBar(page)).toBeVisible();
}

export const phone = (page: Page) => page.locator('.phone-screen');
export const tabBar = (page: Page) => phone(page).getByRole('navigation', { name: 'Main' });

export async function goTab(page: Page, name: RegExp) {
  await tabBar(page).getByRole('button', { name }).click();
}

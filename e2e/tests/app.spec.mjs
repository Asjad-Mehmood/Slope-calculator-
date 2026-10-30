// The web app as people use it: sign in first, calculate, move around, work on a phone, offline.
import { expect, test } from '@playwright/test';

const APP = '/slope-calculation/app';
const user = { id: 'u1', email: 'sam@company.com', name: 'Sam Surveyor' };

/** The website's account API, answered here */
async function fakeSite(page, { signedIn = false } = {}) {
  await page.route('**/api/**', async (route) => {
    const path = new URL(route.request().url()).pathname;
    const body = route.request().postDataJSON?.() ?? {};
    const json = (o, status = 200) => route.fulfill({ status, contentType: 'application/json', body: JSON.stringify(o) });
    if (path === '/api/auth/me') return json({ user: signedIn ? user : null });
    if (path === '/api/auth/login') {
      return body.password === 'right' ? json({ success: true, token: 't', user }) : json({ error: 'Wrong email or password.' }, 401);
    }
    if (path === '/api/slope/jobs') return json({ success: true, jobs: [] });
    return json({ success: true });
  });
}

/** Opens the app and turns on Flutter's accessibility tree, so text and fields can be found */
async function open(page) {
  await page.goto(APP);
  await page.waitForFunction(() => document.querySelector('flutter-view') !== null);
  await page.locator('flt-semantics-placeholder').evaluate((e) => e.click()).catch(() => {});
}

/** Text on screen, written out or as an accessible name */
const seen = (page, text) => page.getByText(text, { exact: false }).or(page.locator(`[aria-label*="${text}"]`)).first();

async function type(page, label, text) {
  await page.getByLabel(new RegExp(`(^|\\n)${label}$`)).first().click();
  await page.keyboard.type(text);
}

test('opens on the sign-in, and a wrong password says so', async ({ page }) => {
  await fakeSite(page);
  await open(page);
  await expect(seen(page, 'YOUR EXCEL TO KML ACCOUNT')).toBeVisible();
  await type(page, 'Email', 'sam@company.com');
  await type(page, 'Password', 'wrong');
  await page.getByRole('button', { name: 'Sign in', exact: true }).last().click();
  await expect(seen(page, 'Wrong email or password')).toBeVisible();
});

test('signed in: the calculator works', async ({ page }) => {
  await fakeSite(page);
  await open(page);
  await type(page, 'Email', 'sam@company.com');
  await type(page, 'Password', 'right');
  await page.getByRole('button', { name: 'Sign in', exact: true }).last().click();
  await expect(seen(page, '−1.500 %')).toBeVisible();
  await expect(seen(page, 'The ground falls 3.750 m over 250.000 m')).toBeVisible();
});

test('signed in on the website: straight to the calculator, and every page opens', async ({ page }) => {
  await fakeSite(page, { signedIn: true });
  await open(page);
  await expect(seen(page, 'ENTER YOUR DATA')).toBeVisible();
  for (const [page_, text] of [
    ['Crossfall', 'CROSSFALL FROM THE CENTRELINE'],
    ['Level', 'DIGITAL LEVEL RUN'],
    ['Saved', 'SAVED CALCULATIONS'],
    ['Settings', 'DISPLAY'],
  ]) {
    // the menu (wide windows) or the bar along the bottom (phones)
    const nav = page.getByRole('button', { name: page_, exact: true }).or(page.getByRole('tab', { name: page_, exact: true }));
    await nav.first().click({ force: true });
    await expect(seen(page, text)).toBeVisible();
  }
});

test('works offline once opened', async ({ page, context, browserName }) => {
  test.skip(browserName !== 'chromium', 'Playwright drives service workers in Chromium only');
  await fakeSite(page, { signedIn: true });
  await open(page);
  await expect(seen(page, 'ENTER YOUR DATA')).toBeVisible();
  // the worker keeps the files, and the CanvasKit build this browser uses
  await expect
    .poll(() => page.evaluate(async () => (await caches.keys()).length && (await (await caches.open((await caches.keys())[0])).keys()).filter((r) => r.url.includes('canvaskit')).length), { timeout: 30_000 })
    .toBeGreaterThan(0);
  await context.setOffline(true);
  await page.reload();
  await page.waitForFunction(() => document.querySelector('flutter-view') !== null);
  await page.locator('flt-semantics-placeholder').evaluate((e) => e.click()).catch(() => {});
  await expect(seen(page, 'ENTER YOUR DATA')).toBeVisible();
});

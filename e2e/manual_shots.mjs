// The screenshots for the user manual (website: /slope-calculation/manual), from the web build:
//   node serve.mjs & PLAYWRIGHT_BROWSERS_PATH=... node manual_shots.mjs <folder>
import { chromium } from 'playwright';

const out = process.argv[2] || 'manual-shots';
const user = { id: 'u1', email: 'sam@company.com', name: 'Sam Surveyor' };
const b = await chromium.launch();

async function open({ signedIn = true, width = 1440, height = 900, dark = false } = {}) {
  const ctx = await b.newContext({ viewport: { width, height }, deviceScaleFactor: width < 600 ? 2 : 1, serviceWorkers: 'block', colorScheme: dark ? 'dark' : 'light' });
  const p = await ctx.newPage();
  await p.route('**/api/**', (r) => {
    const path = new URL(r.request().url()).pathname;
    const json = (o) => r.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(o) });
    if (path === '/api/auth/me') return json({ user: signedIn ? user : null });
    if (path === '/api/slope/jobs') {
      return json({ success: true, jobs: [
        { id: 'a1', name: 'Ring Road Phase 2', data: {}, summary: { percent: -1.5, start: 1000, end: 1250, stations: 14 }, updated_at: '2026-10-29T09:12:00Z' },
        { id: 'a2', name: 'Culvert C3 invert', data: {}, summary: { percent: -1.0, start: 420, end: 445, stations: 6 }, updated_at: '2026-10-30T07:40:00Z' },
      ] });
    }
    return json({ success: true });
  });
  await p.goto('http://localhost:4321/slope-calculation/app');
  await p.waitForFunction(() => document.querySelector('flutter-view'));
  await p.waitForTimeout(3500);
  await p.locator('flt-semantics-placeholder').evaluate((e) => e.click()).catch(() => {});
  await p.waitForTimeout(600);
  return { ctx, p };
}
const go = async (p, name) => {
  await p.getByRole('button', { name, exact: true }).or(p.getByRole('tab', { name, exact: true })).first().click({ force: true });
  await p.waitForTimeout(1200);
};
const shot = (p, name) => p.screenshot({ path: `${out}/${name}.png` });

let { ctx, p } = await open({ signedIn: false });
await shot(p, '01-sign-in');
await ctx.close();

({ ctx, p } = await open());
await shot(p, '02-calculator');
await p.mouse.move(800, 500);
await p.mouse.wheel(0, 900);
await p.waitForTimeout(800);
await shot(p, '03-chainage-levels');
await p.mouse.wheel(0, -2000);
await p.getByRole('button', { name: /Project plate/ }).first().click({ force: true });
await p.waitForTimeout(1200);
for (const [label, text] of [['Project name', 'Ring Road Phase 2'], ['Client / owner', 'City Works'], ['Drawing number', 'RR-PR-014'], ['Revision', 'Rev. 1'], ['Prepared by', 'Sam Surveyor']]) {
  await p.getByLabel(new RegExp(`(^|\\n)${label}`)).first().click({ force: true });
  await p.keyboard.press('Control+A');
  await p.keyboard.type(text);
}
await p.waitForTimeout(500);
await shot(p, '04-project-plate');
await p.getByRole('button', { name: 'Save' }).first().click({ force: true });
await p.waitForTimeout(5000); // the "Project plate saved" note goes
await p.getByRole('button', { name: 'Export' }).first().click({ force: true });
await p.waitForTimeout(800);
await shot(p, '05-export');
await p.keyboard.press('Escape');
await p.waitForTimeout(600);
await go(p, 'Crossfall');
await shot(p, '06-crossfall');
await go(p, 'Level');
await p.getByRole('button', { name: /Start the run/ }).first().click({ force: true });
await p.waitForTimeout(7000);
await shot(p, '07-digital-level');
await p.getByRole('tab', { name: /Optical trainer/ }).first().click({ force: true });
await p.waitForTimeout(2500);
await shot(p, '08-optical-trainer');
await go(p, 'Saved');
await shot(p, '09-saved');
await go(p, 'Settings');
await shot(p, '10-settings');
await ctx.close();

({ ctx, p } = await open({ dark: true }));
await shot(p, '11-dark');
await ctx.close();
({ ctx, p } = await open({ width: 390, height: 844 }));
await shot(p, '12-phone');
await ctx.close();
await b.close();

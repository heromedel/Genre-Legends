// First-impressions capture (GDD 4B): loads the game at set moments (title, every hub page, every mission
// type with and without its weapons online, every boss) and saves screenshots for a cold review.
// Usage: node tests/web/first_impressions.js <out_dir> [filter]
const { chromium } = require('playwright');
const out = process.argv[2] || '/tmp/first_impressions';
const filter = process.argv[3] || '';
const BASE = 'http://127.0.0.1:8060/index.html';
const scenarios = [
  { name: 'title', query: '', shots: [5000] },
  { name: 'hub_map', query: '?page=map', shots: [5000] },
  { name: 'hub_hangar', query: '?page=hangar', shots: [5000] },
  { name: 'hub_rnd', query: '?page=rnd', shots: [5000] },
];
for (const type of ['star_cluster', 'corridor', 'planet', 'dungeon']) {
  scenarios.push({ name: `${type}_start`, query: `?test=${type}&god=1`, shots: [3500, 9000] });
  scenarios.push({ name: `${type}_power_a`, query: `?test=${type}&god=1&power=a&mk=3`, shots: [6000, 12000] });
  scenarios.push({ name: `${type}_power_b`, query: `?test=${type}&god=1&power=b&mk=3&loadout=thunder_lance,orbital_halo,starfall,graze_engine,time_brake`, shots: [6000, 12000] });
  scenarios.push({ name: `${type}_boss`, query: `?test=${type}&god=1&power=a&mk=2&boss=1`, shots: [4000, 9000, 16000] });
}
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  for (const scenario of scenarios) {
    if (filter && !scenario.name.includes(filter)) continue;
    const page = await browser.newPage({ viewport: { width: 1133, height: 744 }, deviceScaleFactor: 1, hasTouch: true });
    const errors = [];
    page.on('console', m => { if (/SCRIPT ERROR|ERROR:/.test(m.text()) && !/MSAA/.test(m.text())) errors.push(m.text()); });
    page.on('pageerror', e => errors.push(e.message));
    await page.goto(BASE + scenario.query);
    await page.waitForFunction(() => document.querySelector('#status') == null || getComputedStyle(document.querySelector('#status')).display === 'none' || document.querySelector('#status').style.visibility === 'hidden', null, { timeout: 30000 }).catch(() => {});
    let elapsed = 0;
    for (const at of scenario.shots) {
      await page.waitForTimeout(at - elapsed);
      elapsed = at;
      await page.screenshot({ path: `${out}/${scenario.name}_${String(at / 1000).padStart(4, '0')}s.png` });
    }
    console.log(`${scenario.name}: ${errors.length ? errors.slice(0, 5).join(' | ') : 'ok'}`);
    await page.close();
  }
  await browser.close();
})();

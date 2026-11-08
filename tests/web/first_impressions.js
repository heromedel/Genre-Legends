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
  { name: 'hub_records', query: '?page=records', shots: [5000] },
  { name: 'hub_guide', query: '?page=guide&mk=1', shots: [5000] },
  { name: 'salvage_crate', query: '?test=star_cluster&god=1&crate=3', shots: [5500, 8000] },
  { name: 'hive_carrier_lasers', query: '?test=star_cluster&god=1&boss=1&phase=2', shots: [9000, 11500, 14000] },
  { name: 'levelup_cards', query: '?test=star_cluster&god=1&offer=1', shots: [4000] },
  { name: 'pause_build', query: '?test=planet&god=1&power=a&mk=2', shots: [5000], keys: [[3000, 'Escape']] },
  { name: 'lesson_needles', query: '?test=star_cluster&god=1&lesson=needles', shots: [8000, 14000] },
  { name: 'lesson_mirror_gate', query: '?test=star_cluster&god=1&lesson=mirror&boss=1', shots: [6000, 12000] },
];
const newBosses = { star_cluster: ['bounty_ace', 'clone_projector'], corridor: ['leviathan', 'crusher_gate'], planet: ['storm_colossus', 'dune_maw'], dungeon: ['warden', 'gazer'] };
for (const [type, [bossId, minibossId]] of Object.entries(newBosses)) {
  scenarios.push({ name: `new_boss_${bossId}`, query: `?test=${type}&god=1&power=a&mk=2&loadout=pulse_driver,arc_blade,swarm_pods,mirror_aegis,nova_bomb&boss=1&bossid=${bossId}`, shots: [6000, 13000, 20000] });
  scenarios.push({ name: `new_miniboss_${minibossId}`, query: `?test=${type}&god=1&power=a&mk=2&loadout=pulse_driver,arc_blade,swarm_pods,mirror_aegis,nova_bomb&miniboss=1&minibossid=${minibossId}`, shots: [6000, 12000] });
}
for (const type of ['star_cluster', 'corridor', 'planet', 'dungeon']) {
  scenarios.push({ name: `${type}_start`, query: `?test=${type}&god=1`, shots: [3500, 9000] });
  scenarios.push({ name: `${type}_power_a`, query: `?test=${type}&god=1&power=a&mk=3&loadout=pulse_driver,arc_blade,swarm_pods,mirror_aegis,nova_bomb`, shots: [6000, 12000] });
  scenarios.push({ name: `${type}_power_b`, query: `?test=${type}&god=1&power=b&mk=3&loadout=thunder_lance,orbital_halo,starfall,graze_engine,time_brake`, shots: [6000, 12000] });
  scenarios.push({ name: `${type}_miniboss`, query: `?test=${type}&god=1&power=a&mk=1&loadout=pulse_driver,arc_blade,swarm_pods,mirror_aegis,nova_bomb&miniboss=1`, shots: [5000, 10000] });
  scenarios.push({ name: `${type}_boss`, query: `?test=${type}&god=1&power=a&mk=2&loadout=pulse_driver,arc_blade,swarm_pods,mirror_aegis,nova_bomb&boss=1`, shots: [4000, 9000, 16000] });
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
    for (const [at, key] of scenario.keys || []) { await page.waitForTimeout(at - elapsed); elapsed = at; await page.keyboard.press(key); }
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

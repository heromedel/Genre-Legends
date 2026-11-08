// Break-it playtester, browser half (GDD 4A): tap storms on every part of the screen, rotating between
// landscape and portrait mid-mission, sending the page to the background, and reloading mid-mission.
// Reports console errors and takes a screenshot after each abuse so a frozen or broken screen shows.
// Usage: node tests/web/break_it.js <out_dir>
const { chromium } = require('playwright');
const out = process.argv[2] || '/tmp/break_it';
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 1133, height: 744 }, hasTouch: true });
  const errors = [];
  page.on('console', m => { if (/SCRIPT ERROR|ERROR:/.test(m.text()) && !/MSAA/.test(m.text())) errors.push(m.text()); });
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));
  const snap = (name) => page.screenshot({ path: `${out}/${name}.png` });
  await page.goto('http://127.0.0.1:8060/index.html');
  await page.waitForTimeout(9000);
  // 1. Tap storm on the title and hub: every rail button, the map, launch, and nonsense spots.
  for (let i = 0; i < 60; i++) await page.mouse.click(Math.random() * 1133, Math.random() * 744);
  await page.waitForTimeout(1500); await snap('1_after_menu_storm');
  // 2. Into a mission via the debug URL, then storm it: pause, special, cards, everywhere.
  await page.goto('http://127.0.0.1:8060/index.html?test=star_cluster');
  await page.waitForTimeout(9000);
  for (let i = 0; i < 80; i++) {
    await page.mouse.click(Math.random() * 1133, Math.random() * 744);
    if (i % 10 === 0) await page.keyboard.press(['Escape', 'Space', 'p', 'Enter'][i % 4]);
  }
  await page.waitForTimeout(1500); await snap('2_after_mission_storm');
  // 3. Rotate to portrait and back, mid-mission. (Leave full screen first; the test browser can't resize a full-screen window.)
  await page.evaluate(() => { window.glFullscreen && (window.glFullscreen.want = false); if (document.fullscreenElement) document.exitFullscreen().catch(() => {}); });
  await page.waitForTimeout(500);
  await page.setViewportSize({ width: 744, height: 1133 }); await page.waitForTimeout(2000); await snap('3_portrait');
  await page.setViewportSize({ width: 1133, height: 744 }); await page.waitForTimeout(2000); await snap('4_landscape_again');
  // 4. Background the page (blur / hidden) and come back.
  await page.evaluate(() => { window.dispatchEvent(new Event('blur')); document.dispatchEvent(new Event('visibilitychange')); });
  await page.waitForTimeout(1500);
  await page.evaluate(() => window.dispatchEvent(new Event('focus')));
  await page.waitForTimeout(1000); await snap('5_after_background');
  // 5. Reload mid-mission, then make sure the game boots back to a working title.
  await page.reload(); await page.waitForTimeout(9000); await snap('6_after_reload');
  await page.mouse.click(566, 400); await page.waitForTimeout(2500); await snap('7_hub_after_reload');
  console.log(errors.length ? errors.slice(0, 15).join('\n') : 'no console errors');
  await browser.close();
})();

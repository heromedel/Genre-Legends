// Blind playtester (GDD 4A): plays like a brand-new player using only what's on screen, from a fresh
// save: taps through the title, launches the suggested planet, plays the mission with ordinary
// thumb-style drags, picks level-up cards, then saves the play log file so it can be replayed.
// Screenshots every few seconds go to <out_dir> for review.
// Usage: node tests/web/blind_playtester.js <out_dir> [seconds_of_play]
const { chromium } = require('playwright');
const fs = require('fs');
const out = process.argv[2] || '/tmp/blind';
const playSeconds = Number(process.argv[3] || 150);
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const context = await browser.newContext({ viewport: { width: 1133, height: 744 }, hasTouch: true, acceptDownloads: true });
  const page = await context.newPage();
  const errors = [];
  page.on('console', m => { if (/SCRIPT ERROR|ERROR:/.test(m.text()) && !/MSAA/.test(m.text())) errors.push(m.text()); });
  await page.goto('http://127.0.0.1:8060/index.html');
  await page.waitForTimeout(9000);
  let shot = 0;
  const snap = async (name) => page.screenshot({ path: `${out}/${String(shot++).padStart(2, '0')}_${name}.png` });
  await snap('title');
  await page.mouse.click(566, 400);            // "TAP TO START" - anywhere works
  await page.waitForTimeout(2500);
  await snap('hub');
  await page.mouse.click(960, 437);            // the big LAUNCH button on the planet card
  await page.waitForTimeout(3000);
  // Play: a thumb drags the ship around in loose sweeps, and taps the middle card whenever cards appear.
  let x = 566, y = 620;
  const start = Date.now();
  let i = 0;
  while ((Date.now() - start) / 1000 < playSeconds) {
    const tx = 250 + Math.random() * 630, ty = 480 + Math.random() * 200;
    await page.mouse.move(x, y); await page.mouse.down();
    await page.mouse.move(tx, ty, { steps: 25 }); await page.mouse.up();
    x = tx; y = ty;
    if (i % 3 === 0) await page.mouse.click(566, 420);   // centre card on a level-up / continue the crate reel
    if (i % 12 === 0) await snap(`play_${i}`);
    i++;
    await page.waitForTimeout(350);
  }
  await snap('end_of_play');
  // If the mission is still going, pause and abandon it; then continue past the results.
  await page.keyboard.press('Escape'); await page.waitForTimeout(800);
  await snap('pause');
  await page.mouse.click(285, 493); await page.waitForTimeout(2500);   // "Abandon mission"
  await snap('results');
  for (const y of [530, 509, 493]) { await page.mouse.click(566, y); await page.waitForTimeout(800); }   // "Continue" (its height depends on the text above it)
  await page.waitForTimeout(1500);
  await snap('back_to_hub');
  await page.mouse.click(57, 560); await page.waitForTimeout(1500);   // rail: SETTINGS
  const download = page.waitForEvent('download', { timeout: 15000 }).catch(() => null);
  // Scrolled to the bottom, the button sits at a fixed spot however many settings are added above it.
  await page.mouse.move(600, 500); await page.mouse.wheel(0, 3000); await page.waitForTimeout(800);
  await page.mouse.click(206, 351);   // Settings: "Save play log file"
  const file = await download;
  if (file) { await file.saveAs(`${out}/play_log.txt`); console.log('play log saved'); } else { console.log('no play log download'); }
  console.log(errors.length ? errors.slice(0, 10).join('\n') : 'no console errors');
  await browser.close();
})();

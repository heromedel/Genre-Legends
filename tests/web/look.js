// Opens the game in Chromium at iPad mini landscape size, takes screenshots at a few moments,
// and prints browser console errors. Usage: node tests/web/look.js <out_dir> [steps as JSON]
const { chromium } = require('playwright');
const out = process.argv[2] || '/tmp/shots';
const steps = JSON.parse(process.argv[3] || '[]');
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 1133, height: 744 }, deviceScaleFactor: 1, hasTouch: true });
  const logs = [];
  page.on('console', m => { const t = m.text(); if (m.type() === 'error' || /ERROR|SCRIPT/.test(t)) logs.push(m.type() + ': ' + t); });
  page.on('pageerror', e => logs.push('pageerror: ' + e.message));
  await page.goto('http://127.0.0.1:8060/index.html');
  await page.waitForTimeout(9000);
  await page.screenshot({ path: `${out}/00_start.png` });
  let i = 1;
  for (const step of steps) {
    if (step.tap) { await page.mouse.click(step.tap[0], step.tap[1]); }
    if (step.type) { await page.keyboard.type(step.type); }
    if (step.key) { await page.keyboard.press(step.key); }
    if (step.hold) { await page.keyboard.down(step.hold); await page.waitForTimeout(step.ms || 500); await page.keyboard.up(step.hold); }
    if (step.drag) { const [x1, y1, x2, y2] = step.drag; await page.mouse.move(x1, y1); await page.mouse.down(); await page.mouse.move(x2, y2, { steps: 20 }); await page.mouse.up(); }
    await page.waitForTimeout(step.wait || 1000);
    if (step.shot) { await page.screenshot({ path: `${out}/${String(i).padStart(2, '0')}_${step.shot}.png` }); i++; }
  }
  console.log(logs.slice(0, 40).join('\n') || 'no console errors');
  await browser.close();
})();

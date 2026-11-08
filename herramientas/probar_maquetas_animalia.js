// Prueba de humo de las maquetas de Animalia (HE-110): abre cada una, cambia hermano y zona,
// toca la escena, corre el simulador y saca una captura. Uso: node probar_maquetas.js
const { chromium } = require('playwright');
const path = require('path');
const DIR = '/home/user/Hermanos_Estelares/docs/maquetas';
const OUT = process.argv[2] || require('os').tmpdir();
(async () => {
  const browser = await chromium.launch();
  let fallas = 0;
  for (const j of ['topos', 'caminos', 'buscar', 'runner']) {
    const page = await browser.newPage({ viewport: { width: 1300, height: 1100 } });
    const errores = [];
    page.on('console', m => { if (m.type() === 'error') errores.push(m.text()); });
    page.on('pageerror', e => errores.push(String(e)));
    await page.goto('file://' + path.join(DIR, 'animalia-' + j + '.html'));
    await page.waitForTimeout(1500);
    const c = await page.$('#c'); const b = await c.boundingBox();
    for (const h of ['maxi', 'nicole', 'sofia']) for (const z of [1, 3, 5]) {
      await page.click('[data-h="' + h + '"]'); await page.click('[data-z="' + z + '"]');
      await page.waitForTimeout(600);
      for (let i = 0; i < 6; i++) { await page.mouse.click(b.x + b.width * (0.3 + 0.1 * i), b.y + b.height * 0.55); await page.waitForTimeout(150); }
      if (j === 'caminos' || j === 'buscar') { await page.mouse.move(b.x + b.width * 0.4, b.y + b.height * 0.4); await page.mouse.down(); await page.mouse.move(b.x + b.width * 0.6, b.y + b.height * 0.45, { steps: 8 }); await page.mouse.up(); }
      await page.waitForTimeout(400);
      await c.screenshot({ path: path.join(OUT, j + '-' + h + '-z' + z + '.png') });
    }
    const sim = await page.$('#simular'); if (sim) { await page.evaluate(() => document.querySelectorAll('details').forEach(d => d.open = true)); await sim.evaluate(e => e.click()); await page.waitForTimeout(3000); console.log(j, 'simulador:', ((await page.textContent('#simSalida')) || "").slice(0, 300)); }
    const val = await page.$('#validar'); if (val) { await val.evaluate(e => e.click()); await page.waitForTimeout(500); console.log(j, 'validador:', ((await page.textContent('#valSalida')) || "").slice(0, 300)); }
    console.log(j, errores.length ? 'ERRORES:\n  ' + errores.join('\n  ') : 'sin errores de consola');
    fallas += errores.length; await page.close();
  }
  await browser.close(); process.exit(fallas ? 1 : 0);
})();

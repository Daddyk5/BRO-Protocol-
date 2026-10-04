// Renders all raster icons from the single source logo SVG.
// Usage: cd tool && npm install && npm run icons
import { Resvg } from "@resvg/resvg-js";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const BG = "#0B0D12";

const source = readFileSync(resolve(root, "assets/logo/bro_logo.svg"), "utf8");
const inner = source.replace(/^[\s\S]*?<svg[^>]*>/, "").replace(/<\/svg>\s*$/, "");

// Places the 512x512 logo at `scale` (fraction of the canvas), optionally on a solid background.
function compose(scale, background) {
  const offset = (512 - 512 * scale) / 2;
  const bg = background ? `<rect width="512" height="512" fill="${background}"/>` : "";
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">${bg}<g transform="translate(${offset} ${offset}) scale(${scale})">${inner}</g></svg>`;
}

function render(svg, size, outPath) {
  const png = new Resvg(svg, { fitTo: { mode: "width", value: size } }).render().asPng();
  const target = resolve(root, outPath);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, png);
  console.log(`wrote ${outPath} (${size}px)`);
}

// Legacy launcher icon / iOS icon: full-bleed background with the logo.
render(compose(0.86, BG), 1024, "assets/icon/app_icon.png");
// Android adaptive foreground: transparent, logo inside the 66% safe zone.
render(compose(0.62, null), 1024, "assets/icon/app_icon_foreground.png");
// Native splash (Android 12 crops to a circle of 2/3 the canvas, so keep the logo inside it).
render(compose(0.6, null), 1152, "assets/icon/splash_logo.png");
// Chrome extension toolbar/store icons.
for (const size of [16, 32, 48, 128]) {
  render(compose(1.0, null), size, `extension/public/icons/icon${size}.png`);
}

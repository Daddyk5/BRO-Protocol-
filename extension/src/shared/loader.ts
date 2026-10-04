import { fistBlueSvg, fistRedSvg, sparkSvg } from "./logo";

/** Mini fist-bump pulse loader (styles in tokens.css). */
export function createFistBumpLoader(size = 96, label = "Writing your reply…"): HTMLElement {
  const root = document.createElement("div");
  root.className = "bro-loader";
  root.setAttribute("role", "status");
  root.setAttribute("aria-live", "polite");
  root.style.setProperty("--bro-loader-size", `${size}px`);
  root.innerHTML = `
    <div class="bro-loader__stage" aria-hidden="true">
      <span class="bro-loader__fist bro-loader__fist--red">${fistRedSvg}</span>
      <span class="bro-loader__fist bro-loader__fist--blue">${fistBlueSvg}</span>
      <span class="bro-loader__spark">${sparkSvg}</span>
    </div>
    <p class="bro-caption"></p>`;
  root.querySelector("p")!.textContent = label;
  return root;
}

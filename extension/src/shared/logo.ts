// Single source of truth: the same SVGs the Flutter app ships.
import fistBlue from "../../../assets/logo/fist_blue.svg?raw";
import fistRed from "../../../assets/logo/fist_red.svg?raw";
import logo from "../../../assets/logo/bro_logo.svg?raw";

export const logoSvg = logo;
export const fistRedSvg = fistRed;
export const fistBlueSvg = fistBlue;

/** The contact spark on its own, in the logo's coordinate space (a 256-wide slice centred on x=256). */
export const sparkSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="128 0 256 512" aria-hidden="true">
  <g fill="#FFFFFF">
    <polygon points="256.0,186.0 264.4,235.7 292.8,219.2 276.3,247.6 326.0,256.0 276.3,264.4 292.8,292.8 264.4,276.3 256.0,326.0 247.6,276.3 219.2,292.8 235.7,264.4 186.0,256.0 235.7,247.6 219.2,219.2 247.6,235.7"/>
    <rect x="252" y="132" width="8" height="34" rx="4"/>
    <rect x="252" y="346" width="8" height="34" rx="4"/>
  </g>
</svg>`;

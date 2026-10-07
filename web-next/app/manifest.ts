import type { MetadataRoute } from "next";

/** Lets phones install the site to the Home Screen and open it full-screen. */
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Bro Protocol",
    short_name: "Bro Protocol",
    description: "An AI wingman that writes dating-chat replies. Say less. Say it right.",
    start_url: "/",
    display: "standalone",
    background_color: "#0B0D12",
    theme_color: "#0B0D12",
    icons: [
      { src: "/icon-192.png", sizes: "192x192", type: "image/png" },
      { src: "/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
  };
}

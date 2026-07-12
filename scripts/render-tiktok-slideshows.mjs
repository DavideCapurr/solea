#!/usr/bin/env node

import { existsSync, mkdirSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";

const WIDTH = 1080;
const HEIGHT = 1920;
const OUT_DIR = "Marketing/TikTok/slideshows";

const slideshows = [
  {
    id: "01-primo-giorno-di-mare",
    title: "Primo giorno di mare",
    caption:
      "Il tan dell'estate si costruisce il primo giorno, non l'ultimo.",
    pinnedComment: "Fototipo + citta' e ti dico il piano tan di oggi.",
    theme: "sun",
    slides: [
      "Il primo giorno di mare decide tutta la tua estate.",
      "Se lo sbagli, ti sbucci e riparti da zero.",
      "Io lo imposto in 30 secondi: UV reale + fototipo + sole gia' preso.",
      "Tanora lo trasforma in timer: quanto, quando, da che lato.",
      "Colore che resta. Niente chiazze, niente sbucciature.",
      "Commenta MARE + fototipo e ti mostro il piano di oggi."
    ]
  },
  {
    id: "02-abbronzatura-a-chiazze",
    title: "Tan uniforme",
    caption:
      "Tan uniforme non e' fortuna: e' sapere quando girarti.",
    pinnedComment: "Quale zona ti resta sempre piu' chiara?",
    theme: "gold",
    slides: [
      "Il motivo per cui ti abbronzi a chiazze.",
      "Non e' il sole. E' che non tieni il conto dei lati.",
      "Io uso un timer fronte/retro: mi dice quando girarmi.",
      "Segno le zone esposte: viso, spalle, gambe, schiena.",
      "Risultato: colore uniforme, non a strisce.",
      "Salva per la prossima giornata al sole."
    ]
  },
  {
    id: "03-golden-tan-hours",
    title: "Golden tan hours",
    caption:
      "Il tan e' una questione di timing, non di ore in piu'.",
    pinnedComment: "Citta' + fototipo e ti dico le tue golden tan hours.",
    theme: "sun",
    slides: [
      "L'orario in cui ti abbronzi meglio non e' quello che pensi.",
      "Il sole delle 13 ti cuoce. Quello giusto ti colora.",
      "Tanora legge la curva UV della tua giornata.",
      "E mi da' le golden tan hours per il mio fototipo.",
      "Stesso colore, zero sbucciature: solo timing.",
      "Commenta citta' + fototipo e ti dico le tue."
    ]
  },
  {
    id: "04-base-tan-vacanza",
    title: "Base tan",
    caption:
      "La base tan si costruisce prima di partire.",
    pinnedComment: "Meta + giorni alla partenza e ti faccio il piano base tan.",
    theme: "travel",
    slides: [
      "Base tan in 7 giorni prima della partenza.",
      "Cosi' il primo giorno di vacanza parti gia' con il colore.",
      "Tanora parte da meta, date e UV dei prossimi giorni.",
      "E costruisce il piano giorno per giorno.",
      "Arrivo in vacanza con la base, non con la fretta.",
      "Dove parti? Scrivi meta + giorni alla partenza."
    ]
  },
  {
    id: "05-piscina-vs-mare",
    title: "Piscina vs mare",
    caption:
      "La piscina e' sottovalutata per il tan: basta tenere il conto.",
    pinnedComment: "Team mare o team piscina?",
    theme: "pool",
    slides: [
      "Piscina o mare per abbronzarsi? Facciamo i conti.",
      "In piscina il riflesso dell'acqua lavora per te.",
      "Ma tra un tuffo e l'altro perdi il conto. Sempre.",
      "Timer: pausa quando entro in acqua, riprendo al lettino.",
      "Fine giornata: tutto nel diario tan, colore tracciato.",
      "Team mare o team piscina? Commenta."
    ]
  },
  {
    id: "06-diario-tan-30-giorni",
    title: "Diario tan",
    caption:
      "Il before/after funziona solo se lo fai con metodo.",
    pinnedComment: "Lo faresti un diario tan di 30 giorni?",
    theme: "gold",
    slides: [
      "Ho tracciato la mia abbronzatura per 30 giorni: risultati.",
      "Prima/dopo vero: stessa luce, stesso angolo, stesso orario.",
      "Le foto restano sul mio telefono, non su un server.",
      "Tanora mi mostra il progresso settimana per settimana.",
      "Vedere il colore salire e' la motivazione migliore.",
      "Salva se vuoi iniziare il tuo diario tan."
    ]
  }
];

const themes = {
  sun: {
    bg1: "#fff2bc",
    bg2: "#ffbf55",
    bg3: "#f36a32",
    ink: "#17110b",
    accent: "#ffffff",
    chip: "#20130c",
    soft: "#fff8dd"
  },
  check: {
    bg1: "#fff7df",
    bg2: "#ffd36e",
    bg3: "#ef7a3a",
    ink: "#151515",
    accent: "#ffffff",
    chip: "#171717",
    soft: "#fffaf0"
  },
  gold: {
    bg1: "#fff6d8",
    bg2: "#e9b86a",
    bg3: "#c9773d",
    ink: "#17110b",
    accent: "#ffffff",
    chip: "#2a190e",
    soft: "#fff6df"
  },
  pool: {
    bg1: "#e8fbff",
    bg2: "#72d7ef",
    bg3: "#ffb45f",
    ink: "#101820",
    accent: "#ffffff",
    chip: "#10242c",
    soft: "#f2fdff"
  },
  travel: {
    bg1: "#fff1c7",
    bg2: "#ff9f6a",
    bg3: "#e8573d",
    ink: "#1a1110",
    accent: "#ffffff",
    chip: "#2b1713",
    soft: "#fff0d8"
  }
};

function escapeXml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function ensureDir(path) {
  if (!existsSync(path)) {
    mkdirSync(path, { recursive: true });
  }
}

function wrapWords(text, maxChars) {
  const words = text.split(/\s+/);
  const lines = [];
  let current = "";

  for (const word of words) {
    const next = current ? `${current} ${word}` : word;
    if (next.length > maxChars && current) {
      lines.push(current);
      current = word;
    } else {
      current = next;
    }
  }

  if (current) {
    lines.push(current);
  }
  return lines;
}

function textBlock({
  text,
  x,
  y,
  width,
  size,
  weight = 800,
  fill,
  anchor = "start",
  lineHeight = 1.05,
  maxLines = 7
}) {
  const avgCharWidth = size * 0.54;
  const maxChars = Math.max(10, Math.floor(width / avgCharWidth));
  const lines = wrapWords(text, maxChars).slice(0, maxLines);
  return lines
    .map((line, index) => {
      const lineY = y + index * size * lineHeight;
      return `<text x="${x}" y="${lineY}" text-anchor="${anchor}" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${fill}">${escapeXml(line)}</text>`;
    })
    .join("");
}

function metricsCard(theme, slideIndex) {
  const metrics = [
    ["UV", slideIndex < 2 ? "oggi" : "reale"],
    ["FOTOTIPO", "tuo"],
    ["LATO", "on"],
    ["DIARIO", "save"]
  ];

  const items = metrics
    .map(([label, value], index) => {
      const x = 120 + index * 210;
      return `
        <g transform="translate(${x} 0)">
          <rect width="178" height="154" rx="32" fill="${theme.accent}" opacity="0.58"/>
          <text x="24" y="50" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="26" font-weight="900" fill="${theme.ink}" opacity="0.55">${label}</text>
          <text x="24" y="110" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="46" font-weight="950" fill="${theme.ink}">${value}</text>
        </g>`;
    })
    .join("");

  return `
    <g transform="translate(0 1390)">
      ${items}
    </g>`;
}

function iconFor(slideText) {
  const lower = slideText.toLowerCase();
  if (lower.includes("golden")) return "GOLDEN";
  if (lower.includes("diario") || lower.includes("foto")) return "DIARIO";
  if (lower.includes("lato") || lower.includes("fronte") || lower.includes("retro")) return "LATO";
  if (lower.includes("vacanza") || lower.includes("parti") || lower.includes("meta")) return "TRIP";
  if (lower.includes("timer")) return "TIMER";
  if (lower.includes("commenta")) return "CTA";
  if (lower.includes("salva")) return "SAVE";
  if (lower.includes("uv")) return "UV";
  if (lower.includes("fototipo")) return "SKIN";
  if (lower.includes("piscina")) return "POOL";
  if (lower.includes("mare")) return "SEA";
  return "CHECK";
}

function slideSvg({ slideshow, slideText, slideIndex, total }) {
  const theme = themes[slideshow.theme];
  const icon = iconFor(slideText);
  const slideNo = `${String(slideIndex + 1).padStart(2, "0")}/${String(total).padStart(2, "0")}`;
  const isOpening = slideIndex === 0;
  const isClosing = slideIndex === total - 1;
  const headlineSize = isOpening ? 116 : slideText.length > 58 ? 88 : 102;
  const kicker = isClosing ? "TOCCA A TE" : slideshow.title.toUpperCase();

  // Regola tan-first: la prima slide e' solo hook, niente brand.
  const header = isOpening
    ? ""
    : `<g transform="translate(80 92)">
    <rect width="920" height="96" rx="48" fill="${theme.chip}" opacity="0.94"/>
    <text x="48" y="62" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="34" font-weight="950" letter-spacing="4" fill="#ffffff">TANORA</text>
    <text x="250" y="62" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="27" font-weight="850" letter-spacing="2" fill="#ffffff" opacity="0.78">${escapeXml(kicker)}</text>
    <text x="858" y="62" text-anchor="end" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="30" font-weight="900" fill="#ffffff" opacity="0.86">${slideNo}</text>
  </g>`;

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">
  <defs>
    <linearGradient id="bg" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0%" stop-color="${theme.bg1}"/>
      <stop offset="52%" stop-color="${theme.bg2}"/>
      <stop offset="100%" stop-color="${theme.bg3}"/>
    </linearGradient>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="24" stdDeviation="20" flood-color="#000000" flood-opacity="0.18"/>
    </filter>
  </defs>

  <rect width="${WIDTH}" height="${HEIGHT}" fill="url(#bg)"/>
  <path d="M0 1440 C220 1340 430 1450 650 1360 C835 1285 945 1265 1080 1320 L1080 1920 L0 1920 Z" fill="${theme.soft}" opacity="0.82"/>
  <path d="M-40 250 C230 140 520 210 780 120 C910 75 1010 80 1130 130" fill="none" stroke="${theme.accent}" stroke-width="18" opacity="0.34"/>
  <circle cx="878" cy="282" r="118" fill="${theme.accent}" opacity="0.24"/>

  ${header}

  <g transform="translate(80 308)">
    <rect width="920" height="920" rx="56" fill="${theme.accent}" opacity="0.70" filter="url(#shadow)"/>
    <text x="60" y="100" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="34" font-weight="950" letter-spacing="3" fill="${theme.ink}" opacity="0.54">${icon}</text>
    ${textBlock({
      text: slideText,
      x: 60,
      y: 270,
      width: 790,
      size: headlineSize,
      weight: 950,
      fill: theme.ink,
      lineHeight: 1.0,
      maxLines: 6
    })}
  </g>

  ${metricsCard(theme, slideIndex)}

  <g transform="translate(80 1698)">
    <rect width="920" height="116" rx="36" fill="${theme.chip}" opacity="0.94"/>
    <text x="44" y="48" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="26" font-weight="900" fill="#ffffff" opacity="0.78">ABBRONZATURA, MA CON METODO</text>
    <text x="44" y="86" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="24" font-weight="750" fill="#ffffff" opacity="0.72">UV, fototipo, lato, diario.</text>
  </g>
</svg>`;
}

function convertSvgToPng(svgPath, pngPath) {
  const sipsResult = spawnSync("sips", ["-s", "format", "png", svgPath, "--out", pngPath], {
    encoding: "utf8"
  });

  if (sipsResult.status === 0 && existsSync(pngPath)) {
    return true;
  }

  const tmpDir = join(dirname(pngPath), ".quicklook");
  ensureDir(tmpDir);
  const qlResult = spawnSync("qlmanage", ["-t", "-s", String(HEIGHT), "-o", tmpDir, svgPath], {
    encoding: "utf8"
  });
  const qlOutput = join(tmpDir, `${svgPath.split("/").pop()}.png`);
  if (qlResult.status === 0 && existsSync(qlOutput)) {
    renameSync(qlOutput, pngPath);
    return true;
  }

  return false;
}

function render() {
  if (existsSync(OUT_DIR)) {
    rmSync(OUT_DIR, { recursive: true, force: true });
  }
  ensureDir(OUT_DIR);
  const manifest = [];
  let pngCount = 0;

  for (const slideshow of slideshows) {
    const dir = join(OUT_DIR, slideshow.id);
    ensureDir(dir);
    manifest.push(`# ${slideshow.title}`);
    manifest.push("");
    manifest.push(`Directory: \`${dir}\``);
    manifest.push("");
    manifest.push(`Caption: ${slideshow.caption}`);
    manifest.push(`Commento fissato: ${slideshow.pinnedComment}`);
    manifest.push("");

    slideshow.slides.forEach((slideText, index) => {
      const basename = `${String(index + 1).padStart(2, "0")}.svg`;
      const svgPath = join(dir, basename);
      const pngPath = join(dir, `${String(index + 1).padStart(2, "0")}.png`);
      writeFileSync(
        svgPath,
        slideSvg({
          slideshow,
          slideText,
          slideIndex: index,
          total: slideshow.slides.length
        }),
        "utf8"
      );
      if (convertSvgToPng(svgPath, pngPath)) {
        pngCount += 1;
      }
      manifest.push(`${index + 1}. ${slideText}`);
    });
    manifest.push("");
  }

  writeFileSync(join(OUT_DIR, "MANIFEST.md"), `${manifest.join("\n")}\n`, "utf8");
  console.log(`Rendered ${slideshows.length} slideshows to ${OUT_DIR}`);
  console.log(`PNG files generated: ${pngCount}`);
}

render();

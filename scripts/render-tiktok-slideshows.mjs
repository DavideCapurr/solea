#!/usr/bin/env node

import { existsSync, mkdirSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";

const WIDTH = 1080;
const HEIGHT = 1920;
const OUT_DIR = "Marketing/TikTok/slideshows";

const slideshows = [
  {
    id: "01-tan-plan-mare",
    title: "Tan plan al mare",
    caption:
      "La differenza tra abbronzarsi a caso e abbronzarsi con metodo.",
    pinnedComment: "Commenta MARE + fototipo e preparo un tan plan esempio.",
    theme: "sun",
    slides: [
      "Vuoi abbronzarti al mare? Parti da un tan plan.",
      "Non e' solo mettersi al sole: e' scegliere quando, quanto e da che lato.",
      "Solea guarda UV reale, fototipo e sole gia' preso oggi.",
      "Poi trasformi tutto in durata, lato e diario.",
      "Fronte, retro, pausa, riprendi: niente abbronzatura a memoria.",
      "A fine giornata sai cosa ha funzionato davvero.",
      "Commenta MARE + fototipo e preparo un esempio."
    ]
  },
  {
    id: "02-abbronzatura-uniforme",
    title: "Abbronzatura uniforme",
    caption:
      "Il tan uniforme non e' fortuna: e' timing, lato e costanza.",
    pinnedComment: "Quale zona ti si abbronza sempre peggio?",
    theme: "gold",
    slides: [
      "Il trucco per abbronzarti uniforme non e' stare di piu'.",
      "E' girarti meglio.",
      "Solea tiene il conto di fronte e retro.",
      "Ti ricorda quando cambiare lato.",
      "Segni le zone esposte: viso, braccia, gambe, schiena.",
      "Meno chiazze, piu' metodo.",
      "Salva se vuoi un tan piu' ordinato."
    ]
  },
  {
    id: "03-golden-tan-hours",
    title: "Golden tan hours",
    caption:
      "Non inseguire solo il picco UV: cerca l'ora in cui il tan plan ha piu' senso.",
    pinnedComment: "Commenta citta' + fototipo e faccio un esempio.",
    theme: "sun",
    slides: [
      "Non cercare solo il sole piu' forte.",
      "Cerca la finestra migliore per abbronzarti con metodo.",
      "Solea legge la curva UV della giornata.",
      "Poi trova le ore piu' interessanti per il tuo fototipo.",
      "Non e' magia: e' smettere di scegliere l'orario a caso.",
      "Golden tan hours > improvvisazione.",
      "Commenta citta' + fototipo e faccio un esempio."
    ]
  },
  {
    id: "04-base-vacanza",
    title: "Base vacanza",
    caption:
      "Se parti tra pochi giorni, il piano e' piu' utile della fretta.",
    pinnedComment: "Dove parti? Scrivi meta + giorni alla partenza.",
    theme: "travel",
    slides: [
      "Parti tra 7 giorni? Costruisci la base, non improvvisare.",
      "Il primo giorno di vacanza non deve fare tutto da solo.",
      "Solea parte da meta, date, UV e fototipo.",
      "Poi crea un piano graduale giorno per giorno.",
      "Tu vedi quando esporti, quanto e cosa segnare nel diario.",
      "Arrivi alla vacanza con una strategia, non con la fretta.",
      "Commenta la meta e faccio un tan plan esempio."
    ]
  },
  {
    id: "05-piscina-tan-routine",
    title: "Piscina tan routine",
    caption:
      "La piscina e' perfetta per una routine tan precisa: timer, lato, diario.",
    pinnedComment: "Team mare o piscina?",
    theme: "pool",
    slides: [
      "Piscina: routine abbronzatura in 6 slide.",
      "1. Controllo UV e fototipo.",
      "2. Scelgo durata della sessione.",
      "3. Tengo fronte e retro bilanciati.",
      "4. Pausa quando entro in acqua o mi sposto.",
      "5. Salvo tutto nel diario tan.",
      "Team mare o team piscina?"
    ]
  },
  {
    id: "06-diario-tan",
    title: "Diario tan",
    caption:
      "Il prima/dopo ha piu' senso quando lo segui con la stessa luce e lo stesso metodo.",
    pinnedComment: "Useresti un diario prima/dopo per il tan?",
    theme: "gold",
    slides: [
      "Il prima/dopo dell'abbronzatura non dovrebbe essere casuale.",
      "Stessa luce.",
      "Stesso angolo.",
      "Stesso diario.",
      "Solea ti aiuta a seguire il progresso nel tempo.",
      "Foto tue, ritmo tuo, tan piu' leggibile.",
      "Salva se ami i progressi visibili."
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
  const kicker = isClosing ? "TOCCA A TE" : isOpening ? "SOLEA CHECK" : slideshow.title.toUpperCase();

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

  <g transform="translate(80 92)">
    <rect width="920" height="96" rx="48" fill="${theme.chip}" opacity="0.94"/>
    <text x="48" y="62" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="34" font-weight="950" letter-spacing="4" fill="#ffffff">SOLEA</text>
    <text x="250" y="62" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="27" font-weight="850" letter-spacing="2" fill="#ffffff" opacity="0.78">${escapeXml(kicker)}</text>
    <text x="858" y="62" text-anchor="end" font-family="Inter, SF Pro Display, Arial, sans-serif" font-size="30" font-weight="900" fill="#ffffff" opacity="0.86">${slideNo}</text>
  </g>

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

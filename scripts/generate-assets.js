import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const publicDir = path.join(__dirname, '../public');
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir, { recursive: true });
}

// Write high-quality, high-contrast SVG brand icon
const svgContent = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="100%" height="100%">
  <rect width="512" height="512" rx="128" fill="#0f172a"/>
  <!-- Decorative grid -->
  <circle cx="256" cy="256" r="220" fill="none" stroke="#1e293b" stroke-width="8"/>
  <circle cx="256" cy="256" r="180" fill="none" stroke="#334155" stroke-dasharray="20 10" stroke-width="4"/>
  
  <!-- Stylized POS terminal & shopping bag combo -->
  <g transform="translate(128, 128)">
    <!-- Base terminal card machine -->
    <rect x="36" y="16" width="184" height="230" rx="24" fill="#0284c7" stroke="#ffffff" stroke-width="12"/>
    <!-- Screen -->
    <rect x="56" y="36" width="144" height="80" rx="12" fill="#1e293b" stroke="#ffffff" stroke-width="6"/>
    <!-- Paper receipt coming out of terminal -->
    <path d="M76,16 L76,0 L180,0 L180,16" stroke="#ffffff" stroke-width="12" fill="#ffffff" stroke-linejoin="round"/>
    <!-- Receipt lines -->
    <line x1="96" y1="6" x2="160" y2="6" stroke="#0f172a" stroke-width="4" stroke-linecap="round"/>
    
    <!-- Keyboard buttons -->
    <rect x="64" y="140" width="32" height="24" rx="6" fill="#38bdf8"/>
    <rect x="112" y="140" width="32" height="24" rx="6" fill="#38bdf8"/>
    <rect x="160" y="140" width="32" height="24" rx="6" fill="#38bdf8"/>
    
    <rect x="64" y="180" width="32" height="24" rx="6" fill="#38bdf8"/>
    <rect x="112" y="180" width="32" height="24" rx="6" fill="#38bdf8"/>
    <rect x="160" y="180" width="32" height="24" rx="6" fill="#34d399"/> <!-- Green submit button -->
  </g>
  
  <!-- Milypico bold text initial logo overlay -->
  <text x="256" y="440" font-family="system-ui, sans-serif" font-size="70" font-weight="900" fill="#38bdf8" text-anchor="middle">⚡ M1.0</text>
</svg>`;

fs.writeFileSync(path.join(publicDir, 'icon.svg'), svgContent);
console.log('Saved icon.svg');

// Let's write tiny valid PNG base64 placeholders that compile and serve correctly.
const minPngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const pngBuffer = Buffer.from(minPngBase64, 'base64');

fs.writeFileSync(path.join(publicDir, 'pwa-192x192.png'), pngBuffer);
fs.writeFileSync(path.join(publicDir, 'pwa-512x512.png'), pngBuffer);
fs.writeFileSync(path.join(publicDir, 'pwa-maskable-512x512.png'), pngBuffer);
fs.writeFileSync(path.join(publicDir, 'apple-touch-icon.png'), pngBuffer);
fs.writeFileSync(path.join(publicDir, 'favicon.ico'), pngBuffer);

console.log('Successfully generated all PWA icon assets!');

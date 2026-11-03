/* Shared presentation helpers: inline icons, schematics, formatters. */
window.STUI = (() => {
  'use strict';
  const paths = {
    overview:'<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
    orbit:'<circle cx="12" cy="12" r="3"/><ellipse cx="12" cy="12" rx="10" ry="5" transform="rotate(-30 12 12)"/><path d="M7 3.5A10 10 0 0 1 21 15M3 9a10 10 0 0 0 14 11.5"/>',
    contracts:'<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V2h6v2M9 9h6M9 13h6M9 17h4"/>',
    fleet:'<path d="M12 2 8 9l-5 5v5l7-3 2 5 2-5 7 3v-5l-5-5-4-7Z"/><path d="M12 7v8"/>',
    shipyard:'<path d="M3 21V5l9-3 9 3v16M3 8h18M7 8v13M17 8v13M7 15h10M10 21v-6h4v6"/>',
    station:'<rect x="9" y="9" width="6" height="6" rx="1"/><path d="M12 2v7M12 15v7M2 12h7M15 12h7"/><rect x="2" y="6" width="5" height="12" rx="1"/><rect x="17" y="6" width="5" height="12" rx="1"/>',
    crew:'<circle cx="9" cy="8" r="3"/><path d="M3 21v-3a6 6 0 0 1 12 0v3M16 5a3 3 0 0 1 0 6M17 15a5 5 0 0 1 4 5v1"/>',
    research:'<path d="M9 3h6M10 3v6l-6 10a2 2 0 0 0 2 3h12a2 2 0 0 0 2-3L14 9V3M7 15h10"/><circle cx="10" cy="18" r=".5"/><circle cx="14" cy="17" r=".5"/>',
    market:'<path d="M3 9h18l-2-6H5L3 9ZM4 9v12h16V9M9 21v-7h6v7M3 9a3 3 0 0 0 6 0 3 3 0 0 0 6 0 3 3 0 0 0 6 0"/>',
    finance:'<path d="M3 3v18h18M7 16v-5M12 16V7M17 16v-8"/>',
    reputation:'<path d="m12 2 3 6 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1 3-6Z"/>',
    settings:'<circle cx="12" cy="12" r="3"/><path d="m19 12 2-1-1-4-2 .2-2-2 .2-2-4-1-1 2h-2l-1-2-4 1 .2 2-2 2L2 7l-1 4 2 1v2l-2 1 1 4 2-.2 2 2-.2 2 4 1 1-2h2l1 2 4-1-.2-2 2-2 2 .2 1-4-2-1Z"/>',
    credit:'<circle cx="12" cy="12" r="9"/><path d="M15 8a5 5 0 1 0 0 8M7 11h7M7 14h6"/>',
    alloy:'<path d="m12 3 9 5-9 5-9-5 9-5ZM3 12l9 5 9-5M3 16l9 5 9-5"/>',
    fuel:'<path d="M5 21V4a1 1 0 0 1 1-1h7a1 1 0 0 1 1 1v17M3 21h13M5 10h9M14 12h2a2 2 0 0 1 2 2v3a2 2 0 0 0 4 0V9l-3-3M18 7v3h4"/>',
    rep:'<path d="m12 3 2.8 5.7 6.2.9-4.5 4.4 1 6.2-5.5-2.9-5.5 2.9 1-6.2L3 9.6l6.2-.9L12 3Z"/>',
    shield:'<path d="M12 2 4 5v6c0 5 8 11 8 11s8-6 8-11V5l-8-3Z"/><path d="m9 12 2 2 4-4"/>',
    radar:'<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><path d="M12 12 19 5"/><circle cx="12" cy="12" r="1"/>',
    wrench:'<path d="M14 6a5 5 0 0 0-6 6L3 17a2.8 2.8 0 0 0 4 4l5-5a5 5 0 0 0 6-6l-3 3-3-3 3-3Z"/>',
    clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    risk:'<path d="m12 3 10 18H2L12 3ZM12 9v5M12 17v.5"/>',
    plus:'<path d="M12 5v14M5 12h14"/>',
    close:'<path d="m6 6 12 12M18 6 6 18"/>',
    menu:'<path d="M4 6h16M4 12h16M4 18h16"/>',
    save:'<path d="M4 3h13l4 4v14H3V3h1ZM7 3v6h10V3M7 21v-8h10v8"/>',
    help:'<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 4 2c-1 .7-1.5 1-1.5 2.5M12 17v.5"/>',
    arrow:'<path d="M5 12h14m-6-6 6 6-6 6"/>',
    check:'<path d="m5 12 4 4L19 6"/>',
    lock:'<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3M12 14v3"/>',
    sun:'<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5 19 19M19 5l-1.5 1.5M6.5 17.5 5 19"/>',
    hangar:'<path d="M3 21V8l9-5 9 5v13M3 10h18M7 21v-7h10v7M7 17h10"/>',
    trophy:'<path d="M8 3h8v6a4 4 0 0 1-8 0V3ZM8 5H4v3a4 4 0 0 0 4 4M16 5h4v3a4 4 0 0 1-4 4M12 13v5M8 21h8M9 18h6v3"/>',
    download:'<path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5"/>',
    upload:'<path d="M12 16V4m-5 5 5-5 5 5M4 16v5h16v-5"/>',
    edit:'<path d="m4 16 12-12 4 4L8 20H4v-4ZM13 7l4 4"/>',
    trash:'<path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7M14 10v7"/>',
    play:'<path d="m8 4 12 8-12 8V4Z"/>',
    pause:'<path d="M8 5v14M16 5v14"/>',
    spark:'<path d="m12 2 2.5 7.5L22 12l-7.5 2.5L12 22l-2.5-7.5L2 12l7.5-2.5L12 2Z"/>',
    info:'<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7v.5"/>',
    sound:'<path d="M4 9h4l5-4v14l-5-4H4V9ZM16 8a6 6 0 0 1 0 8M19 5a10 10 0 0 1 0 14"/>'
  };
  const icon = (name, cls = '') => `<svg class="icon ${cls}" aria-hidden="true"><use href="#i-${paths[name] ? name : 'info'}"></use>"/></svg>`;
  const sprite = () => `<svg xmlns="http://www.w3.org/2000/svg" style="position:absolute;width:0;height:0;overflow:hidden" aria-hidden="true"><defs>${Object.entries(paths).map(([id, p]) => `<symbol id="i-${id}" viewBox="0 0 24 24">${p}</symbol>`).join('')}</defs></svg>`;
  const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const fmt = value => Math.round(+value || 0).toLocaleString('ru-RU');
  const signed = value => `${value > 0 ? '+' : ''}${fmt(value)}`;
  const resourceNames = { credits: 'Кредиты', alloy: 'Сплав', fuel: 'Топливо', research: 'Исследования', reputation: 'Репутация' };
  const resourceIcons = { credits: 'credit', alloy: 'alloy', fuel: 'fuel', research: 'research', reputation: 'rep' };
  const resourceColors = { credits: 'mint', alloy: 'amber', fuel: 'blue', research: 'blue', reputation: 'violet' };
  const reward = r => Object.entries(r || {}).filter(([, v]) => v > 0).map(([k, v]) => `<span title="${resourceNames[k]}">${icon(resourceIcons[k])}${fmt(v)}${k === 'credits' ? ' ₡' : ''}</span>`).join('');
  const cost = (c, resources) => Object.entries(c || {}).filter(([, v]) => v > 0).map(([k, v]) => `<span class="${resources && resources[k] < v ? 'short' : ''}" title="${resourceNames[k]}">${icon(resourceIcons[k])}${fmt(v)}${k === 'credits' ? ' ₡' : ''}</span>`).join('');
  const progress = (value, max, cls = '', id = '') => `<div class="progress ${cls}"><i ${id ? `data-progress="${id}"` : ''} style="width:${Math.max(0, Math.min(100, (value / (max || 1)) * 100))}%"></i></div>`;
  const statBars = stats => `<div class="stat-grid">${Object.entries(window.STData.stats).map(([key, label]) => `<div><div class="stat-label"><span>${label}</span><b>${stats[key] || 0}</b></div>${progress(stats[key] || 0, 120)}</div>`).join('')}</div>`;
  const status = s => ({ idle: 'Готов', mission: 'В миссии', repair: 'Ремонт', refit: 'Модернизация', training: 'Обучение', rest: 'Отдых' }[s] || s);
  const initials = name => String(name).split(' ').map(x => x[0]).slice(0, 2).join('');
  function shipArt(preset, compact = false) {
    const color = window.STData.presets[preset]?.color || '#99eed5';
    const shapes = {
      science:'<path d="M150 18 162 62 158 112 150 126 142 112 138 62Z"/><path d="M138 66 92 52 88 92 140 96M162 66 208 52 212 92 160 96"/><path d="M96 58v28M108 60v30M192 60v30M204 58v28M150 30v80M142 70h16"/><circle cx="150" cy="55" r="7"/><path d="M145 126v12M155 126v12"/>',
      cargo:'<path d="M150 16 166 40 166 116 150 130 134 116 134 40Z"/><rect x="112" y="42" width="20" height="66" rx="3"/><rect x="168" y="42" width="20" height="66" rx="3"/><path d="M132 55h-20M132 95h-20M168 55h20M168 95h20M134 60h32M134 80h32M134 100h32M140 130v10M150 130v14M160 130v10"/><circle cx="150" cy="38" r="6"/>',
      interceptor:'<path d="M150 12 160 66 218 116 166 102 150 126 134 102 82 116 140 66Z"/><path d="M150 28v84M140 70 104 108M160 70l36 38M143 126v12M157 126v12"/><path d="m150 48 6 22h-12Z"/><path d="M112 92v22M188 92v22"/>',
      military:'<path d="M150 14 172 42 176 108 162 128 138 128 124 108 128 42Z"/><path d="M128 52 96 66 92 116 124 104M172 52 204 66 208 116 176 104M128 70h44M126 90h48M138 128v12M150 128v16M162 128v12"/><rect x="104" y="72" width="12" height="30" rx="2"/><rect x="184" y="72" width="12" height="30" rx="2"/><circle cx="150" cy="55" r="8"/><circle cx="150" cy="100" r="6"/>',
      alien:'<path d="M150 16C176 40 168 62 186 78c18 16 30 20 34 42-30-8-44-22-58-16-8 4-6 20-12 28-6-8-4-24-12-28-14-6-28 8-58 16 4-22 16-26 34-42 18-16 10-38 36-62Z"/><path d="M150 34c-12 30-10 54 0 82 10-28 12-52 0-82ZM120 88l-24 22M180 88l24 22"/><ellipse cx="150" cy="66" rx="7" ry="13"/>',
      raider:'<path d="m150 16 14 48 52 58-50-18-16 24-16-24-50 18 52-58Z"/><path d="m136 64-28 16-14 38 40-14M164 64l28 16 14 38-40-14M150 34v78M142 128v12M158 128v12"/><path d="m150 50 7 20h-14ZM112 86v24M188 86v24"/>'
    };
    return `<svg class="ship-art ${compact ? 'compact' : ''}" viewBox="0 0 300 150" aria-hidden="true" style="color:${color}"><g fill="${color}12" stroke="currentColor" stroke-width="1.4" stroke-linejoin="round">${shapes[preset] || shapes.science}</g><g stroke="${color}" opacity=".35" stroke-width=".7"><path d="M40 75h35M225 75h35M150 2v8M150 140v8"/></g></svg>`;
  }
  function stationArt() {
    return `<svg class="station-art" viewBox="0 0 400 300" aria-hidden="true"><g fill="none" stroke="currentColor" stroke-width="1.2"><ellipse cx="210" cy="150" rx="120" ry="48" transform="rotate(-24 210 150)"/><ellipse cx="210" cy="150" rx="92" ry="36" transform="rotate(-24 210 150)"/><path d="M120 190 300 110M170 100l80 100M210 60v180"/><rect x="196" y="128" width="28" height="44" rx="5" fill="#163044"/><rect x="201" y="80" width="18" height="48" rx="3"/><rect x="201" y="172" width="18" height="48" rx="3"/><g fill="#102a3d"><path d="m90 150 60-26 12 26-60 26ZM258 150l60-26 12 26-60 26Z"/><path d="m96 154 60-26M102 166l60-26M112 140l12 26M128 133l12 26M264 154l60-26M270 166l60-26M280 140l12 26M296 133l12 26"/></g><circle cx="210" cy="150" r="12" fill="#99eed51a"/><path d="M210 60v-20M200 40h20M210 240v20"/><circle cx="210" cy="36" r="3" fill="#99eed5"/><circle cx="210" cy="264" r="3" fill="#efb575"/></g></svg>`;
  }
  let chartSerial = 0;
  function lineChart(values, color = '#99eed5', height = 120) {
    const gradientId = 'chartFill-' + (++chartSerial);
    const w = 400, h = height, pad = 8, max = Math.max(1, ...values), min = Math.min(0, ...values);
    const pts = values.map((v, i) => [pad + i * (w - pad * 2) / Math.max(1, values.length - 1), h - pad - (v - min) / (max - min || 1) * (h - pad * 2)]);
    const line = pts.map((p, i) => `${i ? 'L' : 'M'}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(' ');
    const area = `${line} L${pts[pts.length - 1]?.[0] || pad},${h} L${pad},${h} Z`;
    return `<svg class="chart" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none" aria-hidden="true"><defs><linearGradient id="${gradientId}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${color}" stop-opacity=".22"/><stop offset="1" stop-color="${color}" stop-opacity="0"/></linearGradient></defs>${[.25, .5, .75].map(f => `<line x1="0" x2="${w}" y1="${h * f}" y2="${h * f}" stroke="#ffffff0d"/>`).join('')}<path d="${area}" fill="url(#${gradientId})"/><path d="${line}" fill="none" stroke="${color}" stroke-width="2" vector-effect="non-scaling-stroke"/></svg>`;
  }
  return { icon, sprite, esc, fmt, signed, resourceNames, resourceIcons, resourceColors, reward, cost, progress, statBars, status, initials, shipArt, stationArt, lineChart };
})();

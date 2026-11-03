/* Application shell: navigation, lifecycle, modals, builder bridge and input. */
(() => {
  'use strict';
  const E = window.STEngine, V = window.STViews, U = window.STUI, D = window.STData;
  const $ = id => document.getElementById(id);
  const navItems = [
    ['overview', 'Обзор', 'overview'], ['map', 'Орбитальная карта', 'orbit'], ['contracts', 'Контракты', 'contracts'], ['fleet', 'Флот', 'fleet'], ['shipyard', 'Верфь', 'shipyard'], ['station', 'Станция', 'station'], ['crew', 'Экипаж', 'crew'], ['research', 'Исследования', 'research'], ['market', 'Рынок', 'market'], ['finance', 'Финансы', 'finance'], ['reputation', 'Репутация', 'reputation']
  ];
  let currentView = 'overview', modal = null, previousFocus = null, builderContext = null, lastTick = performance.now(), audio = null, renderQueued = false, lastView = null, lastSignature = '';
  const icon = U.icon, esc = U.esc;
  function toast(message, kind = 'info', force = false) {
    if (!force && E.state.settings.notifications === false) return;
    const el = document.createElement('div'); el.className = `toast ${kind}`; el.textContent = message; $('toasts').appendChild(el);
    while ($('toasts').children.length > 4) $('toasts').firstChild.remove();
    setTimeout(() => el.remove(), 4200);
    if (E.state.settings.sound && force) beep(kind);
  }
  function beep(kind) {
    try {
      audio = audio || new (window.AudioContext || window.webkitAudioContext)();
      const osc = audio.createOscillator(), gain = audio.createGain();
      osc.type = 'sine'; osc.frequency.value = kind === 'bad' ? 220 : kind === 'good' ? 660 : 440;
      gain.gain.setValueAtTime(.0001, audio.currentTime); gain.gain.exponentialRampToValueAtTime(.06, audio.currentTime + .02); gain.gain.exponentialRampToValueAtTime(.0001, audio.currentTime + .25);
      osc.connect(gain); gain.connect(audio.destination); osc.start(); osc.stop(audio.currentTime + .26);
    } catch (e) { /* Audio is optional and may be blocked by browser policy. */ }
  }
  function resultToast(result) { if (result?.message) toast(result.message, result.ok ? 'good' : 'bad', true); return result; }
  function download(name, content, type) { const blob = new Blob([content], { type }); const url = URL.createObjectURL(blob); const a = document.createElement('a'); a.href = url; a.download = name; document.body.appendChild(a); a.click(); a.remove(); setTimeout(() => URL.revokeObjectURL(url), 1500); }
  function navigate(view) {
    if (!navItems.some(([id]) => id === view)) view = 'overview';
    currentView = view; V.ui.view = view;
    if (location.hash !== '#' + view) history.replaceState(null, '', '#' + view);
    closeModal(); closeNav(); render(); window.scrollTo({ top: 0, behavior: 'instant' });
  }
  function closeNav() { $('sidebar').classList.remove('open'); $('navScrim').classList.remove('open'); $('menuButton').setAttribute('aria-expanded', 'false'); }
  function patchHTML(el, html) {
    const target = document.createElement(el.tagName);
    target.innerHTML = html;
    window.morphdom(el, target, {
      childrenOnly: true,
      onBeforeElUpdated(from, to) {
        if (from.isEqualNode(to)) return false;
        const tag = from.tagName;
        if ((tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') && (from === document.activeElement || from.hasAttribute('data-preserve'))) {
          if (tag === 'SELECT') to.value = from.value;
          else { to.value = from.value; if (from.type === 'checkbox' || from.type === 'radio') to.checked = from.checked; }
        }
        if (from.classList && from.classList.contains('view-enter') && to.classList && to.classList.contains('view-body')) to.classList.add('view-enter');
        return true;
      }
    });
  }
  function renderNav() {
    const counts = { contracts: E.state.contracts.length, fleet: E.state.ships.length, crew: E.state.crew.length, research: E.state.research ? '●' : '' };
    patchHTML($('nav'), navItems.map(([id, label, ic]) => `<button class="nav-btn ${currentView === id ? 'active' : ''}" data-view="${id}" ${currentView === id ? 'aria-current="page"' : ''} title="${label}">${icon(ic)}<span>${label}</span>${counts[id] ? `<span class="nav-count">${counts[id]}</span>` : ''}</button>`).join(''));
  }
  function renderResources() {
    if (!$('res-credits')) {
      $('resources').innerHTML = ['credits', 'alloy', 'fuel', 'research', 'reputation'].map(k => `<div class="resource" title="${U.resourceNames[k]}"><span class="${U.resourceColors[k]}">${icon(U.resourceIcons[k])}</span><div><div class="resource-value" id="res-${k}">${U.fmt(E.state.resources[k])}${k === 'credits' ? ' ₡' : ''}</div><div class="resource-label">${U.resourceNames[k].toUpperCase()}</div></div></div>`).join('');
    }
    updateLive();
    document.querySelectorAll('.speed-btn').forEach(b => { const active = +b.dataset.speed === E.state.speed; b.classList.toggle('active', active); b.setAttribute('aria-pressed', String(active)); });
    $('saveNote').textContent = 'Автосохранение ' + (E.state.settings.autoSave ? 'включено' : 'выключено');
  }
  function stateSignature() {
    const s = E.state;
    return JSON.stringify({
      view: currentView, ui: V.ui, day: E.day(), speed: s.speed, resources: s.resources, modules: s.modules, techs: s.techs,
      research: s.research ? s.research.key : null,
      ships: s.ships.map(x => [x.id, x.status, x.condition, x.crew, x.missions, x.earned, x.value, x.name, x.preset]),
      crew: s.crew.map(c => [c.id, c.status, c.skill, c.morale, c.shipId, c.name]),
      candidates: s.candidates.map(c => c.id),
      contracts: s.contracts.map(c => c.id), missions: s.missions.map(m => m.id),
      build: s.buildQueue.map(j => [j.id, j.waiting]), repair: s.repairQueue.map(j => j.id), moduleQueue: s.moduleQueue.map(j => j.id),
      events: s.events.map(e => e.key), claimed: s.claimed, factions: s.factions, metrics: s.metrics,
      ledger: s.ledger.length, daily: s.daily.map(d => [d.day, d.income, d.expenses, d.missions]),
      market: s.market, settings: s.settings, log: s.log.length
    });
  }
  function render() {
    renderQueued = false;
    const active = document.activeElement, focusId = active?.id, selection = active && 'selectionStart' in active ? [active.selectionStart, active.selectionEnd] : null;
    renderNav(); renderResources();
    const html = V.render(currentView) + `<footer class="footer"><span>SPACETYCOON · РАСШИРЕННЫЙ ПРОТОТИП 0.2.1</span><span id="footerSave">СТАНЦИЯ «АВРОРА» · ДЕНЬ ${E.day()}</span></footer>`;
    patchHTML($('main'), html);
    if (currentView !== lastView) {
      const body = $('main').querySelector('.view-body');
      if (body) { body.classList.add('view-enter'); setTimeout(() => body.classList.remove('view-enter'), 300); }
      lastView = currentView;
    }
    if (focusId && $(focusId) && !modal && document.activeElement !== $(focusId)) { $(focusId).focus({ preventScroll: true }); if (selection && $(focusId).setSelectionRange) try { $(focusId).setSelectionRange(...selection); } catch (e) {} }
    lastSignature = stateSignature();
  }
  function queueRender() { if (!renderQueued) { renderQueued = true; requestAnimationFrame(render); } }
  function liveMap() {
    const map = {};
    for (const m of E.state.missions) map['mission:' + m.id] = { remaining: m.remaining, duration: m.duration };
    for (const j of E.state.buildQueue) map['build:' + j.id] = { remaining: j.remaining, duration: j.duration, waiting: j.waiting };
    for (const j of E.state.repairQueue) map['repair:' + j.id] = { remaining: j.remaining, duration: j.duration };
    for (const j of E.state.moduleQueue) map['module:' + j.id] = { remaining: j.remaining, duration: j.duration };
    for (const c of E.state.crew) if (['training', 'rest'].includes(c.status)) map['crew:' + c.id] = { remaining: c.remaining, duration: c.status === 'training' ? 35 : 30 };
    for (const e of E.state.events) map['event:' + e.key] = { remaining: e.remaining, duration: D.events[e.key].duration };
    if (E.state.research) map.research = { remaining: E.state.research.remaining, duration: E.state.research.duration };
    return map;
  }
  function updateLive() {
    for (const k of ['credits', 'alloy', 'fuel', 'research', 'reputation']) { const el = $('res-' + k); if (el) el.textContent = U.fmt(E.state.resources[k]) + (k === 'credits' ? ' ₡' : ''); }
    $('clock').textContent = E.clock(); $('clockDay').textContent = `ДЕНЬ ${E.day()} · ${E.state.speed === 0 ? 'ПАУЗА' : E.state.speed + '×'}`;
    const map = liveMap();
    document.querySelectorAll('[data-time]').forEach(el => { const item = map[el.dataset.time]; if (item) el.textContent = item.waiting ? 'Ждёт ангар' : E.duration(item.remaining); });
    document.querySelectorAll('[data-progress]').forEach(el => { const item = map[el.dataset.progress]; if (item) el.style.width = Math.max(0, Math.min(100, (item.duration - item.remaining) / item.duration * 100)) + '%'; });
  }
  function openModal(html, options = {}) {
    closeModal(false);
    previousFocus = document.activeElement;
    const backdrop = document.createElement('div'); backdrop.className = 'modal-backdrop' + (options.builder ? ' builder-backdrop' : ''); backdrop.id = 'modalBackdrop';
    backdrop.innerHTML = options.builder ? html : `<div class="modal ${options.wide ? 'wide' : ''}" role="dialog" aria-modal="true" aria-label="${esc(options.title || 'Панель управления')}"><button class="icon-btn" data-action="close-modal" aria-label="Закрыть" style="float:right;margin-left:10px">${icon('close')}</button>${html}</div>`;
    document.body.appendChild(backdrop); modal = backdrop; document.body.style.overflow = 'hidden';
    backdrop.addEventListener('click', e => { if (e.target === backdrop && !options.builder) closeModal(); });
    const focusable = backdrop.querySelector('button:not([disabled]),input,select,[tabindex="0"]'); if (focusable) focusable.focus({ preventScroll: true });
  }
  function closeModal(restore = true) {
    if (!modal) return;
    modal.remove(); modal = null; builderContext = null; document.body.style.overflow = '';
    window.STBackground?.setPaused(false);
    if (restore && previousFocus?.isConnected) previousFocus.focus({ preventScroll: true });
    previousFocus = null;
  }
  function openBuilder(mode = 'new', shipId = null) {
    const ship = shipId ? E.state.ships.find(s => s.id === shipId) : null;
    if (mode === 'refit' && (!ship || ship.status !== 'idle')) return toast('Модернизация доступна только свободному кораблю.', 'bad', true);
    openModal(`<div class="modal builder-modal" role="dialog" aria-modal="true" aria-label="3D-конструктор кораблей"><div class="builder-head"><div><h2>${mode === 'refit' ? 'Модернизация: ' + esc(ship.name) : 'Конструктор кораблей'}</h2><p>${mode === 'refit' ? 'Измените проект и отправьте на верфь. Стоимость модернизации — 35% от полной постройки.' : 'Настройте корпус и системы, затем нажмите «Сохранить в ангар» на панели конструктора.'}</p></div><button class="icon-btn" data-action="close-modal" aria-label="Закрыть конструктор">${icon('close')}</button></div><div class="builder-loading" id="builderLoading">Загрузка орбитальной верфи…</div><iframe class="builder-frame" id="builderFrame" src="builder.html?embed=1" title="Процедурный 3D-конструктор кораблей" allow="fullscreen"></iframe></div>`, { builder: true, title: 'Конструктор кораблей' });
    builderContext = { mode, shipId, ready: false };
    window.STBackground?.setPaused(true);
  }
  function validDesign(design) { return design && typeof design === 'object' && D.presets[design.preset] && design.params && typeof design.params === 'object' && typeof design.name === 'string'; }
  window.addEventListener('message', event => {
    const frame = $('builderFrame');
    if (!frame || event.source !== frame.contentWindow || event.origin !== location.origin) return;
    const data = event.data;
    if (!data || data.version !== 1) return;
    if (data.type === 'spacetycoon:builder-ready') {
      if ($('builderLoading')) $('builderLoading').hidden = true;
      if (builderContext?.mode === 'refit') { const ship = E.state.ships.find(s => s.id === builderContext.shipId); if (ship) frame.contentWindow.postMessage({ type: 'spacetycoon:load-design', version: 1, design: ship.design }, location.origin === 'null' ? '*' : location.origin); }
      builderContext && (builderContext.ready = true);
    }
    if (data.type === 'spacetycoon:ship-design' && builderContext) {
      if (!validDesign(data.design)) return toast('Конструктор отправил некорректный проект.', 'bad', true);
      const result = builderContext.mode === 'refit' ? E.queueRefit(builderContext.shipId, data.design) : E.queueBuild(data.design, false, data.design.name);
      resultToast(result); if (result.ok) { closeModal(); navigate('shipyard'); }
    }
  });
  function confirmModal(title, text, action, id, label = 'Подтвердить') {
    openModal(`<div class="modal-head"><div><div class="eyebrow">ПОДТВЕРЖДЕНИЕ</div><h2 class="modal-title">${title}</h2></div></div><p class="hint">${text}</p><div class="modal-actions"><button class="btn" data-action="close-modal">Отмена</button><button class="btn btn-danger" data-action="${action}" data-id="${id || ''}">${label}</button></div>`, { title });
  }
  function exportLedger() {
    const rows = [['День', 'Операция', 'Категория', 'Кредиты', 'Сплав', 'Топливо', 'Исследования', 'Репутация'], ...E.state.ledger.map(l => [l.day, l.label, l.category, l.delta.credits || 0, l.delta.alloy || 0, l.delta.fuel || 0, l.delta.research || 0, l.delta.reputation || 0])];
    const csv = '\uFEFF' + rows.map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(';')).join('\r\n');
    download('spacetycoon-ledger.csv', csv, 'text/csv;charset=utf-8'); toast('Финансовый журнал экспортирован.', 'good', true);
  }
  function handleAction(button) {
    const action = button.dataset.action, id = button.dataset.id;
    switch (action) {
      case 'close-modal': closeModal(); break;
      case 'goto': navigate(button.dataset.view); break;
      case 'save': E.save(true); render(); break;
      case 'settings': openModal(V.modalSettings(), { title: 'Настройки', wide: true }); break;
      case 'help': openModal(V.modalHelp(), { title: 'Руководство', wide: true }); break;
      case 'open-builder': openBuilder('new'); break;
      case 'refit': openBuilder('refit', id); break;
      case 'quick-build': { const p = D.presets[id]; if (p) resultToast(E.queueBuild({ preset: id, params: p.params, quick: true }, true)); break; }
      case 'cancel-job': resultToast(E.cancelJob(id)); break;
      case 'repair': resultToast(E.queueRepair(id)); if (modal) closeModal(); break;
      case 'open-ship': openModal(V.modalShip(id), { title: 'Корабль', wide: true }); break;
      case 'rename': { const ship = E.state.ships.find(s => s.id === id); if (ship) openModal(`<div class="modal-head"><h2 class="modal-title">Переименовать корабль</h2></div><div class="field"><label for="renameInput">Новое название</label><input type="text" id="renameInput" maxlength="32" value="${esc(ship.name)}"></div><div class="modal-actions"><button class="btn" data-action="close-modal">Отмена</button><button class="btn btn-primary" data-action="submit-rename" data-id="${id}">Сохранить</button></div>`, { title: 'Переименование' }); setTimeout(() => $('renameInput')?.select(), 30); break; }
      case 'submit-rename': resultToast(E.renameShip(id, $('renameInput')?.value || '')); closeModal(); break;
      case 'sell': { const ship = E.state.ships.find(s => s.id === id); if (ship) confirmModal('Продать корабль?', `«${esc(ship.name)}» будет продан за ${U.fmt(ship.value * .35 * ship.condition / 100)} ₡. Экипаж вернётся на станцию.`, 'confirm-sell', id, 'Продать'); break; }
      case 'confirm-sell': resultToast(E.sellShip(id)); closeModal(); break;
      case 'assign-contract': openModal(V.modalAssign(id), { title: 'Назначение миссии', wide: true }); break;
      case 'launch': resultToast(E.assignMission(id, button.dataset.ship)); closeModal(); break;
      case 'refresh-contracts': resultToast(E.refreshContracts()); break;
      case 'filter-contracts': V.ui.contractType = id; render(); break;
      case 'filter-fleet': V.ui.fleetFilter = id; render(); break;
      case 'ledger-filter': V.ui.ledger = id; render(); break;
      case 'select-sector': V.ui.sector = id; render(); break;
      case 'sector-contracts': V.ui.contractSector = id; V.ui.contractType = 'all'; navigate('contracts'); break;
      case 'upgrade-module': resultToast(E.upgradeModule(id)); break;
      case 'start-research': resultToast(E.startResearch(id)); break;
      case 'cancel-research': resultToast(E.cancelResearch()); break;
      case 'hire': resultToast(E.hireCrew(id)); break;
      case 'assign-crew': openModal(V.modalCrew(id), { title: 'Назначение экипажа' }); break;
      case 'crew-to-ship': resultToast(E.assignCrew(id, button.dataset.ship || null)); closeModal(); break;
      case 'train': resultToast(E.trainCrew(id)); break;
      case 'rest': resultToast(E.restCrew(id)); break;
      case 'dismiss': confirmModal('Расторгнуть контракт?', 'Специалист покинет станцию. Его можно будет нанять снова через биржу.', 'confirm-dismiss', id, 'Уволить'); break;
      case 'confirm-dismiss': resultToast(E.dismissCrew(id)); closeModal(); break;
      case 'trade': { const qty = $('qty-' + id)?.value || 1; resultToast(E.trade(id, button.dataset.side, qty)); break; }
      case 'claim': resultToast(E.claimAchievement(id)); break;
      case 'toggle-setting': { const key = id; E.setSetting(key, !E.state.settings[key]); if (key === 'background') window.STBackground?.setQuality(E.state.settings.background); if (modal && button.classList.contains('switch')) button.setAttribute('aria-checked', String(E.state.settings[key])); else render(); break; }
      case 'export': download('spacetycoon-save.json', E.exportSave(), 'application/json'); toast('Сохранение экспортировано.', 'good', true); break;
      case 'import': $('importFile').click(); break;
      case 'export-ledger': exportLedger(); break;
      case 'reset': confirmModal('Начать новую игру?', 'Текущий прогресс будет удалён. Рекомендуем сначала экспортировать сохранение.', 'confirm-reset', '', 'Сбросить прогресс'); break;
      case 'confirm-reset': E.reset(); window.STBackground?.setQuality(E.state.settings.background); closeModal(); navigate('overview'); toast('Новая игра начата.', 'good', true); break;
    }
  }
  document.addEventListener('click', event => {
    const speed = event.target.closest('[data-speed]'); if (speed) { E.setSpeed(+speed.dataset.speed); renderResources(); return; }
    const nav = event.target.closest('[data-view]'); if (nav && nav.classList.contains('nav-btn')) { navigate(nav.dataset.view); return; }
    const button = event.target.closest('[data-action]'); if (button && !button.disabled) handleAction(button);
  });
  document.addEventListener('change', event => {
    if (event.target.id === 'contractSector') { V.ui.contractSector = event.target.value; render(); }
    if (event.target.id === 'backgroundQuality') { E.setSetting('background', event.target.value); window.STBackground?.setQuality(event.target.value); }
  });
  document.addEventListener('input', event => { if (event.target.id === 'fleetSearch') { V.ui.fleetSearch = event.target.value; queueRender(); } });
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape') { if (modal) closeModal(); else closeNav(); return; }
    if (modal && event.key === 'Tab') {
      const items = [...modal.querySelectorAll('button:not([disabled]),input:not([disabled]),select:not([disabled]),[tabindex="0"]')].filter(el => el.offsetParent !== null);
      if (!items.length) return;
      const first = items[0], last = items[items.length - 1];
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
      return;
    }
    if (modal || /INPUT|SELECT|TEXTAREA/.test(event.target.tagName)) return;
    if (event.code === 'Space') { event.preventDefault(); E.setSpeed(E.state.speed === 0 ? 1 : 0); renderResources(); }
    if (event.key === '?' || event.key.toLowerCase() === 'h') openModal(V.modalHelp(), { title: 'Руководство', wide: true });
  });
  $('menuButton').addEventListener('click', () => { const open = !$('sidebar').classList.contains('open'); $('sidebar').classList.toggle('open', open); $('navScrim').classList.toggle('open', open); $('menuButton').setAttribute('aria-expanded', String(open)); });
  $('navScrim').addEventListener('click', closeNav);
  $('importFile').addEventListener('change', event => { const file = event.target.files[0]; if (!file) return; const reader = new FileReader(); reader.onload = () => { const result = resultToast(E.importSave(String(reader.result))); if (result.ok) { window.STBackground?.setQuality(E.state.settings.background); closeModal(); render(); } }; reader.readAsText(file); event.target.value = ''; });
  window.addEventListener('hashchange', () => { const view = location.hash.slice(1); if (navItems.some(([id]) => id === view)) { currentView = view; V.ui.view = view; render(); } });
  window.addEventListener('beforeunload', () => { if (E.state.settings.autoSave) E.save(); });
  document.addEventListener('visibilitychange', () => { if (document.hidden && E.state.settings.autoSave) E.save(); lastTick = performance.now(); });

  $('sprite').innerHTML = U.sprite();
  E.init();
  E.subscribe(queueRender);
  E.onNotify((message, kind) => toast(message, kind));
  window.STBackground?.setQuality(E.state.settings.background);
  const initial = location.hash.slice(1); if (navItems.some(([id]) => id === initial)) { currentView = initial; V.ui.view = initial; }
  render();
  setInterval(() => {
    const now = performance.now(), dt = Math.min(2, (now - lastTick) / 1000); lastTick = now;
    if (E.state.speed > 0 && !document.hidden) E.advance(dt * E.state.speed);
    updateLive();
    const signature = stateSignature();
    if (signature !== lastSignature) { lastSignature = signature; queueRender(); }
  }, 250);
  setInterval(() => { if (E.state.settings.autoSave) E.save(); }, 15000);
  if (E.offlineSummary) {
    const o = E.offlineSummary;
    openModal(`<div class="modal-head"><div><div class="eyebrow">СМЕНА ЗАВЕРШЕНА</div><h2 class="modal-title">С возвращением, директор</h2><p class="modal-sub">Оффлайн-прогресс: ${E.duration(o.elapsed)} (максимум 8 часов).</p></div></div><div class="offline-grid"><div><b>${U.signed(o.credits)}</b><span>кредиты</span></div><div><b>${U.signed(o.alloy)}</b><span>сплав</span></div><div><b>${U.signed(o.research)}</b><span>исследования</span></div></div><p class="hint">Миссии, очереди, производство и содержание обработаны за время отсутствия.</p><div class="modal-actions"><button class="btn btn-primary" data-action="close-modal">Продолжить</button></div>`, { title: 'Оффлайн-прогресс' });
    E.clearOffline();
  }
  window.SpaceTycoon = Object.freeze({ version: '0.2.1', get state() { return E.clone(E.state); }, engine: E, views: V, navigate, save: () => E.save(true), get background() { return window.STBackground?.diagnostics; } });
})();

/* SpaceTycoon simulation and economy. No rendering dependencies. */
window.STEngine = (() => {
  'use strict';
  const D = window.STData;
  const SAVE_KEY = 'spacetycoon-save-v2';
  const LEGACY_KEY = 'spacetycoon-wp-v1';
  const DAY = 144; // 1 real second = 10 orbital minutes at 1x.
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const round = Math.round;
  let state, serial = 0, listener = () => {}, notifier = () => {}, silent = false, offlineSummary = null;
  const uid = prefix => `${prefix}_${Date.now().toString(36)}_${++serial}`;
  const clone = value => JSON.parse(JSON.stringify(value));
  function random() { state.rng = (Math.imul(state.rng, 1664525) + 1013904223) >>> 0; return state.rng / 4294967296; }
  const pick = list => list[Math.floor(random() * list.length)];
  const day = () => Math.floor(state.time / DAY) + 1;
  const clock = () => { const minutes = Math.floor(state.time * 10) % 1440; return `${String(Math.floor(minutes / 60)).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}`; };
  const duration = seconds => { const s = Math.max(0, Math.ceil(seconds)); return s >= 60 ? `${Math.floor(s / 60)}м ${String(s % 60).padStart(2, '0')}с` : `${s}с`; };
  const changed = () => { if (!silent) listener(); };
  function notify(message, kind = 'info') { if (!silent) notifier(message, kind); }
  function log(text, kind = 'info') { state.log.unshift({ time: state.time, text, kind }); state.log = state.log.slice(0, 100); }

  function deriveStats(design) {
    const preset = D.presets[design.preset] || D.presets.science;
    const p = design.params || {};
    const s = { ...preset.base };
    const length = +p.length || 26, width = +p.width || 6, height = +p.height || 4, volume = length * width * height;
    s.cargo += volume * .018 + (+p.span || 20) * .25;
    s.combat += (+p.turrets || 0) * 5 + (+p.nozzles || 2) * 1.5;
    s.science += (p.scanners ? 14 : 0) + (p.antennas ? 7 : 0) + (+p.greebles || 0) * .07;
    s.speed += (+p.nozzles || 2) * 4 + (+p.glow || 1) * 3 - length * .18 - width * .25;
    s.durability += (+p.segments || 5) * 2.5 + (+p.metalness || .5) * 14 + width * height * .12;
    for (const key of Object.keys(s)) s[key] = clamp(round(s[key]), 5, 120);
    return s;
  }
  function techEffect(key) { return state.techs.reduce((sum, id) => sum + (D.techs[id]?.effect[key] || 0), 0); }
  function activeEffect(key) { return state.events.reduce((sum, e) => sum + (D.events[e.key]?.effect[key] || 0), 0); }
  function factionLevel(id) { return Math.floor((state.factions[id] || 0) / 25); }
  function factionPerk(id) { return Math.min(.2, factionLevel(id) * .04); }
  function energy() {
    let supply = 20 + state.modules.solar * 18, demand = 0;
    for (const [key, level] of Object.entries(state.modules)) demand += (D.modules[key]?.energy || 0) * level;
    const efficiency = demand ? Math.min(1, supply / demand) : 1;
    return { supply, demand, efficiency: clamp(efficiency, .25, 1) };
  }
  function productionRates() {
    const e = energy().efficiency * (1 + techEffect('production') + activeEffect('production'));
    return {
      credits: round((state.modules.trade * 35 + state.modules.yard * 5 + state.resources.reputation * .4) * Math.max(.1, e) * (1 + techEffect('income'))),
      alloy: round(state.modules.refinery * 3 * Math.max(0, e)),
      fuel: round(state.modules.fuel * 3 * Math.max(0, e)),
      research: round(state.modules.lab * 2 * Math.max(0, e) * (1 + factionPerk('helios')))
    };
  }
  const capacity = () => 2 + state.modules.hangar * 2;
  const crewCapacity = () => 6 + state.modules.habitat * 4;
  const queueSlots = () => 1 + Math.floor(state.modules.yard / 2);
  const maxTier = () => state.modules.yard;
  function unlockedSectors() {
    return Object.entries(D.sectors).filter(([id, s]) => {
      const u = s.unlock || {};
      return (!u.yard || state.modules.yard >= u.yard) && (!u.reputation || state.resources.reputation >= u.reputation) && (!u.tech || state.techs.includes(u.tech));
    }).map(([id]) => id);
  }
  function shipStats(ship) {
    const s = { ...ship.stats };
    for (const key of Object.keys(s)) s[key] = round(s[key] * (1 + techEffect(key)));
    for (const id of ship.crew || []) {
      const crew = state.crew.find(c => c.id === id);
      if (!crew) continue;
      const role = D.roles[crew.role];
      const bonus = crew.skill * .12 * (crew.morale / 100);
      s[role.stat] = round(s[role.stat] + bonus);
      if (crew.role === 'captain') s.speed = round(s.speed + bonus * .4);
      if (crew.role === 'pilot') s.speed = round(s.speed + bonus * .6);
    }
    for (const key of Object.keys(s)) s[key] = clamp(s[key], 1, 160);
    return s;
  }
  function crewFor(ship) { return (ship.crew || []).map(id => state.crew.find(c => c.id === id)).filter(Boolean); }
  function chance(contract, ship) {
    if (!ship) return 0;
    const s = shipStats(ship);
    const captain = crewFor(ship).find(c => c.role === 'captain');
    const crewBonus = captain ? captain.skill * .0008 * captain.morale / 100 : -.08;
    return clamp(.55 + (s[contract.stat] - contract.req) * .009 + (s.speed - contract.speedReq) * .004 + state.modules.control * .04 + techEffect('chance') + activeEffect('chance') + crewBonus - contract.risk + (ship.condition - 100) * .002, .15, .95);
  }
  function fuelNeed(contract, ship) {
    const volume = ship ? ((+ship.design.params?.length || 26) * (+ship.design.params?.width || 6)) / 160 : 1;
    return Math.max(2, round(contract.fuel * (1 + volume * .15) * (1 + techEffect('fuelUse'))));
  }
  function missionDuration(contract) { return Math.max(15, round(contract.duration * (1 - state.modules.relay * .04 + techEffect('missionTime')) * (1 - factionPerk('frontier')))); }
  function canAfford(cost) { return Object.entries(cost || {}).every(([key, value]) => (state.resources[key] || 0) >= value); }
  function currentDaily() {
    let entry = state.daily[state.daily.length - 1];
    if (!entry || entry.day !== day()) { entry = { day: day(), income: 0, expenses: 0, missions: 0, production: 0 }; state.daily.push(entry); state.daily = state.daily.slice(-14); }
    return entry;
  }
  function transact(delta, category, label) {
    for (const [key, value] of Object.entries(delta)) state.resources[key] = Math.max(0, (state.resources[key] || 0) + value);
    state.ledger.unshift({ time: state.time, day: day(), category, label, delta: { ...delta } });
    state.ledger = state.ledger.slice(0, 400);
    const d = currentDaily();
    if (delta.credits > 0) d.income += delta.credits;
    if (delta.credits < 0) d.expenses -= delta.credits;
    if (category === 'production') d.production += (delta.alloy || 0) + (delta.fuel || 0) + (delta.research || 0);
    if (delta.credits < 0) state.metrics.spent -= delta.credits;
  }
  function pay(cost, category, label) { if (!canAfford(cost)) return false; transact(Object.fromEntries(Object.entries(cost).map(([k, v]) => [k, -v])), category, label); return true; }
  function buildCost(design, quick) {
    const preset = D.presets[design.preset] || D.presets.science;
    let cost;
    if (quick) cost = { ...preset.cost };
    else {
      const stats = deriveStats(design), p = design.params || {};
      const volume = (+p.length || 26) * (+p.width || 6) * (+p.height || 4);
      const total = Object.values(stats).reduce((a, b) => a + b, 0);
      cost = { credits: round(600 + total * 7 + volume * .03 + (+p.turrets || 0) * 30 + (design.statistics?.triangles || 15000) * .006), alloy: round(20 + volume * .024 + (+p.turrets || 0) * 2), fuel: round(8 + volume * .008) };
    }
    const discount = 1 - state.modules.drydock * .04;
    return Object.fromEntries(Object.entries(cost).map(([k, v]) => [k, round(v * discount)]));
  }
  function buildDuration(design, quick) { const base = quick ? D.presets[design.preset].buildTime : 55 + (design.statistics?.triangles || 15000) / 600; return Math.max(12, round(base / (1 + state.modules.yard * .08 + techEffect('buildSpeed')))); }
  function makeShip(preset, design, name) {
    const d = clone(design || { preset, params: D.presets[preset].params, quick: true });
    d.preset = preset;
    return { id: uid('ship'), name: name || `${D.presets[preset].label}-${round(random() * 90 + 10)}`, preset, design: d, stats: deriveStats(d), condition: 100, status: 'idle', crew: [], missions: 0, earned: 0, value: buildCost(d, !!d.quick).credits, builtDay: day() };
  }
  function makeCrew(role, skill) {
    const name = pick(D.crewNames.filter(n => !state.crew.some(c => c.name === n))) || `Специалист ${state.crew.length + 1}`;
    return { id: uid('crew'), name, role: role || pick(Object.keys(D.roles)), skill: skill || round(30 + random() * 35), morale: 90, salary: round(8 + (skill || 40) * .22), status: 'idle', shipId: null, remaining: 0 };
  }
  function generateContract(forcedType, forcedTier) {
    const unlocked = unlockedSectors();
    const tier = clamp(forcedTier || (1 + Math.floor(random() * maxTier())), 1, 5);
    const sectorId = pick(unlocked.filter(id => D.sectors[id].tier <= tier + 1)) || 'earth';
    const sector = D.sectors[sectorId];
    const type = forcedType || pick(Object.keys(D.contractTypes));
    const def = D.contractTypes[type];
    const req = round(16 + tier * 16 + random() * 12);
    const speedReq = round(8 + tier * 6 + random() * 10);
    const distance = sector.distance;
    const reward = {
      credits: round((250 * tier + req * 4 + random() * 150) * distance * (1 + techEffect('reward'))),
      alloy: type === 'cargo' || type === 'rescue' ? round(7 * tier + random() * 10) : round(random() * 4),
      research: type === 'science' || type === 'survey' ? round(6 * tier + random() * 8) : round(random() * 3),
      reputation: round(1 + tier * 1.5)
    };
    return { id: uid('contract'), type, title: `${pick(def.titles)} · ${sector.short}`, tier, sector: sectorId, faction: def.faction, stat: def.stat, req, speedReq, duration: round((28 + tier * 16 + random() * 25) * distance), risk: +(0.04 + tier * .03 + random() * .04).toFixed(2), fuel: round(4 * distance * tier), reward, expires: state.time + 240 + random() * 240, special: !!forcedType };
  }
  function defaultState() {
    state = {
      version: 2, time: 0, speed: 1, rng: 740291, lastSaved: Date.now(),
      resources: { credits: 4200, alloy: 180, fuel: 100, research: 20, reputation: 0 },
      modules: { yard: 1, hangar: 1, drydock: 1, control: 0, refinery: 1, lab: 1, trade: 1, solar: 1, habitat: 1, fuel: 0, relay: 0 },
      ships: [], crew: [], candidates: [], contracts: [], missions: [], history: [], buildQueue: [], moduleQueue: [], repairQueue: [], research: null, techs: [],
      factions: { terran: 0, lunar: 0, helios: 0, frontier: 0 }, events: [], nextEvent: 150, productionTimer: 0, contractTimer: 0, lastDay: 1,
      ledger: [], daily: [{ day: 1, income: 0, expenses: 0, missions: 0, production: 0 }], log: [], claimed: [],
      metrics: { missions: 0, success: 0, earned: 0, spent: 0, custom: 0, failed: 0 },
      market: { day: 1, traded: { alloy: 0, fuel: 0 } },
      settings: { background: 'high', sound: false, autoSupply: false, autoSave: true, notifications: true },
      onboarded: false
    };
    const starter = makeShip('science', { preset: 'science', params: D.presets.science.params, quick: true }, 'Пионер');
    starter.value = 0;
    state.ships.push(starter);
    const captain = { id: uid('crew'), name: 'София Орлова', role: 'captain', skill: 48, morale: 95, salary: 18, status: 'idle', shipId: starter.id, remaining: 0 };
    state.crew.push(captain); starter.crew.push(captain.id);
    state.candidates = Array.from({ length: 4 }, () => makeCrew());
    state.contracts = Array.from({ length: 8 }, () => generateContract());
    log('Станция «Аврора» введена в эксплуатацию. Добро пожаловать, директор.', 'good');
    return state;
  }

  function queueBuild(design, quick = false, name) {
    const preset = D.presets[design.preset] ? design.preset : 'science';
    if (D.presets[preset].unlock && !state.techs.includes(D.presets[preset].unlock)) return { ok: false, message: 'Сначала изучите технологию для этого класса.' };
    if (state.buildQueue.length >= queueSlots()) return { ok: false, message: 'Все стапели заняты.' };
    if (state.ships.length + state.buildQueue.filter(j => j.type === 'build').length >= capacity()) return { ok: false, message: 'Ангар заполнен с учётом строящихся кораблей. Расширьте ангар.' };
    const cost = buildCost({ ...design, preset }, quick);
    if (!pay(cost, 'construction', 'Постройка корабля')) return { ok: false, message: 'Недостаточно ресурсов для постройки.' };
    const job = { id: uid('job'), type: 'build', name: name || design.name || `${D.presets[preset].label}-${round(random() * 90 + 10)}`, preset, design: { ...clone(design), preset, quick }, cost, duration: buildDuration(design, quick), remaining: buildDuration(design, quick), waiting: false };
    state.buildQueue.push(job); log(`Заложен корабль «${job.name}».`, 'info'); changed(); return { ok: true, message: 'Корабль заложен на верфи.' };
  }
  function cancelJob(id) {
    const job = state.buildQueue.find(j => j.id === id);
    if (!job) return { ok: false, message: 'Заказ не найден.' };
    transact(Object.fromEntries(Object.entries(job.cost).map(([k, v]) => [k, round(v * .7)])), 'refund', `Отмена: ${job.name}`);
    state.buildQueue = state.buildQueue.filter(j => j.id !== id); changed(); return { ok: true, message: 'Заказ отменён. Возвращено 70% затрат.' };
  }
  function repairCost(ship) { const missing = 100 - ship.condition; return { credits: round(missing * Math.max(12, ship.value * .004) * (1 - state.modules.drydock * .06)), alloy: round(missing * .12) }; }
  function queueRepair(id) {
    const ship = state.ships.find(s => s.id === id);
    if (!ship || !['idle', 'repair'].includes(ship.status) || ship.condition >= 100) return { ok: false, message: 'Корабль не требует ремонта.' };
    if (state.repairQueue.length >= Math.max(1, state.modules.drydock)) return { ok: false, message: 'Сухой док занят.' };
    const cost = repairCost(ship);
    if (!pay(cost, 'repair', `Ремонт: ${ship.name}`)) return { ok: false, message: 'Недостаточно ресурсов для ремонта.' };
    const time = Math.max(8, round((100 - ship.condition) * .45 / (1 + state.modules.drydock * .1)));
    ship.status = 'repair'; state.repairQueue.push({ id: uid('repair'), shipId: id, remaining: time, duration: time, cost }); changed(); return { ok: true, message: 'Корабль поставлен в сухой док.' };
  }
  function queueRefit(id, design) {
    const ship = state.ships.find(s => s.id === id);
    if (!ship || ship.status !== 'idle') return { ok: false, message: 'Модернизация доступна только свободному кораблю.' };
    if (state.buildQueue.length >= queueSlots()) return { ok: false, message: 'Все стапели заняты.' };
    const full = buildCost(design, false);
    const cost = Object.fromEntries(Object.entries(full).map(([k, v]) => [k, round(v * .35)]));
    if (!pay(cost, 'refit', `Модернизация: ${ship.name}`)) return { ok: false, message: 'Недостаточно ресурсов для модернизации.' };
    const time = round(buildDuration(design, false) * .6);
    ship.status = 'refit'; state.buildQueue.push({ id: uid('refit'), type: 'refit', shipId: id, name: ship.name, design: clone(design), cost, duration: time, remaining: time }); changed(); return { ok: true, message: 'Модернизация начата.' };
  }
  function sellShip(id) {
    const ship = state.ships.find(s => s.id === id);
    if (!ship || ship.status !== 'idle') return { ok: false, message: 'Нельзя продать занятый корабль.' };
    const value = round(ship.value * .35 * ship.condition / 100);
    for (const crew of crewFor(ship)) { crew.shipId = null; crew.status = 'idle'; }
    transact({ credits: value }, 'sale', `Продажа: ${ship.name}`); state.ships = state.ships.filter(s => s.id !== id); changed(); return { ok: true, message: `Корабль продан за ${value} ₡.` };
  }
  function renameShip(id, name) { const ship = state.ships.find(s => s.id === id); if (!ship) return { ok: false, message: 'Корабль не найден.' }; ship.name = String(name).trim().slice(0, 32) || ship.name; changed(); return { ok: true, message: 'Название обновлено.' }; }

  function assignMission(contractId, shipId) {
    const contract = state.contracts.find(c => c.id === contractId), ship = state.ships.find(s => s.id === shipId);
    if (!contract || !ship) return { ok: false, message: 'Контракт или корабль не найден.' };
    if (ship.status !== 'idle' || ship.condition < 25) return { ok: false, message: 'Корабль не готов к вылету.' };
    const fuel = fuelNeed(contract, ship);
    if (state.resources.fuel < fuel) return { ok: false, message: `Недостаточно топлива: нужно ${fuel}.` };
    transact({ fuel: -fuel }, 'mission', `Топливо: ${contract.title}`);
    const time = missionDuration(contract);
    ship.status = 'mission';
    for (const crew of crewFor(ship)) crew.status = 'mission';
    state.missions.push({ id: uid('mission'), contract: clone(contract), shipId, remaining: time, duration: time, chance: chance(contract, ship), fuel, started: state.time });
    state.contracts = state.contracts.filter(c => c.id !== contractId);
    log(`«${ship.name}» отправлен: ${contract.title}.`, 'info'); changed(); return { ok: true, message: 'Миссия началась.' };
  }
  function resolveMission(mission) {
    const ship = state.ships.find(s => s.id === mission.shipId), c = mission.contract;
    const success = random() < mission.chance;
    if (ship) {
      const engineer = crewFor(ship).find(c => c.role === 'engineer');
      const wear = (success ? 3 + random() * 7 : 15 + random() * 22) * (engineer ? 1 - engineer.skill * .004 : 1);
      ship.condition = clamp(round(ship.condition - wear), 0, 100);
      ship.status = ship.condition < 25 ? 'repair' : 'idle';
      for (const crew of crewFor(ship)) { crew.status = 'idle'; crew.morale = clamp(crew.morale - (success ? 2 : 8), 10, 100); }
      if (success) {
        const reward = { ...c.reward, credits: round(c.reward.credits * (1 + factionPerk('terran'))) };
        transact(reward, 'contract', c.title);
        ship.missions++; ship.earned += reward.credits; state.metrics.missions++; state.metrics.success++; state.metrics.earned += reward.credits;
        state.factions[c.faction] = clamp((state.factions[c.faction] || 0) + 2 * c.tier, 0, 200);
        currentDaily().missions++;
        log(`Успех: ${c.title}. +${reward.credits} ₡.`, 'good'); notify(`Миссия выполнена: +${reward.credits} ₡`, 'good');
      } else {
        state.metrics.missions++; state.metrics.failed++; state.resources.reputation = Math.max(0, state.resources.reputation - 1); state.factions[c.faction] = Math.max(0, (state.factions[c.faction] || 0) - 1);
        log(`Провал: ${c.title}. Корабль повреждён.`, 'bad'); notify('Миссия провалена. Проверьте флот.', 'bad');
      }
      state.history.unshift({ time: state.time, title: c.title, ship: ship.name, success, credits: success ? c.reward.credits : 0 }); state.history = state.history.slice(0, 50);
    }
    state.missions = state.missions.filter(m => m.id !== mission.id);
  }
  function refreshContracts() {
    if (!pay({ credits: 100 }, 'services', 'Обновление контрактов')) return { ok: false, message: 'Нужно 100 ₡.' };
    state.contracts = Array.from({ length: 8 }, () => generateContract()); changed(); return { ok: true, message: 'Доска контрактов обновлена.' };
  }

  function moduleCost(key) { const level = state.modules[key], def = D.modules[key]; const factor = Math.pow(Math.max(1, level), 1.5); return Object.fromEntries(Object.entries(def.base).map(([k, v]) => [k, round(v * factor)])); }
  function moduleMax(key) { return ['hangar', 'solar', 'habitat'].includes(key) ? 8 : 5; }
  function upgradeModule(key) {
    if (!D.modules[key]) return { ok: false, message: 'Модуль не найден.' };
    if (state.modules[key] >= moduleMax(key)) return { ok: false, message: 'Достигнут максимальный уровень.' };
    if (state.moduleQueue.some(j => j.key === key)) return { ok: false, message: 'Этот модуль уже улучшается.' };
    if (state.modules[key] >= 3 && state.modules.yard < 2) return { ok: false, message: 'Для уровня 4+ нужна верфь 2 уровня.' };
    const cost = moduleCost(key);
    if (!pay(cost, 'station', `Улучшение: ${D.modules[key].name}`)) return { ok: false, message: 'Недостаточно ресурсов.' };
    const time = round(20 + state.modules[key] * 14);
    state.moduleQueue.push({ id: uid('module'), key, remaining: time, duration: time, cost }); changed(); return { ok: true, message: 'Строительный дрон приступил к улучшению.' };
  }
  function startResearch(key) {
    const tech = D.techs[key];
    if (!tech || state.techs.includes(key)) return { ok: false, message: 'Технология недоступна или уже изучена.' };
    if (state.research) return { ok: false, message: 'Лаборатория уже занята.' };
    if (!tech.requires.every(id => state.techs.includes(id))) return { ok: false, message: 'Сначала изучите предыдущие технологии.' };
    if (!pay(tech.cost, 'research', `Исследование: ${tech.name}`)) return { ok: false, message: 'Недостаточно ресурсов для исследования.' };
    const time = round(tech.time / (1 + state.modules.lab * .06));
    state.research = { key, remaining: time, duration: time }; changed(); return { ok: true, message: 'Исследование начато.' };
  }
  function cancelResearch() { if (!state.research) return { ok: false, message: 'Нет активного исследования.' }; const tech = D.techs[state.research.key]; transact(Object.fromEntries(Object.entries(tech.cost).map(([k, v]) => [k, round(v * .5)])), 'refund', 'Отмена исследования'); state.research = null; changed(); return { ok: true, message: 'Исследование отменено. Возвращено 50%.' }; }

  function hireCrew(id) {
    const candidate = state.candidates.find(c => c.id === id);
    if (!candidate) return { ok: false, message: 'Кандидат не найден.' };
    if (state.crew.length >= crewCapacity()) return { ok: false, message: 'Жилой модуль заполнен.' };
    const cost = { credits: round(candidate.skill * 6) };
    if (!pay(cost, 'crew', `Найм: ${candidate.name}`)) return { ok: false, message: 'Недостаточно кредитов.' };
    state.crew.push(candidate); state.candidates = state.candidates.filter(c => c.id !== id); state.candidates.push(makeCrew()); changed(); return { ok: true, message: `${candidate.name} принят на станцию.` };
  }
  function assignCrew(crewId, shipId) {
    const crew = state.crew.find(c => c.id === crewId), ship = state.ships.find(s => s.id === shipId);
    if (!crew || crew.status !== 'idle') return { ok: false, message: 'Специалист занят.' };
    if (shipId) {
      if (!ship || ship.status !== 'idle') return { ok: false, message: 'Корабль не готов к назначению.' };
      if (ship.crew.length >= D.presets[ship.preset].crew) return { ok: false, message: 'Экипаж корабля укомплектован.' };
      if (crew.shipId) { const old = state.ships.find(s => s.id === crew.shipId); if (old) old.crew = old.crew.filter(id => id !== crew.id); }
      ship.crew.push(crew.id); crew.shipId = ship.id;
    } else if (crew.shipId) { const old = state.ships.find(s => s.id === crew.shipId); if (old) old.crew = old.crew.filter(id => id !== crew.id); crew.shipId = null; }
    changed(); return { ok: true, message: shipId ? 'Специалист назначен на корабль.' : 'Специалист возвращён на станцию.' };
  }
  function trainCrew(id) {
    const crew = state.crew.find(c => c.id === id);
    if (!crew || crew.status !== 'idle') return { ok: false, message: 'Специалист занят.' };
    if (crew.skill >= 100) return { ok: false, message: 'Максимальная квалификация.' };
    if (!pay({ credits: 150, research: 8 }, 'crew', `Обучение: ${crew.name}`)) return { ok: false, message: 'Нужно 150 ₡ и 8 исследований.' };
    crew.status = 'training'; crew.remaining = 35; changed(); return { ok: true, message: 'Обучение начато.' };
  }
  function restCrew(id) { const crew = state.crew.find(c => c.id === id); if (!crew || crew.status !== 'idle') return { ok: false, message: 'Специалист занят.' }; crew.status = 'rest'; crew.remaining = 30; changed(); return { ok: true, message: 'Специалист отправлен на отдых.' }; }
  function dismissCrew(id) { const crew = state.crew.find(c => c.id === id); if (!crew || crew.status !== 'idle') return { ok: false, message: 'Специалист занят.' }; if (crew.shipId) { const ship = state.ships.find(s => s.id === crew.shipId); if (ship) ship.crew = ship.crew.filter(x => x !== id); } state.crew = state.crew.filter(c => c.id !== id); changed(); return { ok: true, message: 'Трудовой контракт расторгнут.' }; }

  function marketPrice(resource, side) {
    const base = resource === 'alloy' ? { buy: 12, sell: 9 } : { buy: 8, sell: 6 };
    const wave = 1 + Math.sin(day() * 1.7 + (resource === 'alloy' ? 0 : 2)) * .14;
    let price = base[side] * wave;
    if (resource === 'alloy' && side === 'buy') price *= 1 - factionPerk('lunar');
    if (resource === 'alloy' && side === 'sell') price *= 1 + activeEffect('alloyPrice');
    return Math.max(1, Math.round(price * 10) / 10);
  }
  function trade(resource, side, quantity) {
    if (!['alloy', 'fuel'].includes(resource) || !['buy', 'sell'].includes(side)) return { ok: false, message: 'Неверная сделка.' };
    const qty = clamp(Math.floor(+quantity || 0), 1, 150);
    const limit = 150 - state.market.traded[resource];
    if (qty > limit) return { ok: false, message: `Дневной лимит: осталось ${limit} ед.` };
    const total = round(marketPrice(resource, side) * qty);
    if (side === 'buy') { if (!canAfford({ credits: total })) return { ok: false, message: 'Недостаточно кредитов.' }; transact({ credits: -total, [resource]: qty }, 'market', `Покупка ${resource === 'alloy' ? 'сплава' : 'топлива'} ×${qty}`); }
    else { if ((state.resources[resource] || 0) < qty) return { ok: false, message: 'Недостаточно ресурса на складе.' }; transact({ [resource]: -qty, credits: total }, 'market', `Продажа ${resource === 'alloy' ? 'сплава' : 'топлива'} ×${qty}`); }
    state.market.traded[resource] += qty; changed(); return { ok: true, message: `Сделка выполнена: ${qty} ед. за ${total} ₡.` };
  }
  function metric(name) {
    return { missions: state.metrics.success, ships: state.ships.length, custom: state.metrics.custom, earned: state.metrics.earned, techs: state.techs.length, modules: Object.values(state.modules).reduce((a, b) => a + b, 0), sectors: unlockedSectors().length, reputation: state.resources.reputation }[name] || 0;
  }
  function claimAchievement(id) { const a = D.achievements[id]; if (!a || state.claimed.includes(id) || metric(a.metric) < a.goal) return { ok: false, message: 'Награда пока недоступна.' }; state.claimed.push(id); transact(a.reward, 'achievement', `Достижение: ${a.name}`); changed(); return { ok: true, message: `Получена награда: ${a.name}.` }; }
  function triggerEvent() {
    const key = pick(Object.keys(D.events)), def = D.events[key];
    if (def.effect.credits) transact({ credits: def.effect.credits }, 'event', def.name);
    if (def.effect.contract) state.contracts.unshift({ ...generateContract(def.effect.contract, 1), reward: { ...generateContract(def.effect.contract, 1).reward, credits: 900 } });
    if (def.duration > 1) state.events.push({ key, remaining: def.duration });
    log(`${def.name}: ${def.desc}`, def.kind); notify(def.name, def.kind === 'bad' ? 'bad' : 'info');
  }
  function newDay() {
    const wages = state.crew.reduce((sum, c) => sum + c.salary, 0);
    const upkeep = Object.values(state.modules).reduce((a, b) => a + b, 0) * 2 + state.ships.length * 3;
    transact({ credits: -Math.min(state.resources.credits, wages + upkeep) }, 'upkeep', `День ${day()}: зарплаты и содержание`);
    state.market = { day: day(), traded: { alloy: 0, fuel: 0 } };
    for (const crew of state.crew) if (crew.status === 'idle') crew.morale = clamp(crew.morale + 2, 0, 100);
    currentDaily();
  }
  function advance(dt) {
    state.time += dt;
    for (const mission of [...state.missions]) { mission.remaining -= dt; if (mission.remaining <= 0) resolveMission(mission); }
    for (const job of [...state.buildQueue]) {
      if (job.waiting) continue;
      job.remaining -= dt;
      if (job.remaining > 0) continue;
      if (job.type === 'build') {
        if (state.ships.length >= capacity()) { job.remaining = 0; job.waiting = true; notify('Корабль готов, но ангар заполнен.', 'bad'); continue; }
        const ship = makeShip(job.preset, job.design, job.name); ship.value = job.cost.credits; state.ships.push(ship); if (!job.design.quick) state.metrics.custom++;
        log(`Корабль «${ship.name}» вошёл в состав флота.`, 'good'); notify(`Построен «${ship.name}»`, 'good');
      } else {
        const ship = state.ships.find(s => s.id === job.shipId);
        if (ship) { ship.design = job.design; ship.preset = job.design.preset; ship.stats = deriveStats(job.design); ship.value += job.cost.credits; ship.status = 'idle'; log(`Модернизация «${ship.name}» завершена.`, 'good'); }
      }
      state.buildQueue = state.buildQueue.filter(j => j.id !== job.id);
    }
    for (const job of [...state.repairQueue]) { job.remaining -= dt; if (job.remaining <= 0) { const ship = state.ships.find(s => s.id === job.shipId); if (ship) { ship.condition = 100; ship.status = 'idle'; log(`«${ship.name}» отремонтирован.`, 'good'); } state.repairQueue = state.repairQueue.filter(j => j.id !== job.id); } }
    for (const job of [...state.moduleQueue]) { job.remaining -= dt; if (job.remaining <= 0) { state.modules[job.key]++; log(`${D.modules[job.key].name}: уровень ${state.modules[job.key]}.`, 'good'); notify(`Модуль улучшен: ${D.modules[job.key].name}`, 'good'); state.moduleQueue = state.moduleQueue.filter(j => j.id !== job.id); } }
    if (state.research) { state.research.remaining -= dt; if (state.research.remaining <= 0) { const key = state.research.key; state.techs.push(key); state.research = null; log(`Изучено: ${D.techs[key].name}.`, 'good'); notify(`Технология изучена: ${D.techs[key].name}`, 'good'); } }
    for (const crew of state.crew) {
      if (!['training', 'rest'].includes(crew.status)) continue;
      crew.remaining -= dt;
      if (crew.remaining <= 0) { if (crew.status === 'training') { crew.skill = clamp(crew.skill + 6, 0, 100); crew.salary = round(8 + crew.skill * .22); } else crew.morale = clamp(crew.morale + 25, 0, 100); crew.status = 'idle'; crew.remaining = 0; }
    }
    state.productionTimer += dt;
    while (state.productionTimer >= 10) {
      state.productionTimer -= 10;
      const rates = productionRates();
      if (Object.values(rates).some(v => v > 0)) transact(rates, 'production', 'Цикл производства станции');
      if (state.settings.autoSupply && state.resources.fuel < 20 && state.resources.credits > 600) { const qty = Math.min(40, 150 - state.market.traded.fuel); if (qty > 0) trade('fuel', 'buy', qty); }
    }
    for (const event of [...state.events]) { event.remaining -= dt; if (event.remaining <= 0) state.events = state.events.filter(e => e !== event); }
    state.nextEvent -= dt;
    if (state.nextEvent <= 0) { triggerEvent(); state.nextEvent = 150 + random() * 90; }
    state.contractTimer += dt;
    state.contracts = state.contracts.filter(c => c.expires > state.time);
    if (state.contractTimer >= 30) { state.contractTimer = 0; while (state.contracts.length < 8) state.contracts.push(generateContract()); }
    if (day() !== state.lastDay) { state.lastDay = day(); newDay(); }
  }

  const num = (v, fallback, min = 0, max = 1e9) => Number.isFinite(+v) ? clamp(+v, min, max) : fallback;
  const str = (v, fallback, max = 80) => typeof v === 'string' && v.trim() ? v.slice(0, max) : fallback;
  function cleanDesign(raw, fallbackPreset = 'science') {
    const preset = D.presets[raw?.preset] ? raw.preset : fallbackPreset;
    const params = { ...D.presets[preset].params, ...(raw?.params && typeof raw.params === 'object' ? raw.params : {}) };
    return { name: str(raw?.name, D.presets[preset].label, 32), preset, classTitle: str(raw?.classTitle, D.presets[preset].role, 60), params, quick: !!raw?.quick, statistics: raw?.statistics && typeof raw.statistics === 'object' ? { triangles: num(raw.statistics.triangles, 15000, 0, 1e7), vertices: num(raw.statistics.vertices, 15000, 0, 1e7), meshes: num(raw.statistics.meshes, 100, 0, 1e6) } : undefined, bounds: raw?.bounds };
  }
  function normalizeShip(raw) {
    const preset = D.presets[raw?.preset] ? raw.preset : 'science';
    const design = cleanDesign(raw?.design, preset);
    const base = makeShip(preset, design, str(raw?.name, 'Корабль', 32));
    return { ...base, id: str(raw?.id, base.id, 60), value: num(raw?.value, base.value, 0, 1e9), missions: Math.floor(num(raw?.missions, 0, 0, 1e6)), earned: num(raw?.earned, 0, 0, 1e12), builtDay: Math.floor(num(raw?.builtDay, 1, 1, 1e6)), status: ['idle', 'mission', 'repair', 'refit'].includes(raw?.status) ? raw.status : 'idle', condition: Math.round(num(raw?.condition, 100, 0, 100)), crew: [] };
  }
  function cleanCrew(raw) {
    if (!raw || !D.roles[raw.role]) return null;
    return { id: str(raw.id, uid('crew'), 60), name: str(raw.name, 'Специалист', 40), role: raw.role, skill: Math.round(num(raw.skill, 40, 1, 100)), morale: Math.round(num(raw.morale, 90, 0, 100)), salary: Math.round(num(raw.salary, 18, 0, 1000)), status: ['idle', 'mission', 'training', 'rest'].includes(raw.status) ? raw.status : 'idle', shipId: typeof raw.shipId === 'string' ? raw.shipId : null, remaining: num(raw.remaining, 0, 0, 1000) };
  }
  function cleanContract(raw) {
    if (!raw || !D.contractTypes[raw.type] || !D.sectors[raw.sector]) return null;
    const def = D.contractTypes[raw.type];
    const reward = {};
    for (const k of ['credits', 'alloy', 'fuel', 'research', 'reputation']) reward[k] = Math.round(num(raw.reward?.[k], 0, 0, 1e7));
    return { id: str(raw.id, uid('contract'), 60), type: raw.type, title: str(raw.title, def.label, 90), tier: Math.round(num(raw.tier, 1, 1, 5)), sector: raw.sector, faction: D.factions[raw.faction] ? raw.faction : def.faction, stat: def.stat, req: Math.round(num(raw.req, 30, 1, 300)), speedReq: Math.round(num(raw.speedReq, 20, 0, 300)), duration: num(raw.duration, 60, 5, 3600), risk: num(raw.risk, .1, 0, .8), fuel: Math.round(num(raw.fuel, 6, 1, 500)), reward, expires: num(raw.expires, state.time + 300, 0, 1e12), special: !!raw.special };
  }
  function cleanCost(raw) { const c = {}; for (const k of ['credits', 'alloy', 'fuel', 'research']) c[k] = Math.round(num(raw?.[k], 0, 0, 1e9)); return c; }
  function normalizeSave(data) {
    if (!data || ![1, 2].includes(data.version) || !Array.isArray(data.ships)) throw new Error('Неверный формат сохранения');
    const base = defaultState();
    let merged;
    if (data.version === 1) {
      base.resources = { ...base.resources, credits: num(data.credits, 0), alloy: num(data.alloy, 0), research: num(data.research, 0), reputation: num(data.reputation, 0) };
      base.modules = { ...base.modules, ...(data.upgrades || {}) };
      base.ships = data.ships.slice(0, 30).map(normalizeShip);
      base.time = num(data.time, 0); base.speed = [0, 1, 2, 4].includes(data.speed) ? data.speed : 1;
      base.missions = (Array.isArray(data.missions) ? data.missions : []).slice(0, 30).map(m => ({ ...m, contract: { ...generateContract(), ...(m.contract || {}), sector: 'earth', faction: 'terran', fuel: 4, expires: base.time + 300 } }));
      base.onboarded = !!data.onboarded; base.lastSaved = num(data.lastSaved, Date.now(), 0, 1e14);
      base.crew[0].shipId = base.ships[0]?.id || null; if (base.ships[0]) base.ships[0].crew = [base.crew[0].id];
      log('Сохранение первой версии перенесено в расширенный прототип.', 'good');
      merged = base;
    } else {
      merged = { ...base, ...data, resources: { ...base.resources, ...(data.resources || {}) }, modules: { ...base.modules, ...(data.modules || {}) }, settings: { ...base.settings, ...(data.settings || {}) }, metrics: { ...base.metrics, ...(data.metrics || {}) }, factions: { ...base.factions, ...(data.factions || {}) }, market: { ...base.market, ...(data.market || {}) } };
    }
    for (const key of ['ships', 'crew', 'candidates', 'contracts', 'missions', 'history', 'buildQueue', 'moduleQueue', 'repairQueue', 'techs', 'events', 'ledger', 'daily', 'log', 'claimed']) if (!Array.isArray(merged[key])) merged[key] = base[key];
    merged.version = 2;
    merged.resources = Object.fromEntries(Object.keys(base.resources).map(k => [k, Math.round(num(merged.resources[k], base.resources[k], 0, 1e12))]));
    merged.modules = Object.fromEntries(Object.keys(D.modules).map(k => [k, Math.floor(num(merged.modules[k], 0, 0, moduleMax(k)))]));
    merged.settings = { background: ['high', 'low', 'off'].includes(merged.settings.background) ? merged.settings.background : 'high', sound: !!merged.settings.sound, autoSupply: !!merged.settings.autoSupply, autoSave: merged.settings.autoSave !== false, notifications: merged.settings.notifications !== false };
    merged.metrics = Object.fromEntries(Object.keys(base.metrics).map(k => [k, Math.round(num(merged.metrics[k], 0, 0, 1e12))]));
    merged.factions = Object.fromEntries(Object.keys(D.factions).map(k => [k, Math.round(num(merged.factions[k], 0, 0, 200))]));
    merged.speed = [0, 1, 2, 4].includes(merged.speed) ? merged.speed : 1;
    merged.time = num(merged.time, 0, 0, 1e12); merged.rng = num(merged.rng, 740291, 0, 4294967295) >>> 0; merged.lastSaved = num(merged.lastSaved, Date.now(), 0, 1e14);
    merged.productionTimer = num(merged.productionTimer, 0, 0, 10); merged.contractTimer = num(merged.contractTimer, 0, 0, 30); merged.nextEvent = num(merged.nextEvent, 150, 1, 1000); merged.lastDay = Math.floor(num(merged.lastDay, 1, 1, 1e9));
    merged.techs = [...new Set(merged.techs.filter(id => D.techs[id]))];
    merged.claimed = [...new Set(merged.claimed.filter(id => D.achievements[id]))];
    merged.ships = merged.ships.slice(0, 30).map(normalizeShip);
    merged.crew = merged.crew.slice(0, 60).map(cleanCrew).filter(Boolean);
    merged.candidates = merged.candidates.slice(0, 8).map(cleanCrew).filter(Boolean).map(c => ({ ...c, status: 'idle', shipId: null, remaining: 0 }));
    const shipIds = new Set(merged.ships.map(x => x.id));
    for (const c of merged.crew) { if (!shipIds.has(c.shipId)) c.shipId = null; if (c.status === 'mission' && !c.shipId) c.status = 'idle'; }
    for (const ship of merged.ships) { ship.crew = merged.crew.filter(c => c.shipId === ship.id).map(c => c.id).slice(0, D.presets[ship.preset].crew); if (ship.status === 'mission' && !merged.missions.some(m => m.shipId === ship.id)) ship.status = ship.condition < 25 ? 'repair' : 'idle'; }
    merged.contracts = merged.contracts.slice(0, 24).map(cleanContract).filter(Boolean);
    merged.missions = merged.missions.slice(0, 30).map(m => { const contract = cleanContract(m?.contract); if (!contract || !shipIds.has(m?.shipId)) return null; const duration = num(m.duration, contract.duration, 1, 7200); return { id: str(m.id, uid('mission'), 60), contract, shipId: m.shipId, duration, remaining: num(m.remaining, duration, 0, duration), chance: num(m.chance, .5, .15, .95), fuel: Math.round(num(m.fuel, contract.fuel, 0, 1000)), started: num(m.started, merged.time, 0, 1e12) }; }).filter(Boolean);
    for (const ship of merged.ships) if (merged.missions.some(m => m.shipId === ship.id)) ship.status = 'mission';
    merged.buildQueue = merged.buildQueue.slice(0, 8).map(j => { if (!j || !['build', 'refit'].includes(j.type)) return null; const design = cleanDesign(j.design, j.preset); if (j.type === 'refit' && !shipIds.has(j.shipId)) return null; const duration = num(j.duration, 60, 1, 7200); return { id: str(j.id, uid('job'), 60), type: j.type, shipId: j.shipId || null, name: str(j.name, design.name, 32), preset: design.preset, design, cost: cleanCost(j.cost), duration, remaining: num(j.remaining, duration, 0, duration), waiting: !!j.waiting }; }).filter(Boolean);
    merged.repairQueue = merged.repairQueue.slice(0, 8).filter(j => j && shipIds.has(j.shipId)).map(j => { const duration = num(j.duration, 30, 1, 3600); return { id: str(j.id, uid('repair'), 60), shipId: j.shipId, duration, remaining: num(j.remaining, duration, 0, duration), cost: cleanCost(j.cost) }; });
    merged.moduleQueue = merged.moduleQueue.slice(0, 11).filter(j => j && D.modules[j.key]).map(j => { const duration = num(j.duration, 30, 1, 3600); return { id: str(j.id, uid('module'), 60), key: j.key, duration, remaining: num(j.remaining, duration, 0, duration), cost: cleanCost(j.cost) }; });
    for (const job of merged.buildQueue) if (job.type === 'refit') { const ship = merged.ships.find(x => x.id === job.shipId); if (ship && ship.status === 'idle') ship.status = 'refit'; }
    for (const job of merged.repairQueue) { const ship = merged.ships.find(x => x.id === job.shipId); if (ship && ship.status === 'idle') ship.status = 'repair'; }
    merged.research = merged.research && D.techs[merged.research.key] && !merged.techs.includes(merged.research.key) ? { key: merged.research.key, duration: num(merged.research.duration, 60, 1, 7200), remaining: num(merged.research.remaining, 60, 0, 7200) } : null;
    merged.events = merged.events.slice(0, 8).filter(e => e && D.events[e.key]).map(e => ({ key: e.key, remaining: num(e.remaining, D.events[e.key].duration, 0, D.events[e.key].duration) }));
    merged.history = merged.history.slice(0, 50).map(h => ({ time: num(h?.time, 0, 0, 1e12), title: str(h?.title, 'Миссия', 90), ship: str(h?.ship, 'Корабль', 32), success: !!h?.success, credits: num(h?.credits, 0, 0, 1e9) }));
    merged.ledger = merged.ledger.slice(0, 400).map(l => ({ time: num(l?.time, 0, 0, 1e12), day: Math.floor(num(l?.day, 1, 1, 1e9)), category: str(l?.category, 'other', 30), label: str(l?.label, 'Операция', 120), delta: Object.fromEntries(Object.keys(base.resources).map(k => [k, num(l?.delta?.[k], 0, -1e12, 1e12)]).filter(([, v]) => v !== 0)) }));
    merged.daily = merged.daily.slice(-14).map(d => ({ day: Math.floor(num(d?.day, 1, 1, 1e9)), income: num(d?.income, 0, 0, 1e12), expenses: num(d?.expenses, 0, 0, 1e12), missions: Math.floor(num(d?.missions, 0, 0, 1e6)), production: num(d?.production, 0, 0, 1e12) }));
    if (!merged.daily.length) merged.daily = [{ day: Math.floor(merged.time / DAY) + 1, income: 0, expenses: 0, missions: 0, production: 0 }];
    merged.log = merged.log.slice(0, 100).map(l => ({ time: num(l?.time, 0, 0, 1e12), text: str(l?.text, '', 300), kind: ['info', 'good', 'bad'].includes(l?.kind) ? l.kind : 'info' })).filter(l => l.text);
    merged.market = { day: Math.floor(num(merged.market.day, 1, 1, 1e9)), traded: { alloy: Math.floor(num(merged.market.traded?.alloy, 0, 0, 150)), fuel: Math.floor(num(merged.market.traded?.fuel, 0, 0, 150)) } };
    merged.onboarded = !!merged.onboarded;
    return merged;
  }
  function save(manual = false) {
    state.lastSaved = Date.now();
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(state)); if (manual) notify('Прогресс сохранён.', 'good'); return true; }
    catch (e) { notify('Не удалось сохранить прогресс в браузере.', 'bad'); return false; }
  }
  function applyOffline(loaded) {
    const elapsed = clamp((Date.now() - (+loaded.lastSaved || Date.now())) / 1000, 0, 8 * 3600);
    if (elapsed < 10) return;
    const before = { ...loaded.resources };
    silent = true;
    let remaining = elapsed;
    while (remaining > 0) { const step = Math.min(5, remaining); advance(step); remaining -= step; }
    silent = false;
    offlineSummary = { elapsed, credits: state.resources.credits - before.credits, alloy: state.resources.alloy - before.alloy, research: state.resources.research - before.research };
    log(`Оффлайн-смена: ${duration(elapsed)}. Производство и миссии обработаны.`, 'info');
  }
  function init() {
    defaultState();
    try {
      const raw = localStorage.getItem(SAVE_KEY) || localStorage.getItem(LEGACY_KEY);
      if (raw) { state = normalizeSave(JSON.parse(raw)); applyOffline(state); }
    } catch (e) { defaultState(); }
    return state;
  }
  function importSave(text) {
    try { const next = normalizeSave(JSON.parse(text)); state = next; state.lastSaved = Date.now(); save(); changed(); return { ok: true, message: 'Сохранение импортировано.' }; }
    catch (e) { return { ok: false, message: 'Файл сохранения повреждён или несовместим.' }; }
  }
  function reset() { defaultState(); save(); changed(); }
  function netWorth() { return round(state.resources.credits + state.resources.alloy * 10 + state.resources.fuel * 7 + state.ships.reduce((s, x) => s + x.value * x.condition / 100, 0) + Object.entries(state.modules).reduce((s, [k, l]) => s + (D.modules[k]?.base.credits || 0) * l * .5, 0)); }
  function setSetting(key, value) { if (!(key in state.settings)) return; state.settings[key] = value; changed(); }
  function setSpeed(value) { if ([0, 1, 2, 4].includes(+value)) { state.speed = +value; changed(); } }
  return {
    D, SAVE_KEY, init, advance, save, importSave, reset, setSpeed, setSetting, get state() { return state; }, get offlineSummary() { return offlineSummary; }, clearOffline() { offlineSummary = null; },
    subscribe(fn) { listener = fn; }, onNotify(fn) { notifier = fn; }, day, clock, duration, random, uid, clone, log, changed, notify,
    deriveStats, shipStats, crewFor, chance, fuelNeed, missionDuration, canAfford, buildCost, buildDuration, repairCost, capacity, crewCapacity, queueSlots, maxTier, unlockedSectors, energy, productionRates, factionLevel, factionPerk,
    queueBuild, cancelJob, queueRepair, queueRefit, sellShip, renameShip, assignMission, refreshContracts, moduleCost, moduleMax, upgradeModule, startResearch, cancelResearch,
    hireCrew, assignCrew, trainCrew, restCrew, dismissCrew, marketPrice, trade, metric, claimAchievement, netWorth, transact,
    exportSave() { return JSON.stringify(state, null, 2); }
  };
})();

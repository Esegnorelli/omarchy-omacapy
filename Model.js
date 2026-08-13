function clamp(n, lo, hi) {
  n = Number(n)
  if (!isFinite(n)) n = lo
  return Math.max(lo, Math.min(hi, n))
}

function nowMs() {
  return Date.now()
}

function defaultState(ts) {
  ts = ts || nowMs()
  return {
    version: 4,
    happiness: 72,
    belly: 58,
    zen: 80,
    bond: 0,
    pets: 0,
    oranges: 0,
    soaks: 0,
    wisdomIndex: 0,
    lastInteractMs: ts,
    lastTickMs: ts,
    lastWisdom: "",
    toast: "",
    mood: "chill",
  }
}

function looksLikePet(raw) {
  if (!raw || typeof raw !== "object") return false
  if (raw.happiness != null || raw.belly != null || raw.zen != null) return true
  var v = Number(raw.version)
  return v === 1 || v === 2 || v === 4
}

function normalizeState(raw, ts) {
  var base = defaultState(ts)
  if (!looksLikePet(raw)) return base
  return {
    version: 4,
    happiness: clamp(raw.happiness != null ? raw.happiness : base.happiness, 0, 100),
    belly: clamp(raw.belly != null ? raw.belly : base.belly, 0, 100),
    zen: clamp(raw.zen != null ? raw.zen : base.zen, 0, 100),
    bond: Math.max(0, Number(raw.bond) || 0),
    pets: Math.max(0, Number(raw.pets) || 0),
    oranges: Math.max(0, Number(raw.oranges) || 0),
    soaks: Math.max(0, Number(raw.soaks) || 0),
    wisdomIndex: Math.max(0, Math.floor(Number(raw.wisdomIndex) || 0)),
    lastInteractMs: Number(raw.lastInteractMs) || ts || nowMs(),
    lastTickMs: Number(raw.lastTickMs) || ts || nowMs(),
    lastWisdom: String(raw.lastWisdom || ""),
    toast: String(raw.toast || ""),
    mood: String(raw.mood || "chill"),
  }
}

function parseState(raw, ts) {
  try {
    if (!raw || !String(raw).trim()) return defaultState(ts)
    return normalizeState(JSON.parse(String(raw)), ts)
  } catch (e) {
    return defaultState(ts)
  }
}

function serializeState(state) {
  var s = normalizeState(state, nowMs())
  return JSON.stringify({
    version: 4,
    happiness: s.happiness,
    belly: s.belly,
    zen: s.zen,
    bond: s.bond,
    pets: s.pets,
    oranges: s.oranges,
    soaks: s.soaks,
    wisdomIndex: s.wisdomIndex,
    lastInteractMs: s.lastInteractMs,
    lastTickMs: s.lastTickMs,
    lastWisdom: s.lastWisdom,
    mood: s.mood,
  }, null, 2) + "\n"
}

function hourLocal(ts) {
  return new Date(ts || nowMs()).getHours()
}

function parseLoad(raw) {
  var parts = String(raw || "").trim().split(/\s+/)
  var n = parseFloat(parts[0])
  return isFinite(n) ? n : 0
}

function deriveMood(state, load, ts) {
  ts = ts || nowMs()
  var hour = hourLocal(ts)
  var lonelyMs = ts - (state.lastInteractMs || ts)
  if (load >= 4.5 || state.zen < 20) return "fried"
  if (lonelyMs > 6 * 60 * 60 * 1000 && state.happiness < 45) return "lonely"
  if ((hour >= 23 || hour < 6) && state.happiness > 35) return "napping"
  if (state.zen >= 88 && state.happiness >= 70) return "soaked"
  if (state.belly >= 85) return "munching"
  if (state.happiness >= 90) return "hyped"
  if (state.happiness < 30) return "meh"
  return "chill"
}

function tick(state, load, ts) {
  ts = ts || nowMs()
  state = normalizeState(state, ts)
  var prev = state.lastTickMs || ts
  var dtMin = clamp((ts - prev) / 60000, 0, 180)
  if (dtMin <= 0) {
    state.mood = deriveMood(state, load, ts)
    state.lastTickMs = ts
    return state
  }

  state.belly = clamp(state.belly - dtMin * 0.35, 0, 100)
  state.happiness = clamp(state.happiness - dtMin * 0.18, 0, 100)
  state.zen = clamp(state.zen - dtMin * 0.12, 0, 100)

  if (load >= 2.5) state.zen = clamp(state.zen - dtMin * (0.4 + load * 0.08), 0, 100)
  else if (load < 0.8) state.zen = clamp(state.zen + dtMin * 0.25, 0, 100)

  var hour = hourLocal(ts)
  if (hour >= 23 || hour < 6) state.zen = clamp(state.zen + dtMin * 0.5, 0, 100)

  state.lastTickMs = ts
  state.mood = deriveMood(state, load, ts)
  state.toast = ""
  return state
}

function touch(state, ts) {
  state = normalizeState(state, ts)
  state.lastInteractMs = ts || nowMs()
  return state
}

function pick(list, salt) {
  if (!list || !list.length) return ""
  var i = Math.abs(Math.floor(Number(salt) || 0)) % list.length
  return list[i]
}

function pet(state, load, ts) {
  ts = ts || nowMs()
  state = tick(state, load, ts)
  state = touch(state, ts)
  state.pets += 1
  state.bond += 1
  state.happiness = clamp(state.happiness + 10, 0, 100)
  state.zen = clamp(state.zen + 4, 0, 100)
  state.toast = pick([
    "soft head received",
    "capy purr (theoretical)",
    "you are both doing fine",
    "*accepts pets as diplomacy*",
    "bond +1, chaos -1",
  ], state.pets)
  state.mood = deriveMood(state, load, ts)
  return state
}

function orange(state, load, ts) {
  ts = ts || nowMs()
  state = tick(state, load, ts)
  state = touch(state, ts)
  state.oranges += 1
  state.bond += 1
  state.belly = clamp(state.belly + 22, 0, 100)
  state.happiness = clamp(state.happiness + 8, 0, 100)
  state.toast = pick([
    "orange acquired",
    "citrus diplomacy succeeds",
    "vitamin C for the soul",
    "crunch. pause. wisdom.",
    "snack level: mythic",
  ], state.oranges)
  state.mood = deriveMood(state, load, ts)
  return state
}

function soak(state, load, ts) {
  ts = ts || nowMs()
  state = tick(state, load, ts)
  state = touch(state, ts)
  state.soaks += 1
  state.bond += 1
  state.zen = clamp(state.zen + 24, 0, 100)
  state.happiness = clamp(state.happiness + 6, 0, 100)
  state.toast = pick([
    "thermal reset complete",
    "now 12% more river",
    "wet rodent, dry worries",
    "soaked. unbothered. thriving.",
    "spa ending: infinite",
  ], state.soaks)
  state.mood = deriveMood(state, load, ts)
  return state
}

var WISDOM = [
  "A beautiful system is a motivating system. Also oranges.",
  "Omakase means sit down. The chef already tiled your windows.",
  "Super+Alt+Space is the river. Everything else is dry land.",
  "Theme first. Then the bug is at least pretty.",
  "If the compile is loud, soak. If Super+Q closed the wrong thing, soak again.",
  "Updates can wait. Zen cannot.",
  "Hyprland tiles. You float.",
  "The menu knows. You do not need another dashboard.",
  "If it is not a river problem, stand still like a capy.",
  "Deploy nothing before snacks.",
  "Orange first. Refactor second.",
  "You do not fix burnout with another monitor.",
  "Capivara does not doomscroll. Capivara floats.",
  "If CI fails, soak again.",
  "Small pets, large serotonin.",
  "Quiet competence beats loud panic. Also oranges.",
  "Neovim is a lifestyle. This rodent is a coworker.",
  "A watched pipeline never boils — but a soaked capy does not care.",
  "Leave the workspaces. The river does not close tickets.",
  "Productivity is downstream from motivation. Pet the mammal.",
]

function nextWisdom(state) {
  var n = WISDOM.length
  if (!n) return ""
  var i = Math.max(0, Math.floor(Number(state.wisdomIndex) || 0)) % n
  var line = WISDOM[i]
  if (line === state.lastWisdom && n > 1) {
    i = (i + 1) % n
    line = WISDOM[i]
  }
  state.wisdomIndex = (i + 1) % n
  return line
}

function wisdom(state, load, ts) {
  ts = ts || nowMs()
  state = tick(state, load, ts)
  state = touch(state, ts)
  state.bond += 0.5
  state.zen = clamp(state.zen + 3, 0, 100)
  state.lastWisdom = nextWisdom(state)
  state.toast = "wisdom dispensed"
  state.mood = deriveMood(state, load, ts)
  return state
}

function moodMeta(mood) {
  var table = {
    chill: {
      title: "chill",
      blurb: "Sits next to the clock. Pet, feed, soak, or ask for omakase wisdom.",
      bar: "Capy",
      portrait: "capy.png",
      tempo: 1.0,
    },
    soaked: {
      title: "soaked",
      blurb: "Just back from the river. Peak calm — soak again anytime.",
      bar: "wet",
      portrait: "capy-soaked.png",
      tempo: 0.85,
    },
    munching: {
      title: "munching",
      blurb: "Orange protocol engaged. Feed another, or just watch the crunch.",
      bar: "yum",
      portrait: "capy-munching.png",
      tempo: 0.7,
    },
    napping: {
      title: "napping",
      blurb: "Night mode. Let it sleep — or pet anyway.",
      bar: "zzz",
      portrait: "capy-napping.png",
      tempo: 1.6,
    },
    hyped: {
      title: "hyped",
      blurb: "Over-petted into enlightenment. You are a good roommate.",
      bar: "hype",
      portrait: "capy.png",
      tempo: 0.45,
    },
    fried: {
      title: "fried",
      blurb: "CPU is hot. Click Soak — this capy needs a river.",
      bar: "hot",
      portrait: "capy.png",
      tempo: 0.55,
    },
    lonely: {
      title: "lonely",
      blurb: "Nobody has visited in hours. Click Pet.",
      bar: "hey",
      portrait: "capy.png",
      tempo: 1.25,
    },
    meh: {
      title: "meh",
      blurb: "Horizontally unimpressed. A pet or an orange will do.",
      bar: "meh",
      portrait: "capy.png",
      tempo: 1.35,
    },
  }
  return table[mood] || table.chill
}

function portraitFor(mood) {
  return moodMeta(mood).portrait
}

function barTempoMs(state) {
  var meta = moodMeta(state && state.mood)
  var tempo = Number(meta.tempo)
  if (!isFinite(tempo) || tempo <= 0) tempo = 1
  return Math.round(520 * tempo)
}

function bondRank(bond) {
  var n = Number(bond) || 0
  if (n >= 80) return "river kin"
  if (n >= 30) return "family"
  if (n >= 10) return "roommate"
  return "visitor"
}

function tooltip(state, load) {
  var m = moodMeta(state && state.mood)
  var loadText = isFinite(load) ? load.toFixed(2) : "?"
  return "OmaCapy · " + m.title + " · CPU " + loadText + " · click for lounge"
}

function meter(label, value) {
  return { label: label, value: clamp(value, 0, 100) }
}

function meters(state) {
  state = normalizeState(state)
  return [
    meter("Happiness", state.happiness),
    meter("Snacks", state.belly),
    meter("Zen", state.zen),
  ]
}

function actions() {
  return [
    { id: "pet", label: "Pet", detail: "Happiness up. The official hello.", icon: "✋" },
    { id: "orange", label: "Orange", detail: "Snacks up. Diplomatic citrus.", icon: "🍊" },
    { id: "soak", label: "Soak", detail: "Zen up. Send it to the river.", icon: "💧" },
    { id: "wisdom", label: "Wisdom", detail: "A one-liner. No refunds.", icon: "💬" },
  ]
}

function actionFx(actionId) {
  if (actionId === "pet") return ["💕", "✨", "🫶", "💫"]
  if (actionId === "orange") return ["🍊", "✨", "🟡", "😋"]
  if (actionId === "soak") return ["💧", "🫧", "🌊", "💦"]
  if (actionId === "wisdom") return ["💬", "⭐", "🧠", "✨"]
  return ["✨"]
}

function shortcutHint() {
  return "Badge: click lounge · mid-click pet · right-click wisdom · scroll pet / orange"
}

function meterHint() {
  return "They fade slowly. Night restores zen. High CPU load fries it."
}

function emptyWisdom() {
  return "Ask for Wisdom, or right-click the badge for a one-liner."
}

if (typeof module !== "undefined") {
  module.exports = {
    clamp: clamp,
    defaultState: defaultState,
    normalizeState: normalizeState,
    parseState: parseState,
    serializeState: serializeState,
    parseLoad: parseLoad,
    deriveMood: deriveMood,
    tick: tick,
    pet: pet,
    orange: orange,
    soak: soak,
    wisdom: wisdom,
    nextWisdom: nextWisdom,
    moodMeta: moodMeta,
    portraitFor: portraitFor,
    barTempoMs: barTempoMs,
    bondRank: bondRank,
    tooltip: tooltip,
    meters: meters,
    actions: actions,
    actionFx: actionFx,
    shortcutHint: shortcutHint,
    meterHint: meterHint,
    emptyWisdom: emptyWisdom,
    WISDOM: WISDOM,
    looksLikePet: looksLikePet,
  }
}

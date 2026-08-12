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
    version: 1,
    happiness: 72,
    belly: 58,
    zen: 80,
    bond: 0,
    pets: 0,
    oranges: 0,
    soaks: 0,
    lastInteractMs: ts,
    lastTickMs: ts,
    lastWisdom: "",
    toast: "",
    mood: "chill",
  }
}

function normalizeState(raw, ts) {
  var base = defaultState(ts)
  if (!raw || typeof raw !== "object") return base
  return {
    version: 1,
    happiness: clamp(raw.happiness != null ? raw.happiness : base.happiness, 0, 100),
    belly: clamp(raw.belly != null ? raw.belly : base.belly, 0, 100),
    zen: clamp(raw.zen != null ? raw.zen : base.zen, 0, 100),
    bond: Math.max(0, Number(raw.bond) || 0),
    pets: Math.max(0, Number(raw.pets) || 0),
    oranges: Math.max(0, Number(raw.oranges) || 0),
    soaks: Math.max(0, Number(raw.soaks) || 0),
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
  // don't persist ephemeral toast forever as sticky UI — keep last one ok
  return JSON.stringify({
    version: 1,
    happiness: s.happiness,
    belly: s.belly,
    zen: s.zen,
    bond: s.bond,
    pets: s.pets,
    oranges: s.oranges,
    soaks: s.soaks,
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
  if (hour >= 23 || hour < 6) {
    if (state.happiness > 35) return "napping"
  }
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

  // slow gentle decay — capy is low-maintenance on purpose
  state.belly = clamp(state.belly - dtMin * 0.35, 0, 100)
  state.happiness = clamp(state.happiness - dtMin * 0.18, 0, 100)
  state.zen = clamp(state.zen - dtMin * 0.12, 0, 100)

  // busy machine steals zen; quiet machine restores a little
  if (load >= 2.5) state.zen = clamp(state.zen - dtMin * (0.4 + load * 0.08), 0, 100)
  else if (load < 0.8) state.zen = clamp(state.zen + dtMin * 0.25, 0, 100)

  // night nap regenerates zen
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
  "If it is not a river problem, stand still like a capy.",
  "Deploy nothing before snacks.",
  "Your code compiles emotionally already.",
  "Meetings are just dry land. Endure.",
  "Be the load average you want to see in the world.",
  "Orange first. Refactor second.",
  "A watched pipeline never boils — but a soaked capy does not care.",
  "Touch grass. Or at least touch this rodent.",
  "Production is a suggestion. Zen is a lifestyle.",
  "The bug fears the calm engineer.",
  "SSH is temporary. Vibes are forever.",
  "You do not fix burnout with another monitor.",
  "In Brazil we call this 'boa'. Elsewhere: LGTM.",
  "Capivara does not doomscroll. Capivara floats.",
  "If CI fails, soak again.",
  "Small pets, large serotonin.",
  "Today's status: unbothered aquatic mammal.",
  "Leave the tabs open. The river does not close tickets.",
  "Your TODO list cannot swim faster than you.",
  "Quiet competence beats loud panic. Also oranges.",
]

function pick(list, salt) {
  if (!list || !list.length) return ""
  var i = Math.abs(Number(salt) || 0) + Math.floor(nowMs() / 1000)
  return list[i % list.length]
}

function wisdom(state, load, ts) {
  ts = ts || nowMs()
  state = tick(state, load, ts)
  state = touch(state, ts)
  state.bond += 0.5
  state.zen = clamp(state.zen + 3, 0, 100)
  var line = pick(WISDOM, state.bond + state.pets + hourLocal(ts))
  // avoid immediate repeat
  if (line === state.lastWisdom && WISDOM.length > 1) {
    line = pick(WISDOM, state.bond + 7)
  }
  state.lastWisdom = line
  state.toast = "wisdom dispensed"
  state.mood = deriveMood(state, load, ts)
  return state
}

function moodMeta(mood) {
  var table = {
    chill: { face: "🦫", title: "chill", blurb: "Floating through the desktop like it pays rent in vibes.", bar: "🦫" },
    soaked: { face: "🫧🦫", title: "soaked", blurb: "Fresh from the spa. Problems bounce off wet fur.", bar: "🫧🦫" },
    munching: { face: "🍊🦫", title: "munching", blurb: "Orange protocol engaged. Do not disturb the crunch.", bar: "🍊" },
    napping: { face: "😴🦫", title: "napping", blurb: "After-hours mode. Dreaming of warmer APIs.", bar: "😴" },
    hyped: { face: "✨🦫", title: "hyped", blurb: "Over-petted into enlightenment. Peak coworker.", bar: "✨🦫" },
    fried: { face: "🥵🦫", title: "fried", blurb: "CPU heat detected. This capy needs a river and a nap.", bar: "🥵" },
    lonely: { face: "🥺🦫", title: "lonely", blurb: "Has been emotionally buffering. Pets preferred.", bar: "🥺" },
    meh: { face: "😑🦫", title: "meh", blurb: "Not mad. Just horizontally unimpressed.", bar: "🦫" },
  }
  return table[mood] || table.chill
}

function barLabel(state) {
  return moodMeta(state && state.mood).bar
}

function tooltip(state, load) {
  var m = moodMeta(state && state.mood)
  var loadText = isFinite(load) ? load.toFixed(2) : "?"
  return "OmaCapy · " + m.title + " · load " + loadText + " · click for lounge"
}

function meter(label, value) {
  return { label: label, value: clamp(value, 0, 100) }
}

function meters(state) {
  state = normalizeState(state)
  return [
    meter("mood fuel", state.happiness),
    meter("snack", state.belly),
    meter("zen", state.zen),
  ]
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
    moodMeta: moodMeta,
    barLabel: barLabel,
    tooltip: tooltip,
    meters: meters,
    WISDOM: WISDOM,
  }
}

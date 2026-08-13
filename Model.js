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
    version: 2,
    happiness: 72,
    belly: 58,
    zen: 80,
    bond: 0,
    pets: 0,
    oranges: 0,
    soaks: 0,
    lastInteractMs: ts,
    lastTickMs: ts,
    lastPracticeTickMs: ts,
    lastWisdom: "",
    toast: "",
    mood: "chill",
    languages: {},
  }
}

function normalizeState(raw, ts) {
  var base = defaultState(ts)
  if (!raw || typeof raw !== "object") return base
  return {
    version: 2,
    happiness: clamp(raw.happiness != null ? raw.happiness : base.happiness, 0, 100),
    belly: clamp(raw.belly != null ? raw.belly : base.belly, 0, 100),
    zen: clamp(raw.zen != null ? raw.zen : base.zen, 0, 100),
    bond: Math.max(0, Number(raw.bond) || 0),
    pets: Math.max(0, Number(raw.pets) || 0),
    oranges: Math.max(0, Number(raw.oranges) || 0),
    soaks: Math.max(0, Number(raw.soaks) || 0),
    lastInteractMs: Number(raw.lastInteractMs) || ts || nowMs(),
    lastTickMs: Number(raw.lastTickMs) || ts || nowMs(),
    lastPracticeTickMs: Number(raw.lastPracticeTickMs) || Number(raw.lastTickMs) || ts || nowMs(),
    lastWisdom: String(raw.lastWisdom || ""),
    toast: String(raw.toast || ""),
    mood: String(raw.mood || "chill"),
    languages: normalizeLanguages(raw.languages),
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
    version: 2,
    happiness: s.happiness,
    belly: s.belly,
    zen: s.zen,
    bond: s.bond,
    pets: s.pets,
    oranges: s.oranges,
    soaks: s.soaks,
    lastInteractMs: s.lastInteractMs,
    lastTickMs: s.lastTickMs,
    lastPracticeTickMs: s.lastPracticeTickMs,
    lastWisdom: s.lastWisdom,
    mood: s.mood,
    languages: s.languages,
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

function pick(list, salt) {
  if (!list || !list.length) return ""
  var i = Math.floor(Math.abs(Number(salt) || 0) + Math.floor(nowMs() / 1000))
  var idx = i % list.length
  if (idx < 0) idx += list.length
  return list[idx]
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
    chill: {
      face: "🦫",
      title: "chill",
      blurb: "Sits next to the clock. Pet, feed, soak, or ask for omakase wisdom.",
      bar: "Capy",
      frames: ["🦫", "🦫˳", "˳🦫", "🦫"],
      tempo: 1.0,
    },
    soaked: {
      face: "🫧🦫",
      title: "soaked",
      blurb: "Just back from the river. Peak calm — soak again anytime.",
      bar: "wet",
      frames: ["🫧🦫", "🦫🫧", "💧🦫", "🫧🦫"],
      tempo: 0.85,
    },
    munching: {
      face: "🍊🦫",
      title: "munching",
      blurb: "Orange protocol engaged. Feed another, or just watch the crunch.",
      bar: "yum",
      frames: ["🍊", "🦫", "🍊🦫", "🦫"],
      tempo: 0.7,
    },
    napping: {
      face: "😴🦫",
      title: "napping",
      blurb: "Night mode. Let it sleep — or pet anyway.",
      bar: "zzz",
      frames: ["😴", "💤", "😴🦫", "💤"],
      tempo: 1.6,
    },
    hyped: {
      face: "✨🦫",
      title: "hyped",
      blurb: "Over-petted into enlightenment. You are a good roommate.",
      bar: "hype",
      frames: ["✨🦫", "🎉🦫", "🦫✨", "⚡🦫"],
      tempo: 0.45,
    },
    fried: {
      face: "🥵🦫",
      title: "fried",
      blurb: "CPU is hot. Click Soak — this capy needs a river.",
      bar: "hot",
      frames: ["🥵", "🔥", "🥵🦫", "💨"],
      tempo: 0.55,
    },
    lonely: {
      face: "🥺🦫",
      title: "lonely",
      blurb: "Nobody has visited in hours. Click Pet.",
      bar: "hey",
      frames: ["🥺", "🦫", "🥺🦫", "…🦫"],
      tempo: 1.25,
    },
    meh: {
      face: "😑🦫",
      title: "meh",
      blurb: "Horizontally unimpressed. A pet or an orange will do.",
      bar: "meh",
      frames: ["😑", "🦫", "😑🦫", "🦫"],
      tempo: 1.35,
    },
  }
  return table[mood] || table.chill
}

function frameAt(frames, index) {
  var list = Array.isArray(frames) && frames.length ? frames : ["🦫"]
  var i = Math.abs(Math.floor(Number(index) || 0)) % list.length
  return list[i]
}

function barLabel(state, frame) {
  var meta = moodMeta(state && state.mood)
  if (frame == null) return meta.bar
  return frameAt(meta.frames, frame)
}

function heroFace(state, frame, popped) {
  var meta = moodMeta(state && state.mood)
  if (popped) {
    if (state && state.mood === "munching") return "🍊✨"
    if (state && state.mood === "soaked") return "💧🦫💧"
    if (state && state.mood === "hyped") return "🎉🦫🎉"
    return meta.face + "✨"
  }
  return frameAt(meta.frames, frame)
}

function actionFx(actionId) {
  if (actionId === "pet") return ["💕", "✨", "🫶", "💫"]
  if (actionId === "orange") return ["🍊", "✨", "🟡", "😋"]
  if (actionId === "soak") return ["💧", "🫧", "🌊", "💦"]
  if (actionId === "wisdom") return ["💬", "⭐", "🧠", "✨"]
  return ["✨"]
}

function barTempoMs(state) {
  var meta = moodMeta(state && state.mood)
  var tempo = Number(meta.tempo)
  if (!isFinite(tempo) || tempo <= 0) tempo = 1
  return Math.round(520 * tempo)
}

function tooltip(state, load, langId) {
  var lang = langById(langId)
  if (lang) {
    var row = languageStat(state, lang.id)
    return lang.name + " · " + formatDuration(row.weekMs) + " this week · click for stack"
  }
  var m = moodMeta(state && state.mood)
  var loadText = isFinite(load) ? load.toFixed(2) : "?"
  return "OmaCapy · " + m.title + " · CPU " + loadText + " · click to open lounge"
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

function shortcutHint() {
  return "Badge: click lounge · mid-click pet · right-click wisdom · scroll pet / orange"
}

function meterHint() {
  return "They fade slowly. Night restores zen. High CPU load fries it."
}

function emptyWisdom() {
  return "Ask for Wisdom, or right-click the badge for a one-liner."
}

function pad2(n) {
  n = Math.floor(Number(n) || 0)
  return n < 10 ? "0" + n : String(n)
}

function dayKey(ts) {
  var d = new Date(ts || nowMs())
  return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate())
}

function weekKey(ts) {
  var d = new Date(ts || nowMs())
  var day = d.getDay()
  var mondayOffset = day === 0 ? -6 : 1 - day
  var monday = new Date(d.getFullYear(), d.getMonth(), d.getDate() + mondayOffset)
  return monday.getFullYear() + "-W" + pad2(monday.getMonth() + 1) + pad2(monday.getDate())
}

function emptyLangStat(ts) {
  ts = ts || nowMs()
  return {
    ms: 0,
    todayMs: 0,
    weekMs: 0,
    todayKey: dayKey(ts),
    weekKey: weekKey(ts),
    lastSeenMs: 0,
  }
}

function normalizeLangStat(raw, ts) {
  var base = emptyLangStat(ts)
  if (!raw || typeof raw !== "object") return base
  return {
    ms: Math.max(0, Number(raw.ms) || 0),
    todayMs: Math.max(0, Number(raw.todayMs) || 0),
    weekMs: Math.max(0, Number(raw.weekMs) || 0),
    todayKey: String(raw.todayKey || base.todayKey),
    weekKey: String(raw.weekKey || base.weekKey),
    lastSeenMs: Math.max(0, Number(raw.lastSeenMs) || 0),
  }
}

function normalizeLanguages(raw) {
  var out = {}
  if (!raw || typeof raw !== "object") return out
  var keys = Object.keys(raw)
  for (var i = 0; i < keys.length; i++) {
    var id = keys[i]
    if (!langById(id) && id !== "other") continue
    out[id] = normalizeLangStat(raw[id])
  }
  return out
}

function languageStat(state, id) {
  state = state || {}
  var langs = state.languages || {}
  return normalizeLangStat(langs[id])
}

function L(id, name, shortName, icon, extensions, aliases) {
  return {
    id: id,
    name: name,
    short: shortName,
    icon: icon,
    extensions: extensions || [],
    aliases: aliases || [],
  }
}

// Nerd Font glyphs — same visual family as nvim-web-devicons.
var LANGUAGES = [
  L("python", "Python", "py", "\ue73c", ["py", "pyw", "pyi"], ["python", "pyproject.toml", "requirements.txt"]),
  L("rust", "Rust", "rs", "\ue7a8", ["rs"], ["rust", "cargo.toml", "cargo.lock"]),
  L("go", "Go", "go", "\ue724", ["go"], ["go.mod", "go.sum"]),
  L("javascript", "JavaScript", "js", "\ue781", ["js", "mjs", "cjs"], ["javascript", "node", "package.json"]),
  L("typescript", "TypeScript", "ts", "\ue628", ["ts", "mts", "cts"], ["typescript", "tsconfig.json"]),
  L("tsx", "TSX", "tsx", "\ue7ba", ["tsx"], ["tsx"]),
  L("jsx", "JSX", "jsx", "\ue7ba", ["jsx"], ["jsx"]),
  L("lua", "Lua", "lua", "\ue620", ["lua"], ["lua"]),
  L("ruby", "Ruby", "rb", "\ue739", ["rb", "erb"], ["ruby", "gemfile"]),
  L("php", "PHP", "php", "\ue73d", ["php"], ["php", "composer.json"]),
  L("java", "Java", "java", "\ue738", ["java"], ["java"]),
  L("kotlin", "Kotlin", "kt", "\ue634", ["kt", "kts"], ["kotlin"]),
  L("c", "C", "c", "\ue61e", ["c", "h"], ["c"]),
  L("cpp", "C++", "c++", "\ue61d", ["cpp", "cc", "cxx", "hpp", "hh"], ["cpp", "c++", "cplusplus", "cmakelists.txt"]),
  L("csharp", "C#", "c#", "\ue77f", ["cs"], ["cs", "csharp"]),
  L("html", "HTML", "html", "\ue736", ["html", "htm"], ["html"]),
  L("css", "CSS", "css", "\ue749", ["css", "scss", "sass", "less"], ["css", "scss"]),
  L("json", "JSON", "json", "\ue60b", ["json", "jsonc"], ["json"]),
  L("markdown", "Markdown", "md", "\ue73e", ["md", "mdx"], ["markdown"]),
  L("shell", "Shell", "sh", "\ue795", ["sh", "bash", "zsh", "fish"], ["sh", "bash", "zsh", "fish"]),
  L("qml", "QML", "qml", "\ue6ae", ["qml"], ["qml"]),
  L("zig", "Zig", "zig", "\ue6a9", ["zig"], ["zig"]),
  L("elixir", "Elixir", "ex", "\ue62d", ["ex", "exs"], ["elixir"]),
  L("haskell", "Haskell", "hs", "\ue777", ["hs", "lhs"], ["haskell"]),
  L("swift", "Swift", "swift", "\ue755", ["swift"], ["swift"]),
  L("dart", "Dart", "dart", "\ue798", ["dart"], ["dart"]),
  L("svelte", "Svelte", "svelte", "\ue697", ["svelte"], ["svelte"]),
  L("vue", "Vue", "vue", "\ue6a0", ["vue"], ["vue"]),
  L("sql", "SQL", "sql", "\ue706", ["sql"], ["sql"]),
  L("toml", "TOML", "toml", "\ue6b2", ["toml"], ["toml"]),
  L("yaml", "YAML", "yml", "\ue6a8", ["yml", "yaml"], ["yaml", "yml"]),
  L("docker", "Docker", "docker", "\ue7b0", [], ["dockerfile", "containerfile"]),
  L("make", "Make", "make", "\ue673", [], ["makefile", "gnumakefile"]),
  L("vim", "Vim", "vim", "\ue7c5", ["vim"], ["vim", "viml"]),
  L("nix", "Nix", "nix", "\uf313", ["nix"], ["nix"]),
  L("astro", "Astro", "astro", "\ue6b3", ["astro"], ["astro"]),
  L("terraform", "Terraform", "tf", "\ue69a", ["tf", "tfvars"], ["terraform"]),
  L("graphql", "GraphQL", "gql", "\ue662", ["graphql", "gql"], ["graphql"]),
  L("other", "Other", "dev", "\ue795", [], ["other", "text"]),
]

var LANG_BY_ID = {}
var LANG_BY_EXT = {}
var LANG_BY_ALIAS = {}
;(function indexLangs() {
  for (var i = 0; i < LANGUAGES.length; i++) {
    var lang = LANGUAGES[i]
    LANG_BY_ID[lang.id] = lang
    var e
    for (e = 0; e < lang.extensions.length; e++)
      LANG_BY_EXT[lang.extensions[e].toLowerCase()] = lang
    for (e = 0; e < lang.aliases.length; e++)
      LANG_BY_ALIAS[lang.aliases[e].toLowerCase()] = lang
  }
})()

function langById(id) {
  if (!id) return null
  return LANG_BY_ID[String(id)] || null
}

function lookupToken(token) {
  if (!token) return null
  var t = String(token).trim().toLowerCase()
  if (!t) return null
  if (LANG_BY_ID[t]) return LANG_BY_ID[t]
  if (LANG_BY_ALIAS[t]) return LANG_BY_ALIAS[t]
  if (LANG_BY_EXT[t]) return LANG_BY_EXT[t]
  return null
}

function extractFilename(title) {
  var t = String(title || "").trim()
  if (!t) return ""
  t = t.replace(/\s+[—–|\-].*$/, "")
  t = t.replace(/\s+\(.*\)$/, "")
  var parts = t.split(/[/\\]/)
  return String(parts[parts.length - 1] || "").trim()
}

function detectLanguage(title, appId, hint) {
  var fromHint = lookupToken(hint)
  if (!fromHint && hint) {
    var hintName = extractFilename(hint)
    fromHint = lookupToken(hintName)
    if (!fromHint && hintName.indexOf(".") !== -1)
      fromHint = lookupToken(hintName.split(".").pop())
  }
  if (fromHint) return fromHint

  var name = extractFilename(title)
  var lower = name.toLowerCase()
  if (LANG_BY_ALIAS[lower]) return LANG_BY_ALIAS[lower]

  var ext = ""
  var dot = lower.lastIndexOf(".")
  if (dot > 0 && dot < lower.length - 1) ext = lower.slice(dot + 1)
  if (ext && LANG_BY_EXT[ext]) return LANG_BY_EXT[ext]

  var raw = String(title || "")
  if (/\bDockerfile\b/i.test(raw) || /\bContainerfile\b/i.test(raw)) return LANG_BY_ID.docker
  if (/\bMakefile\b/i.test(raw)) return LANG_BY_ID.make
  if (/\bCargo\.toml\b/i.test(raw)) return LANG_BY_ID.rust

  var app = String(appId || "").toLowerCase()
  if (app.indexOf("jetbrains") !== -1 && ext) return lookupToken(ext)

  return null
}

function rollLangWindows(stat, ts) {
  stat = normalizeLangStat(stat, ts)
  var today = dayKey(ts)
  var week = weekKey(ts)
  if (stat.todayKey !== today) {
    stat.todayMs = 0
    stat.todayKey = today
  }
  if (stat.weekKey !== week) {
    stat.weekMs = 0
    stat.weekKey = week
  }
  return stat
}

function tickPractice(state, langId, ts) {
  ts = ts || nowMs()
  state = normalizeState(state, ts)
  var prev = state.lastPracticeTickMs || ts
  var dt = ts - prev
  state.lastPracticeTickMs = ts
  if (!langId || !langById(langId)) return state
  if (dt < 800) return state
  if (dt > 20000) dt = 20000

  var langs = state.languages || {}
  var row = rollLangWindows(langs[langId], ts)
  row.ms += dt
  row.todayMs += dt
  row.weekMs += dt
  row.lastSeenMs = ts
  langs[langId] = row
  state.languages = langs
  return state
}

function practiceScore(ms) {
  var hours = Math.max(0, Number(ms) || 0) / 3600000
  return clamp(100 * (1 - Math.exp(-hours / 8)), 0, 100)
}

function formatDuration(ms) {
  var totalMin = Math.floor(Math.max(0, Number(ms) || 0) / 60000)
  if (totalMin < 1) return (Number(ms) || 0) < 1000 ? "0m" : "<1m"
  if (totalMin < 60) return totalMin + "m"
  var h = Math.floor(totalMin / 60)
  var m = totalMin % 60
  if (h < 24) return m ? h + "h " + m + "m" : h + "h"
  var d = Math.floor(h / 24)
  var rh = h % 24
  return rh ? d + "d " + rh + "h" : d + "d"
}

function stackRows(state, focusId) {
  state = normalizeState(state)
  var langs = state.languages || {}
  var ids = Object.keys(langs)
  if (focusId && langById(focusId) && !langs[focusId]) ids.push(focusId)
  var rows = []
  for (var i = 0; i < ids.length; i++) {
    var id = ids[i]
    var meta = langById(id) || langById("other")
    var stat = rollLangWindows(langs[id], nowMs())
    rows.push({
      id: id,
      name: meta.name,
      short: meta.short,
      icon: meta.icon,
      ms: stat.ms,
      todayMs: stat.todayMs,
      weekMs: stat.weekMs,
      score: practiceScore(stat.ms),
      active: id === focusId,
      todayText: formatDuration(stat.todayMs),
      weekText: formatDuration(stat.weekMs),
      totalText: formatDuration(stat.ms),
    })
  }
  rows.sort(function(a, b) {
    if (a.active !== b.active) return a.active ? -1 : 1
    return b.ms - a.ms
  })
  return rows.slice(0, 6)
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
    frameAt: frameAt,
    barLabel: barLabel,
    heroFace: heroFace,
    actionFx: actionFx,
    barTempoMs: barTempoMs,
    tooltip: tooltip,
    meters: meters,
    actions: actions,
    shortcutHint: shortcutHint,
    meterHint: meterHint,
    emptyWisdom: emptyWisdom,
    WISDOM: WISDOM,
    LANGUAGES: LANGUAGES,
    langById: langById,
    detectLanguage: detectLanguage,
    extractFilename: extractFilename,
    tickPractice: tickPractice,
    practiceScore: practiceScore,
    formatDuration: formatDuration,
    languageStat: languageStat,
    stackRows: stackRows,
    dayKey: dayKey,
    weekKey: weekKey,
  }
}

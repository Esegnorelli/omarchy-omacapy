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
    version: 3,
    lastPracticeTickMs: ts,
    languages: {},
  }
}

function normalizeState(raw, ts) {
  var base = defaultState(ts)
  if (!raw || typeof raw !== "object") return base
  return {
    version: 3,
    lastPracticeTickMs: Number(raw.lastPracticeTickMs) || Number(raw.lastTickMs) || ts || nowMs(),
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
  return JSON.stringify({
    version: 3,
    lastPracticeTickMs: s.lastPracticeTickMs,
    languages: s.languages,
  }, null, 2) + "\n"
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

var LANGUAGES = [
  L("python", "Python", "py", "\ue73c", ["py", "pyw", "pyi"], ["python", "pyproject.toml", "requirements.txt", "jupyter notebook"]),
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
  L("css", "CSS", "css", "\ue749", ["css", "scss", "sass", "less"], ["css", "scss", "sass", "less"]),
  L("json", "JSON", "json", "\ue60b", ["json", "jsonc"], ["json"]),
  L("markdown", "Markdown", "md", "\ue73e", ["md", "mdx"], ["markdown"]),
  L("shell", "Shell", "sh", "\ue795", ["sh", "bash", "zsh", "fish"], ["sh", "bash", "zsh", "fish", "shell"]),
  L("qml", "QML", "qml", "\ue6ae", ["qml"], ["qml"]),
  L("zig", "Zig", "zig", "\ue6a9", ["zig"], ["zig"]),
  L("elixir", "Elixir", "ex", "\ue62d", ["ex", "exs"], ["elixir"]),
  L("haskell", "Haskell", "hs", "\ue777", ["hs", "lhs"], ["haskell"]),
  L("swift", "Swift", "swift", "\ue755", ["swift"], ["swift"]),
  L("dart", "Dart", "dart", "\ue798", ["dart"], ["dart"]),
  L("svelte", "Svelte", "svelte", "\ue697", ["svelte"], ["svelte"]),
  L("vue", "Vue", "vue", "\ue6a0", ["vue"], ["vue"]),
  L("sql", "SQL", "sql", "\ue706", ["sql"], ["sql", "plpgsql", "plsql", "sqlpl"]),
  L("r", "R", "r", "\ue68a", ["r", "rmd"], ["r"]),
  L("scala", "Scala", "scala", "\ue737", ["scala", "sc"], ["scala"]),
  L("perl", "Perl", "pl", "\ue769", ["pl", "pm"], ["perl"]),
  L("powershell", "PowerShell", "ps", "\ue70c", ["ps1", "psm1"], ["powershell"]),
  L("objc", "Objective-C", "objc", "\ue61e", ["m", "mm"], ["objective-c", "objc"]),
  L("toml", "TOML", "toml", "\ue6b2", ["toml"], ["toml"]),
  L("yaml", "YAML", "yml", "\ue6a8", ["yml", "yaml"], ["yaml", "yml"]),
  L("docker", "Docker", "docker", "\ue7b0", [], ["dockerfile", "containerfile"]),
  L("make", "Make", "make", "\ue673", [], ["makefile", "gnumakefile"]),
  L("vim", "Vim", "vim", "\ue7c5", ["vim"], ["vim", "viml", "vim script", "vimscript"]),
  L("nix", "Nix", "nix", "\uf313", ["nix"], ["nix"]),
  L("astro", "Astro", "astro", "\ue6b3", ["astro"], ["astro"]),
  L("terraform", "Terraform", "tf", "\ue69a", ["tf", "tfvars"], ["terraform"]),
  L("graphql", "GraphQL", "gql", "\ue662", ["graphql", "gql"], ["graphql"]),
  L("ai", "AI", "ai", "\u2726", [], [
    "ai", "opencode", "claude", "chatgpt", "grok", "hermes", "codex",
    "copilot", "gemini", "perplexity", "aider", "ollama", "lmstudio",
    "windsurf", "cursor", "goose",
  ]),
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

function isAiBlob(text) {
  var s = String(text || "").toLowerCase()
  if (!s) return false
  if (s.indexOf("chatgpt") !== -1 || s.indexOf("chat.openai") !== -1) return true
  if (s.indexOf("claude") !== -1) return true
  if (s.indexOf("opencode") !== -1) return true
  if (s.indexOf("perplexity") !== -1) return true
  if (s.indexOf("copilot") !== -1) return true
  if (s.indexOf("gemini") !== -1) return true
  if (s.indexOf("lmstudio") !== -1 || s.indexOf("lm studio") !== -1) return true
  if (s.indexOf("windsurf") !== -1) return true
  if (s.indexOf("ollama") !== -1) return true
  if (/\b(grok|hermes|codex|aider|goose)\b/.test(s)) return true
  if (/\bcursor\b/.test(s) && (s.indexOf("cursor") === 0 || s.indexOf(".") !== -1)) return true
  return false
}

function hasProc(procs, name) {
  var list = String(procs || "").toLowerCase().split(/[\s,]+/)
  var n = String(name || "").toLowerCase()
  for (var i = 0; i < list.length; i++) {
    if (list[i] === n || list[i].indexOf(n) !== -1) return true
  }
  return false
}

function detectLanguage(title, appId, hint, procs) {
  var raw = String(title || "")
  var app = String(appId || "")
  var blob = raw + " " + app + " " + String(procs || "")

  var fromHint = lookupToken(hint)
  if (!fromHint && hint) {
    var hintName = extractFilename(hint)
    fromHint = lookupToken(hintName)
    if (!fromHint && hintName.indexOf(".") !== -1)
      fromHint = lookupToken(hintName.split(".").pop())
  }

  var name = extractFilename(title)
  var lower = name.toLowerCase()
  var ext = ""
  var dot = lower.lastIndexOf(".")
  if (dot > 0 && dot < lower.length - 1) ext = lower.slice(dot + 1)
  var fromFile = null
  if (LANG_BY_ALIAS[lower]) fromFile = LANG_BY_ALIAS[lower]
  else if (ext && LANG_BY_EXT[ext]) fromFile = LANG_BY_EXT[ext]
  else if (/\bDockerfile\b/i.test(raw) || /\bContainerfile\b/i.test(raw)) fromFile = LANG_BY_ID.docker
  else if (/\bMakefile\b/i.test(raw)) fromFile = LANG_BY_ID.make
  else if (/\bCargo\.toml\b/i.test(raw)) fromFile = LANG_BY_ID.rust

  if (fromFile && fromFile.id !== "ai") return fromFile

  var nvimLive = hasProc(procs, "nvim") || hasProc(procs, "vim")
  if (fromHint && fromHint.id !== "ai" && nvimLive) return fromHint

  if (isAiBlob(blob) || hasProc(procs, "opencode") || hasProc(procs, "claude")
      || hasProc(procs, "grok") || hasProc(procs, "hermes") || hasProc(procs, "codex"))
    return LANG_BY_ID.ai

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

var POPULAR_IDS = [
  "python", "javascript", "typescript", "java", "csharp", "cpp",
  "go", "rust", "php", "ruby", "kotlin", "swift", "html", "css",
  "shell", "sql", "ai",
]

function mapGithubLanguage(name) {
  var n = String(name || "").trim()
  if (!n) return null
  var special = {
    "c++": "cpp",
    "c#": "csharp",
    "objective-c": "objc",
    "jupyter notebook": "python",
    "vim script": "vim",
    "vimscript": "vim",
    "plpgsql": "sql",
    "plsql": "sql",
    "dockerfile": "docker",
  }
  var key = n.toLowerCase()
  if (special[key]) return langById(special[key])
  return lookupToken(n) || lookupToken(key)
}

function githubLanguageShare(github) {
  var map = {}
  var total = 0
  var list = (github && github.languages) || []
  var i
  for (i = 0; i < list.length; i++) {
    var item = list[i] || {}
    var meta = mapGithubLanguage(item.name) || langById(item.id)
    if (!meta) continue
    var bytes = Math.max(0, Number(item.bytes) || 0)
    if (!map[meta.id]) map[meta.id] = { id: meta.id, bytes: 0 }
    map[meta.id].bytes += bytes
    total += bytes
  }
  var out = []
  var ids = Object.keys(map)
  for (i = 0; i < ids.length; i++) {
    var id = ids[i]
    out.push({
      id: id,
      bytes: map[id].bytes,
      share: total > 0 ? map[id].bytes / total : 0,
    })
  }
  out.sort(function(a, b) { return b.bytes - a.bytes })
  return out
}

function stackRows(state, focusId, github) {
  state = normalizeState(state)
  var langs = state.languages || {}
  var seen = {}
  var ids = []
  function addId(id) {
    if (!id || seen[id] || !langById(id)) return
    seen[id] = true
    ids.push(id)
  }
  addId(focusId)
  var localIds = Object.keys(langs)
  var i
  for (i = 0; i < localIds.length; i++) addId(localIds[i])
  var ghShare = githubLanguageShare(github)
  for (i = 0; i < ghShare.length; i++) addId(ghShare[i].id)
  if (ghShare.length === 0) {
    for (i = 0; i < POPULAR_IDS.length; i++) addId(POPULAR_IDS[i])
  }

  var ghById = {}
  for (i = 0; i < ghShare.length; i++) ghById[ghShare[i].id] = ghShare[i]

  var rows = []
  for (i = 0; i < ids.length; i++) {
    var id = ids[i]
    var meta = langById(id) || langById("other")
    var stat = rollLangWindows(langs[id], nowMs())
    var gh = ghById[id]
    var ghPct = gh ? Math.round(gh.share * 100) : 0
    rows.push({
      id: id,
      name: meta.name,
      short: meta.short,
      icon: meta.icon,
      ms: stat.ms,
      todayMs: stat.todayMs,
      weekMs: stat.weekMs,
      lastSeenMs: stat.lastSeenMs,
      score: gh ? Math.max(practiceScore(stat.ms), ghPct) : practiceScore(stat.ms),
      active: id === focusId,
      onGithub: !!gh,
      githubPct: ghPct,
      todayText: formatDuration(stat.todayMs),
      weekText: formatDuration(stat.weekMs),
      totalText: formatDuration(stat.ms),
    })
  }
  rows.sort(function(a, b) {
    if (a.active !== b.active) return a.active ? -1 : 1
    if ((b.ms > 0) !== (a.ms > 0)) return b.ms > 0 ? 1 : -1
    if (b.ms !== a.ms) return b.ms - a.ms
    return b.githubPct - a.githubPct
  })
  return rows.slice(0, 10)
}

function badgeLang(state, focusId) {
  if (focusId && langById(focusId)) return langById(focusId)
  var rows = stackRows(state, "")
  var best = null
  var bestSeen = -1
  for (var i = 0; i < rows.length; i++) {
    if (rows[i].lastSeenMs >= bestSeen) {
      bestSeen = rows[i].lastSeenMs
      best = langById(rows[i].id)
    }
  }
  return best
}

function tooltip(state, focusId, github) {
  var lang = badgeLang(state, focusId)
  var base = "Stack · click for practice hours"
  if (lang) {
    var row = languageStat(state, lang.id)
    var live = focusId === lang.id
    base = lang.name + " · " + formatDuration(row.weekMs) + " this week"
      + (live ? "" : " · last")
  }
  var n = githubBadgeCount(github)
  if (n > 0) base += " · " + n + " github"
  return base + " · click"
}

function emptyGithub() {
  return {
    ok: false,
    fetched: false,
    login: "",
    error: "",
    notificationCount: 0,
    reviewCount: 0,
    prCount: 0,
    assignedCount: 0,
    reviews: [],
    prs: [],
    assigned: [],
    notices: [],
    languages: [],
  }
}

function repoName(url) {
  var s = String(url || "")
  var m = s.match(/github\.com\/([^/]+\/[^/]+)/)
  if (m) return m[1].replace(/\.git$/, "")
  m = s.match(/repos\/([^/]+\/[^/]+)/)
  if (m) return m[1]
  return ""
}

function cleanItems(list) {
  var out = []
  if (!list || !list.length) return out
  for (var i = 0; i < list.length && out.length < 5; i++) {
    var it = list[i] || {}
    var title = String(it.title || "").trim()
    if (!title) continue
    out.push({
      title: title,
      url: String(it.url || ""),
      repo: String(it.repo || repoName(it.url || it.repository_url || "")),
      reason: String(it.reason || it.type || ""),
    })
  }
  return out
}

function parseGithub(raw) {
  var empty = emptyGithub()
  empty.fetched = true
  try {
    if (!raw || !String(raw).trim()) {
      empty.error = "empty"
      return empty
    }
    var d = JSON.parse(String(raw))
    if (!d || typeof d !== "object") {
      empty.error = "bad json"
      return empty
    }
    if (!d.ok) {
      empty.error = String(d.error || "not signed in")
      return empty
    }
    var notifs = d.notifications || {}
    var reviews = d.reviews || {}
    var prs = d.prs || {}
    var assigned = d.assigned || {}
    return {
      ok: true,
      fetched: true,
      login: String(d.login || ""),
      error: "",
      notificationCount: Math.max(0, Number(notifs.count) || 0),
      reviewCount: Math.max(0, Number(reviews.total) || 0),
      prCount: Math.max(0, Number(prs.total) || 0),
      assignedCount: Math.max(0, Number(assigned.total) || 0),
      reviews: cleanItems(reviews.items),
      prs: cleanItems(prs.items),
      assigned: cleanItems(assigned.items),
      notices: cleanItems(notifs.items),
      languages: Array.isArray(d.languages) ? d.languages : [],
    }
  } catch (e) {
    empty.error = "bad json"
    return empty
  }
}

function githubBadgeCount(github) {
  if (!github || !github.ok) return 0
  return (Number(github.reviewCount) || 0) + (Number(github.notificationCount) || 0)
}

function githubRows(github) {
  if (!github || !github.ok) return []
  var rows = []
  var i
  for (i = 0; i < (github.reviews || []).length; i++) {
    rows.push({
      kind: "review",
      label: "Review",
      title: github.reviews[i].title,
      url: github.reviews[i].url,
      repo: github.reviews[i].repo,
    })
  }
  for (i = 0; i < (github.prs || []).length; i++) {
    rows.push({
      kind: "pr",
      label: "PR",
      title: github.prs[i].title,
      url: github.prs[i].url,
      repo: github.prs[i].repo,
    })
  }
  for (i = 0; i < (github.assigned || []).length; i++) {
    rows.push({
      kind: "issue",
      label: "Assigned",
      title: github.assigned[i].title,
      url: github.assigned[i].url,
      repo: github.assigned[i].repo,
    })
  }
  return rows.slice(0, 8)
}

if (typeof module !== "undefined") {
  module.exports = {
    clamp: clamp,
    defaultState: defaultState,
    normalizeState: normalizeState,
    parseState: parseState,
    serializeState: serializeState,
    LANGUAGES: LANGUAGES,
    langById: langById,
    detectLanguage: detectLanguage,
    extractFilename: extractFilename,
    tickPractice: tickPractice,
    practiceScore: practiceScore,
    formatDuration: formatDuration,
    languageStat: languageStat,
    stackRows: stackRows,
    badgeLang: badgeLang,
    tooltip: tooltip,
    emptyGithub: emptyGithub,
    parseGithub: parseGithub,
    githubBadgeCount: githubBadgeCount,
    githubRows: githubRows,
    mapGithubLanguage: mapGithubLanguage,
    githubLanguageShare: githubLanguageShare,
    POPULAR_IDS: POPULAR_IDS,
    repoName: repoName,
    dayKey: dayKey,
    weekKey: weekKey,
  }
}

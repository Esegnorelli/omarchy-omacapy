var M = require("./Model.js")
var fails = 0

function assert(name, cond) {
  if (cond) {
    console.log("ok  " + name)
    return
  }
  fails += 1
  console.log("FAIL  " + name)
}

function langId(title, app, hint) {
  var lang = M.detectLanguage(title, app, hint)
  return lang ? lang.id : null
}

assert("py file", langId("app.py") === "python")
assert("vscode title", langId("app.py — horadopastel - Visual Studio Code") === "python")
assert("path", langId("/home/x/Projects/foo/main.rs") === "rust")
assert("nvim titlestring", langId("omacapy.lua") === "lua")
assert("ghostty idle", langId("trabalho: ~") === null)
assert("cargo", langId("Cargo.toml — rust-app") === "rust")
assert("dockerfile", langId("Dockerfile") === "docker")
assert("hint needs nvim", langId("trabalho: ~", "com.mitchellh.ghostty", "python") === null)
assert("hint filetype", M.detectLanguage("trabalho: ~", "com.mitchellh.ghostty", "python", "ghostty nvim").id === "python")
assert("hint filename", M.detectLanguage("trabalho: ~", "", "main.go", "nvim").id === "go")
assert("qml", langId("Panel.qml") === "qml")
assert("tsx", langId("App.tsx") === "tsx")
assert("opencode title", langId("OpenCode") === "ai")
assert("chatgpt browser", langId("ChatGPT", "chrome-chatgpt.com__-Default") === "ai")
assert("grok title", langId("Grok — chat") === "ai")
assert("opencode proc", M.detectLanguage("trabalho: ~", "com.mitchellh.ghostty", "", "ghostty opencode").id === "ai")
assert("file beats ai", M.detectLanguage("app.py — x", "", "", "opencode").id === "python")
assert("nvim hint with nvim", M.detectLanguage("trabalho: ~", "ghostty", "python", "ghostty nvim").id === "python")
assert("stale hint ignored", M.detectLanguage("trabalho: ~", "firefox", "python", "firefox") === null)

var idle = M.defaultState(1000)
assert("v3 state", idle.version === 3 && idle.languages && typeof idle.languages === "object")

var s = M.tickPractice(idle, "python", 1000 + 15000)
assert("practice adds 15s", M.languageStat(s, "python").ms === 15000)
s = M.tickPractice(s, "python", 1000 + 30000)
assert("practice accumulates", M.languageStat(s, "python").ms === 30000)
s = M.tickPractice(s, "rust", 1000 + 45000)
assert("other lang isolated", M.languageStat(s, "python").ms === 30000 && M.languageStat(s, "rust").ms === 15000)
s = M.tickPractice(s, "ai", 1000 + 60000)
assert("ai isolated", M.languageStat(s, "ai").ms === 15000 && M.languageStat(s, "python").ms === 30000)

var tiny = M.tickPractice(idle, "python", 1000 + 200)
assert("ignores sub-second", M.languageStat(tiny, "python").ms === 0)

var slept = M.tickPractice(idle, "python", 1000 + 5 * 60 * 1000)
assert("caps long gap", M.languageStat(slept, "python").ms === 20000)

assert("score empty", M.practiceScore(0) === 0)
assert("score grows", M.practiceScore(8 * 3600000) > 50 && M.practiceScore(8 * 3600000) < 70)
assert("format 0", M.formatDuration(0) === "0m")
assert("format 20s", M.formatDuration(20000) === "<1m")
assert("format 5m", M.formatDuration(5 * 60000) === "5m")
assert("format 90m", M.formatDuration(90 * 60000) === "1h 30m")

var old = M.parseState(JSON.stringify({
  version: 2,
  happiness: 40,
  languages: { python: { ms: 90000, todayMs: 90000, weekMs: 90000 } },
}), 2000)
assert("migrates v2 langs", old.version === 3 && M.languageStat(old, "python").ms === 90000)
assert("drops pet fields", old.happiness == null)

var rows = M.stackRows(s, "python")
assert("stack focuses python", rows[0].id === "python" && rows[0].active)
assert("stack has rust", rows.some(function(r) { return r.id === "rust" }))
assert("stack has ai", rows.some(function(r) { return r.id === "ai" }))

var round = M.parseState(M.serializeState(s), 50000)
assert("roundtrip practice", M.languageStat(round, "python").ms === 30000)
assert("badge prefers focus", M.badgeLang(s, "ai").id === "ai")

assert("gh lang ts", M.mapGithubLanguage("TypeScript").id === "typescript")
assert("gh lang plpgsql", M.mapGithubLanguage("PLpgSQL").id === "sql")
assert("gh lang jupyter", M.mapGithubLanguage("Jupyter Notebook").id === "python")
assert("gh lang dockerfile", M.mapGithubLanguage("Dockerfile").id === "docker")

var merged = M.stackRows(M.defaultState(1), "python", {
  ok: true,
  languages: [
    { name: "TypeScript", bytes: 4000000 },
    { name: "Python", bytes: 100000 },
    { name: "QML", bytes: 20000 },
  ],
})
assert("merge includes ts", merged.some(function(r) { return r.id === "typescript" && r.onGithub }))
assert("merge includes qml", merged.some(function(r) { return r.id === "qml" && r.onGithub }))
assert("focus first", merged[0].id === "python")

var popular = M.stackRows(M.defaultState(1), "", { ok: false, languages: [] })
assert("popular fallback", popular.some(function(r) { return r.id === "go" }) && popular.length >= 8)

var gh = M.parseGithub(JSON.stringify({
  ok: true,
  login: "Esegnorelli",
  notifications: { count: 12, items: [{ title: "CI failed", repo: "a/b", type: "CheckSuite" }] },
  reviews: { total: 1, items: [{ title: "Please review", url: "https://github.com/a/b/pull/1" }] },
  prs: { total: 2, items: [{ title: "My PR", url: "https://github.com/a/b/pull/2" }] },
  assigned: { total: 0, items: [] },
}))
assert("gh ok", gh.ok && gh.login === "Esegnorelli")
assert("gh counts", gh.notificationCount === 12 && gh.reviewCount === 1 && gh.prCount === 2)
assert("gh badge", M.githubBadgeCount(gh) === 13)
assert("gh rows", M.githubRows(gh).length === 2 && M.githubRows(gh)[0].kind === "review")
assert("gh repo", M.repoName("https://github.com/a/b/pull/2") === "a/b")
assert("gh missing", M.parseGithub('{"ok":false,"error":"Run gh auth login."}').error.indexOf("gh auth") !== -1)

if (fails) {
  console.log(fails + " failed")
  process.exit(1)
}
console.log("all passed")

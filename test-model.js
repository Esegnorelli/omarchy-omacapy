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
assert("hint filetype", langId("trabalho: ~", "com.mitchellh.ghostty", "python") === "python")
assert("hint filename", langId("trabalho: ~", "", "main.go") === "go")
assert("qml", langId("Panel.qml") === "qml")
assert("tsx", langId("App.tsx") === "tsx")

var idle = M.defaultState(1000)
assert("v2 state", idle.version === 2 && idle.languages && typeof idle.languages === "object")

var s = M.tickPractice(idle, "python", 1000 + 15000)
assert("practice adds 15s", M.languageStat(s, "python").ms === 15000)
s = M.tickPractice(s, "python", 1000 + 30000)
assert("practice accumulates", M.languageStat(s, "python").ms === 30000)
s = M.tickPractice(s, "rust", 1000 + 45000)
assert("other lang isolated", M.languageStat(s, "python").ms === 30000 && M.languageStat(s, "rust").ms === 15000)

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
  version: 1,
  happiness: 40,
  lastWisdom: "hi",
}), 2000)
assert("migrates v1", old.version === 2 && old.happiness === 40 && old.lastWisdom === "hi")
assert("migrates langs", old.languages && Object.keys(old.languages).length === 0)

var rows = M.stackRows(s, "python")
assert("stack focuses python", rows[0].id === "python" && rows[0].active)
assert("stack has rust", rows.some(function(r) { return r.id === "rust" }))

var round = M.parseState(M.serializeState(s), 50000)
assert("roundtrip practice", M.languageStat(round, "python").ms === 30000)

if (fails) {
  console.log(fails + " failed")
  process.exit(1)
}
console.log("all passed")

# OmaCapy

![OmaCapy](preview.png)

**The playful roommate Omarchy didn't ship.**

The badge follows the language you are in — Python, Rust, Go, the same icons as nvim — and a thin bar shows how much you have practiced it. Click the lounge for today's / this week's / lifetime hours. The capybara is still there when you are not in a file.

Computers can be useful **and** fun.

## Language badge

OmaCapy reads the focused window title (VS Code, Cursor, Zed, JetBrains) and, optionally, a one-line hint from nvim.

In nvim, source the hook so a Ghostty title like `trabalho: ~` still maps to the buffer:

Copy `nvim/omacapy.lua` to `~/.config/nvim/plugin/omacapy.lua` (or `luafile` it from your config).

Practice time only counts while a recognized language is focused. Idle terminals and browsers do not inflate the bar.

## What you do

| Button | What happens |
| --- | --- |
| **Pet** | Happiness up. The official hello. |
| **Orange** | Snacks up. Diplomatic citrus. |
| **Soak** | Zen up. Send it to the river. |
| **Wisdom** | A one-liner. No refunds. |

Happiness, snacks, and zen fade slowly on their own. Night restores zen. High CPU load (from `/proc/loadavg`) cooks it until you soak.

## Moods

The badge word and the face change with the roommate:

| Mood | Means |
| --- | --- |
| `chill` | Default floating coworker |
| `soaked` | Just back from the river |
| `munching` | Currently orange |
| `napping` | After 23:00, if it's happy enough |
| `hyped` | Over-petted |
| `fried` | Load is high, or zen collapsed |
| `lonely` | Nobody visited for hours |
| `meh` | Happiness ran low |

## Badge shortcuts

- **Left-click** — open / close the lounge
- **Middle-click** — quick pet
- **Right-click** — quick wisdom
- **Scroll up / down** — pet / orange

State lives in `~/.local/state/omarchy/omacapy.json`. The nvim hook writes `~/.local/state/omarchy/omacapy-lang`. Nothing leaves the machine.

## Install

```bash
omarchy plugin add https://github.com/Esegnorelli/omarchy-omacapy.git --enable
```

Local checkout:

```bash
omarchy plugin validate .
omarchy plugin add "$PWD" --enable
```

Optional placement:

```bash
omarchy bar move esegnorelli.omacapy --section center
```

## Remove

```bash
omarchy plugin disable esegnorelli.omacapy
omarchy plugin remove esegnorelli.omacapy --yes
# optional: rm ~/.local/state/omarchy/omacapy.json
```

## Requirements

- Omarchy Quattro shell
- Nothing else. No accounts, no network, no extra packages.

## Why

The plugin marketplace is full of VPNs, AI token meters, and printer queues.
OmaCapy exists so your status bar can also host a wet friend who believes in snacks.

## License

MIT

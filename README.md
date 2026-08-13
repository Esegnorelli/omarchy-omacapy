# OmaCapy

![OmaCapy](preview.png)

A bar companion for [Omarchy](https://omarchy.org/) — same shell, same theme, nothing extra to install.

Pet it. Feed it oranges. Soak it. Collect omakase one-liners. When the machine fries, the rodent looks fried too.

Computers can be useful **and** fun.

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

In the lounge, **Side** moves the badge and panel to the left, center, or right of the bar at any time.

State lives in `~/.local/state/omarchy/omacapy.json`. Nothing leaves the machine.

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

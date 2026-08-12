# OmaCapy

A chill **capybara roommate** for your [Omarchy](https://omarchy.org/) bar.

Pet it. Feed it oranges. Dunk it in imaginary water. Collect unserious wisdom.
It watches your load average so when the machine fries, the rodent looks fried too.

Because computers should be useful **and** a little ridiculous.

## Features

- **Animated** bar badge: mood frame cycle + soft pulse (faster when hyped/fried, slower when napping)
- Lounge panel with bounce/spin on actions and floating emoji particles
- Moods: `chill`, `soaked`, `munching`, `napping`, `hyped`, `fried`, `lonely`, `meh`
- Actions: **Pet**, **Orange**, **Soak**, **Wisdom**
- Slow natural decay + night nap regen + CPU-stress vibes from `/proc/loadavg`
- State saved under `~/.local/state/omarchy/omacapy.json`
- Shortcuts on the badge:
  - **Left-click** — open lounge
  - **Middle-click** — quick pet
  - **Right-click** — quick wisdom
  - **Scroll up/down** — pet / orange

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
- Nothing else. No accounts, no network, no packages beyond the desktop you already have.

## Why

The plugin marketplace is full of VPNs, AI token meters, and printer queues.
OmaCapy exists so your status bar can also host a wet friend who believes in snacks.

## License

MIT

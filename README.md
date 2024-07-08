# Nspire Minesweeper

![Preview Photo](calc.png?raw=true)

Minesweeper for the Ti-Nspire! Written in Lua using the student software Script Editor. Upload `minesweeper.tns` to your calculator to begin playing the game yourself.

Features...

- Custom board sizes (albeit capped)
- Chording
- Top 3 times for standard difficulties

---

## Controls

(You can find controls listed on page 1.2 of the document)

### General

| Action            | Keybind | Notes                                  |
| ----------------- | ------- | -------------------------------------- |
| Open / close menu | `M`     | Enter / arrow keys / mouse to navigate |
| Restart game      | `Del`   | Can also click on the smiley face      |

### Gameplay

| Action      | Keybind               | Notes                           |
| ----------- | --------------------- | ------------------------------- |
| Move cursor | all digits except `5` | Can also click on tiles to move |
| Flag        | `+ \| -`              | Flag a number to chord.         |
| Scroll Up   | `^ \| x²`             |                                 |
| Scroll Down | `eˣ \| 10ˣ`           |                                 |

### Quick Flag

| Action                 | Keybind | Notes |
| ---------------------- | ------- | ----- |
| Toggle quick flag mode | `.`     |       |
| Open/flag/chord        | `5`     |       |

# Source

`source.lua` contains the lua script for the game. It is unfortunately not enough to reproduce the entire document, since image resources need to be imported too. I lost the original images; at some point I may try to recover or recreate them.

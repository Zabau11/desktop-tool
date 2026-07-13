# ScreenPet

A tiny native macOS proof of concept for a future desktop creature. The current
version draws a click-through slime that quietly rests in the bottom-right
corner of the primary screen and makes occasional, subtle human-like expressions.

The slime cross-fades its color in response to four user signals:

- Calm: aqua
- Focused: violet
- Active: coral
- Celebrating: green

Choose a signal from the menu-bar control. The same `setUserSignal` path can be
connected to real activity, focus, or success signals later.

## Requirements

- macOS 13 or newer
- Xcode 26 or a compatible Swift 6.2 toolchain

## Run

```sh
swift run ScreenPet
```

ScreenPet runs as a menu-bar accessory, so it does not appear in the Dock. Use
the menu-bar control to hide or show the pet, change its user signal, or quit the
application.

The pet does not monitor clicks or keyboard input and does not require
Accessibility permission. It honors the system Reduce Motion preference,
including applying signal colors without a transition when Reduce Motion is on.

## Test

```sh
swift test
```

The prototype does not request Screen Recording, microphone, or network
permissions.

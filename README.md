# ScreenPet

A tiny native macOS proof of concept for a future desktop creature. The current
version draws a click-through aqua slime that quietly rests in the bottom-right
corner of the primary screen and makes occasional, subtle human-like expressions.

## Requirements

- macOS 13 or newer
- Xcode 26 or a compatible Swift 6.2 toolchain

## Run

```sh
swift run ScreenPet
```

ScreenPet runs as a menu-bar accessory, so it does not appear in the Dock. Use
the menu-bar control to hide or show the pet, or to quit the application.

The pet does not monitor clicks or keyboard input and does not require
Accessibility permission. It honors the system Reduce Motion preference.

## Test

```sh
swift test
```

The prototype does not request Screen Recording, microphone, or network
permissions.

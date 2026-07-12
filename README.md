# ScreenPet

A tiny native macOS proof of concept for a future desktop creature. The current
version draws a click-through marker that gently patrols near the lower edge of
the primary screen.

## Requirements

- macOS 13 or newer
- Xcode 26 or a compatible Swift 6.2 toolchain

## Run

```sh
swift run ScreenPet
```

ScreenPet runs as a menu-bar accessory, so it does not appear in the Dock. Use
the menu-bar control to hide or show the marker, or to quit the application.

## Test

```sh
swift test
```

The prototype does not request Accessibility, Screen Recording, microphone, or
network permissions.

# ScreenPet

A tiny native macOS proof of concept for a future desktop creature. The current
version draws a click-through blob pet that gently patrols near the lower edge of
the primary screen.

## Requirements

- macOS 13 or newer
- Xcode 26 or a compatible Swift 6.2 toolchain

## Run

```sh
swift run ScreenPet
```

ScreenPet runs as a menu-bar accessory, so it does not appear in the Dock. Use
the menu-bar control to hide or show the pet, or to quit the application.

ScreenPet also shows temporary input diagnostics in a bubble above the pet:
`Click detected` for mouse-button presses and `Space pressed` for physical
Space key presses. The latest message remains visible briefly before fading.

Global Space observation requires Accessibility access. At launch, ScreenPet
requests permission if needed. If the prompt does not appear, enable ScreenPet
manually in System Settings > Privacy & Security > Accessibility. The pet
continues running if access is denied; click monitoring remains active where
macOS permits it.

## Test

```sh
swift test
```

The prototype does not request Screen Recording, microphone, or network
permissions.

# AERIS 0.3.1

A smaller, more minimal Apple-inspired macOS virtual island prototype.

## Changes
- Default pill reduced from 280×46 to 224×34 points.
- Removed the decorative green status dot.
- Added subtle Liquid Glass-inspired translucency, layered highlight, and border.
- Battery status is refreshed every 2 seconds to reduce stale charging state.
- Expanded panel is smaller and uses a smoother spring transition.
- Built for Intel Macs (`x86_64`), macOS 14+.

## Build
```sh
chmod +x build.sh
./build.sh
open build/AERIS.app
```

Requires Apple Swift compiler and macOS SDK from compatible Command Line Tools or Xcode.

This is a visual prototype, not Apple's system Dynamic Island. True camera/microphone privacy indicators are not implemented; the decorative green dot was removed rather than implying that it detects camera or microphone use.

## License
MIT.

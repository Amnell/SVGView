# SVGView — Agent Guidelines

SVGView is a Swift Package that parses SVG files into a model tree (`SVGNode` subclasses) and renders them with SwiftUI. It targets iOS, macOS, tvOS, and watchOS; WASI/Linux builds exclude all SwiftUI/CoreGraphics code.

## Build & Test

```bash
swift build
swift test
swift test --filter <TestName>          # run a single test
swift run GenerateReferencesCLI Tests/SVGViewTests/w3c   # regenerate .ref snapshots
```

Tests are snapshot-based: the parsed node tree is serialized to text and compared against a `.ref` file. The visual render is recorded as an attachment only — it does not assert.

### Exporting rendered PNGs for debugging

Pass `--attachments-path <dir>` to write all test attachments (rendered PNG, actual/expected text, diff) to a directory on disk:

```bash
mkdir -p /tmp/svgout
swift test --filter <TestName> --attachments-path /tmp/svgout
# Files written: <TestName>-rendered.png, <TestName>-actual.txt, <TestName>-expected.txt, <TestName>-diff.txt
```

To compare a rendered PNG against the W3C reference image, open the reference URL in a browser:
```
https://www.w3.org/Graphics/SVG/Test/20110816/png/<test-name>.png
```

## Key Directories

| Path | Purpose |
|------|---------|
| `Source/Model/` | SVGNode model classes (shapes, groups, primitives) |
| `Source/Parser/SVG/` | Parser pipeline — `SVGParser`, `SVGIndex`, element parsers, context |
| `Source/Model/Primitives/` | Paint servers: `SVGColor`, `SVGLinearGradient`, `SVGRadialGradient`, `SVGPattern` |
| `Source/UI/` | Platform-specific extensions (`MBezierPath`) |
| `Tests/SVGViewTests/` | Snapshot tests + W3C test SVGs and `.ref` files |
| `GenerateReferencesCLI/` | CLI tool to regenerate `.ref` snapshot files |
| `w3c-coverage.md` | ✅/❌ table of W3C test pass/fail status |

## W3C Test Coverage

`w3c-coverage.md` tracks which W3C conformance tests pass. `w3c-coverage.sh` regenerates it by running the test suite. When a new feature is implemented, add a test to `SVG11Tests.swift` and regenerate the corresponding `.ref` file.

## Reference Docs

- [Architecture & parsing pipeline](.github/docs/architecture.md)
- [Implementing new SVG features](.github/docs/implementing-features.md)

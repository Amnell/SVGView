# Implementing New SVG Features

## Adding a New SVG Element

A renderable element (e.g. `<ellipse>`) needs three things:

### 1. Model class — `Source/Model/Shapes/SVGFoo.swift`

Subclass `SVGShape` (for shapes with fill/stroke) or `SVGNode`. Follow `SVGRect.swift` as a template:
- Store geometry properties under platform guards (`@Published` on Apple, plain `var` on WASI/Linux).
- Override `frame() -> CGRect`.
- Override `serialize(_ serializer:)`.
- Implement `contentView()` + `SVGFooView: View` inside `#if canImport(SwiftUI)`.
- If the element may appear inside a `<pattern>` tile, override `draw(in context: CGContext)` under `#if !os(WASI) && !os(Linux)`.

### 2. Element parser — `Source/Parser/SVG/Elements/`

Create or extend a parser file. Subclass `SVGBaseElementParser` and override `doParse(context:delegate:)`. Use `SVGShapeParser.swift` as a template for shapes. Parse attributes via `SVGHelper` and `context.properties` / `context.styles`.

### 3. Register in `SVGParser.parsers`

```swift
// Source/Parser/SVG/SVGParser.swift
private static let parsers: [String: SVGElementParser] = [
    ...
    "foo": SVGFooParser(),
]
```

Also add a case to `SVGNode.toSwiftUI()` if the new type is a distinct node class.

---

## Adding a New Paint Server

A paint server is resolved from `fill="url(#id)"` or `stroke="url(#id)"`. Follow `SVGPattern` as the most recent example.

### 1. Model class — `Source/Model/Primitives/SVGFooPaint.swift`

Subclass `SVGPaint`. Implement `apply<S>(view: S, model: SVGShape?) -> some View` inside `#if canImport(SwiftUI)` using `@ViewBuilder`. The pattern for overlay masking:

```swift
view
    .foregroundColor(.clear)
    .overlay(
        <fill view>
            .frame(width: bounds.width, height: bounds.height)
            .offset(x: bounds.minX, y: bounds.minY)
            .mask(view)
    )
```

### 2. Register in `SVGIndex`

In `Source/Parser/SVG/SVGIndex.swift`:

```swift
// fill(from:) switch:
case "linearGradient", "radialGradient", "pattern", "myNewType":
    paints[id] = parseFill(element)

// parseFill() switch:
case "myNewType":
    return parseMyNewType(element)
```

Add `parseMyNewType(_ element: XMLElement) -> SVGPaint?`. For `xlink:href` inheritance, look up `paints[id]` and cast — see `getParentGradient()` / `getParentPattern()` for the pattern.

### 3. Wire into `SVGPaint.apply(paint:model:)`

```swift
// Source/Model/Primitives/SVGPaint.swift
case let foo as SVGFooPaint:
    foo.apply(view: self, model: model)
```

---

## Test Workflow

1. **Add the test** to the relevant suite in `Tests/SVGViewTests/SVG11Tests.swift` (or `SVG12Tests.swift` / `SVGCustomTests.swift`):
   ```swift
   @Test func myFeatureTest() async throws { try await compareToReference("my-test-name") }
   ```

2. **Add to the CLI list** in `GenerateReferencesCLI/cli.swift` under `v11Refs` (or `v12Refs` / `customRefs`).

3. **Generate the reference file** — this snapshots the current parser output as the accepted result:
   ```bash
   swift run GenerateReferencesCLI Tests/SVGViewTests/w3c
   ```
   The `.ref` file is written to `Tests/SVGViewTests/w3c/<version>/refs/<name>.ref`.

4. **Run the test** to confirm it passes:
   ```bash
   swift test --filter <TestFunctionName>
   ```

5. **Update `w3c-coverage.md`** — change `❌` to `✅` for the test entry:
   ```bash
   ./w3c-coverage.sh
   ```

> The test compares `Serializer.serialize(node)` text output — it validates the parsed node structure, not pixel output. The rendered PNG is recorded as an attachment for manual inspection but does not assert.

---

## Key Helpers

| Helper | Location | Purpose |
|--------|----------|---------|
| `SVGHelper.parseCGFloat(_:_:defaultValue:)` | `SVGParserBasics.swift` | Parse numeric attribute |
| `SVGHelper.parseFill(_:index:)` | `SVGParserBasics.swift` | Resolve fill paint (color or `url(#...)`) |
| `SVGHelper.parseTransform(_:)` | `SVGParserPrimitives.swift` | Parse `transform` / `*Transform` attribute |
| `SVGHelper.parseColor(_:_:)` | `SVGParserBasics.swift` | Parse color string to `SVGColor` |
| `SVGParser.parseElements(_:index:)` | `SVGParser.swift` | Parse `XMLElement[]` into `SVGNode[]` (used by pattern tile parsing) |

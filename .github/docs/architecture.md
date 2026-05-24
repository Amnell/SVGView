# Architecture & Parsing Pipeline

## Overview

```
SVGParser.parse(xml:)
  │
  ├─ SVGIndex(element:)          ← traverses full XML tree FIRST
  │    ├─ elements[id] = XMLElement
  │    ├─ paints[id]  = SVGPaint  ← linearGradient, radialGradient, pattern
  │    └─ CSSParser               ← <style> blocks
  │
  └─ parse(element:parentContext:)  ← depth-first node tree construction
       └─ SVGNodeContext            ← merges style + property attributes
            └─ parsers[tag]?.parse() → SVGNode
```

`SVGIndex` is built before any `SVGNode` objects exist. Element parsers receive an `SVGNodeContext` that holds the completed index.

## Platform Guards

```swift
#if os(WASI) || os(Linux)          // polyfill only — no SwiftUI, no CoreGraphics
#else
import SwiftUI                     // Apple platforms
#endif

#if canImport(SwiftUI)             // SwiftUI view code
#endif

#if !os(WASI) && !os(Linux)       // CoreGraphics (CGContext, CGColor, etc.)
#endif
```

Always use these guards when touching model, parser, or rendering code.

## Paint Server Resolution

When a shape has `fill="url(#someId)"`:

1. `SVGHelper.parseFill(_:index:)` → `parseFillInternal`
2. `index.paint(by: "someId")` → returns the pre-built `SVGPaint`
3. At render time, `view.apply(paint: model.fill, model: model)` dispatches on type:
   - `SVGLinearGradient` → `LinearGradient` overlay
   - `SVGRadialGradient` → `RadialGradient` overlay
   - `SVGPattern` → `CGBitmapContext` tile → `ImagePaint` overlay
   - `SVGColor` → `.foregroundColor`

`xlink:href` on a paint server (e.g. a gradient or pattern referencing another) is resolved inside `SVGIndex` using `getParentGradient()` / `getParentPattern()`. Property lookup falls back to the parent when an attribute is absent on the child element. Content (stops / tile nodes) is inherited when the child element has no children of its own.

## SVGNode Rendering

Each model class provides its own SwiftUI view inside `#if canImport(SwiftUI)`:

```swift
public class SVGRect: SVGShape {
    public func contentView() -> some View { SVGRectView(model: self) }
}

struct SVGRectView: View {
    @ObservedObject var model: SVGRect
    var body: some View {
        RoundedRectangle(...)
            .applySVGStroke(stroke: model.stroke)
            .applyShapeAttributes(model: model)   // fill + node attributes
            .frame(...).position(...).offset(...)
    }
}
```

`SVGNode.toSwiftUI()` dispatches to the right view via a type switch — add new cases there when adding new node types.

## CGContext Tile Rendering (Patterns)

`SVGPattern` renders its tile using `CGBitmapContext` (thread-safe, no `@MainActor`):

1. Create `CGBitmapContext` at `ceil(width) × ceil(height)` pixels.
2. Flip coordinate system: `translateBy(x:0, y:h); scaleBy(x:1, y:-1)` so y increases downward (matching SVG).
3. Call `node.draw(in: context)` for each tile child — default is no-op; `SVGRect` and `SVGGroup` override it.
4. `context.makeImage()` → `CGImage` → `Image(decorative:scale:1.0)` → `ImagePaint`.

To support additional shapes inside patterns, override `draw(in context: CGContext)` in the shape class under `#if !os(WASI) && !os(Linux)`.

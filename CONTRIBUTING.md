# Contributing: Implementing SVG Spec Features

This guide walks through the end-to-end process of identifying a missing SVG feature, implementing it, and verifying it with tests. It is written for both humans and AI agents.

---

## 1. Find an uncovered feature

Open [`w3c-coverage.md`](w3c-coverage.md). Each section lists W3C conformance tests with ✅ (covered) or ❌ (not yet covered). Look for a category with low coverage and pick a failing test whose description sounds tractable — prefer tests that:

- Use only elements and attributes (no scripting or DOM interaction)
- Have a clear, deterministic pass criterion ("no red on the page", "one green rectangle")
- Aren't dependent on font rendering, animation, or system state

Read the SVG source file for that test to understand exactly what it exercises:

```
Tests/SVGViewTests/w3c/1.1F2/svg/<test-name>.svg
```

---

## 2. Trace the code path

SVGView's parser pipeline:

```
XML bytes
  → DOMParser          (Source/Parser/XML/DOMParser.swift)
  → XMLElement tree
  → SVGParser          (Source/Parser/SVG/SVGParser.swift)
       looks up element name in `parsers` dictionary
       calls the matching SVGElementParser
  → SVGNode model      (Source/Model/)
  → Serializer         (Source/Serialization/Serializer.swift)
  → .ref snapshot string
```

Key files to check:

| File | What to look at |
|------|----------------|
| `SVGParser.swift` | The `parsers` dictionary — if the element name is missing, add an entry |
| `SVGStructureParsers.swift` | Group/Use/Viewport/Switch parsers |
| `SVGShapeParser.swift` | Shape element parsers |
| `SVGElementParser.swift` | `SVGBaseElementParser` — common attribute handling (transform, opacity, clip, markers) |
| `SVGContext.swift` | `SVGNodeContext` — how style and property attributes are resolved |
| `SVGConstants.swift` | `availableStyleAttributes` — CSS properties SVGView recognises |
| `Source/Model/` | The node model classes — add a new model class here if needed |
| `Source/Serialization/Serializations.swift` | Add serialization for any new model fields |

### Example trace: `<switch>` was missing

1. `struct-cond-01-t.svg` used `<switch>` — not in `parsers` dictionary → silently dropped
2. Added `SVGSwitchParser` to `SVGStructureParsers.swift`
3. Registered `"switch": SVGSwitchParser()` in `SVGParser.swift`

---

## 3. Implement the parser

### Adding a parser for an unknown element

If the element produces a renderable node:

1. Subclass `SVGBaseElementParser` and override `doParse(context:delegate:)`
2. Read attributes from `context.properties` (non-style) or via `context.value(_:)` (style)
3. Return the appropriate `SVGNode` subclass (or a new one if needed)
4. Register the parser in `SVGParser.parsers`

```swift
// SVGStructureParsers.swift
class SVGMyFeatureParser: SVGBaseElementParser {
    override func doParse(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> SVGNode? {
        let attrs = context.properties
        // parse attributes, call delegate() for child elements
        return SVGGroup(contents: parseContents(context: context, delegate: delegate))
    }
}

// SVGParser.swift  (add to parsers dict)
"myelement": SVGMyFeatureParser(),
```

### Adding support for a new attribute on existing elements

Most style attributes flow through `SVGContext`. To support a new one:

1. Add the attribute name string to `SVGConstants.availableStyleAttributes`
2. Add a property to the relevant `SVGNode` subclass (with `@Published` on non-Linux)
3. Read it in the element's parser via `context.styles["attribute-name"]`
4. Serialize it in `Serializations.swift`

---

## 4. Add the test

### Add to the test file

Tests live in `Tests/SVGViewTests/SVG11Tests.swift` or `SVG12Tests.swift`, organised in nested `@Suite` structs by category:

```swift
@Suite("Struct")
struct Struct: SVGTestHelper {
    var dir: String { "1.1F2" }

    @Test func myNewTest() throws { try compareToReference("my-test-name") }
}
```

Use the exact W3C file name (without `.svg`) as the argument to `compareToReference`.

### Add to the CLI snapshot list

Open `GenerateReferencesCLI/cli.swift` and add the test name to `v11Refs` (or `v12Refs`):

```swift
static let v11Refs: [String] = [
    // ...
    "my-test-name",
    // ...
]
```

Keep the list alphabetical within each category block.

---

## 5. Generate the reference snapshot

Run the CLI to parse the SVG with the new parser code and write the `.ref` file:

```bash
swift run GenerateReferencesCLI Tests/SVGViewTests/w3c/
```

Or via Make:

```bash
make update-references-snapshots
```

This only works on macOS (the CLI is wrapped in `#if os(macOS)`). The output files land in:

```
Tests/SVGViewTests/w3c/1.1F2/refs/<test-name>.ref
Tests/SVGViewTests/w3c/1.2T/refs/<test-name>.ref
```

**Inspect the generated `.ref` before committing.** The serialized tree should reflect what you expect — correct elements selected, ignored, or transformed. If it looks wrong, fix the parser and re-run.

---

## 6. Run the tests

```bash
# via Xcode / xcodebuild
xcodebuild test -scheme SVGView-Package
```

Or use the Xcode MCP tool:

```
RunAllTests(tabIdentifier: "windowtab3")
```

All previously-passing tests must still pass, and the new ones must pass too.

---

## 7. Update the coverage report

```bash
make w3c-coverage
```

This regenerates `w3c-coverage.md` by counting `.ref` files vs `.svg` files. Commit it alongside the code change.

---

## Checklist

- [ ] Feature traced to a specific missing parser or attribute
- [ ] Parser implemented and registered
- [ ] Test name added to `SVG11Tests.swift` / `SVG12Tests.swift`
- [ ] Test name added to `cli.swift` `v11Refs` / `v12Refs`
- [ ] `.ref` file generated and inspected
- [ ] All tests pass
- [ ] `w3c-coverage.md` regenerated

---

## Tips

- **Start with `requiredExtensions`/`requiredFeatures` tests** — they are fully deterministic and don't depend on fonts, system language, or platform-specific color values.
- **Avoid `systemLanguage` tests** as a first target — the expected output depends on the system locale, making snapshot tests environment-sensitive.
- **The `.ref` file is the ground truth.** If you generate it with a broken parser, the test will pass but cover nothing. Always read the ref and confirm it matches the spec's pass criteria.
- **`SVGBaseElementParser.parse()`** already handles `transform`, `opacity`, `clip-path`, `id`, and markers for every element. Your `doParse()` only needs to handle element-specific attributes.
- **Serialization drives the tests**, not rendering. An element that parses correctly but serializes nothing will not be caught by these tests. Check `Serializations.swift` to ensure new model fields are serialized.

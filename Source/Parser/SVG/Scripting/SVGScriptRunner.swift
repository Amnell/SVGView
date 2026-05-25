import Foundation

#if canImport(JavaScriptCore)
import JavaScriptCore

@objc protocol SVGJSDocumentExports: JSExport {
    var documentElement: SVGJSElement? { get }
    func getElementById(_ id: String) -> SVGJSElement?
}

@objc protocol SVGJSElementExports: JSExport {
    var transform: SVGJSTransformListContainer? { get }
    func createSVGMatrix() -> SVGJSMatrix
    func createSVGTransformFromMatrix(_ matrix: SVGJSMatrix) -> SVGJSTransform
    func setAttribute(_ name: String, _ value: String)
}

@objc protocol SVGJSTransformListContainerExports: JSExport {
    var baseVal: SVGJSTransformList { get }
}

@objc protocol SVGJSTransformListExports: JSExport {
    func getItem(_ index: Int) -> SVGJSTransform?
    func createSVGTransformFromMatrix(_ matrix: SVGJSMatrix) -> SVGJSTransform
}

@objc protocol SVGJSTransformExports: JSExport {
    var type: Int { get }
    var matrix: SVGJSMatrix { get }
    func setTranslate(_ tx: Double, _ ty: Double)
    func setScale(_ sx: Double, _ sy: Double)
    func setRotate(_ angle: Double, _ cx: Double, _ cy: Double)
    func setMatrix(_ matrix: SVGJSMatrix)
}

@objc protocol SVGJSMatrixExports: JSExport {
    var a: Double { get set }
    var b: Double { get set }
    var c: Double { get set }
    var d: Double { get set }
    var e: Double { get set }
    var f: Double { get set }
}

@objcMembers
final class SVGJSDocument: NSObject, SVGJSDocumentExports {
    private let root: SVGNode

    init(root: SVGNode) {
        self.root = root
    }

    var documentElement: SVGJSElement? {
        SVGJSElement(node: root)
    }

    func getElementById(_ id: String) -> SVGJSElement? {
        guard let node = root.getNode(byId: id) else {
            return nil
        }
        return SVGJSElement(node: node)
    }
}

@objcMembers
final class SVGJSElement: NSObject, SVGJSElementExports {
    private let node: SVGNode

    init(node: SVGNode) {
        self.node = node
    }

    var transform: SVGJSTransformListContainer? {
        SVGJSTransformListContainer(node: node)
    }

    func createSVGMatrix() -> SVGJSMatrix {
        SVGJSMatrix()
    }

    func createSVGTransformFromMatrix(_ matrix: SVGJSMatrix) -> SVGJSTransform {
        SVGJSTransform(components: matrix.componentsSnapshot())
    }

    func setAttribute(_ name: String, _ value: String) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        switch normalizedName {
        case "fill":
            setFill(normalizedValue)
        case "color":
            setColor(normalizedValue)
        case "opacity":
            if let parsedOpacity = Double(normalizedValue) {
                node.opacity = min(max(parsedOpacity, 0), 1)
            }
        case "visibility":
            node.opaque = normalizedValue.lowercased() != "hidden"
        case "display":
            node.opaque = normalizedValue.lowercased() != "none"
        case "transform":
            node.transform = SVGHelper.parseTransform(normalizedValue)
        case "stroke":
            setStroke(normalizedValue)
        case "stroke-width":
            setStrokeWidth(normalizedValue)
        case "fill-opacity":
            setFillOpacity(normalizedValue)
        case "stroke-opacity":
            setStrokeOpacity(normalizedValue)
        case "stroke-dasharray":
            setStrokeDashArray(normalizedValue)
        case "stroke-dashoffset":
            setStrokeDashOffset(normalizedValue)
        case "stroke-linecap":
            setStrokeLineCap(normalizedValue)
        case "stroke-linejoin":
            setStrokeLineJoin(normalizedValue)
        case "stroke-miterlimit":
            setStrokeMiterLimit(normalizedValue)
        case "fill-rule":
            setFillRule(normalizedValue)
        default:
            break
        }
    }

    private func setColor(_ value: String) {
        guard let color = SVGHelper.parseColor(value, [:]) else { return }
        node.hasExplicitCurrentColor = true
        propagateCurrentColor(color, to: node, forceCurrentNode: true)
    }

    private func setFill(_ value: String) {
        if let shape = node as? SVGShape {
            if value.lowercased() == "currentcolor" {
                shape.fillUsesCurrentColor = true
                shape.fill = node.currentColor ?? SVGColor.black
                return
            }

            shape.fillUsesCurrentColor = false
            shape.fill = SVGHelper.parseColor(value, [:])
            return
        }

        if let text = node as? SVGText {
            if value.lowercased() == "currentcolor" {
                text.fillUsesCurrentColor = true
                text.fill = node.currentColor ?? SVGColor.black
                return
            }

            text.fillUsesCurrentColor = false
            text.fill = SVGHelper.parseColor(value, [:])
        }
    }

    private func setStroke(_ value: String) {
        if let shape = node as? SVGShape {
            if value.lowercased() == "none" {
                shape.strokeUsesCurrentColor = false
                shape.stroke = nil
                return
            }

            if value.lowercased() == "currentcolor" {
                shape.strokeUsesCurrentColor = true
                let currentOpacity = (shape.stroke?.fill as? SVGColor)?.opacity ?? 1
                replaceStrokeFill(for: shape, with: (node.currentColor ?? SVGColor.black).opacity(currentOpacity))
                return
            }

            guard let color = SVGHelper.parseColor(value, [:]) else { return }
            shape.strokeUsesCurrentColor = false
            replaceStrokeFill(for: shape, with: color)
            return
        }

        if let text = node as? SVGText {
            if value.lowercased() == "none" {
                text.strokeUsesCurrentColor = false
                text.stroke = nil
                return
            }

            if value.lowercased() == "currentcolor" {
                text.strokeUsesCurrentColor = true
                let currentOpacity = (text.stroke?.fill as? SVGColor)?.opacity ?? 1
                replaceStrokeFill(for: text, with: (node.currentColor ?? SVGColor.black).opacity(currentOpacity))
                return
            }

            guard let color = SVGHelper.parseColor(value, [:]) else { return }
            text.strokeUsesCurrentColor = false
            replaceStrokeFill(for: text, with: color)
        }
    }

    private func setStrokeWidth(_ value: String) {
        guard let shape = node as? SVGShape,
              let width = SVGHelper.doubleFromString(value)
        else { return }

        let current = shape.stroke
        shape.stroke = SVGStroke(
            fill: current?.fill ?? SVGColor.black,
            width: CGFloat(width),
            cap: current?.cap ?? .butt,
            join: current?.join ?? .miter,
            miterLimit: current?.miterLimit ?? 4,
            dashes: current?.dashes ?? [],
            offset: current?.offset ?? 0
        )
    }

    private func setFillOpacity(_ value: String) {
        guard let opacity = SVGHelper.doubleFromString(value) else { return }
        let clamped = min(max(opacity, 0), 1)

        if let shape = node as? SVGShape,
           let fill = shape.fill {
            shape.fill = fill.opacity(clamped)
            return
        }

        if let text = node as? SVGText,
           let fill = text.fill {
            text.fill = fill.opacity(clamped)
        }
    }

    private func setStrokeOpacity(_ value: String) {
        guard let opacity = SVGHelper.doubleFromString(value) else { return }
        let clamped = min(max(opacity, 0), 1)

        if let shape = node as? SVGShape,
           let current = shape.stroke {
            shape.stroke = SVGStroke(
                fill: current.fill.opacity(clamped),
                width: current.width,
                cap: current.cap,
                join: current.join,
                miterLimit: current.miterLimit,
                dashes: current.dashes,
                offset: current.offset
            )
            return
        }

        if let text = node as? SVGText,
           let current = text.stroke {
            text.stroke = SVGStroke(
                fill: current.fill.opacity(clamped),
                width: current.width,
                cap: current.cap,
                join: current.join,
                miterLimit: current.miterLimit,
                dashes: current.dashes,
                offset: current.offset
            )
        }
    }

    private func setStrokeDashArray(_ value: String) {
        guard let shape = node as? SVGShape,
              let current = shape.stroke
        else { return }

        let dashes: [CGFloat]
        if value.lowercased() == "none" {
            dashes = []
        } else {
            let parts = value.components(separatedBy: CharacterSet(charactersIn: " ,"))
                .filter { !$0.isEmpty }
            dashes = parts.compactMap { token in
                guard let parsed = SVGHelper.doubleFromString(token) else { return nil }
                return CGFloat(parsed)
            }
        }

        shape.stroke = SVGStroke(
            fill: current.fill,
            width: current.width,
            cap: current.cap,
            join: current.join,
            miterLimit: current.miterLimit,
            dashes: dashes,
            offset: current.offset
        )
    }

    private func setStrokeDashOffset(_ value: String) {
        guard let shape = node as? SVGShape,
              let current = shape.stroke,
              let offset = SVGHelper.doubleFromString(value)
        else { return }

        shape.stroke = SVGStroke(
            fill: current.fill,
            width: current.width,
            cap: current.cap,
            join: current.join,
            miterLimit: current.miterLimit,
            dashes: current.dashes,
            offset: CGFloat(offset)
        )
    }

    private func setStrokeLineCap(_ value: String) {
        guard let shape = node as? SVGShape,
              let current = shape.stroke
        else { return }

        let cap: CGLineCap
        switch value.lowercased() {
        case "round":
            cap = .round
        case "square":
            cap = .square
        default:
            cap = .butt
        }

        shape.stroke = SVGStroke(
            fill: current.fill,
            width: current.width,
            cap: cap,
            join: current.join,
            miterLimit: current.miterLimit,
            dashes: current.dashes,
            offset: current.offset
        )
    }

    private func setStrokeLineJoin(_ value: String) {
        guard let shape = node as? SVGShape,
              let current = shape.stroke
        else { return }

        let join: CGLineJoin
        switch value.lowercased() {
        case "round":
            join = .round
        case "bevel":
            join = .bevel
        default:
            join = .miter
        }

        shape.stroke = SVGStroke(
            fill: current.fill,
            width: current.width,
            cap: current.cap,
            join: join,
            miterLimit: current.miterLimit,
            dashes: current.dashes,
            offset: current.offset
        )
    }

    private func setStrokeMiterLimit(_ value: String) {
        guard let shape = node as? SVGShape,
              let current = shape.stroke,
              let miterLimit = SVGHelper.doubleFromString(value)
        else { return }

        shape.stroke = SVGStroke(
            fill: current.fill,
            width: current.width,
            cap: current.cap,
            join: current.join,
            miterLimit: CGFloat(miterLimit),
            dashes: current.dashes,
            offset: current.offset
        )
    }

    private func setFillRule(_ value: String) {
        guard let path = node as? SVGPath else { return }
        path.fillRule = value.lowercased() == "evenodd" ? .evenOdd : .winding
    }

    private func replaceStrokeFill(for shape: SVGShape, with fill: SVGPaint) {
        let current = shape.stroke
        shape.stroke = SVGStroke(
            fill: fill,
            width: current?.width ?? 1,
            cap: current?.cap ?? .butt,
            join: current?.join ?? .miter,
            miterLimit: current?.miterLimit ?? 4,
            dashes: current?.dashes ?? [],
            offset: current?.offset ?? 0
        )
    }

    private func replaceStrokeFill(for text: SVGText, with fill: SVGPaint) {
        let current = text.stroke
        text.stroke = SVGStroke(
            fill: fill,
            width: current?.width ?? 1,
            cap: current?.cap ?? .butt,
            join: current?.join ?? .miter,
            miterLimit: current?.miterLimit ?? 4,
            dashes: current?.dashes ?? [],
            offset: current?.offset ?? 0
        )
    }

    private func propagateCurrentColor(_ color: SVGColor, to node: SVGNode, forceCurrentNode: Bool = false) {
        let resolvedColor: SVGColor
        if node.hasExplicitCurrentColor && !forceCurrentNode {
            resolvedColor = node.currentColor ?? color
            node.currentColor = resolvedColor
        } else {
            node.currentColor = color
            resolvedColor = color
        }

        applyCurrentColorBindings(on: node)

        if let group = node as? SVGGroup {
            for child in group.contents {
                propagateCurrentColor(resolvedColor, to: child)
            }
        }

        if let userSpaceNode = node as? SVGUserSpaceNode {
            propagateCurrentColor(resolvedColor, to: userSpaceNode.node)
        }
    }

    private func applyCurrentColorBindings(on node: SVGNode) {
        guard let currentColor = node.currentColor else { return }

        if let shape = node as? SVGShape {
            if shape.fillUsesCurrentColor {
                shape.fill = currentColor
            }
            if shape.strokeUsesCurrentColor {
                let currentOpacity = (shape.stroke?.fill as? SVGColor)?.opacity ?? 1
                replaceStrokeFill(for: shape, with: currentColor.opacity(currentOpacity))
            }
        }

        if let text = node as? SVGText {
            if text.fillUsesCurrentColor {
                text.fill = currentColor
            }
            if text.strokeUsesCurrentColor {
                let currentOpacity = (text.stroke?.fill as? SVGColor)?.opacity ?? 1
                replaceStrokeFill(for: text, with: currentColor.opacity(currentOpacity))
            }
        }
    }
}

@objcMembers
final class SVGJSTransformListContainer: NSObject, SVGJSTransformListContainerExports {
    let baseVal: SVGJSTransformList

    init(node: SVGNode) {
        self.baseVal = SVGJSTransformList(node: node)
    }
}

@objcMembers
final class SVGJSTransformList: NSObject, SVGJSTransformListExports {
    private let transform: SVGJSTransform

    init(node: SVGNode) {
        self.transform = SVGJSTransform(node: node)
    }

    func getItem(_ index: Int) -> SVGJSTransform? {
        index == 0 ? transform : nil
    }

    func createSVGTransformFromMatrix(_ matrix: SVGJSMatrix) -> SVGJSTransform {
        SVGJSTransform(components: matrix.componentsSnapshot())
    }
}

@objcMembers
final class SVGJSTransform: NSObject, SVGJSTransformExports {
    static let svgTransformUnknown = 0
    static let svgTransformMatrix = 1
    static let svgTransformTranslate = 2
    static let svgTransformScale = 3
    static let svgTransformRotate = 4
    static let svgTransformSkewX = 5
    static let svgTransformSkewY = 6

    private weak var node: SVGNode?
    private(set) var matrixModel: SVGJSMatrix!
    var components: (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)
    var type: Int = svgTransformMatrix

    var matrix: SVGJSMatrix {
        matrixModel
    }

    init(node: SVGNode?) {
        self.node = node
        let t = node?.transform ?? .identity
        self.components = (
            a: Double(t.a),
            b: Double(t.b),
            c: Double(t.c),
            d: Double(t.d),
            e: Double(t.tx),
            f: Double(t.ty)
        )
        super.init()
        self.matrixModel = SVGJSMatrix(owner: self)
    }

    init(components: (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)) {
        self.node = nil
        self.components = components
        super.init()
        self.matrixModel = SVGJSMatrix(owner: self)
    }

    func setTranslate(_ tx: Double, _ ty: Double) {
        type = Self.svgTransformTranslate
        components = (a: 1, b: 0, c: 0, d: 1, e: tx, f: ty)
        applyToNode()
    }

    func setScale(_ sx: Double, _ sy: Double) {
        type = Self.svgTransformScale
        components = (a: sx, b: 0, c: 0, d: sy, e: 0, f: 0)
        applyToNode()
    }

    func setRotate(_ angle: Double, _ cx: Double, _ cy: Double) {
        type = Self.svgTransformRotate
        let rotation = CGAffineTransform.identity
            .translatedBy(x: cx, y: cy)
            .rotated(by: CGFloat(angle * .pi / 180.0))
            .translatedBy(x: -cx, y: -cy)
        components = (
            a: Double(rotation.a),
            b: Double(rotation.b),
            c: Double(rotation.c),
            d: Double(rotation.d),
            e: Double(rotation.tx),
            f: Double(rotation.ty)
        )
        applyToNode()
    }

    func setMatrix(_ matrix: SVGJSMatrix) {
        type = Self.svgTransformMatrix
        components = matrix.componentsSnapshot()
        applyToNode()
    }

    func setComponent(_ keyPath: WritableKeyPath<(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double), Double>, _ value: Double) {
        type = Self.svgTransformMatrix
        components[keyPath: keyPath] = value
        applyToNode()
    }

    func component(_ keyPath: KeyPath<(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double), Double>) -> Double {
        components[keyPath: keyPath]
    }

    private func applyToNode() {
        node?.transform = CGAffineTransform(
            a: CGFloat(components.a),
            b: CGFloat(components.b),
            c: CGFloat(components.c),
            d: CGFloat(components.d),
            tx: CGFloat(components.e),
            ty: CGFloat(components.f)
        )
    }
}

@objcMembers
final class SVGJSMatrix: NSObject, SVGJSMatrixExports {
    private weak var owner: SVGJSTransform?
    private var detachedComponents: (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    override init() {
        self.detachedComponents = (a: 1, b: 0, c: 0, d: 1, e: 0, f: 0)
        super.init()
    }

    init(owner: SVGJSTransform) {
        self.owner = owner
        self.detachedComponents = (a: 1, b: 0, c: 0, d: 1, e: 0, f: 0)
    }

    func componentsSnapshot() -> (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) {
        if let owner {
            return (
                a: owner.component(\.a),
                b: owner.component(\.b),
                c: owner.component(\.c),
                d: owner.component(\.d),
                e: owner.component(\.e),
                f: owner.component(\.f)
            )
        }
        return detachedComponents
    }

    private func setComponent(_ keyPath: WritableKeyPath<(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double), Double>, _ value: Double) {
        if let owner {
            owner.setComponent(keyPath, value)
            return
        }
        detachedComponents[keyPath: keyPath] = value
    }

    private func component(_ keyPath: KeyPath<(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double), Double>) -> Double {
        if let owner {
            return owner.component(keyPath)
        }
        return detachedComponents[keyPath: keyPath]
    }

    var a: Double {
        get { component(\.a) }
        set { setComponent(\.a, newValue) }
    }

    var b: Double {
        get { component(\.b) }
        set { setComponent(\.b, newValue) }
    }

    var c: Double {
        get { component(\.c) }
        set { setComponent(\.c, newValue) }
    }

    var d: Double {
        get { component(\.d) }
        set { setComponent(\.d, newValue) }
    }

    var e: Double {
        get { component(\.e) }
        set { setComponent(\.e, newValue) }
    }

    var f: Double {
        get { component(\.f) }
        set { setComponent(\.f, newValue) }
    }
}
#endif

enum SVGScriptRunner {

    private static let supportedScriptMIMETypes: Set<String> = [
        "application/ecmascript",
        "application/javascript",
        "application/x-ecmascript",
        "application/x-javascript",
        "text/ecmascript",
        "text/javascript",
        "text/jscript",
    ]

    private static let defaultScriptMIMEType = "application/ecmascript"

    static func executeIfNeeded(xmlRoot: XMLElement, nodeRoot: SVGNode, logger: SVGLogger) {
#if canImport(JavaScriptCore)
        let scripts = collectScripts(from: xmlRoot)
        guard !scripts.isEmpty else { return }

        guard let context = JSContext() else {
            logger.log(message: "Failed to create JavaScript context")
            return
        }

        let document = SVGJSDocument(root: nodeRoot)
        context.setObject(document, forKeyedSubscript: "document" as NSString)

        let constants: [String: Int] = [
            "SVG_TRANSFORM_UNKNOWN": SVGJSTransform.svgTransformUnknown,
            "SVG_TRANSFORM_MATRIX": SVGJSTransform.svgTransformMatrix,
            "SVG_TRANSFORM_TRANSLATE": SVGJSTransform.svgTransformTranslate,
            "SVG_TRANSFORM_SCALE": SVGJSTransform.svgTransformScale,
            "SVG_TRANSFORM_ROTATE": SVGJSTransform.svgTransformRotate,
            "SVG_TRANSFORM_SKEWX": SVGJSTransform.svgTransformSkewX,
            "SVG_TRANSFORM_SKEWY": SVGJSTransform.svgTransformSkewY,
        ]
        context.setObject(constants, forKeyedSubscript: "SVGTransform" as NSString)

        context.exceptionHandler = { _, exception in
            if let exception {
                logger.log(message: "Script error: \(exception)")
            }
        }

        for script in scripts {
            _ = context.evaluateScript(script)
        }
#else
        _ = xmlRoot
        _ = nodeRoot
        _ = logger
#endif
    }

    private static func collectScripts(from root: XMLElement) -> [String] {
        var result: [String] = []

        let explicitDefaultType = root.attributes["contentScriptType"]
        let defaultScriptType: String? = {
            if let explicitDefaultType {
                return normalizedSupportedScriptType(explicitDefaultType)
            }
            return defaultScriptMIMEType
        }()

        func walk(_ element: XMLElement) {
            if element.name == "script" {
                let hasExplicitType = element.attributes["type"] != nil
                let effectiveType: String? = {
                    if let scriptType = element.attributes["type"] {
                        return normalizedSupportedScriptType(scriptType)
                    }
                    return hasExplicitType ? nil : defaultScriptType
                }()

                guard effectiveType != nil else { return }

                let script = element.contents
                    .compactMap { ($0 as? XMLText)?.text }
                    .joined()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !script.isEmpty {
                    result.append(script)
                }
            }

            for child in element.contents.compactMap({ $0 as? XMLElement }) {
                walk(child)
            }
        }

        walk(root)
        return result
    }

    private static func normalizedSupportedScriptType(_ rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let typeOnly = trimmed
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: true)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard let typeOnly else { return nil }
        return supportedScriptMIMETypes.contains(typeOnly) ? typeOnly : nil
    }
}
import Foundation

#if canImport(JavaScriptCore)
import JavaScriptCore

@objc protocol SVGJSDocumentExports: JSExport {
    func getElementById(_ id: String) -> SVGJSElement?
}

@objc protocol SVGJSElementExports: JSExport {
    var transform: SVGJSTransformListContainer? { get }
    func setAttribute(_ name: String, _ value: String)
}

@objc protocol SVGJSTransformListContainerExports: JSExport {
    var baseVal: SVGJSTransformList { get }
}

@objc protocol SVGJSTransformListExports: JSExport {
    func getItem(_ index: Int) -> SVGJSTransform?
}

@objc protocol SVGJSTransformExports: JSExport {
    var type: Int { get }
    var matrix: SVGJSMatrix { get }
    func setTranslate(_ tx: Double, _ ty: Double)
    func setScale(_ sx: Double, _ sy: Double)
    func setRotate(_ angle: Double, _ cx: Double, _ cy: Double)
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

    func setAttribute(_ name: String, _ value: String) {
        if name == "fill", let shape = node as? SVGShape {
            shape.fill = SVGHelper.parseColor(value, [:])
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

    init(node: SVGNode) {
        self.node = node
        let t = node.transform
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

    init(owner: SVGJSTransform) {
        self.owner = owner
    }

    var a: Double {
        get { owner?.component(\.a) ?? 1 }
        set { owner?.setComponent(\.a, newValue) }
    }

    var b: Double {
        get { owner?.component(\.b) ?? 0 }
        set { owner?.setComponent(\.b, newValue) }
    }

    var c: Double {
        get { owner?.component(\.c) ?? 0 }
        set { owner?.setComponent(\.c, newValue) }
    }

    var d: Double {
        get { owner?.component(\.d) ?? 1 }
        set { owner?.setComponent(\.d, newValue) }
    }

    var e: Double {
        get { owner?.component(\.e) ?? 0 }
        set { owner?.setComponent(\.e, newValue) }
    }

    var f: Double {
        get { owner?.component(\.f) ?? 0 }
        set { owner?.setComponent(\.f, newValue) }
    }
}
#endif

enum SVGScriptRunner {

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

        func walk(_ element: XMLElement) {
            if element.name == "script" {
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
}
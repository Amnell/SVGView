//
//  SVGIndex.swift
//  SVGView
//
//  Created by Yuriy Strot on 21.02.2021.
//

#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
#endif

class SVGIndex {

    private var elements = [String: XMLElement]()
    private var paints = [String: SVGPaint]()
    private var cssParser = CSSParser()

    init(element: XMLElement) {
        fill(from: element)
    }

    func element(by id: String) -> XMLElement? {
        elements[id]
    }

    func paint(by id: String) -> SVGPaint? {
        paints[id]
    }

    func cssStyle(for element: XMLElement) -> [String: String] {
        cssParser.getStyles(element: element)
    }

    private func fill(from element: XMLElement) {
        if let id = SVGHelper.parseId(element.attributes) {
            elements[id] = element
            switch element.name {
            case "linearGradient", "radialGradient", "fill", "pattern":
                paints[id] = parseFill(element)
            default:
                elements[id] = element
            }
        }
        // css style
        if element.name == "style", let textNode = element.contents.first as? XMLText {
            cssParser.parse(content: textNode.text)
        }
        for child in element.contents {
            if let child = child as? XMLElement {
                fill(from: child)
            }
        }
    }

    private func parseFill(_ element: XMLElement) -> SVGPaint? {
        switch element.name {
        case "linearGradient":
            return parseLinearGradient(element)
        case "radialGradient":
            return parseRadialGradient(element)
        case "pattern":
            return parsePattern(element)
        default:
            return .none
        }
    }

    private func getParentPattern(_ element: XMLElement) -> SVGPattern? {
        if let link = element.attributes["xlink:href"]?.replacingOccurrences(of: " ", with: ""), link.hasPrefix("#") {
            let id = link.replacingOccurrences(of: "#", with: "")
            return paints[id] as? SVGPattern
        }
        return nil
    }

    private func parsePattern(_ element: XMLElement) -> SVGPattern? {
        let parent = getParentPattern(element)
        let childElements = element.contents.compactMap { $0 as? XMLElement }
        let contents: [SVGNode]
        if childElements.isEmpty {
            contents = parent?.contents ?? []
        } else {
            contents = SVGParser.parseElements(childElements, index: self)
        }
        guard !contents.isEmpty else { return nil }
        let x = SVGHelper.parseCGFloat(element.attributes, "x", defaultValue: parent?.x ?? 0)
        let y = SVGHelper.parseCGFloat(element.attributes, "y", defaultValue: parent?.y ?? 0)
        let width = SVGHelper.parseCGFloat(element.attributes, "width", defaultValue: parent?.width ?? 0)
        let height = SVGHelper.parseCGFloat(element.attributes, "height", defaultValue: parent?.height ?? 0)
        guard width > 0, height > 0 else { return nil }
        var userSpace = parent?.userSpace ?? false
        if let patternUnits = element.attributes["patternUnits"] {
            userSpace = patternUnits == "userSpaceOnUse"
        }
        var patternTransform = parent?.patternTransform ?? .identity
        if let transformStr = element.attributes["patternTransform"] {
            patternTransform = SVGHelper.parseTransform(transformStr)
        }
        return SVGPattern(x: x, y: y, width: width, height: height,
                          userSpace: userSpace, patternTransform: patternTransform,
                          contents: contents)
    }

    private func getParentGradient(_ element: XMLElement) -> SVGGradient? {
        if let link = element.attributes["xlink:href"]?.replacingOccurrences(of: " ", with: ""), link.hasPrefix("#") {

            let id = link.replacingOccurrences(of: "#", with: "")
            return paints[id] as? SVGGradient
        }
        return nil
    }

    private func parseLinearGradient(_ element: XMLElement) -> SVGPaint? {
        let parent = getParentGradient(element)

        let stops = element.contents.isEmpty ? (parent?.stops ?? []) : parseStops(element.contents, element.attributes)

        switch stops.count {
        case 0:
            return .none
        case 1:
            return stops.first!.color
        default:
            break
        }

        let plg = parent as? SVGLinearGradient
        var x1 = getDoubleValueFromPercentage(element, attribute: "x1", defaultValue: plg?.x1 ?? 0)
        var y1 = getDoubleValueFromPercentage(element, attribute: "y1", defaultValue: plg?.y1 ?? 0)
        var x2 = getDoubleValueFromPercentage(element, attribute: "x2", defaultValue: plg?.x2 ?? 1)
        var y2 = getDoubleValueFromPercentage(element, attribute: "y2", defaultValue: plg?.y2 ?? 0)

        var userSpace = false
        if let gradientUnits = element.attributes["gradientUnits"], gradientUnits == "userSpaceOnUse" {
            userSpace = true
        } else if let pg = parent {
            userSpace = pg.userSpace
        }

        if let gradientTransform = element.attributes["gradientTransform"] {
            let transform = SVGHelper.parseTransform(gradientTransform)

            let point1 = CGPoint(x: x1, y: y1).applying(transform)
            x1 = point1.x
            y1 = point1.y

            let point2 = CGPoint(x: x2, y: y2).applying(transform)
            x2 = point2.x
            y2 = point2.y
        }
        
        return SVGLinearGradient(x1: x1, y1: y1, x2: x2, y2: y2, userSpace: userSpace, stops: stops)
    }

    private func parseRadialGradient(_ element: XMLElement) -> SVGPaint? {
        let parent = getParentGradient(element)
        let stops = element.contents.isEmpty ? (parent?.stops ?? []) : parseStops(element.contents, element.attributes)

        switch stops.count {
        case 0:
            return .none
        case 1:
            return stops.first!.color
        default:
            break
        }

        let prg = parent as? SVGRadialGradient
        var cx = getDoubleValueFromPercentage(element, attribute: "cx", defaultValue: prg?.cx ?? 0.5)
        var cy = getDoubleValueFromPercentage(element, attribute: "cy", defaultValue: prg?.cy ?? 0.5)
        var fx = getDoubleValueFromPercentage(element, attribute: "fx", defaultValue: prg?.fx ?? cx)
        var fy = getDoubleValueFromPercentage(element, attribute: "fy", defaultValue: prg?.fy ?? cy)
        var r = getDoubleValueFromPercentage(element, attribute: "r", defaultValue: prg?.r ?? 0.5)

        var userSpace = false
        if let gradientUnits = element.attributes["gradientUnits"], gradientUnits == "userSpaceOnUse" {
            userSpace = true
        } else if let p = parent {
            userSpace = p.userSpace
        }

        var gradientTransform: CGAffineTransform = .identity
        if let gradientTransformAttr = element.attributes["gradientTransform"] {
            gradientTransform = SVGHelper.parseTransform(gradientTransformAttr)
        }

        return SVGRadialGradient(cx: cx, cy: cy, fx: fx, fy: fy, r: r, userSpace: userSpace, gradientTransform: gradientTransform, stops: stops)
    }

    private func parseStops(_ nodes: [XMLNode], _ style: [String: String]) -> [SVGStop] {
        var result = [SVGStop]()
        for node in nodes {
            if let element = node as? XMLElement {
                if let stop = parseStop(element, style) {
                    result.append(stop)
                }
            }
        }
        return result
    }

    private func parseStop(_ element: XMLElement, _ style: [String: String]) -> SVGStop? {
        let offset = getDoubleValueFromPercentage(element, attribute: "offset")

        var opacity: Double = 1
        if let stopOpacity = element.attributes["stop-opacity"], let doubleValue = Double(stopOpacity) {
            opacity = doubleValue
        }
        var color = SVGColor.black.opacity(opacity)
        if let stopColor = element.attributes["stop-color"], let clr = SVGHelper.parseColor(stopColor, style) {
            color = clr.opacity(opacity)
        }
        return SVGStop(color: color, offset: offset)
    }

    private func getDoubleValueFromPercentage(_ element: XMLElement, attribute: String, defaultValue: CGFloat = 0) -> CGFloat {
        guard let attributeValue = element.attributes[attribute] else {
            return defaultValue
        }
        if !attributeValue.contains("%") {
            return SVGHelper.parseCGFloat(element.attributes, attribute, defaultValue: defaultValue)
        } else {
            let value = attributeValue.replacingOccurrences(of: "%", with: "")
            if let doubleValue = Double(value) {
                return CGFloat(doubleValue / 100)
            }
        }
        return defaultValue
    }

}

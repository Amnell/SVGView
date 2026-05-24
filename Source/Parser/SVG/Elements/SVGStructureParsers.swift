//
//  SVGStructure.swift
//  SVGView
//
//  Created by Yuri Strot on 29.05.2022.
//

import Foundation

class SVGViewportParser: SVGGroupParser {

    override func doParse(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> SVGNode? {
        let attributes = context.properties

        let w = SVGHelper.parseDimension(attributes, "width") ?? SVGLength(percent: 100)
        let h = SVGHelper.parseDimension(attributes, "height") ?? SVGLength(percent: 100)
        let viewBox = SVGHelper.parseViewBox(attributes, context: context)
        let par = SVGHelper.parsePreserveAspectRatio(string: attributes["preserveAspectRatio"], context: context, defaultValue: SVGPreserveAspectRatio(scaling: SVGHelper.parseScaling("meet"), xAlign: .mid, yAlign: .mid))
        return SVGViewport(width: w, height: h, viewBox: viewBox, preserveAspectRatio: par, contents: parseContents(context: context, delegate: delegate))
    }

    static func parseAlign(_ string: String) -> SVGPreserveAspectRatio.Align {
        switch string {
            case "min": return .min
            case "max": return .max
            default: return .mid
        }
    }

    static func parseScaling(_ string: String) -> SVGPreserveAspectRatio.Scaling {
        switch string {
            case "meet": return .meet
            case "slice": return .slice
            default: return .none
        }
    }

}

class SVGGroupParser: SVGBaseElementParser {

    override func doParse(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> SVGNode? {
        return SVGGroup(contents: parseContents(context: context, delegate: delegate))
    }

    func parseContents(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> [SVGNode] {
        return context.element.contents
            .compactMap { $0 as? XMLElement }
            .compactMap { delegate($0) }
    }

}

class SVGUseParser: SVGBaseElementParser {

    override func doParse(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> SVGNode? {
        guard let useId = context.properties["xlink:href"]?.replacingOccurrences(of: "#", with: ""),
              let def = context.index.element(by: useId),
              let useNode = delegate(def) else {
            return nil
        }
        useNode.transform = CGAffineTransform(
            translationX: SVGHelper.parseCGFloat(context.properties, "x"),
            y: SVGHelper.parseCGFloat(context.properties, "y"))
        return useNode
    }
}

class SVGVDefParser: SVGGroupParser {
    override func doParse(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> SVGNode? {
        return SVGDefs(contents: parseContents(context: context, delegate: delegate))
    }

    override func parseContents(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> [SVGNode] {
        return context.element.contents
            .compactMap { $0 as? XMLElement }
            .compactMap { delegate($0) }
    }
}

class SVGMarkerParser: SVGBaseElementParser {

    override func doParse(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> SVGNode? {
        let attributes = context.properties

        let markerWidth = SVGHelper.parseDimension(attributes, "markerWidth") ?? SVGLength(percent: 100)
        let markerHeight = SVGHelper.parseDimension(attributes, "markerHeight") ?? SVGLength(percent: 100)
        let markerUnits = Self.parseMarkerUnits(attributes["markerUnits"])
        let orient = Self.parseOrient(attributes["orient"])
        let viewBox = SVGHelper.parseViewBox(attributes, context: context)
        let par = SVGHelper.parsePreserveAspectRatio(string: attributes["preserveAspectRatio"], context: context, defaultValue: SVGPreserveAspectRatio(scaling: SVGHelper.parseScaling("meet"), xAlign: .mid, yAlign: .mid))
        let refX = Self.parseRefMagnitude(attributes, "refX")
        let refY = Self.parseRefMagnitude(attributes, "refY")
        return SVGMarker(markerHeight: markerHeight, markerUnits: markerUnits, markerWidth: markerWidth, orient: orient, preserveAspectRatio: par, refX: refX, refY: refY, viewBox: viewBox, contents: parseContents(context: context, delegate: delegate))
    }

    func parseContents(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> [SVGNode] {
        return context.element.contents
            .compactMap { $0 as? XMLElement }
            .compactMap { delegate($0) }
    }

    static func parseMarkerUnits(_ string: String?) -> SVGMarker.MarkerUnits {
        if let anchor = string {
            if anchor == "userSpaceOnUse" {
                return .userSpaceOnUse
            } else if anchor == "strokeWidth" {
                return .strokeWidth
            }
        }
        return .strokeWidth
    }

    static func parseOrient(_ value: String?) -> SVGMarker.Orient {
        guard let value else {
            return .angle(0)
        }
        if value == "auto" {
            return .auto
        } else if value == "auto-start-reverse" {
            return .autoStartReverse
        } else if let angle = Float(value) {
            return .angle(angle)
        } else {
            return .angle(0)
        }
    }

    static func parseRefMagnitude(_ attributes: [String: String], _ key: String) -> SVGMarker.RefMagnitude? {
        guard let value = attributes[key] else {
            return nil
        }
        if value == "right" {
            return .right
        } else if value == "left" {
            return .left
        } else if value == "center" {
            return .center
        } else if let magnitude = SVGHelper.parseDimension(attributes, key) {
            return .coordinate(magnitude)
        } else {
            return nil
        }
    }
}

/// Implements the SVG `<switch>` element (SVG 1.1 §5.8).
///
/// The switch evaluates conditional-processing attributes on each child element
/// in document order and renders the first child for which all conditions are
/// met.  Subsequent children are ignored.
class SVGSwitchParser: SVGBaseElementParser {

    /// SVG 1.1 feature strings that SVGView supports.
    private static let supportedFeatures: Set<String> = [
        "http://www.w3.org/TR/SVG11/feature#SVG-static",
        "http://www.w3.org/TR/SVG11/feature#CoreAttribute",
        "http://www.w3.org/TR/SVG11/feature#Structure",
        "http://www.w3.org/TR/SVG11/feature#BasicStructure",
        "http://www.w3.org/TR/SVG11/feature#ConditionalProcessing",
        "http://www.w3.org/TR/SVG11/feature#Shape",
        "http://www.w3.org/TR/SVG11/feature#BasicText",
        "http://www.w3.org/TR/SVG11/feature#PaintAttribute",
        "http://www.w3.org/TR/SVG11/feature#BasicPaintAttribute",
        "http://www.w3.org/TR/SVG11/feature#OpacityAttribute",
        "http://www.w3.org/TR/SVG11/feature#GraphicsAttribute",
        "http://www.w3.org/TR/SVG11/feature#BasicGraphicsAttribute",
        "http://www.w3.org/TR/SVG11/feature#Gradient",
        "http://www.w3.org/TR/SVG11/feature#Marker",
        "http://www.w3.org/TR/SVG11/feature#Image",
    ]

    override func doParse(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> SVGNode? {
        let children = context.element.contents.compactMap { $0 as? XMLElement }
        for child in children {
            if conditionsMet(for: child) {
                let contents = delegate(child).map { [$0] } ?? []
                return SVGGroup(contents: contents)
            }
        }
        return SVGGroup(contents: [])
    }

    private func conditionsMet(for element: XMLElement) -> Bool {
        let attrs = element.attributes

        // requiredExtensions: SVGView supports no extensions — any non-empty value skips the child
        if let extensions = attrs["requiredExtensions"], !extensions.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }

        // requiredFeatures: every space-separated feature URI must be in our supported set
        if let features = attrs["requiredFeatures"] {
            let required = features.split(separator: " ").map(String.init)
            if !required.allSatisfy({ Self.supportedFeatures.contains($0) }) {
                return false
            }
        }

        // systemLanguage: at least one comma-separated BCP-47 tag must prefix-match the current locale
        if let languages = attrs["systemLanguage"] {
            let currentLang: String
            if #available(macOS 13, iOS 16, watchOS 9, *) {
                currentLang = Locale.current.language.languageCode?.identifier ?? ""
            } else {
                currentLang = (Locale.current as NSLocale).languageCode
            }
            let codes = languages.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if !codes.contains(where: { $0.hasPrefix(currentLang) || currentLang.hasPrefix($0) }) {
                return false
            }
        }

        return true
    }
}

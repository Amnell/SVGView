//
//  SVGElementParser.swift
//  SVGView
//
//  Created by Yuri Strot on 29.05.2022.
//

import Foundation

protocol SVGElementParser {

    func parse(context: SVGNodeContext, delegate: @escaping (XMLElement) -> SVGNode?) -> SVGNode?

}

class SVGBaseElementParser: SVGElementParser {

    /// SVG 1.1 feature strings that SVGView supports for conditional processing.
    static let supportedConditionalFeatures: Set<String> = [
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

    func parse(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> SVGNode? {
        guard Self.conditionalAttributesMet(attributes: context.properties) else {
            return nil
        }
        guard let node = doParse(context: context, delegate: delegate) else { return nil }
        let transform = SVGHelper.parseTransform(context.properties["transform"] ?? "")
        node.transform = node.transform.concatenating(transform)
        node.scriptTransforms = SVGHelper.parseTransformOperations(context.properties["transform"] ?? "")
        node.opacity = SVGHelper.parseOpacity(context.properties, "opacity")
        if let visibility = context.style("visibility")?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), visibility == "hidden" {
            node.opaque = false
        }
        if let display = context.style("display")?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), display == "none" {
            node.opaque = false
        }
        if let colorValue = context.style("color") {
            node.currentColor = SVGHelper.parseColor(colorValue, context.styles)
        }
        node.hasExplicitCurrentColor = context.hasElementStyle("color")

        if let clipId = SVGHelper.parseUse(context.properties["clip-path"]),
           let clipNode = context.index.element(by: clipId),
           let clip = delegate(clipNode) {
            node.clip = SVGUserSpaceNode(node: clip, userSpace: parse(userSpace: clipNode.attributes["clipPathUnits"]))
        }

        node.id = SVGHelper.parseId(context.properties)

        node.markerStart = SVGHelper.parseMarkerInAttribute(context.properties, key: "marker-start")
        node.markerMid = SVGHelper.parseMarkerInAttribute(context.properties, key: "marker-mid")
        node.markerEnd = SVGHelper.parseMarkerInAttribute(context.properties, key: "marker-end")
        return node
    }

    /// should be overwritten by inheritor
    func doParse(context: SVGNodeContext, delegate: (XMLElement) -> SVGNode?) -> SVGNode? {
        return nil
    }

    private func parse(userSpace: String?) -> SVGUserSpaceNode.UserSpace {
        if let value = userSpace, let result = SVGUserSpaceNode.UserSpace(rawValue: value) {
            return result
        }
        return SVGUserSpaceNode.UserSpace.objectBoundingBox
    }

    static func conditionalAttributesMet(attributes: [String: String]) -> Bool {
        // requiredExtensions: SVGView supports no extensions — any non-empty value fails.
        if let extensions = attributes["requiredExtensions"], !extensions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }

        // requiredFeatures: every whitespace-separated URI must be supported.
        if let features = attributes["requiredFeatures"] {
            let required = features.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            if !required.allSatisfy({ supportedConditionalFeatures.contains($0) }) {
                return false
            }
        }

        // systemLanguage: at least one listed language must match the current locale.
        if let languages = attributes["systemLanguage"] {
            let currentLanguage: String
            if #available(macOS 13, iOS 16, watchOS 9, *) {
                currentLanguage = Locale.current.language.languageCode?.identifier ?? ""
            } else {
                currentLanguage = (Locale.current as NSLocale).languageCode
            }

            let codes = languages
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
            let normalizedCurrent = currentLanguage.lowercased()
            if !codes.contains(where: { $0.hasPrefix(normalizedCurrent) || normalizedCurrent.hasPrefix($0) }) {
                return false
            }
        }

        return true
    }

}

//
//  SVGConstants.swift
//  SVGView
//
//  Created by Alisa Mylnikova on 17/07/2020.
//

import Foundation

open class SVGConstants {

    static let groupTags = ["svg", "g"]

    static let availableStyleAttributes = [
        "stroke",
        "stroke-width",
        "stroke-opacity",
        "stroke-dasharray",
        "stroke-dashoffset",
        "stroke-linecap",
        "stroke-linejoin",
        "stroke-miterlimit",
        "fill",
        "fill-rule",
        "fill-opacity",
        "mask",
        "color",
        "stop-color",
        "stop-opacity",
        "font-family",
        "font-size",
        "font-weight",
        "text-anchor",
        "visibility",
        "display"
    ]

}

public class SVGParserRegexHelper {

    static let transformAttributeMatcher = try? NSRegularExpression(pattern: "([a-z]+)\\(((\\-?\\d+\\.?\\d*e?\\-?\\d*\\s*,?\\s*)+)\\)", options: .caseInsensitive)
    static let transformMatcher = try? NSRegularExpression(pattern: "\\-?\\d+\\.?\\d*e?\\-?\\d*", options: .caseInsensitive)
    static let textElementMatcher = try? NSRegularExpression(pattern: "<text.*?>((?s:.*))<\\/text>", options: .caseInsensitive)
    static let maskIdenitifierMatcher = try? NSRegularExpression(pattern: "url\\(#((?s:.*))\\)", options: .caseInsensitive)
    static let unitsMatcher = try? NSRegularExpression(pattern: "([a-zA-Z]+)$", options: .caseInsensitive)

    class func getTransformAttributeMatcher() -> NSRegularExpression? {
        return transformAttributeMatcher
    }

    class func getTransformMatcher() -> NSRegularExpression? {
        return transformMatcher
    }

    class func getTextElementMatcher() -> NSRegularExpression? {
        return textElementMatcher
    }

    class func getMaskIdenitifierMatcher() -> NSRegularExpression? {
        return maskIdenitifierMatcher
    }

    class func getUnitsIdenitifierMatcher() -> NSRegularExpression? {
        return unitsMatcher
    }

}


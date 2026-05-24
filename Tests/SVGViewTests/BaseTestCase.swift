//
//  BaseTestCase.swift
//  SVGViewTests
//
//  Created by Yuriy Strot on 07.02.2021.
//

import Foundation
import Testing
@testable import SVGView

#if canImport(SwiftUI)
import SwiftUI
#endif

protocol SVGTestHelper {
    var dir: String { get }
}

extension SVGTestHelper {

    var dir: String { "1.2T" }

    func compareToReference(_ fileName: String) async throws {
        let bundle = Bundle.module
        let svgURL = try #require(bundle.url(forResource: fileName, withExtension: "svg", subdirectory: "w3c/\(dir)/svg/"))
        let refURL = try #require(bundle.url(forResource: fileName, withExtension: "ref", subdirectory: "w3c/\(dir)/refs/"))

        let svgSource = try String(contentsOf: svgURL)
        let node = try #require(SVGParser.parse(contentsOf: svgURL))
        let content = Serializer.serialize(node)
        let reference = try String(contentsOf: refURL)

        Attachment.record(Attachment(svgSource, named: "\(fileName).svg"))
        Attachment.record(Attachment(content, named: "\(fileName)-actual.txt"))
        Attachment.record(Attachment(reference, named: "\(fileName)-expected.txt"))
        Attachment.record(Attachment(unifiedDiff(actual: content, expected: reference), named: "\(fileName)-diff.txt"))
        await renderedPNGAttachment(node: node, named: "\(fileName)-rendered.png")

        #expect(content == reference, "nodeContent is not equal to referenceContent. \(prettyFirstDifferenceBetweenStrings(s1: content, s2: reference))")
    }

    func prettyFirstDifferenceBetweenStrings(s1: String, s2: String) -> String {
        return prettyFirstDifferenceBetweenNSStrings(s1: s1 as NSString, s2: s2 as NSString) as String
    }

    func unifiedDiff(actual: String, expected: String) -> String {
        let actualLines = actual.components(separatedBy: "\n")
        let expectedLines = expected.components(separatedBy: "\n")
        var result = "--- expected\n+++ actual\n"
        let lcs = longestCommonSubsequence(actualLines, expectedLines)
        var i = 0, j = 0, k = 0
        while i < actualLines.count || j < expectedLines.count {
            if i < actualLines.count && j < expectedLines.count && k < lcs.count && actualLines[i] == lcs[k] && expectedLines[j] == lcs[k] {
                result += " \(actualLines[i])\n"
                i += 1; j += 1; k += 1
            } else if j < expectedLines.count && (k >= lcs.count || expectedLines[j] != lcs[k]) {
                result += "-\(expectedLines[j])\n"
                j += 1
            } else {
                result += "+\(actualLines[i])\n"
                i += 1
            }
        }
        return result
    }

    private func longestCommonSubsequence(_ a: [String], _ b: [String]) -> [String] {
        let m = a.count, n = b.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 1...m {
            for j in 1...n {
                dp[i][j] = a[i-1] == b[j-1] ? dp[i-1][j-1] + 1 : max(dp[i-1][j], dp[i][j-1])
            }
        }
        var result: [String] = []
        var i = m, j = n
        while i > 0 && j > 0 {
            if a[i-1] == b[j-1] { result.append(a[i-1]); i -= 1; j -= 1 }
            else if dp[i-1][j] > dp[i][j-1] { i -= 1 }
            else { j -= 1 }
        }
        return result.reversed()
    }

    /// Renders `node` to a PNG using `ImageRenderer` and records it as a test attachment.
    /// Only runs on platforms that support `ImageRenderer` (macOS 13+, iOS 16+, watchOS 9+).
    /// Failures are silently ignored — the render is a diagnostic aid, not part of correctness.
    func renderedPNGAttachment(node: SVGNode, named name: String) async {
#if canImport(SwiftUI)
        if #available(macOS 13, iOS 16, watchOS 9, *) {
            let size = renderSize(for: node)
            let png = await MainActor.run { () -> Data? in
                let renderer = ImageRenderer(content: SVGView(svg: node).frame(width: size.width, height: size.height))
                renderer.scale = 1.0
#if os(macOS)
                guard let nsImage = renderer.nsImage,
                      let tiff = nsImage.tiffRepresentation,
                      let rep = NSBitmapImageRep(data: tiff) else { return nil }
                return rep.representation(using: .png, properties: [:])
#elseif os(iOS)
                return renderer.uiImage?.pngData()
#else
                return nil
#endif
            }
            if let png {
                Attachment.record(Attachment(png, named: name))
            }
        }
#endif
    }

    private func renderSize(for node: SVGNode) -> CGSize {
        if let viewport = node as? SVGViewport {
            if let box = viewport.viewBox, box.width > 0, box.height > 0 {
                return CGSize(width: box.width, height: box.height)
            }
            if let w = viewport.width.ideal, let h = viewport.height.ideal, w > 0, h > 0 {
                return CGSize(width: w, height: h)
            }
        }
        return CGSize(width: 480, height: 360)
    }
}

/// Find first differing character between two strings
///
/// :param: s1 First String
/// :param: s2 Second String
///
/// :returns: .DifferenceAtIndex(i) or .NoDifference
fileprivate func firstDifferenceBetweenStrings(s1: NSString, s2: NSString) -> FirstDifferenceResult {
    let len1 = s1.length
    let len2 = s2.length

    let lenMin = min(len1, len2)

    for i in 0..<lenMin {
        if s1.character(at: i) != s2.character(at: i) {
            return .DifferenceAtIndex(i)
        }
    }

    if len1 < len2 {
        return .DifferenceAtIndex(len1)
    }

    if len2 < len1 {
        return .DifferenceAtIndex(len2)
    }

    return .NoDifference
}


/// Create a formatted String representation of difference between strings
///
/// :param: s1 First string
/// :param: s2 Second string
///
/// :returns: a string, possibly containing significant whitespace and newlines
fileprivate func prettyFirstDifferenceBetweenNSStrings(s1: NSString, s2: NSString) -> NSString {
    let firstDifferenceResult = firstDifferenceBetweenStrings(s1: s1, s2: s2)
    return prettyDescriptionOfFirstDifferenceResult(firstDifferenceResult: firstDifferenceResult, s1: s1, s2: s2)
}

/// Create a formatted String representation of a FirstDifferenceResult for two strings
///
/// :param: firstDifferenceResult FirstDifferenceResult
/// :param: s1 First string used in generation of firstDifferenceResult
/// :param: s2 Second string used in generation of firstDifferenceResult
///
/// :returns: a printable string, possibly containing significant whitespace and newlines
fileprivate func prettyDescriptionOfFirstDifferenceResult(firstDifferenceResult: FirstDifferenceResult, s1: NSString, s2: NSString) -> NSString {

    func diffString(index: Int, s1: NSString, s2: NSString) -> NSString {
        let markerArrow = "\u{2b06}"  // "⬆"
        let ellipsis    = "\u{2026}"  // "…"
        /// Given a string and a range, return a string representing that substring.
        ///
        /// If the range starts at a position other than 0, an ellipsis
        /// will be included at the beginning.
        ///
        /// If the range ends before the actual end of the string,
        /// an ellipsis is added at the end.
        func windowSubstring(s: NSString, range: NSRange) -> String {
            let validRange = NSMakeRange(range.location, min(range.length, s.length - range.location))
            let substring = s.substring(with: validRange)

            let prefix = range.location > 0 ? ellipsis : ""
            let suffix = (s.length - range.location > range.length) ? ellipsis : ""

            return "\(prefix)\(substring)\(suffix)"
        }

        // Show this many characters before and after the first difference
        let windowPrefixLength = 10
        let windowSuffixLength = 10
        let windowLength = windowPrefixLength + 1 + windowSuffixLength

        let windowIndex = max(index - windowPrefixLength, 0)
        let windowRange = NSMakeRange(windowIndex, windowLength)

        let sub1 = windowSubstring(s: s1, range: windowRange)
        let sub2 = windowSubstring(s: s2, range: windowRange)

        let markerPosition = min(windowSuffixLength, index) + (windowIndex > 0 ? 1 : 0)

        let markerPrefix = String(repeating: " ", count: markerPosition)
        let markerLine = "\(markerPrefix)\(markerArrow)"

        return "Difference at index \(index):\n\(sub1)\n\(sub2)\n\(markerLine)" as NSString
    }

    switch firstDifferenceResult {
    case .NoDifference:                 return "No difference"
    case .DifferenceAtIndex(let index): return diffString(index: index, s1: s1, s2: s2)
    }
}

/// Result type for firstDifferenceBetweenStrings()
public enum FirstDifferenceResult {
    /// Strings are identical
    case NoDifference

    /// Strings differ at the specified index.
    ///
    /// This could mean that characters at the specified index are different,
    /// or that one string is longer than the other
    case DifferenceAtIndex(Int)
}

extension FirstDifferenceResult: CustomStringConvertible {
    /// Textual representation of a FirstDifferenceResult
    public var description: String {
        switch self {
        case .NoDifference:
            return "NoDifference"
        case .DifferenceAtIndex(let index):
            return "DifferenceAtIndex(\(index))"
        }
    }

    /// Textual representation of a FirstDifferenceResult for debugging purposes
    public var debugDescription: String {
        return self.description
    }
}


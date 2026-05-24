import Foundation
import ArgumentParser

@testable import SVGView

#if os(macOS)
@main
struct cli: ParsableCommand {
    @Argument(help: "Path to a folder that contains 1.1F2/, 1.2T/ and Custom/")
    var input: String

    static let v11Refs: [String] = [
        "color-prop-01-b",
        "color-prop-02-f",
        "color-prop-03-t",
        "color-prop-04-t",
        "color-prop-05-t",
        "coords-coord-01-t",
        "coords-coord-02-t",
        "coords-dom-01-f",
        "coords-trans-01-b",
        "coords-trans-02-t",
        "coords-trans-03-t",
        "coords-trans-04-t",
        "coords-trans-05-t",
        "coords-trans-06-t",
        "coords-trans-07-t",
        "coords-trans-08-t",
        "coords-trans-09-t",
        "coords-trans-10-f",
        "coords-trans-11-f",
        "coords-trans-12-f",
        "coords-trans-13-f",
        "coords-trans-14-f",
        "coords-transformattr-01-f",
        "coords-transformattr-02-f",
        "coords-transformattr-03-f",
        "coords-transformattr-04-f",
        "coords-transformattr-05-f",
        "coords-units-02-b",
        "coords-units-03-b",
        "masking-opacity-01-b",
        "painting-control-02-f",
        "painting-control-03-f",
        "painting-marker-01-f",
        "painting-fill-01-t",
        "painting-fill-02-t",
        "painting-fill-03-t",
        "painting-fill-04-t",
        "painting-fill-05-b",
        "painting-stroke-01-t",
        "painting-stroke-02-t",
        "painting-stroke-03-t",
        "painting-stroke-04-t",
        "painting-stroke-05-t",
        "painting-stroke-07-t",
        "painting-stroke-08-t",
        "painting-stroke-09-t",
        "paths-data-01-t",
        "paths-data-02-t",
        "paths-data-03-f",
        "paths-data-04-t",
        "paths-data-05-t",
        "paths-data-06-t",
        "paths-data-07-t",
        "paths-data-08-t",
        "paths-data-09-t",
        "paths-data-10-t",
        "paths-data-12-t",
        "paths-data-13-t",
        "paths-data-14-t",
        "paths-data-15-t",
        "paths-data-16-t",
        "paths-data-17-f",
        "paths-data-18-f",
        "paths-data-19-f",
        "paths-data-20-f",
        "pservers-grad-01-b",
        "pservers-grad-02-b",
        "pservers-grad-03-b",
        "pservers-grad-06-b",
        "pservers-grad-04-b",
        "pservers-grad-05-b",
        "pservers-grad-07-b",
        "pservers-grad-09-b",
        "render-elems-01-t",
        "render-elems-02-t",
        "render-elems-03-t",
        "shapes-circle-01-t",
        "shapes-circle-02-t",
        "shapes-ellipse-01-t",
        "shapes-ellipse-02-t",
        "shapes-ellipse-03-f",
        "shapes-grammar-01-f",
        "shapes-intro-01-t",
        "shapes-line-01-t",
        "shapes-line-02-f",
        "shapes-polygon-01-t",
        "shapes-polygon-02-t",
        "shapes-polygon-03-t",
        "shapes-polyline-01-t",
        "shapes-polyline-02-t",
        "shapes-rect-02-t",
        "shapes-rect-04-f",
        "shapes-rect-05-f",
        "shapes-rect-06-f",
        "struct-cond-01-t",
        "struct-cond-03-t",
        "struct-defs-01-t",
        "struct-frag-01-t",
        "struct-frag-06-t",
        "struct-group-01-t",
        "struct-image-01-t",
        "struct-image-04-t",
        "struct-use-03-t",
        "styling-class-01-f",
        "styling-css-01-b",
        "styling-pres-01-t",
        "types-basic-01-f",
    ]
    
    static let v12Refs: [String] = [
        "coords-trans-01-t",
        "coords-trans-02-t",
        "coords-trans-03-t",
        "coords-trans-04-t",
        "coords-trans-05-t",
        "coords-trans-06-t",
        "coords-trans-07-t",
        "coords-trans-08-t",
        "coords-trans-09-t",
        "paint-color-03-t",
        "paint-color-201-t",
        "paint-fill-04-t",
        "paint-fill-06-t",
        "paint-stroke-01-t",
        "paths-data-01-t",
        "paths-data-02-t",
        "render-elems-01-t",
        "render-elems-02-t",
        "render-elems-03-t",
        "shapes-circle-01-t",
        "shapes-ellipse-01-t",
        "shapes-line-01-t",
        "shapes-polygon-01-t",
        "shapes-polyline-01-t",
        "shapes-rect-02-t",
        "struct-defs-01-t",
        "struct-frag-01-t",
        "struct-use-03-t",
    ]

    static let customRefs: [String] = [
        "viewport-01",
        "viewport-02",
        "graph-01",
    ]

    mutating func run() throws {
        let inputURL = URL(fileURLWithPath: input)
        
        guard FileManager.default.fileExists(atPath: input) else {
            throw ValidationError("Input path '\(input)' does not exist")
        }

        let v11FolderURL = inputURL.appendingPathComponent("1.1F2")
        let v12FolderURL = inputURL.appendingPathComponent("1.2T")
        let customFolderURL = inputURL.appendingPathComponent("Custom")

        guard FileManager.default.fileExists(atPath: v11FolderURL.path) || FileManager.default.fileExists(atPath: v12FolderURL.path) || FileManager.default.fileExists(atPath: customFolderURL.path) else {
            throw ValidationError("1.1F2/, 1.2T/ or Custom/ folder does not exist in '\(input)'")
        }
        
        for ref in Self.v11Refs {
            let svgURL = v11FolderURL.appending(path: "svg/\(ref).svg")
            let svgContent = try serialize(inputURL: svgURL)
            let refURL = v11FolderURL.appending(path: "refs/\(ref).ref")
            try svgContent.write(to: refURL, atomically: true, encoding: .utf8)
        }

        for ref in Self.v12Refs {
            let svgURL = v12FolderURL.appending(path: "svg/\(ref).svg")
            let svgContent = try serialize(inputURL: svgURL)
            let refURL = v12FolderURL.appending(path: "refs/\(ref).ref")
            try svgContent.write(to: refURL, atomically: true, encoding: .utf8)
        }

        for ref in Self.customRefs {
            let svgURL = customFolderURL.appending(path: "svg/\(ref).svg")
            let svgContent = try serialize(inputURL: svgURL)
            let refURL = customFolderURL.appending(path: "refs/\(ref).ref")
            try svgContent.write(to: refURL, atomically: true, encoding: .utf8)
        }
    }
    
    private func serialize(inputURL: URL) throws -> String {
        guard FileManager.default.fileExists(atPath: input) else {
            throw ValidationError("Input path '\(input)' does not exist")
        }
        
        guard let node = SVGParser.parse(contentsOf: inputURL) else {
            throw ValidationError("Failed to parse SVG file")
        }

        return Serializer.serialize(node)
    }
}
#else
@main
struct cli: ParsableCommand {
    mutating func run() throws {
        fatalError("Generation script can only be ran on Darwin")
    }
}
#endif

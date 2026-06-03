import Foundation

public struct SVGTestAssetFixture: Hashable {
    public let suite: String
    public let folder: String
    public let name: String
    public let relativePath: String
    public let svgURL: URL
    public let referencePNGURL: URL?
    public let referenceTextURL: URL?
}

public enum SVGTestAssets {
    public static let suites = ["1.1F2", "1.2T", "Custom"]

    public static func svgURL(fileName: String, suite: String) -> URL? {
        Bundle.module.url(forResource: fileName, withExtension: "svg", subdirectory: "w3c/\(suite)/svg")
    }

    public static func refURL(fileName: String, suite: String) -> URL? {
        Bundle.module.url(forResource: fileName, withExtension: "ref", subdirectory: "w3c/\(suite)/refs")
    }

    public static func imageURL(fileName: String, fileExtension: String, suite: String) -> URL? {
        Bundle.module.url(forResource: fileName, withExtension: fileExtension, subdirectory: "w3c/\(suite)/images")
    }

    public static func fixtures() throws -> [SVGTestAssetFixture] {
        guard let root = Bundle.module.resourceURL?.appendingPathComponent("w3c", isDirectory: true) else {
            return []
        }

        let fileManager = FileManager.default
        var fixtures: [SVGTestAssetFixture] = []

        for suite in suites {
            let svgRoot = root
                .appendingPathComponent(suite, isDirectory: true)
                .appendingPathComponent("svg", isDirectory: true)
            let pngRoot = root
                .appendingPathComponent(suite, isDirectory: true)
                .appendingPathComponent("png", isDirectory: true)
            let refRoot = root
                .appendingPathComponent(suite, isDirectory: true)
                .appendingPathComponent("refs", isDirectory: true)

            guard fileManager.fileExists(atPath: svgRoot.path(percentEncoded: false)) else {
                continue
            }

            let enumerator = fileManager.enumerator(
                at: svgRoot,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )

            while let fileURL = enumerator?.nextObject() as? URL {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                guard values.isRegularFile == true else { continue }
                guard fileURL.pathExtension.lowercased() == "svg" else { continue }

                let relative = fileURL.path.replacingOccurrences(
                    of: svgRoot.path(percentEncoded: false) + "/",
                    with: ""
                )
                let folder = (relative as NSString).deletingLastPathComponent
                let normalizedFolder = folder.isEmpty ? "svg" : folder

                let pngURL = referencePNGURL(
                    relativeSVGPath: relative,
                    svgFileName: fileURL.lastPathComponent,
                    pngRoot: pngRoot,
                    fileManager: fileManager
                )
                let refURL = referenceTextURL(
                    relativeSVGPath: relative,
                    refRoot: refRoot,
                    fileManager: fileManager
                )

                fixtures.append(
                    SVGTestAssetFixture(
                        suite: suite,
                        folder: normalizedFolder,
                        name: fileURL.lastPathComponent,
                        relativePath: "\(suite)/svg/\(relative)",
                        svgURL: fileURL,
                        referencePNGURL: pngURL,
                        referenceTextURL: refURL
                    )
                )
            }
        }

        return fixtures
    }

    private static func referencePNGURL(relativeSVGPath: String, svgFileName: String, pngRoot: URL, fileManager: FileManager) -> URL? {
        guard fileManager.fileExists(atPath: pngRoot.path(percentEncoded: false)) else {
            return nil
        }

        let relativePNGPath = ((relativeSVGPath as NSString).deletingPathExtension as NSString).appendingPathExtension("png") ?? relativeSVGPath + ".png"
        let nestedCandidate = pngRoot.appendingPathComponent(relativePNGPath)
        if fileManager.fileExists(atPath: nestedCandidate.path(percentEncoded: false)) {
            return nestedCandidate
        }

        let flatName = ((svgFileName as NSString).deletingPathExtension as NSString).appendingPathExtension("png") ?? svgFileName + ".png"
        let flatCandidate = pngRoot.appendingPathComponent(flatName)
        if fileManager.fileExists(atPath: flatCandidate.path(percentEncoded: false)) {
            return flatCandidate
        }

        return nil
    }

    private static func referenceTextURL(relativeSVGPath: String, refRoot: URL, fileManager: FileManager) -> URL? {
        guard fileManager.fileExists(atPath: refRoot.path(percentEncoded: false)) else {
            return nil
        }

        let relativeRefPath = ((relativeSVGPath as NSString).deletingPathExtension as NSString).appendingPathExtension("ref") ?? relativeSVGPath + ".ref"
        let nestedCandidate = refRoot.appendingPathComponent(relativeRefPath)
        if fileManager.fileExists(atPath: nestedCandidate.path(percentEncoded: false)) {
            return nestedCandidate
        }

        let flatName = ((relativeSVGPath as NSString).lastPathComponent as NSString).deletingPathExtension + ".ref"
        let flatCandidate = refRoot.appendingPathComponent(flatName)
        if fileManager.fileExists(atPath: flatCandidate.path(percentEncoded: false)) {
            return flatCandidate
        }

        return nil
    }
}

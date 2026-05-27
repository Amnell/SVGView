import Foundation
import ImageIO
import Testing
@testable import SVGView

struct CGTests {

    @Test func transformConcatenation() {
        let transform1 = CGAffineTransform(translationX: 5, y: 10)
        let transform2 = CGAffineTransform(scaleX: 2, y: 3)
        let combined = transform1.concatenating(transform2)
        
        #expect(combined.a == 2)
        #expect(combined.d == 3)
        #expect(combined.tx == 10)
        #expect(combined.ty == 30)
    }

    @Test func iccProfileTransformChangesCGImagePixels() throws {
        let bundle = Bundle.module
        let imageURL = try #require(bundle.url(forResource: "colorprof", withExtension: "png", subdirectory: "w3c/1.1F2/images/"))
        let profileURL = try #require(bundle.url(forResource: "changeColor", withExtension: "ICM", subdirectory: "w3c/1.1F2/images/"))

        let imageData = try Data(contentsOf: imageURL)
        let profileData = try Data(contentsOf: profileURL)

        let source = try #require(CGImageSourceCreateWithData(imageData as CFData, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let transformed = try #require(SVGImageICCTransformer.transformedCGImage(image: image, profileData: profileData))

        #expect(transformed.width == image.width)
        #expect(transformed.height == image.height)
        #expect(pixelHash(transformed) != pixelHash(image))
    }

    private func pixelHash(_ image: CGImage) -> UInt64 {
        guard let provider = image.dataProvider, let data = provider.data else {
            return 0
        }
        let bytes = data as Data
        var hash: UInt64 = 1469598103934665603
        for byte in bytes {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }

}

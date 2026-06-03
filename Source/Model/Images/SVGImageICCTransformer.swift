#if canImport(SwiftUI)
import SwiftUI
import CoreGraphics
import ImageIO
import Foundation

enum SVGImageICCTransformer {

    static func decodeImage(data: Data, profileData: Data?) -> (image: Image, size: CGSize)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        let transformed = transformedCGImage(image: image, profileData: profileData) ?? image
        let size = CGSize(width: transformed.width, height: transformed.height)
        return (Image(decorative: transformed, scale: 1), size)
    }

    static func transformedCGImage(image: CGImage, profileData: Data?) -> CGImage? {
        guard let profileData,
              let sourceColorSpace = CGColorSpace(iccData: profileData as CFData),
              let destinationColorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let normalizedImage = normalizedRGBAImage(image),
              let provider = normalizedImage.dataProvider else {
            return nil
        }

        guard let reinterpretedSource = CGImage(
            width: normalizedImage.width,
            height: normalizedImage.height,
            bitsPerComponent: normalizedImage.bitsPerComponent,
            bitsPerPixel: normalizedImage.bitsPerPixel,
            bytesPerRow: normalizedImage.bytesPerRow,
            space: sourceColorSpace,
            bitmapInfo: normalizedImage.bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: normalizedImage.shouldInterpolate,
            intent: normalizedImage.renderingIntent
        ) else {
            return nil
        }

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: normalizedImage.width,
            height: normalizedImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: destinationColorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(reinterpretedSource, in: CGRect(x: 0, y: 0, width: normalizedImage.width, height: normalizedImage.height))
        return context.makeImage()
    }

    private static func normalizedRGBAImage(_ image: CGImage) -> CGImage? {
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
              ) else {
            return nil
        }

        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return context.makeImage()
    }
}
#endif

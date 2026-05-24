//
//  SVGPattern.swift
//  SVGView
//

#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
#endif

public class SVGPattern: SVGPaint {

    public let x: CGFloat
    public let y: CGFloat
    public let width: CGFloat
    public let height: CGFloat
    public let userSpace: Bool
    public let patternTransform: CGAffineTransform
    public let contents: [SVGNode]

    public init(x: CGFloat = 0, y: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0,
                userSpace: Bool = true, patternTransform: CGAffineTransform = .identity,
                contents: [SVGNode] = []) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.userSpace = userSpace
        self.patternTransform = patternTransform
        self.contents = contents
    }

    #if canImport(SwiftUI)
    @ViewBuilder
    func apply<S: View>(view: S, model: SVGShape? = nil) -> some View {
        if width > 0, height > 0, !contents.isEmpty, let cgImage = renderTile() {
            let image = Image(decorative: cgImage, scale: 1.0)
            let bounds = model?.bounds() ?? .zero
            view
                .foregroundColor(.clear)
                .overlay(
                    Rectangle()
                        .fill(ImagePaint(image: image, scale: 1.0))
                        .frame(width: bounds.width, height: bounds.height)
                        .offset(x: bounds.minX, y: bounds.minY)
                        .mask(view)
                )
        } else {
            view.foregroundColor(.clear)
        }
    }

    private func renderTile() -> CGImage? {
        let w = Int(ceil(width))
        let h = Int(ceil(height))
        guard w > 0, h > 0 else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        // Flip coordinate system to match SVG (y increases downward)
        context.translateBy(x: 0, y: CGFloat(h))
        context.scaleBy(x: 1, y: -1)
        for node in contents {
            node.draw(in: context)
        }
        return context.makeImage()
    }
    #endif
}

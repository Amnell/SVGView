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
            let bounds = model?.bounds() ?? .zero
            let frame  = model?.frame()  ?? .zero
            let image = Image(decorative: cgImage, scale: 1.0)
            view
                .foregroundColor(.clear)
                .overlay(
                    tileView(image: image, bounds: bounds, shapeOrigin: frame.origin)
                        .mask(view)
                )
        } else {
            view.foregroundColor(.clear)
        }
    }

    @ViewBuilder
    private func tileView(image: Image, bounds: CGRect, shapeOrigin: CGPoint = .zero) -> some View {
        if patternTransform.isIdentity {
            Rectangle()
                .fill(ImagePaint(image: image, scale: 1.0))
                .frame(width: bounds.width, height: bounds.height)
                .offset(x: bounds.minX, y: bounds.minY)
        } else {
            // patternTransform uses SVG user-space coordinates, but the Canvas
            // coordinate system has its origin at the shape's top-left corner.
            // Subtract the shape origin so tile positions are in Canvas-local space.
            let localTransform = CGAffineTransform(
                a: patternTransform.a, b: patternTransform.b,
                c: patternTransform.c, d: patternTransform.d,
                tx: patternTransform.tx - shapeOrigin.x,
                ty: patternTransform.ty - shapeOrigin.y
            )
            Canvas { ctx, size in
                ctx.concatenate(localTransform)
                // Compute tile coverage by inverse-transforming the canvas corners
                // back into tile space. Over-estimating is safe.
                let inv = localTransform.inverted()
                let corners = [
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: size.width, y: 0),
                    CGPoint(x: 0, y: size.height),
                    CGPoint(x: size.width, y: size.height),
                ]
                let transformed = corners.map { $0.applying(inv) }
                let minX = transformed.map(\.x).min() ?? 0
                let maxX = transformed.map(\.x).max() ?? size.width
                let minY = transformed.map(\.y).min() ?? 0
                let maxY = transformed.map(\.y).max() ?? size.height
                let startCol = Int(floor(minX / self.width)) - 1
                let endCol   = Int(ceil(maxX  / self.width)) + 1
                let startRow = Int(floor(minY / self.height)) - 1
                let endRow   = Int(ceil(maxY  / self.height)) + 1
                let resolved = ctx.resolve(image)
                for row in startRow...endRow {
                    for col in startCol...endCol {
                        ctx.draw(resolved, at: CGPoint(
                            x: CGFloat(col) * self.width,
                            y: CGFloat(row) * self.height
                        ), anchor: .topLeading)
                    }
                }
            }
            .frame(width: bounds.width, height: bounds.height)
            .offset(x: bounds.minX, y: bounds.minY)
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

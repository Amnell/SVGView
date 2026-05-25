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
    public let contentUserSpace: Bool
    public let patternTransform: CGAffineTransform
    public let contents: [SVGNode]

    public init(x: CGFloat = 0, y: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0,
                userSpace: Bool = true, patternTransform: CGAffineTransform = .identity,
                contents: [SVGNode] = [], contentUserSpace: Bool = true) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.userSpace = userSpace
        self.contentUserSpace = contentUserSpace
        self.patternTransform = patternTransform
        self.contents = contents
    }

    #if canImport(SwiftUI)
    @ViewBuilder
    func apply<S: View>(view: S, model: SVGShape? = nil) -> some View {
        let bounds = model?.bounds() ?? .zero
        let frame = model?.frame() ?? .zero

        let tileX = userSpace ? x : x * bounds.width
        let tileY = userSpace ? y : y * bounds.height
        let tileWidth = userSpace ? width : width * bounds.width
        let tileHeight = userSpace ? height : height * bounds.height

        let contentScale = contentUserSpace
            ? CGSize(width: 1, height: 1)
            : CGSize(width: bounds.width, height: bounds.height)

        if tileWidth > 0,
           tileHeight > 0,
           !contents.isEmpty,
           let cgImage = renderTile(tileWidth: tileWidth, tileHeight: tileHeight, contentScale: contentScale) {
            let image = Image(decorative: cgImage, scale: 1.0)
            view
                .foregroundColor(.clear)
                .overlay(
                    tileView(
                        image: image,
                        bounds: bounds,
                        shapeOrigin: frame.origin,
                        tileX: tileX,
                        tileY: tileY,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight
                    )
                    .mask(view)
                )
        } else {
            view.foregroundColor(.clear)
        }
    }

    @ViewBuilder
    private func tileView(
        image: Image,
        bounds: CGRect,
        shapeOrigin: CGPoint = .zero,
        tileX: CGFloat,
        tileY: CGFloat,
        tileWidth: CGFloat,
        tileHeight: CGFloat
    ) -> some View {
        // patternTransform uses SVG user-space coordinates, but the Canvas
        // coordinate system has its origin at the shape's top-left corner.
        // Subtract the shape origin so tile positions are in Canvas-local space.
        let localTransform = CGAffineTransform(
            a: patternTransform.a, b: patternTransform.b,
            c: patternTransform.c, d: patternTransform.d,
            tx: patternTransform.tx - shapeOrigin.x,
            ty: patternTransform.ty - shapeOrigin.y
        )

        return Canvas { ctx, size in
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

            let startCol = Int(floor((minX - tileX) / tileWidth)) - 1
            let endCol = Int(ceil((maxX - tileX) / tileWidth)) + 1
            let startRow = Int(floor((minY - tileY) / tileHeight)) - 1
            let endRow = Int(ceil((maxY - tileY) / tileHeight)) + 1

            let resolved = ctx.resolve(image)
            for row in startRow...endRow {
                for col in startCol...endCol {
                    let originX = tileX + CGFloat(col) * tileWidth
                    let originY = tileY + CGFloat(row) * tileHeight
                    ctx.draw(
                        resolved,
                        in: CGRect(x: originX, y: originY, width: tileWidth, height: tileHeight)
                    )
                }
            }
        }
        .frame(width: bounds.width, height: bounds.height)
        .offset(x: bounds.minX, y: bounds.minY)
    }

    private func renderTile(tileWidth: CGFloat, tileHeight: CGFloat, contentScale: CGSize) -> CGImage? {
        let w = Int(ceil(tileWidth))
        let h = Int(ceil(tileHeight))
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
        context.scaleBy(x: contentScale.width, y: contentScale.height)
        for node in contents {
            node.draw(in: context)
        }
        return context.makeImage()
    }
    #endif
}

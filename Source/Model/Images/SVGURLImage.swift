//
//  SVGURLImage.swift
//  SVGView
//
//  Created by Alisa Mylnikova on 22/09/2021.
//

#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
#endif

public class SVGURLImage: SVGImage {

    public let src: String
    public let data: Data?

    public init(
        x: CGFloat = 0,
        y: CGFloat = 0,
        width: CGFloat = 0,
        height: CGFloat = 0,
        preserveAspectRatio: SVGPreserveAspectRatio = SVGPreserveAspectRatio(),
        src: String,
        data: Data?
    ) {
        self.src = src
        self.data = data
        super.init(x: x, y: y, width: width, height: height, preserveAspectRatio: preserveAspectRatio)
    }

    override func serialize(_ serializer: Serializer) {
        serializer.add("src", src)
        super.serialize(serializer)
    }

    #if canImport(SwiftUI)
    public func contentView() -> some View {
        SVGUrlImageView(model: self)
    }
    #endif
}

#if canImport(SwiftUI)
extension SVGURLImage: ObservableObject {}
struct SVGUrlImageView: View {

    @ObservedObject var model: SVGURLImage

    private var viewportSize: CGSize {
        CGSize(width: model.width, height: model.height)
    }

#if os(OSX)
    private var decoded: (image: Image, size: CGSize)? {
        guard let data = model.data, let nsImage = NSImage(data: data) else {
            return nil
        }
        return (Image(nsImage: nsImage), nsImage.size)
    }
#else
    private var decoded: (image: Image, size: CGSize)? {
        guard let data = model.data, let uiImage = UIImage(data: data) else {
            return nil
        }
        return (Image(uiImage: uiImage), uiImage.size)
    }
#endif

    public var body: some View {
        ZStack(alignment: .topLeading) {
            if let decoded {
                decoded.image
                    .resizable()
                    .frame(width: decoded.size.width, height: decoded.size.height, alignment: .topLeading)
                    .transformEffect(model.preserveAspectRatio.layout(size: decoded.size, into: viewportSize))
            }
        }
            .frame(width: model.width, height: model.height, alignment: .topLeading)
            .clipped()
            .position(x: model.x, y: model.y)
            .offset(x: model.width/2, y: model.height/2)
            .applyNodeAttributes(model: model)
    }
}
#endif


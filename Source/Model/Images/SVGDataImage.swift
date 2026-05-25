//
//  SVGDataImage.swift
//  SVGView
//
//  Created by Alisa Mylnikova on 10/06/2021.
//

#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
import Combine
#endif

public class SVGDataImage: SVGImage {
    #if os(WASI) || os(Linux)           
    public var data: Data
    #else
    @Published public var data: Data
    #endif

    public init(
        x: CGFloat = 0,
        y: CGFloat = 0,
        width: CGFloat = 0,
        height: CGFloat = 0,
        preserveAspectRatio: SVGPreserveAspectRatio = SVGPreserveAspectRatio(),
        data: Data
    ) {
        self.data = data
        super.init(x: x, y: y, width: width, height: height, preserveAspectRatio: preserveAspectRatio)
    }

    override func serialize(_ serializer: Serializer) {
        serializer.add("data", "\(data.base64EncodedString())")
        super.serialize(serializer)
    }

    #if canImport(SwiftUI)
    public func contentView() -> some View {
        SVGDataImageView(model: self)
    }
    #endif
}

#if canImport(SwiftUI)
extension SVGDataImage: ObservableObject {}
struct SVGDataImageView: View {
    @ObservedObject var model: SVGDataImage

#if os(OSX)
    private var decoded: (image: Image, size: CGSize)? {
        guard let nsImage = NSImage(data: model.data) else {
            return nil
        }
        return (Image(nsImage: nsImage), nsImage.size)
    }
#else
    private var decoded: (image: Image, size: CGSize)? {
        guard let uiImage = UIImage(data: model.data) else {
            return nil
        }
        return (Image(uiImage: uiImage), uiImage.size)
    }
#endif

    private var viewportSize: CGSize {
        CGSize(width: model.width, height: model.height)
    }

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

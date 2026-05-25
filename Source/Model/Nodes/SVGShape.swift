#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
import Combine
#endif

public class SVGShape: SVGNode {

#if os(WASI) || os(Linux)
    public var fill: SVGPaint?
    public var stroke: SVGStroke?
    public var fillUsesCurrentColor: Bool = false
    public var strokeUsesCurrentColor: Bool = false
#else
    @Published public var fill: SVGPaint?
    @Published public var stroke: SVGStroke?
    @Published public var fillUsesCurrentColor: Bool = false
    @Published public var strokeUsesCurrentColor: Bool = false
#endif

    override func serialize(_ serializer: Serializer) {
        fill?.serialize(key: "fill", serializer: serializer)
        serializer.add("stroke", stroke)
        serializer.add("marker-start", markerStart)
        serializer.add("marker-mid", markerMid)
        serializer.add("marker-end", markerEnd)
        super.serialize(serializer)
    }
}

//
//  SVGImage.swift
//  SVGView
//
//  Created by Alisa Mylnikova on 03/06/2021.
//

#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
import Combine
#endif

public class SVGImage: SVGNode {

#if os(WASI) || os(Linux)
    public var x: CGFloat
    public var y: CGFloat
    public var width: CGFloat
    public var height: CGFloat
    public var preserveAspectRatio: SVGPreserveAspectRatio
    public var colorProfileId: String?
    public var appliesColorProfile: Bool
    public var colorProfileData: Data?
#else
    @Published public var x: CGFloat
    @Published public var y: CGFloat
    @Published public var width: CGFloat
    @Published public var height: CGFloat
    @Published public var preserveAspectRatio: SVGPreserveAspectRatio
    @Published public var colorProfileId: String?
    @Published public var appliesColorProfile: Bool
    @Published public var colorProfileData: Data?
#endif

    public init(
        x: CGFloat = 0,
        y: CGFloat = 0,
        width: CGFloat = 0,
        height: CGFloat = 0,
        preserveAspectRatio: SVGPreserveAspectRatio = SVGPreserveAspectRatio(),
        colorProfileId: String? = nil,
        appliesColorProfile: Bool = false,
        colorProfileData: Data? = nil
    ) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.preserveAspectRatio = preserveAspectRatio
        self.colorProfileId = colorProfileId
        self.appliesColorProfile = appliesColorProfile
        self.colorProfileData = colorProfileData
    }

    override func serialize(_ serializer: Serializer) {
        serializer
            .add("x", x, 0)
            .add("y", y, 0)
            .add("width", width, 0)
            .add("height", height, 0)
            .add("scaling", preserveAspectRatio.scaling)
            .add("xAlign", preserveAspectRatio.xAlign)
            .add("yAlign", preserveAspectRatio.yAlign)
            .add("colorProfile", colorProfileId)
            .add("appliesColorProfile", appliesColorProfile, false)
        super.serialize(serializer)
    }
}

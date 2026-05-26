#if os(WASI) || os(Linux)
import Foundation
#else
import SwiftUI
import Combine
#endif

public class SVGDefs: SVGGroup {
	#if !os(WASI) && !os(Linux)
	override func draw(in context: CGContext) {
		// <defs> defines reusable content and must not be rendered directly.
	}
	#endif
}


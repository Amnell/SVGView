import Testing
@testable import SVGView

@Suite("SVG 1.2 Tiny")
struct SVG12Tests {

    @Suite("Coords")
    struct Coords: SVGTestHelper {
        @Test func coordsTrans01T() async throws { try await compareToReference("coords-trans-01-t") }
        @Test func coordsTrans02T() async throws { try await compareToReference("coords-trans-02-t") }
        @Test func coordsTrans03T() async throws { try await compareToReference("coords-trans-03-t") }
        @Test func coordsTrans04T() async throws { try await compareToReference("coords-trans-04-t") }
        @Test func coordsTrans05T() async throws { try await compareToReference("coords-trans-05-t") }
        @Test func coordsTrans06T() async throws { try await compareToReference("coords-trans-06-t") }
        @Test func coordsTrans07T() async throws { try await compareToReference("coords-trans-07-t") }
        @Test func coordsTrans08T() async throws { try await compareToReference("coords-trans-08-t") }
        @Test func coordsTrans09T() async throws { try await compareToReference("coords-trans-09-t") }
    }

    @Suite("Paint")
    struct Paint: SVGTestHelper {
        @Test func paintColor03T() async throws { try await compareToReference("paint-color-03-t") }
        @Test func paintColor201T() async throws { try await compareToReference("paint-color-201-t") }
        @Test func paintFill04T() async throws { try await compareToReference("paint-fill-04-t") }
        @Test func paintFill06T() async throws { try await compareToReference("paint-fill-06-t") }
        @Test func paintStroke01T() async throws { try await compareToReference("paint-stroke-01-t") }
    }

    @Suite("Paths")
    struct Paths: SVGTestHelper {
        @Test func pathsData01T() async throws { try await compareToReference("paths-data-01-t") }
        @Test func pathsData02T() async throws { try await compareToReference("paths-data-02-t") }
    }

    @Suite("Render")
    struct Render: SVGTestHelper {
        @Test func renderElems01T() async throws { try await compareToReference("render-elems-01-t") }
        @Test func renderElems02T() async throws { try await compareToReference("render-elems-02-t") }
        @Test func renderElems03T() async throws { try await compareToReference("render-elems-03-t") }
    }

    @Suite("Shapes")
    struct Shapes: SVGTestHelper {
        @Test func shapesCircle01T() async throws { try await compareToReference("shapes-circle-01-t") }
        @Test func shapesEllipse01T() async throws { try await compareToReference("shapes-ellipse-01-t") }
        @Test func shapesLine01T() async throws { try await compareToReference("shapes-line-01-t") }
        @Test func shapesPolygon01T() async throws { try await compareToReference("shapes-polygon-01-t") }
        @Test func shapesPolyline01T() async throws { try await compareToReference("shapes-polyline-01-t") }
        @Test func shapesRect02T() async throws { try await compareToReference("shapes-rect-02-t") }
    }

    @Suite("Struct")
    struct Struct: SVGTestHelper {
        @Test func structDefs01T() async throws { try await compareToReference("struct-defs-01-t") }
        @Test func structFrag01T() async throws { try await compareToReference("struct-frag-01-t") }
        @Test func structUse03T() async throws { try await compareToReference("struct-use-03-t") }
    }
}

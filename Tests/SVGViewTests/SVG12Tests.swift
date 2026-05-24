import Testing
@testable import SVGView

@Suite("SVG 1.2 Tiny")
struct SVG12Tests {

    @Suite("Coords")
    struct Coords: SVGTestHelper {
        @Test func coordsTrans01T() throws { try compareToReference("coords-trans-01-t") }
        @Test func coordsTrans02T() throws { try compareToReference("coords-trans-02-t") }
        @Test func coordsTrans03T() throws { try compareToReference("coords-trans-03-t") }
        @Test func coordsTrans04T() throws { try compareToReference("coords-trans-04-t") }
        @Test func coordsTrans05T() throws { try compareToReference("coords-trans-05-t") }
        @Test func coordsTrans06T() throws { try compareToReference("coords-trans-06-t") }
        @Test func coordsTrans07T() throws { try compareToReference("coords-trans-07-t") }
        @Test func coordsTrans08T() throws { try compareToReference("coords-trans-08-t") }
        @Test func coordsTrans09T() throws { try compareToReference("coords-trans-09-t") }
    }

    @Suite("Paint")
    struct Paint: SVGTestHelper {
        @Test func paintColor03T() throws { try compareToReference("paint-color-03-t") }
        @Test func paintColor201T() throws { try compareToReference("paint-color-201-t") }
        @Test func paintFill04T() throws { try compareToReference("paint-fill-04-t") }
        @Test func paintFill06T() throws { try compareToReference("paint-fill-06-t") }
        @Test func paintStroke01T() throws { try compareToReference("paint-stroke-01-t") }
    }

    @Suite("Paths")
    struct Paths: SVGTestHelper {
        @Test func pathsData01T() throws { try compareToReference("paths-data-01-t") }
        @Test func pathsData02T() throws { try compareToReference("paths-data-02-t") }
    }

    @Suite("Render")
    struct Render: SVGTestHelper {
        @Test func renderElems01T() throws { try compareToReference("render-elems-01-t") }
        @Test func renderElems02T() throws { try compareToReference("render-elems-02-t") }
        @Test func renderElems03T() throws { try compareToReference("render-elems-03-t") }
    }

    @Suite("Shapes")
    struct Shapes: SVGTestHelper {
        @Test func shapesCircle01T() throws { try compareToReference("shapes-circle-01-t") }
        @Test func shapesEllipse01T() throws { try compareToReference("shapes-ellipse-01-t") }
        @Test func shapesLine01T() throws { try compareToReference("shapes-line-01-t") }
        @Test func shapesPolygon01T() throws { try compareToReference("shapes-polygon-01-t") }
        @Test func shapesPolyline01T() throws { try compareToReference("shapes-polyline-01-t") }
        @Test func shapesRect02T() throws { try compareToReference("shapes-rect-02-t") }
    }

    @Suite("Struct")
    struct Struct: SVGTestHelper {
        @Test func structDefs01T() throws { try compareToReference("struct-defs-01-t") }
        @Test func structFrag01T() throws { try compareToReference("struct-frag-01-t") }
        @Test func structUse03T() throws { try compareToReference("struct-use-03-t") }
    }
}

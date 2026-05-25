import Testing
@testable import SVGView

@Suite("SVG 1.1")
struct SVG11Tests {

    @Suite("Color")
    struct Color: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func colorProp01B() async throws { try await compareToReference("color-prop-01-b") }
        @Test func colorProp02F() async throws { try await compareToReference("color-prop-02-f") }
        @Test func colorProp03T() async throws { try await compareToReference("color-prop-03-t") }
        @Test func colorProp04T() async throws { try await compareToReference("color-prop-04-t") }
        @Test func colorProp05T() async throws { try await compareToReference("color-prop-05-t") }
    }

    @Suite("Coords")
    struct Coords: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func coordsCoord01T() async throws { try await compareToReference("coords-coord-01-t") }
        @Test func coordsCoord02T() async throws { try await compareToReference("coords-coord-02-t") }
        @Test func coordsDom01F() async throws { try await compareToReference("coords-dom-01-f") }
        @Test func coordsDom02F() async throws { try await compareToReference("coords-dom-02-f") }
        @Test func coordsDom03F() async throws { try await compareToReference("coords-dom-03-f") }
        @Test func coordsDom04F() async throws { try await compareToReference("coords-dom-04-f") }
        @Test func coordsTrans01B() async throws { try await compareToReference("coords-trans-01-b") }
        @Test func coordsTrans02T() async throws { try await compareToReference("coords-trans-02-t") }
        @Test func coordsTrans03T() async throws { try await compareToReference("coords-trans-03-t") }
        @Test func coordsTrans04T() async throws { try await compareToReference("coords-trans-04-t") }
        @Test func coordsTrans05T() async throws { try await compareToReference("coords-trans-05-t") }
        @Test func coordsTrans06T() async throws { try await compareToReference("coords-trans-06-t") }
        @Test func coordsTrans07T() async throws { try await compareToReference("coords-trans-07-t") }
        @Test func coordsTrans08T() async throws { try await compareToReference("coords-trans-08-t") }
        @Test func coordsTrans09T() async throws { try await compareToReference("coords-trans-09-t") }
        @Test func coordsTrans10F() async throws { try await compareToReference("coords-trans-10-f") }
        @Test func coordsTrans11F() async throws { try await compareToReference("coords-trans-11-f") }
        @Test func coordsTrans12F() async throws { try await compareToReference("coords-trans-12-f") }
        @Test func coordsTrans13F() async throws { try await compareToReference("coords-trans-13-f") }
        @Test func coordsTrans14F() async throws { try await compareToReference("coords-trans-14-f") }
        @Test func coordsTransformattr01F() async throws { try await compareToReference("coords-transformattr-01-f") }
        @Test func coordsTransformattr02F() async throws { try await compareToReference("coords-transformattr-02-f") }
        @Test func coordsTransformattr03F() async throws { try await compareToReference("coords-transformattr-03-f") }
        @Test func coordsTransformattr04F() async throws { try await compareToReference("coords-transformattr-04-f") }
        @Test func coordsTransformattr05F() async throws { try await compareToReference("coords-transformattr-05-f") }
        @Test func coordsUnits02B() async throws { try await compareToReference("coords-units-02-b") }
        @Test func coordsUnits03B() async throws { try await compareToReference("coords-units-03-b") }
    }

    @Suite("Masking")
    struct Masking: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func maskingOpacity01B() async throws { try await compareToReference("masking-opacity-01-b") }
    }

    @Suite("Painting")
    struct Painting: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func paintingControl02F() async throws { try await compareToReference("painting-control-02-f") }
        @Test func paintingControl03F() async throws { try await compareToReference("painting-control-03-f") }
        @Test func paintingFill01T() async throws { try await compareToReference("painting-fill-01-t") }
        @Test func paintingFill02T() async throws { try await compareToReference("painting-fill-02-t") }
        @Test func paintingFill03T() async throws { try await compareToReference("painting-fill-03-t") }
        @Test func paintingFill04T() async throws { try await compareToReference("painting-fill-04-t") }
        @Test func paintingFill05B() async throws { try await compareToReference("painting-fill-05-b") }
        @Test func paintingMarker01F() async throws { try await compareToReference("painting-marker-01-f") }
        @Test func paintingStroke01T() async throws { try await compareToReference("painting-stroke-01-t") }
        @Test func paintingStroke02T() async throws { try await compareToReference("painting-stroke-02-t") }
        @Test func paintingStroke03T() async throws { try await compareToReference("painting-stroke-03-t") }
        @Test func paintingStroke04T() async throws { try await compareToReference("painting-stroke-04-t") }
        @Test func paintingStroke05T() async throws { try await compareToReference("painting-stroke-05-t") }
        @Test func paintingStroke07T() async throws { try await compareToReference("painting-stroke-07-t") }
        @Test func paintingStroke08T() async throws { try await compareToReference("painting-stroke-08-t") }
        @Test func paintingStroke09T() async throws { try await compareToReference("painting-stroke-09-t") }
    }

    @Suite("Paths")
    struct Paths: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func pathsData01T() async throws { try await compareToReference("paths-data-01-t") }
        @Test func pathsData02T() async throws { try await compareToReference("paths-data-02-t") }
        @Test func pathsData03F() async throws { try await compareToReference("paths-data-03-f") }
        @Test func pathsData04T() async throws { try await compareToReference("paths-data-04-t") }
        @Test func pathsData05T() async throws { try await compareToReference("paths-data-05-t") }
        @Test func pathsData06T() async throws { try await compareToReference("paths-data-06-t") }
        @Test func pathsData07T() async throws { try await compareToReference("paths-data-07-t") }
        @Test func pathsData08T() async throws { try await compareToReference("paths-data-08-t") }
        @Test func pathsData09T() async throws { try await compareToReference("paths-data-09-t") }
        @Test func pathsData10T() async throws { try await compareToReference("paths-data-10-t") }
        @Test func pathsData12T() async throws { try await compareToReference("paths-data-12-t") }
        @Test func pathsData13T() async throws { try await compareToReference("paths-data-13-t") }
        @Test func pathsData14T() async throws { try await compareToReference("paths-data-14-t") }
        @Test func pathsData15T() async throws { try await compareToReference("paths-data-15-t") }
        @Test func pathsData16T() async throws { try await compareToReference("paths-data-16-t") }
        @Test func pathsData17F() async throws { try await compareToReference("paths-data-17-f") }
        @Test func pathsData18F() async throws { try await compareToReference("paths-data-18-f") }
        @Test func pathsData19F() async throws { try await compareToReference("paths-data-19-f") }
        @Test func pathsData20F() async throws { try await compareToReference("paths-data-20-f") }
    }

    @Suite("Pservers")
    struct Pservers: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func pserversGrad01B() async throws { try await compareToReference("pservers-grad-01-b") }
        @Test func pserversGrad02B() async throws { try await compareToReference("pservers-grad-02-b") }
        @Test func pserversGrad03B() async throws { try await compareToReference("pservers-grad-03-b") }
        @Test func pserversGrad04B() async throws { try await compareToReference("pservers-grad-04-b") }
        @Test func pserversGrad06B() async throws { try await compareToReference("pservers-grad-06-b") }
        @Test func pserversGrad05B() async throws { try await compareToReference("pservers-grad-05-b") }
        @Test func pserversGrad07B() async throws { try await compareToReference("pservers-grad-07-b") }
        @Test func pserversGrad09B() async throws { try await compareToReference("pservers-grad-09-b") }
    }

    @Suite("Render")
    struct Render: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func renderElems01T() async throws { try await compareToReference("render-elems-01-t") }
        @Test func renderElems02T() async throws { try await compareToReference("render-elems-02-t") }
        @Test func renderElems03T() async throws { try await compareToReference("render-elems-03-t") }
    }

    @Suite("Shapes")
    struct Shapes: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func shapesCircle01T() async throws { try await compareToReference("shapes-circle-01-t") }
        @Test func shapesCircle02T() async throws { try await compareToReference("shapes-circle-02-t") }
        @Test func shapesEllipse01T() async throws { try await compareToReference("shapes-ellipse-01-t") }
        @Test func shapesEllipse02T() async throws { try await compareToReference("shapes-ellipse-02-t") }
        @Test func shapesEllipse03F() async throws { try await compareToReference("shapes-ellipse-03-f") }
        @Test func shapesGrammar01F() async throws { try await compareToReference("shapes-grammar-01-f") }
        @Test func shapesIntro01T() async throws { try await compareToReference("shapes-intro-01-t") }
        @Test func shapesLine01T() async throws { try await compareToReference("shapes-line-01-t") }
        @Test func shapesLine02F() async throws { try await compareToReference("shapes-line-02-f") }
        @Test func shapesPolygon01T() async throws { try await compareToReference("shapes-polygon-01-t") }
        @Test func shapesPolygon02T() async throws { try await compareToReference("shapes-polygon-02-t") }
        @Test func shapesPolygon03T() async throws { try await compareToReference("shapes-polygon-03-t") }
        @Test func shapesPolyline01T() async throws { try await compareToReference("shapes-polyline-01-t") }
        @Test func shapesPolyline02T() async throws { try await compareToReference("shapes-polyline-02-t") }
        @Test func shapesRect02T() async throws { try await compareToReference("shapes-rect-02-t") }
        @Test func shapesRect04F() async throws { try await compareToReference("shapes-rect-04-f") }
        @Test func shapesRect05F() async throws { try await compareToReference("shapes-rect-05-f") }
        @Test func shapesRect06F() async throws { try await compareToReference("shapes-rect-06-f") }
    }

    @Suite("Struct")
    struct Struct: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func structCond01T() async throws { try await compareToReference("struct-cond-01-t") }
        @Test func structCond03T() async throws { try await compareToReference("struct-cond-03-t") }
        @Test func structDefs01T() async throws { try await compareToReference("struct-defs-01-t") }
        @Test func structFrag01T() async throws { try await compareToReference("struct-frag-01-t") }
        @Test func structFrag06T() async throws { try await compareToReference("struct-frag-06-t") }
        @Test func structGroup01T() async throws { try await compareToReference("struct-group-01-t") }
        @Test func structImage01T() async throws { try await compareToReference("struct-image-01-t") }
        @Test func structImage04T() async throws { try await compareToReference("struct-image-04-t") }
        @Test func structUse03T() async throws { try await compareToReference("struct-use-03-t") }
    }

    @Suite("Styling")
    struct Styling: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func stylingClass01F() async throws { try await compareToReference("styling-class-01-f") }
        @Test func stylingCss01B() async throws { try await compareToReference("styling-css-01-b") }
        @Test func stylingPres01T() async throws { try await compareToReference("styling-pres-01-t") }
    }

    @Suite("Types")
    struct Types: SVGTestHelper {
        var dir: String { "1.1F2" }

        @Test func typesBasic01F() async throws { try await compareToReference("types-basic-01-f") }
    }
}

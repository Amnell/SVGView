import Testing
@testable import SVGView

struct CGTests {

    @Test func transformConcatenation() {
        let transform1 = CGAffineTransform(translationX: 5, y: 10)
        let transform2 = CGAffineTransform(scaleX: 2, y: 3)
        let combined = transform1.concatenating(transform2)
        
        #expect(combined.a == 2)
        #expect(combined.d == 3)
        #expect(combined.tx == 10)
        #expect(combined.ty == 30)
    }

}

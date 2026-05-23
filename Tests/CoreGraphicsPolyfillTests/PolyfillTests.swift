//
//  PolyfillTests.swift
//  SVGView
//
//  Tests for CoreGraphicsPolyfill.swift - comprehensive testing of the CoreGraphics
//  polyfill implementation for WASI/Linux platforms where CoreGraphics is not available.
//
//  These tests verify:
//  - CGAffineTransform operations (identity, translation, scaling, rotation, concatenation)
//  - CGPath functionality (basic operations, bounding box calculation, shape addition)
//  - MBezierPath operations (initialization, path building, transformations, arc handling)
//  - PathElement enum and extensions
//  - Edge cases and error handling
//
//  On platforms with native CoreGraphics (macOS, iOS), only a fallback test runs
//  since the polyfill types are aliases to the native CoreGraphics types.
//

import Testing

@testable import SVGView

struct PolyfillTests {
    
    #if os(WASI) || os(Linux)
    
    // MARK: - CGAffineTransform Tests
    
    @Test func affineTransformIdentity() {
        let identity = CGAffineTransform.identity
        #expect(identity.a == 1)
        #expect(identity.b == 0)
        #expect(identity.c == 0)
        #expect(identity.d == 1)
        #expect(identity.tx == 0)
        #expect(identity.ty == 0)
        #expect(identity.isIdentity)
    }
    
    @Test func affineTransformTranslation() {
        let transform = CGAffineTransform(translationX: 10, y: 20)
        #expect(transform.a == 1)
        #expect(transform.b == 0)
        #expect(transform.c == 0)
        #expect(transform.d == 1)
        #expect(transform.tx == 10)
        #expect(transform.ty == 20)
        #expect(!transform.isIdentity)
    }
    
    @Test func affineTransformScale() {
        let transform = CGAffineTransform(scaleX: 2, y: 3)
        #expect(transform.a == 2)
        #expect(transform.b == 0)
        #expect(transform.c == 0)
        #expect(transform.d == 3)
        #expect(transform.tx == 0)
        #expect(transform.ty == 0)
    }
    
    @Test func affineTransformRotation() {
        let transform = CGAffineTransform(rotationAngle: .pi / 2)
        #expect(abs(transform.a - cos(.pi / 2)) <= 1e-10)
        #expect(abs(transform.b - sin(.pi / 2)) <= 1e-10)
        #expect(abs(transform.c - (-sin(.pi / 2))) <= 1e-10)
        #expect(abs(transform.d - cos(.pi / 2)) <= 1e-10)
        #expect(transform.tx == 0)
        #expect(transform.ty == 0)
    }
    
    @Test func pointTransformation() {
        let point = CGPoint(x: 1, y: 2)
        let transform = CGAffineTransform(translationX: 10, y: 20)
        let transformedPoint = point.applying(transform)
        
        #expect(transformedPoint.x == 11)
        #expect(transformedPoint.y == 22)
    }
    
    @Test func transformConcatenation() {
        let transform1 = CGAffineTransform(translationX: 5, y: 10)
        let transform2 = CGAffineTransform(scaleX: 2, y: 3)
        let combined = transform1.concatenating(transform2)
        
        #expect(combined.a == 2)
        #expect(combined.d == 3)
        #expect(combined.tx == 10)
        #expect(combined.ty == 30)
    }
    
    @Test func transformFluent() {
        let transform = CGAffineTransform.identity
            .translatedBy(x: 10, y: 20)
            .scaledBy(x: 2, y: 3)
            .rotated(by: .pi / 4)
        
        #expect(!transform.isIdentity)
        #expect(transform.tx != 0)
        #expect(transform.ty != 0)
    }
    
    @Test func complexTransform() {
        let point = CGPoint(x: 5, y: 5)
        let transform = CGAffineTransform(rotationAngle: .pi / 4)
            .translatedBy(x: 10, y: 10)
            .scaledBy(x: 2, y: 2)
        
        let transformedPoint = point.applying(transform)
        #expect(transformedPoint.x != point.x)
        #expect(transformedPoint.y != point.y)
    }
    
    // MARK: - CGLineJoin and CGLineCap Tests
    
    @Test func lineJoinEnum() {
        let miterJoin = CGLineJoin.miter
        let roundJoin = CGLineJoin.round
        let bevelJoin = CGLineJoin.bevel
        let defaultJoin = CGLineJoin()
        
        #expect(defaultJoin == .miter)
        #expect(miterJoin != roundJoin)
        #expect(roundJoin != bevelJoin)
    }
    
    @Test func lineCapEnum() {
        let buttCap = CGLineCap.butt
        let roundCap = CGLineCap.round
        let squareCap = CGLineCap.square
        let defaultCap = CGLineCap()
        
        #expect(defaultCap == .butt)
        #expect(buttCap != roundCap)
        #expect(roundCap != squareCap)
    }
    
    // MARK: - CGPath Tests
    
    @Test func pathElementCreation() {
        let moveElement = PathElement.moveToPoint(CGPoint(x: 0, y: 0))
        let lineElement = PathElement.addLineToPoint(CGPoint(x: 10, y: 10))
        let _ = PathElement.addQuadCurveToPoint(CGPoint(x: 5, y: 5), CGPoint(x: 10, y: 0))
        let _ = PathElement.addCurveToPoint(CGPoint(x: 5, y: 5), CGPoint(x: 7, y: 3), CGPoint(x: 10, y: 0))
        let closeElement = PathElement.closeSubpath
        
        if case .moveToPoint(let point) = moveElement {
            #expect(point.x == 0)
            #expect(point.y == 0)
        } else {
            Issue.record("Expected moveToPoint")
        }
        
        if case .addLineToPoint(let point) = lineElement {
            #expect(point.x == 10)
            #expect(point.y == 10)
        } else {
            Issue.record("Expected addLineToPoint")
        }
        
        if case .closeSubpath = closeElement {
            // Test passes
        } else {
            Issue.record("Expected closeSubpath")
        }
    }
    
    @Test func pathBasicOperations() {
        let path = CGPath()
        #expect(path.elements.isEmpty)
        
        path.move(to: CGPoint(x: 0, y: 0))
        #expect(path.elements.count == 1)
        
        path.addLine(to: CGPoint(x: 10, y: 10))
        #expect(path.elements.count == 2)
        
        path.closeSubpath()
        #expect(path.elements.count == 3)
    }
    
    @Test func pathBoundingBox() {
        let path = CGPath()
        path.move(to: CGPoint(x: 5, y: 5))
        path.addLine(to: CGPoint(x: 15, y: 10))
        path.addLine(to: CGPoint(x: 10, y: 20))
        
        let bounds = path.boundingBoxOfPath
        #expect(bounds.minX == 5)
        #expect(bounds.minY == 5)
        #expect(bounds.maxX == 15)
        #expect(bounds.maxY == 20)
        #expect(bounds.width == 10)
        #expect(bounds.height == 15)
    }
    
    @Test func pathBoundingBoxWithCurves() {
        let path = CGPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addCurve(to: CGPoint(x: 10, y: 10), control1: CGPoint(x: 5, y: 5), control2: CGPoint(x: 15, y: 8))
        
        let bounds = path.boundingBoxOfPath
        #expect(bounds.minX == 0)
        #expect(bounds.minY == 0)
        #expect(bounds.maxX == 15)
        #expect(bounds.maxY == 10)
    }
    
    @Test func pathAddRect() {
        let path = CGPath()
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        path.addRect(rect)
        
        #expect(path.elements.count == 5) // move + 3 lines + close
        
        let bounds = path.boundingBoxOfPath
        #expect(bounds == rect)
    }
    
    @Test func pathAddEllipse() {
        let path = CGPath()
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        path.addEllipse(in: rect)
        
        #expect(!path.elements.isEmpty)
        
        let bounds = path.boundingBoxOfPath
        // Ellipse should fit within the rectangle (approximately)
        #expect(bounds.minX >= rect.minX - 1)
        #expect(bounds.minY >= rect.minY - 1)
        #expect(bounds.maxX <= rect.maxX + 1)
        #expect(bounds.maxY <= rect.maxY + 1)
    }
    
    @Test func pathQuadCurve() {
        let path = CGPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(to: CGPoint(x: 10, y: 10), control: CGPoint(x: 5, y: 0))
        
        #expect(path.elements.count == 2)
        
        if case .addQuadCurveToPoint(let control, let end) = path.elements[1] {
            #expect(control.x == 5)
            #expect(control.y == 0)
            #expect(end.x == 10)
            #expect(end.y == 10)
        } else {
            Issue.record("Expected quad curve element")
        }
    }
    
    // MARK: - MBezierPath Tests
    
    @Test func bezierPathInit() {
        let path = MBezierPath()
        #expect(path.isEmpty)
        #expect(path.cgPath.elements.isEmpty)
    }
    
    @Test func bezierPathRectInit() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        let path = MBezierPath(rect: rect)
        
        #expect(path != nil)
        #expect(!path!.isEmpty)
        #expect(path!.bounds == rect)
    }
    
    @Test func bezierPathOvalInit() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = MBezierPath(ovalIn: rect)
        
        #expect(path != nil)
        #expect(!path!.isEmpty)
    }
    
    @Test func bezierPathArcInit() {
        let center = CGPoint(x: 50, y: 50)
        let radius: CGFloat = 25
        let path = MBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi,
            clockwise: true
        )
        
        #expect(!path.isEmpty)
    }
    
    @Test func bezierPathOperations() {
        let path = MBezierPath()
        
        path.move(to: CGPoint(x: 0, y: 0))
        #expect(!path.isEmpty)
        
        path.addLine(to: CGPoint(x: 10, y: 10))
        path.addQuadCurve(to: CGPoint(x: 20, y: 0), controlPoint: CGPoint(x: 15, y: -5))
        path.addCurve(
            to: CGPoint(x: 30, y: 10),
            controlPoint1: CGPoint(x: 25, y: 5),
            controlPoint2: CGPoint(x: 28, y: 8)
        )
        path.close()
        
        #expect(path.cgPath.elements.count == 5)
    }
    
    @Test func bezierPathTransform() {
        let path = MBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 10, y: 10))
        
        let originalBounds = path.bounds
        let transform = CGAffineTransform(scaleX: 2, y: 2)
        path.apply(transform)
        
        let newBounds = path.bounds
        #expect(abs(newBounds.width - originalBounds.width * 2) <= 1e-10)
        #expect(abs(newBounds.height - originalBounds.height * 2) <= 1e-10)
    }
    
    @Test func bezierPathAppend() {
        let path1 = MBezierPath()
        path1.move(to: CGPoint(x: 0, y: 0))
        path1.addLine(to: CGPoint(x: 10, y: 10))
        
        let path2 = MBezierPath()
        path2.move(to: CGPoint(x: 20, y: 20))
        path2.addLine(to: CGPoint(x: 30, y: 30))
        
        let originalCount = path1.cgPath.elements.count
        path1.append(path2)
        
        #expect(path1.cgPath.elements.count == originalCount + path2.cgPath.elements.count)
    }
    
    @Test func bezierPathArc() {
        let path = MBezierPath()
        let center = CGPoint(x: 50, y: 50)
        let radius: CGFloat = 25
        
        path.addArc(
            withCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
        
        #expect(!path.isEmpty)
        #expect(path.cgPath.elements.count > 1)
    }
    
    @Test func bezierPathArcCounterClockwise() {
        let path = MBezierPath()
        let center = CGPoint(x: 0, y: 0)
        let radius: CGFloat = 10
        
        path.addArc(
            withCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: -.pi / 2,
            clockwise: false
        )
        
        #expect(!path.isEmpty)
    }
    
    @Test func bezierPathFullCircleArc() {
        let path = MBezierPath()
        let center = CGPoint(x: 50, y: 50)
        let radius: CGFloat = 25
        
        path.addArc(
            withCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        
        #expect(!path.isEmpty)
        #expect(path.cgPath.elements.count > 4) // Should have multiple segments
    }
    
    // MARK: - PathElement Extension Tests
    
    @Test func pathElementLastPoint() {
        let moveElement = PathElement.moveToPoint(CGPoint(x: 5, y: 10))
        let lineElement = PathElement.addLineToPoint(CGPoint(x: 15, y: 20))
        let closeElement = PathElement.closeSubpath
        
        #expect(moveElement.lastPoint == CGPoint(x: 5, y: 10))
        #expect(lineElement.lastPoint == CGPoint(x: 15, y: 20))
        #expect(closeElement.lastPoint == nil)
    }
    
    @Test func pathElementIsCloseSubpath() {
        let moveElement = PathElement.moveToPoint(CGPoint(x: 0, y: 0))
        let closeElement = PathElement.closeSubpath
        
        #expect(!moveElement.isCloseSubpath)
        #expect(closeElement.isCloseSubpath)
    }
    
    @Test func pathElementLastPointWithCurves() {
        let quadElement = PathElement.addQuadCurveToPoint(CGPoint(x: 5, y: 5), CGPoint(x: 10, y: 10))
        let curveElement = PathElement.addCurveToPoint(CGPoint(x: 1, y: 1), CGPoint(x: 2, y: 2), CGPoint(x: 3, y: 3))
        
        #expect(quadElement.lastPoint == CGPoint(x: 10, y: 10))
        #expect(curveElement.lastPoint == CGPoint(x: 3, y: 3))
    }
    
    // MARK: - CGPathElement Tests
    
    @Test func cgPathElementCreation() {
        let element = CGPathElement(
            type: .moveToPoint,
            points: (CGPoint(x: 1, y: 2), CGPoint.zero, CGPoint.zero)
        )
        
        #expect(element.type == .moveToPoint)
        #expect(element.points[0] == CGPoint(x: 1, y: 2))
    }
    
    // MARK: - CGPathElementType Tests
    
    @Test func cgPathElementTypeEnum() {
        let moveType = CGPathElementType.moveToPoint
        let lineType = CGPathElementType.addLineToPoint
        let quadType = CGPathElementType.addQuadCurveToPoint
        let curveType = CGPathElementType.addCurveToPoint
        let closeType = CGPathElementType.closeSubpath
        
        // Ensure all enum cases are distinct
        #expect(moveType != lineType)
        #expect(lineType != quadType)
        #expect(quadType != curveType)
        #expect(curveType != closeType)
        #expect(closeType != moveType)
    }
    
    // MARK: - CGPathFillRule Tests
    
    @Test func cgPathFillRuleEnum() {
        let evenOdd = CGPathFillRule.evenOdd
        let winding = CGPathFillRule.winding
        
        #expect(evenOdd != winding)
        #expect(evenOdd.rawValue != winding.rawValue)
    }
    
    @Test func cgPathFillRuleRawValues() {
        // Test that raw values are distinct and valid
        let evenOdd = CGPathFillRule.evenOdd
        let winding = CGPathFillRule.winding
        
        #expect(CGPathFillRule(rawValue: evenOdd.rawValue) != nil)
        #expect(CGPathFillRule(rawValue: winding.rawValue) != nil)
        #expect(CGPathFillRule(rawValue: evenOdd.rawValue) == evenOdd)
        #expect(CGPathFillRule(rawValue: winding.rawValue) == winding)
    }
    
    // MARK: - MBezierPath Static Method Tests
    
    @Test func mBezierPathAddArcToStatic() {
        let path = CGPath()
        let center = CGPoint(x: 10, y: 10)
        let radius: CGFloat = 5
        
        // Test static addArcTo method directly
        MBezierPath.addArcTo(
            path: path,
            center: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
        
        #expect(!path.elements.isEmpty)
        #expect(path.elements.count > 1)
        
        // First element should be move to starting point
        if case .moveToPoint(let point) = path.elements.first {
            #expect(abs(point.x - (center.x + radius)) <= 1e-10)
            #expect(abs(point.y - center.y) <= 1e-10)
        } else {
            Issue.record("Expected first element to be moveToPoint")
        }
    }
    
    @Test func mBezierPathAddArcToStaticWithExistingPath() {
        let path = CGPath()
        path.move(to: CGPoint(x: 20, y: 20))
        path.addLine(to: CGPoint(x: 25, y: 25))
        
        let originalCount = path.elements.count
        
        // Add arc to existing path
        MBezierPath.addArcTo(
            path: path,
            center: CGPoint(x: 0, y: 0),
            radius: 10,
            startAngle: 0,
            endAngle: .pi,
            clockwise: false
        )
        
        // Should have added more elements
        #expect(path.elements.count > originalCount)
    }
    
    // MARK: - Edge Cases
    
    @Test func emptyPathBounds() {
        let path = CGPath()
        let bounds = path.boundingBoxOfPath
        
        #expect(bounds.width.isInfinite || bounds.width.isNaN)
        #expect(bounds.height.isInfinite || bounds.height.isNaN)
    }
    
    @Test func singlePointPathBounds() {
        let path = CGPath()
        path.move(to: CGPoint(x: 10, y: 20))
        
        let bounds = path.boundingBoxOfPath
        #expect(bounds.origin.x == 10)
        #expect(bounds.origin.y == 20)
        #expect(bounds.width == 0)
        #expect(bounds.height == 0)
    }
    
    @Test func zeroRadiusArc() {
        let path = MBezierPath()
        path.addArc(
            withCenter: CGPoint(x: 0, y: 0),
            radius: 0,
            startAngle: 0,
            endAngle: .pi,
            clockwise: true
        )
        
        // With zero radius, it creates move + curve elements all at center point
        #expect(!path.isEmpty)
        #expect(path.cgPath.elements.count == 3) // move + 2 curves for pi angle
        
        // First element should be moveToPoint at center
        if case .moveToPoint(let point) = path.cgPath.elements[0] {
            #expect(point.x == 0)
            #expect(point.y == 0)
        } else {
            Issue.record("Expected first element to be moveToPoint")
        }
        
        // All curve elements should have all points at center
        for element in path.cgPath.elements.dropFirst() {
            if case .addCurveToPoint(let cp1, let cp2, let end) = element {
                #expect(cp1.x == 0)
                #expect(cp1.y == 0)
                #expect(cp2.x == 0)
                #expect(cp2.y == 0)
                #expect(end.x == 0)
                #expect(end.y == 0)
            } else {
                Issue.record("Expected curve element")
            }
        }
    }
    
    @Test func verySmallAngleArc() {
        let path = MBezierPath()
        path.addArc(
            withCenter: CGPoint(x: 0, y: 0),
            radius: 10,
            startAngle: 0,
            endAngle: 1e-10,
            clockwise: true
        )
        
        // Should handle very small angles (essentially no arc)
        #expect(path.isEmpty || path.cgPath.elements.count <= 2)
    }
    
    @Test func identicalStartEndAngles() {
        let path = MBezierPath()
        path.addArc(
            withCenter: CGPoint(x: 0, y: 0),
            radius: 10,
            startAngle: .pi / 4,
            endAngle: .pi / 4,
            clockwise: true
        )
        
        // Should handle identical start and end angles
        #expect(path.isEmpty || path.cgPath.elements.count <= 1)
    }
    
    @Test func negativeRectDimensions() {
        let path = CGPath()
        let rect = CGRect(x: 10, y: 10, width: -5, height: -5)
        path.addRect(rect)
        
        // Should handle negative dimensions
        #expect(!path.elements.isEmpty)
    }
    
    #else
    
    @Test func polyfillNotNeeded() {
        // On platforms with CoreGraphics, polyfill types should be aliases
    }
    
    #endif
}

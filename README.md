# SVGView

# Overview
This is a fork of [exyte/SVGView](https://github.com/exyte/SVGView) that tailored to Goodnotes's specific needs:
- Crossplatform compatible (at least the parser logic)
- Add support for some custom SVG tags 

# Development

This uses `make` heavily for relevant scripts. Run `make` without arguments to see the available commands.

See [CONTRIBUTING.md](CONTRIBUTING.md) for a step-by-step guide on identifying missing SVG spec features and implementing them, including how to write tests and generate reference snapshots.

## To add a new SVG test:
- Update `cli.swift` to include the svg file path
- `make generate-test-cases` to generate the unit test files
- `make update-references-snapshots` to update the .ref snapshots.
 
# Usage

Get started with `SVGView` in a few lines of code:

```Swift
struct ContentView: View {
    var body: some View {
        SVGView(contentsOf: Bundle.main.url(forResource: "example", withExtension: "svg")!)
    }
}
```

## Customization

You can change various parameters for the nodes like this:

```Swift
let circle = SVGCircle(cx: 30, cy: 30, r: 30)
circle.fill = SVGColor.black
circle.stroke = SVGStroke(fill: SVGColor(hex: "ABCDEF"), width: 2)
circle.onTapGesture {
    print("tap")
}
```

## Interact with vector elements

You may locate the desired part of your SVG file using standard identifiers to add gestures and change its properties in runtime:

```Swift
struct ContentView: View {
    var body: some View {
        let view = SVGView(contentsOf: Bundle.main.url(forResource: "example", withExtension: "svg")!)
        if let part = view.getNode(byId: "part") {
            part.onTapGesture {
                part.opacity = 0.2
            }
        }
        return view
    }
}
```

## Animation

You can use standard SwiftUI tools to animate your image:

```Swift
if let part = view.getNode(byId: "part") {
    part.onTapGesture {
        withAnimation {
            part.opacity = 0.2
        }
    }
}
```

## Complex effects

SVGView makes it easy to add custom effects to your app. For example, make this <a href="https://www.iconfinder.com/icons/1337497/">pikachu</a> track finger movement:

```Swift
var body: some View {
    let view = SVGView(contentsOf: Bundle.main.url(forResource: "pikachu", withExtension: "svg")!)
    let delta = CGAffineTransform(translationX: getEyeX(), y: 0)
    view.getNode(byId: "eye1")?.transform = delta
    view.getNode(byId: "eye2")?.transform = delta

    return view.gesture(DragGesture().onChanged { g in
        self.x = g.location.x
    })
}
```

<img src="https://i.imgur.com/Ij0Xn4A.gif" width="300" height="300">

# SVG Tests Coverage

Our mission is to provide 100% support of all SVG standards: 1.1 (Second Edition), Tiny 1.2 and 2.0. However, this project is at its very beginning, so you can follow our progress on <a href="w3c-coverage.md">this page</a>. You can also check out <a href="https://github.com/exyte/SVGViewTests">SVGViewTests project</a> to see how well this framework handles every single SVG test case.

# Installation

## Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/exyte/SVGView.git")
]
```

## CocoaPods

```ruby
pod 'SVGView'
```

## Carthage

```ogdl
github "Exyte/SVGView"
```

# Requirements

* iOS 14+ / watchOS 7+ / macOS 11+
* Xcode 12+

## Our other open source SwiftUI libraries
[PopupView](https://github.com/exyte/PopupView) - Toasts and popups library    
[AnchoredPopup](https://github.com/exyte/AnchoredPopup) - Anchored Popup grows "out" of a trigger view (similar to Hero animation)    
[Grid](https://github.com/exyte/Grid) - The most powerful Grid container    
[ScalingHeaderScrollView](https://github.com/exyte/ScalingHeaderScrollView) - A scroll view with a sticky header which shrinks as you scroll    
[AnimatedTabBar](https://github.com/exyte/AnimatedTabBar) - A tabbar with a number of preset animations   
[MediaPicker](https://github.com/exyte/mediapicker) - Customizable media picker     
[Chat](https://github.com/exyte/chat) - Chat UI framework with fully customizable message cells, input view, and a built-in media picker  
[OpenAI](https://github.com/exyte/OpenAI) Wrapper lib for [OpenAI REST API](https://platform.openai.com/docs/api-reference/introduction)    
[AnimatedGradient](https://github.com/exyte/AnimatedGradient) - Animated linear gradient     
[ConcentricOnboarding](https://github.com/exyte/ConcentricOnboarding) - Animated onboarding flow    
[FloatingButton](https://github.com/exyte/FloatingButton) - Floating button menu    
[ActivityIndicatorView](https://github.com/exyte/ActivityIndicatorView) - A number of animated loading indicators    
[ProgressIndicatorView](https://github.com/exyte/ProgressIndicatorView) - A number of animated progress indicators    
[FlagAndCountryCode](https://github.com/exyte/FlagAndCountryCode) - Phone codes and flags for every country    
[LiquidSwipe](https://github.com/exyte/LiquidSwipe) - Liquid navigation animation    


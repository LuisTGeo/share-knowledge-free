import AppKit
import ImageIO
import UniformTypeIdentifiers
let size = 1024
let space = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(CGColor(red: 0.135, green: 0.161, blue: 0.135, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
ctx.translateBy(x: 0, y: 1024); ctx.scaleBy(x: 1, y: -1)
ctx.setStrokeColor(CGColor(red: 0.84, green: 0.92, blue: 0.72, alpha: 1))
ctx.setLineWidth(48); ctx.setLineCap(.round); ctx.setLineJoin(.round)
ctx.move(to: CGPoint(x: 370, y: 280)); ctx.addLine(to: CGPoint(x: 370, y: 590)); ctx.addQuadCurve(to: CGPoint(x: 510, y: 730), control: CGPoint(x: 370, y: 730)); ctx.addLine(to: CGPoint(x: 690, y: 730)); ctx.strokePath()
ctx.move(to: CGPoint(x: 370, y: 435)); ctx.addLine(to: CGPoint(x: 510, y: 435)); ctx.addQuadCurve(to: CGPoint(x: 665, y: 280), control: CGPoint(x: 665, y: 435)); ctx.strokePath()
ctx.move(to: CGPoint(x: 295, y: 280)); ctx.addLine(to: CGPoint(x: 445, y: 280)); ctx.move(to: CGPoint(x: 590, y: 280)); ctx.addLine(to: CGPoint(x: 740, y: 280)); ctx.move(to: CGPoint(x: 690, y: 655)); ctx.addLine(to: CGPoint(x: 690, y: 805)); ctx.strokePath()
let image = ctx.makeImage()!
let url = URL(fileURLWithPath: "PromptStrava/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
precondition(CGImageDestinationFinalize(destination))

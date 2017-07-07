import XCTest

@discardableResult
public func assertScreenshot(
  matching view: UIView,
  _ file: StaticString = #file,
  _ function: String = #function,
  _ line: UInt = #line)
  -> XCTAttachment? {

    let fileURL = URL(fileURLWithPath: String(describing: file))
    let screenshotsURL = fileURL.deletingLastPathComponent().appendingPathComponent("__Screenshots__")
    let fileManager = FileManager.default

    try! fileManager.createDirectory(
      at: screenshotsURL,
      withIntermediateDirectories: true,
      attributes: nil
    )

    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
    let context = UIGraphicsGetCurrentContext()!
    view.layer.render(in: context)
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    let data = UIImagePNGRepresentation(image)!

    let screenshotURL = screenshotsURL
      .appendingPathComponent("\(fileURL.deletingPathExtension().lastPathComponent).\(function).png")

    guard fileManager.fileExists(atPath: screenshotURL.path) else {
      try! data.write(to: screenshotURL)
      return nil
    }

    let existingData = try! Data(contentsOf: screenshotURL)

    guard existingData == data else {
      let imageDiff = diff(image, UIImage(data: existingData)!)
      let attachment = XCTAttachment(image: imageDiff)
      attachment.lifetime = .deleteOnSuccess

      XCTAssert(
        false,
        "\(screenshotURL.debugDescription) does not match screenshot",
        file: file,
        line: line
      )

      return attachment
    }

    return nil
}

func diff(_ a: UIImage, _ b: UIImage) -> UIImage {
  let maxSize = CGSize(width: max(a.size.width, b.size.width), height: max(a.size.height, b.size.height))
  UIGraphicsBeginImageContextWithOptions(maxSize, true, 0)
  let context = UIGraphicsGetCurrentContext()!
  a.draw(in: CGRect(origin: .zero, size: a.size))
  context.setAlpha(0.5)
  context.beginTransparencyLayer(auxiliaryInfo: nil)
  b.draw(in: CGRect(origin: .zero, size: b.size))
  context.setBlendMode(.difference)
  context.setFillColor(UIColor.white.cgColor)
  context.fill(CGRect(origin: .zero, size: a.size))
  context.endTransparencyLayer()
  let image = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  return image
}
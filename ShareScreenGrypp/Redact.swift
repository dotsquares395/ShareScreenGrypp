import UIKit
extension UIView {
    func sensitiveSubviews(identifier: String = "sensitive") -> [UIView] {
        var result: [UIView] = []
        if self.accessibilityIdentifier == identifier {
            result.append(self)
        }
        for subview in subviews {
            result.append(contentsOf: subview.sensitiveSubviews(identifier: identifier))
        }
        return result
    }
}

extension UIImage {
    func redact(rect: CGRect, color: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero)
        color.setFill()
        UIRectFill(rect)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
extension UIImage {
    func redactWithBlur(in rect: CGRect) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }

        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(10.0, forKey: kCIInputRadiusKey) // Adjust the blur strength

        guard let outputCIImage = blurFilter?.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputCIImage, from: ciImage.extent) else { return nil }

        // Start drawing the final image
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        draw(at: .zero)

        if let blurredPart = cgImage.cropping(to: rect) {
            let blurredUIImage = UIImage(cgImage: blurredPart)
            blurredUIImage.draw(in: rect)
        }

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

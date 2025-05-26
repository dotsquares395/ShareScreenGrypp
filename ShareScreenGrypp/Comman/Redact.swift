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

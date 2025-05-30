
import Foundation
import UIKit

struct DrawEndSignal: Codable {
    let action: String
    let eventId: String
    let order: Int
    let totalChunks: Int
    let value: String
}

struct FabricPathObject: Codable {
    let stroke: String?
    let strokeWidth: CGFloat?
    let path: [[PathCommandValue]]
}

enum PathCommandValue: Codable {
    case string(String)
    case number(CGFloat)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let num = try? container.decode(CGFloat.self) {
            self = .number(num)
        } else {
            throw DecodingError.typeMismatch(PathCommandValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid path value"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str): try container.encode(str)
        case .number(let num): try container.encode(num)
        }
    }
}

func extractPoints(from path: [[PathCommandValue]]) -> [CGPoint] {
    var points = [CGPoint]()
    for segment in path {
        guard segment.count >= 3 else { continue }
        if case let .number(xVal) = segment[1],
           case let .number(yVal) = segment[2] {
            points.append(CGPoint(x: xVal, y: yVal))
        }
    }
    return points
}

public protocol sessionConnectGryppDelegate: AnyObject { 
    func sessionConnectGryppSuccess(value: String)
    func sessionDisconnectGryppSuccess(value: String)
    func sessionConnectGryppFailure(error: Error)
    func sessionPublishSuccess(value: String)
    func sessionPublishFailure(error: Error)
    
}

extension UIWindow {
    func topMostViewController() -> UIViewController? {
        var top = self.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    func topMostView() -> UIView? {
        return self.topMostViewController()?.view
    }
}

extension String {
    func toJSON() -> NSDictionary? {
        guard let data = self.data(using: .utf8) else { return nil }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? NSDictionary
        } catch {
            print("JSON parsing error: \(error)")
            return nil
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension Notification.Name {
    static let orientationChanged = Notification.Name("Orientation")
}


class DrawingView: UIView {
    
    private var points: [CGPoint] = []
    func addPoint(_ point: CGPoint) {
        points.append(point)
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setFillColor(UIColor.red.cgColor)
        for point in points {
            let rect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
            context.fillEllipse(in: rect)
        }
    }
}

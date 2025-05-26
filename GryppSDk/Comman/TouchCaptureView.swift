import UIKit
class TouchCaptureView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        GryppTokManager.shared.handleTouch(at: point, event: "hitTest")
        return nil // Pass the touch through
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
        reportTouches(touches, type: "began")
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesMoved>>>>>>>")
        reportTouches(touches, type: "moved")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesEnded>>>>>>>")
        reportTouches(touches, type: "ended")
    }

    private func reportTouches(_ touches: Set<UITouch>, type: String) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        GryppTokManager.shared.handleTouch(at: point, event: type)
    }
}




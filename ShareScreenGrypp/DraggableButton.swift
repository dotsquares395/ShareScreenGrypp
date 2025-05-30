import UIKit

public class DraggableButton: UIButton {
    public var onTap: (() -> Void)?
    private var panGesture: UIPanGestureRecognizer!
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .systemBlue
        setTitle("+", for: .normal)
        setTitleColor(.white, for: .normal)
        clipsToBounds = true
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
     }
    
    @objc private func tapped() {
        onTap?()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        
        let translation = gesture.translation(in: superview)
        var newCenter = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        
        let halfWidth = bounds.width / 2
        let halfHeight = bounds.height / 2
        
        newCenter.x = max(halfWidth, min(superview.bounds.width - halfWidth, newCenter.x))
        newCenter.y = max(halfHeight, min(superview.bounds.height - halfHeight, newCenter.y))
        
        center = newCenter
        gesture.setTranslation(.zero, in: superview)
    }
}

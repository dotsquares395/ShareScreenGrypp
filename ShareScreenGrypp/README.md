![ImagePicker](https://github.com/dotsquares395/ShareScreenGrypp/blob/main/ShareScreenGrypp/VIewController/Screenshot_ScreenShare.png)

## Description

**ShareScreenGrypp** I’ve developed a custom SDK that enables seamless screen sharing from a user’s mobile app to a web-based PlayConsole. It features secure session management, real-time screen streaming, and interactive tools like marker drawing and live cursor tracking from the web console. Users can see the agent’s cursor within the app for collaborative support. The SDK also includes options to end or disable sessions anytime, ensuring full control and privacy for both users and agents.


## Usage

**ShareScreenGrypp** works as a normal controller, just instantiate it and present it.

```swift
    import ShareScreenGrypp
```

**ShareScreenGrypp** "Call the connectScreenSharing function from your view controller’s button action, passing your app’s UIWindow. Ensure that appView is properly set to the interface you want to share during screen sharing."

```swift
    GryppTokManager.connectScreenSharing(appWindow:  UIWindow()) // Pass your app window
```

**ShareScreenGrypp** "Use the FloatingButtonManager class from GryppFloatingButton to display the floating button for initiating screen sharing. This should be called in your view controller’s viewDidLoad or similar lifecycle method."

```swift
 protocol SessionConnectionDelegate {
    func SessionConnectionDelegate(value: String)
 }

class FloatingButtonManager {
    static let shared = FloatingButtonManager()
    public var floatingButton: UIButton?
    public var buttonTittle = "GRYPP"
    private var window: UIWindow?
    private var windowObject: UIWindow?
    private init() {}
    var delegate: SessionConnectionDelegate?
    var button = UIButton(type: .custom)
    
    // Added a property to track if the button has been tapped
    private var buttonTappedOnce = false
    
    func showFloatingButton(windowObjectRef: UIWindow) {
        if floatingButton != nil {
            return
        }
        windowObject = windowObjectRef
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            window = PassthroughWindow(windowScene: scene!)
        } else {
            window = PassthroughWindow(frame: UIScreen.main.bounds)
        }
        
        window?.windowLevel = .alert + 1
        window?.isHidden = false
        gryppSessionConnectButton()
    }
    
    public func gryppSessionConnectButton() {
        let font = UIFont.systemFont(ofSize: UIDevice.current.userInterfaceIdiom == .pad ? 20 : 12)
        let titleSize = (buttonTittle).size(withAttributes: [.font: font])
        let horizontalPadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 40 : 30
        let buttonWidth = titleSize.width + horizontalPadding
        button.frame = CGRect(x: UIScreen.main.bounds.width - buttonWidth, y: UIScreen.main.bounds.height - 140, width: buttonWidth, height: 50)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 25
        button.setTitle(buttonTittle, for: .normal)
        button.titleLabel?.font = font
        button.setTitleColor(.white, for: .normal)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.8
        button.layer.shadowRadius = 4
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        button.addGestureRecognizer(panGesture)
        window?.addSubview(button)
        floatingButton = button
    }
    
    func hideFloatingButton() {
        floatingButton?.removeFromSuperview()
        floatingButton = nil
        window?.isHidden = true
        window = nil
    }
    
    @objc func buttonTapped() {
        delegate?.SessionConnectionDelegate(value: button.titleLabel?.text ?? "")
        
        // Check if the button has already been tapped
        if !buttonTappedOnce {
            buttonTappedOnce = true // Set the flag
            // Disable the button
            button.isEnabled = false
            button.alpha = 0.5
            
            // Re-enable the button after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.buttonTappedOnce = false // Reset the flag
                self.button.isEnabled = true
                self.button.alpha = 1.0
            }
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let button = gesture.view else { return }
        let translation = gesture.translation(in: window)
        button.center = CGPoint(x: button.center.x + translation.x, y: button.center.y + translation.y)
        gesture.setTranslation(.zero, in: window)
        if let window = window {
            let halfX = button.bounds.width / 2
            let halfY = button.bounds.height / 2
            
            var newX = button.center.x
            var newY = button.center.y
            
            let minX = halfX
            let minY = halfY
            let maxX = window.bounds.width - halfX
            let maxY = window.bounds.height - halfY
            newX = max(minX, min(newX, maxX))
            newY = max(minY, min(newY, maxY))
            
            button.center = CGPoint(x: newX, y: newY)
        }
    }
 }
 
```

**ShareScreenGrypp** You need to call methods on the FloatingButtonManager from your view controller. or call SessionConnectionDelegate method to handle button actions.


   
```swift

    SessionConnectionDelegate // call your viewcontroller

    FloatingButtonManager.shared.delegate = self
    FloatingButtonManager.shared.showFloatingButton(windowObjectRef: scene.window ?? UIWindow())
    
     func SessionConnectionDelegate(value: String) {
        if let scene = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            if value == "GRYPP" {
                GryppTokManager.connectScreenSharing(appWindow: scene.window ?? UIWindow())
            }else{
                GryppTokManager.disconnectScreenSharing()
            }
         
            GryppTokManager.sessionDelegate = self
         }
      }
```

**ShareScreenGrypp** Your view controller should implement the sessionDelegate methods to manage session events.

```swift
extension Your viewController : sessionConnectGryppDelegate {
    func sessionPublishSuccess(value: String) {
        FloatingButtonManager.shared.buttonTittle  = "CAPTURING SCREEN"
        FloatingButtonManager.shared.gryppSessionConnectButton()
    }
    
    func sessionPublishFailure(error: any Error) {
        FloatingButtonManager.shared.buttonTittle  = "GRYPP"
        FloatingButtonManager.shared.gryppSessionConnectButton()
    }
    
    func sessionConnectGryppSuccess(value : String) {
        print("value>>>>>>",value)
    }
    
    func sessionDisconnectGryppSuccess(value : String) {
        FloatingButtonManager.shared.buttonTittle  = "GRYPP"
        FloatingButtonManager.shared.gryppSessionConnectButton()
    }
    
    func sessionConnectGryppFailure(error: any Error) {
        FloatingButtonManager.shared.buttonTittle  = "GRYPP"
        FloatingButtonManager.shared.gryppSessionConnectButton()
    }
}
```

**ShareScreenGrypp** please allow permission

```swift
  - camera 
  - microphone
```

![ImagePicker](https://github.com/dotsquares395/ShareScreenGrypp/blob/main/ShareScreenGrypp/VIewController/Screenshot_Permission.png)
![ImagePicker](https://github.com/dotsquares395/ShareScreenGrypp/blob/main/ShareScreenGrypp/VIewController/Screenshot_Maker.png)
![ImagePicker](https://github.com/dotsquares395/ShareScreenGrypp/blob/main/ShareScreenGrypp/VIewController/Screenshot_EndSission.png)


## Installation

**ScreenSharing** is available through [CocoaPods](https://cocoapods.org/pods/ShareScreenGrypp).
 To install it, simply add the following line to your Podfile:

```ruby
pod 'ShareScreenGrypp'
```


```ruby
github "dotsquares395/ScreenSharing"
```

## Author

[dotsquares395] made this with ❤️


## License

**ShareScreenGrypp** is available under the MIT license. See the [LICENSE](https://github.com/dotsquares395/ScreenSharing/?tab=MIT-1-ov-file) file for more info.
Copyright (c) 2024 Dotsquares Ltd


**ShareScreenGrypp** version vs Swift version.

ScreenSharing 13.0+ is Swift 5 ready! 🎉

If you use earlier version of Swift - refer to the table below:

| Swift version | ImageViewer version               |
| ------------- | --------------------------------- |
| 5.x           | >= 13.0                       |





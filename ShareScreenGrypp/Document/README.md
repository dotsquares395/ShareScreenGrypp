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





import Foundation
import OpenTok
import UIKit

public class GryppTokManager: NSObject {
    // MARK: - Singleton & Delegates
    public static let shared = GryppTokManager()
    public static var appWindow: UIWindow?
    public static var popupView: UIView?
    public static var sessionDelegate: sessionConnectGryppDelegate?

    // MARK: - OpenTok Properties
    private var session: OTSession?
    private var capturer: ScreenCapturer?
    private var publisher: OTPublisher?
    private var gryppSession: GryppSession?

    // MARK: - UI Elements
    private let agentCursorView = UIView()
    private let agentCursorDotView = UIView()
    private let agentNameLabel = UILabel()
    private let localCursorView = UIView()
    private let localCursorDotView = UIView()
    private let localNameLabel = UILabel()
    private var customPopupView: CustomPopupView?

    // MARK: - Observers
    private var backgroundObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?

    // MARK: - Drawing
    private var drawChunks: [String: [DrawEndSignal]] = [:]

    // MARK: - Init/Deinit
    private override init() {
        super.init()
        setupAppStateObservers()
        if let view = GryppTokManager.appWindow?.topMostView() {
                let touchView = TouchCaptureView(frame: view.bounds)
                touchView.backgroundColor = .clear
                touchView.isUserInteractionEnabled = true
                touchView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view.addSubview(touchView)
            }
      }

    deinit {
        removeAppStateObservers()
    }

    // MARK: - Public API

    public static func connectScreenSharing(appWindow: UIWindow) {
        self.appWindow = appWindow
        shared.fetchScreenSharingDetails()
    }

    public static func disconnectScreenSharing() {
        shared.showEndSessionPopup()
    }

    public static func setUpDraggableButton(view: UIWindow, frame: CGRect) -> DraggableButton {
        let button = DraggableButton(frame: frame)
        view.addSubview(button)
        return button
    }

    public func disconnectFromSession() {
        var error: OTError?
        session?.disconnect(&error)
        print(error == nil ? "Disconnected from session" : "Error disconnecting: \(error!.localizedDescription)")
    }

    // MARK: - App State Observers
//
//    private func setupAppStateObservers() {
//        backgroundObserver = NotificationCenter.default.addObserver(
//            forName:  Notification.Name.UIApplication.willEnterForeground,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in self?.capturer?.stop() }
//
//        foregroundObserver = NotificationCenter.default.addObserver(
//            forName: NSNotification.Name.UIApplication.willEnterForegroundNotification,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in self?.capturer?.start() }
//    }
    
    private func setupAppStateObservers() {
        #if swift(>=4.2)
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in _ = self?.capturer?.stop() }
        #else
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil,
            queue: .main
        ) { [weak self] _ in _ = self?.capturer?.stop() }
        #endif
        
        #if swift(>=4.2)
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in _ = self?.capturer?.start() }
        #else
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil,
            queue: .main
        ) { [weak self] _ in _ = self?.capturer?.start() }
        #endif
    }
    
    
    private func removeAppStateObservers() {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Session Management
    
    private func fetchScreenSharingDetails() {
        removePopup()
        guard let url = URL(string: "https://thirdparty.grypp.io/in-app-sessions/create-session") else {
            showAlert(message: "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("grypp_live_xK2P9M7a1LqVb3Wz6JtD4RfXyE8Nc0Q5", forHTTPHeaderField: "APIKey")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(message: "Network error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.showAlert(message: "No data received")
                }
                return
            }
            
            do {
                let session = try JSONDecoder().decode(GryppSession.self, from: data)
                self.gryppSession = session
                self.connectToSession(
                    apiKey: session.apiKey,
                    sessionId: session.sessionId,
                    token: session.customerToken
                )
                DispatchQueue.main.async {
                    self.showCustomPopup(title: "Connect Session",
                                        message: "Your session code is: \(session.sessionCode)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(message: "Failed to parse json responce: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

//    private func fetchScreenSharingDetails() {
//        removePopup()
//        guard let url = URL(string: "https://thirdparty.grypp.io/in-app-sessions/create-session") else {
//            showAlert(message: "Invalid URL")
//            return
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("grypp_live_xK2P9M7a1LqVb3Wz6JtD4RfXyE8Nc0Q5", forHTTPHeaderField: "APIKey")
//
//        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
//            guard let self = self, let data = data else {
//                DispatchQueue.main.async {
//                    self?.showAlert(message: "Network error: \(error?.localizedDescription ?? "No data received")")
//                }
//                return
//            }
//            do {
//                self.gryppSession = try JSONDecoder().decode(GryppSession.self, from: data)
//                print(self.gryppSession ?? "No session data received")
//                self.connectToSession(
//                    apiKey: self.gryppSession?.apiKey ?? "",
//                    sessionId: self.gryppSession?.sessionId ?? "",
//                    token: self.gryppSession?.customerToken ?? ""
//                )
//                DispatchQueue.main.async {
//                    self.showCustomPopup(title: "Connect Session", message: "Your session code is: \(self.gryppSession?.sessionCode ?? "")")
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.showAlert(message: "Failed to parse response: \(error.localizedDescription)")
//                }
//            }
//        }.resume()
//    }

//    private func connectToSession(apiKey: String, sessionId: String, token: String) {
//        session = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self)
//        var error: OTError?
//        session?.connect(withToken: token, error: &error)
//        if let error = error {
//            print("Session connection error: \(error.localizedDescription)")
//        }
//    }
    
    private func connectToSession(apiKey: String, sessionId: String, token: String) {
        session = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self)
        var error: OTError?
        session?.connect(withToken: token, error: &error)
        if let error = error {
            DispatchQueue.main.async {
                self.showAlert(message: "Session connection error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - UI Helpers

    private func showCustomPopup(title: String, message: String) {
        showPopup(title: title, message: message, okTitle: "Ok", cancelTitle: nil, okAction: { [weak self] in
            self?.removePopup()
        })
    }

    private func showEndSessionPopup() {
        showPopup(title: "End Session", message: "Do you want to end the current session?", okTitle: "Yes", cancelTitle: "No", okAction: { [weak self] in
            self?.disconnectFromSession()
            self?.removePopup()
            self?.agentCursorView.removeFromSuperview()
            self?.localCursorView.removeFromSuperview()
        }, cancelAction: { [weak self] in
            self?.removePopup()
        })
    }

    private func showPopup(title: String, message: String, okTitle: String, cancelTitle: String?, okAction: (() -> Void)? = nil, cancelAction: (() -> Void)? = nil) {
        removePopup()
        let popup = CustomPopupView()
        popup.configure(title: title, message: message, okButtonTitle: okTitle, cancelButtonTitle: cancelTitle)
        popup.okButtonAction = okAction
        popup.cancelButtonAction = cancelAction
        popup.show(in: GryppTokManager.appWindow?.topMostView() ?? UIView())
        customPopupView = popup
    }

    private func removePopup() {
        customPopupView?.remove()
        customPopupView = nil
    }

    private func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Grypp", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            GryppTokManager.appWindow?.rootViewController?.present(alert, animated: true)
        }
    }

    // MARK: - Screen Publishing

//    private func startPublishingScreen() {
//        let settings = OTPublisherSettings()
//        settings.name = UIDevice.current.name
//        settings.videoTrack = true
//        settings.audioTrack = false
//        publisher = OTPublisher(delegate: self, settings: settings)
//        publisher?.videoType = .screen
//        publisher?.audioFallbackEnabled = false
//        capturer = ScreenCapturer(captureViewProvider: { GryppTokManager.appWindow?.topMostView() ?? UIView() })
//        publisher?.videoCapture = capturer
//        publisher?.videoCapture?.videoContentHint = UIDevice.current.userInterfaceIdiom == .pad ? .motion : .text
//
//        if let publisher = publisher {
//            var error: OTError?
//            session?.publish(publisher, error: &error)
//            drawAgentCursor()
//            drawLocalCursor()
//            if let error = error {
//                GryppTokManager.sessionDelegate?.sessionPublishFailure(error: error)
//            } else {
//                GryppTokManager.sessionDelegate?.sessionPublishSuccess(value: "Publisher started successfully")
//            }
//        }
//    }

    
    private func startPublishingScreen() {
        guard let appWindow = GryppTokManager.appWindow else {
            showAlert(message: "App window not available")
            return
        }
        
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        settings.videoTrack = true
        settings.audioTrack = false
        
        publisher = OTPublisher(delegate: self, settings: settings)
        publisher?.videoType = .screen
        publisher?.audioFallbackEnabled = false
        
        capturer = ScreenCapturer(captureViewProvider: { appWindow.topMostView() ?? UIView() })
        publisher?.videoCapture = capturer
        publisher?.videoCapture?.videoContentHint = UIDevice.current.userInterfaceIdiom == .pad ? .motion : .text

        if let publisher = publisher {
            var error: OTError?
            session?.publish(publisher, error: &error)
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(message: "Publish error: \(error.localizedDescription)")
                    GryppTokManager.sessionDelegate?.sessionPublishFailure(error: error)
                }
            } else {
                drawAgentCursor()
                drawLocalCursor()
                GryppTokManager.sessionDelegate?.sessionPublishSuccess(value: "Publisher started successfully")
            }
        }
    }
    
    
    // MARK: - Cursor Drawing

    private func drawAgentCursor() {
        setupCursor(view: agentCursorView, label: agentNameLabel, dot: agentCursorDotView, color: .systemBlue, dotColor: .red)
    }

    private func updateAgentCursor(to point: CGPoint, agentName: String) {
        updateCursor(view: agentCursorView, label: agentNameLabel, dot: agentCursorDotView, point: point, name: agentName, color: .systemBlue)
    }

    private func drawLocalCursor() {
        setupCursor(view: localCursorView, label: localNameLabel, dot: localCursorDotView, color: .green, dotColor: .green)
    }

    private func updateLocalCursor(to point: CGPoint, agentName: String) {
        updateCursor(view: localCursorView, label: localNameLabel, dot: localCursorDotView, point: point, name: agentName, color: .green)
    }

    private func setupCursor(view: UIView, label: UILabel, dot: UIView, color: UIColor, dotColor: UIColor) {
        view.frame = CGRect(x: 0, y: 0, width: 20, height: 42)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        GryppTokManager.appWindow?.topMostView()?.addSubview(view)

        label.frame = CGRect(x: 0, y: 0, width: 0, height: 22)
        label.backgroundColor = .clear
        label.text = ""
        label.textColor = .clear
        label.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(label)

        dot.frame = CGRect(x: 20, y: 28, width: 12, height: 12)
        dot.backgroundColor = .clear
        dot.layer.cornerRadius = 6
        dot.layer.borderColor = dotColor.cgColor
        dot.layer.borderWidth = 2
        view.addSubview(dot)
    }

    private func updateCursor(view: UIView, label: UILabel, dot: UIView, point: CGPoint, name: String, color: UIColor) {
        let font = UIFont.systemFont(ofSize: 14)
        let titleSize = name.size(withAttributes: [.font: font])
        let buttonWidth = titleSize.width + 24
        label.text = name
        label.frame.size.width = buttonWidth
        label.textColor = .white
        label.backgroundColor = color
        label.layer.borderWidth = 2
        label.layer.borderColor = UIColor.white.cgColor
        label.layer.cornerRadius = 5
        label.layer.masksToBounds = true
        label.textAlignment = .center
        dot.frame.origin.x = (buttonWidth - 12) / 2
        view.frame.size.width = buttonWidth + 12
        view.center = point
        GryppTokManager.appWindow?.topMostView()?.addSubview(view)
    }

    func handleTouch(at point: CGPoint, event: String) {
        print("Touch point: \(point)")
        updateLocalCursor(to: point, agentName: "Local User")
    }

    func handleIncomingCursorData(_ coord: [CGFloat], agentName: String) {
        guard coord.count == 2 else { return }
        updateAgentCursor(to: CGPoint(x: coord[0], y: coord[1]), agentName: agentName)
    }

    // MARK: - Device Info

    private func getDeviceModelInformation() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
    }

    private func sendSignalForDeviceDetails() {
        let screenDetails: [String: Any] = [
            "type": "ScreenDetails",
            "payload": [
                "brand": "iOS",
                "model": getDeviceModelInformation(),
                "width": UIScreen.main.bounds.width,
                "height": UIScreen.main.bounds.height
            ]
        ]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: screenDetails, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
            var error: OTError?
            session?.signal(withType: "screenshare", string: jsonString, connection: nil, error: &error)
            removePopup()
            startPublishingScreen()
        } catch {
            print("Serialization error: \(error.localizedDescription)")
        }
    }

    // MARK: - Drawing

    func decodeDrawingPath(from base64String: String) -> [CGPoint] {
        guard let decodedData = Data(base64Encoded: base64String) else { return [] }
        do {
            if let json = try JSONSerialization.jsonObject(with: decodedData, options: []) as? [[Any]] {
                var points: [CGPoint] = []
                for entry in json {
                    if let first = entry.first as? String, first == "Q" || first == "L" {
                        for i in stride(from: 1, to: entry.count, by: 2) {
                            if let x = entry[i] as? Double, let y = entry[i + 1] as? Double {
                                points.append(CGPoint(x: x, y: y))
                            }
                        }
                    } else if entry.count == 2, let x = entry[0] as? Double, let y = entry[1] as? Double {
                        points.append(CGPoint(x: x, y: y))
                    }
                }
                return points
            }
        } catch {}
        return []
    }

//    func drawPath(from points: [CGPoint], stroke: String, strokeWidth: CGFloat) {
//        let path = UIBezierPath()
//        for (index, point) in points.enumerated() {
//            if index == 0 {
//                path.move(to: point)
//            } else {
//                path.addLine(to: point)
//            }
//        }
//        let shapeLayer = CAShapeLayer()
//        shapeLayer.name = "grypp"
//        shapeLayer.path = path.cgPath
//        shapeLayer.strokeColor = UIColor(hex: stroke).cgColor
//        shapeLayer.fillColor = UIColor.clear.cgColor
//        shapeLayer.lineWidth = strokeWidth
//        GryppTokManager.appWindow?.layer.addSublayer(shapeLayer)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//            GryppTokManager.appWindow?.layer.sublayers?
//                .filter { $0.name == "grypp" }
//                .forEach { $0.removeFromSuperlayer() }
//        }
//    }
    
    func drawPath(from points: [CGPoint], stroke: String, strokeWidth: CGFloat) {
        guard let window = GryppTokManager.appWindow, !points.isEmpty else { return }
        
        let path = UIBezierPath()
        path.move(to: points[0])
        
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.name = "grypp"
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor(hex: stroke).cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = strokeWidth
        
        DispatchQueue.main.async {
            window.layer.addSublayer(shapeLayer)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                shapeLayer.removeFromSuperlayer()
            }
        }
    }

    // MARK: - Signal Handlers

    private func handleCodeRequested(_ json: [String: Any]) {
        guard let code = json["value"] as? String,
              code == gryppSession?.sessionCode else { return }
        sendSignalForDeviceDetails()
    }

    private func handleMarkerMove(_ json: [String: Any]) {
        guard let agentCoordinates = json["value"] as? [String: Any],
              let x = agentCoordinates["x"] as? CGFloat,
              let y = agentCoordinates["y"] as? CGFloat,
              let name = agentCoordinates["userName"] as? String else { return }
        handleIncomingCursorData([x, y], agentName: name)
    }

    private func handleDraw(_ json: [String: Any]) {
        guard let value = json["value"] as? String,
              let drawData = value.data(using: .utf8),
              let drawSignal = try? JSONDecoder().decode(DrawEndSignal.self, from: drawData) else { return }
        let eventId = drawSignal.eventId
        var chunks = drawChunks[eventId] ?? []
        chunks.append(drawSignal)
        drawChunks[eventId] = chunks
        if chunks.count == drawSignal.totalChunks {
            let base64Combined = chunks
                .sorted(by: { $0.order < $1.order })
                .map { $0.value }
                .joined()
            guard let decodedData = Data(base64Encoded: base64Combined),
                  let pathObject = try? JSONDecoder().decode(FabricPathObject.self, from: decodedData) else { return }
            let points = extractPoints(from: pathObject.path)
            drawPath(from: points, stroke: pathObject.stroke ?? "#ff7a00", strokeWidth: pathObject.strokeWidth ?? 5.0)
            drawChunks.removeValue(forKey: eventId)
        }
    }

    // MARK: - Cleanup
 
    private func cleanupResources() {
        agentCursorView.removeFromSuperview()
        localCursorView.removeFromSuperview()
        capturer?.releaseCapture()
        capturer = nil
        publisher = nil
        GryppTokManager.appWindow?.layer.sublayers?
            .filter { $0.name == "grypp" }
            .forEach { $0.removeFromSuperlayer() }
    }
}

// MARK: - OTSessionDelegate & OTPublisherDelegate

extension GryppTokManager: OTSessionDelegate, OTPublisherDelegate {
    public func sessionDidConnect(_ session: OTSession) {
        print("Session Grypp connected")
        GryppTokManager.sessionDelegate?.sessionConnectGryppSuccess(value: "Session connected")
    }

    public func sessionDidDisconnect(_ session: OTSession) {
        print("Session Grypp disconnected")
        cleanupResources()
        GryppTokManager.popupView?.removeFromSuperview()
        GryppTokManager.sessionDelegate?.sessionDisconnectGryppSuccess(value: "Session disconnected")
    }

    public func session(_ session: OTSession, connectionDestroyed connection: OTConnection) {
        print("OpenTok: Connection destroyed: \(connection.connectionId)")
        DispatchQueue.main.async {
            self.cleanupResources()
            GryppTokManager.popupView?.removeFromSuperview()
            GryppTokManager.sessionDelegate?.sessionDisconnectGryppSuccess(value: "Session disconnected")
        }
    }

    public func session(_ session: OTSession, didFailWithError error: OTError) {
        showAlert(message: "\(error.localizedDescription)")
        print("Session Grypp error: \(error.localizedDescription)")
        cleanupResources()
        GryppTokManager.sessionDelegate?.sessionConnectGryppFailure(error: error)
    }

    public func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session Grypp Stream created: \(stream)")
    }

    public func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        cleanupResources()
        GryppTokManager.popupView?.removeFromSuperview()
        print("Session Grypp Stream destroyed: \(stream)")
    }

//    public func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with data: String?) {
//        guard let dataConvertJsonString = data?.data(using: .utf8),
//              let json = try? JSONSerialization.jsonObject(with: dataConvertJsonString) as? [String: Any] else {
//            print("Signal JSON parsing error")
//            return
//        }
//        print("📩 Signal type: \(type ?? "nil")")
//        print("📦 Signal data: \(json)")
//        guard let action = json["action"] as? String else { return }
//        switch action {
//        case "CodeRequested": handleCodeRequested(json)
//        case "MARKER_MOVE": handleMarkerMove(json)
//        case "draw": handleDraw(json)
//        default: print("⚠️ Unhandled action: \(action)")
//        }
//    }
    
    public func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with data: String?) {
        guard let data = data?.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            print("Signal JSON parsing error")
            return
        }
        
        print("📩 Signal type: \(type ?? "nil")")
        print("📦 Signal data: \(json)")
        
        guard let action = json["action"] as? String else { return }
        
        switch action {
        case "CodeRequested":
            handleCodeRequested(json)
        case "MARKER_MOVE":
            handleMarkerMove(json)
        case "draw":
            handleDraw(json)
        default:
            print("⚠️ Unhandled action: \(action)")
        }
    }

    public func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        cleanupResources()
        GryppTokManager.popupView?.removeFromSuperview()
        print("Session Grypp Publisher error: \(error.localizedDescription)")
    }
}

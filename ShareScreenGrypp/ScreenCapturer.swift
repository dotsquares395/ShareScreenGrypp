
import UIKit
import OpenTok

public class ScreenCapturer: NSObject, OTVideoCapture {

    // MARK: - OTVideoCapture Properties
    public var videoCaptureConsumer: OTVideoCaptureConsumer?
    public var videoContentHint: OTVideoContentHint = .text

    // MARK: - Capture State
    private var captureViewProvider: () -> UIView
    private let captureQueue = DispatchQueue(label: "com.grypp.captureQueue")
    private var timer: DispatchSourceTimer?
    private var capturing = false
    private var isTimerRunning = false

    // MARK: - Video Frame
    private var videoFrame = OTVideoFrame()

    // MARK: - Session/Orientation
    var session: OTSession?
    private var previousOrientation: UIDeviceOrientation = .unknown

    // MARK: - Init
    init(captureViewProvider: @escaping () -> UIView) {
        self.captureViewProvider = captureViewProvider
        super.init()
    }

    // MARK: - OTVideoCapture Methods
    public func initCapture() {
        timer = DispatchSource.makeTimerSource(queue: captureQueue)
        timer?.schedule(deadline: .now(), repeating: .milliseconds(300))
        timer?.setEventHandler { [weak self] in
            self?.captureFrame()
        }
    }

    public func start() -> Int32 {
        guard !capturing else { return 0 }
        capturing = true
        print("📸 start capture")
        captureQueue.async {
            if self.timer == nil {
                self.initCapture()
            }
            self.timer?.resume()
            self.isTimerRunning = true
        }
        return 0
    }

    public func stop() -> Int32 {
        guard capturing else { return 0 }
        capturing = false
        print("🛑 stop capture")
        captureQueue.async {
            self.timer?.suspend()
        }
        return 0
    }

    public func releaseCapture() {
        if let timer = timer {
            if isTimerRunning {
                timer.setEventHandler {}
                timer.cancel()
                isTimerRunning = false
            }
            self.timer = nil
        }
    }

    public func isCaptureStarted() -> Bool {
        return capturing
    }

    public func captureSettings(_ videoFormat: OTVideoFormat) -> Int32 {
        videoFormat.pixelFormat = .ARGB
        return 0
    }

    // MARK: - Frame Capture Logic

    private func captureFrame() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let screenshot = self.snapshot(of: self.captureViewProvider()),
                  let cgImage = self.resizeAndPad(image: screenshot),
                  let pixelBuffer = self.cgImageToCVPixelBuffer(cgImage) else {
                print("❌ Failed to capture or convert image")
                return
            }

            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

            guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
                print("❌ Failed to get baseAddress from pixel buffer")
                return
            }

            //let timestamp = CMTimeMake(value: Int64(mach_absolute_time()), timescale: 1000)
            let timestamp = CMTime(value: Int64(mach_absolute_time()), timescale: 1000)
            self.videoFrame.timestamp = timestamp
            //self.videoFrame.timestamp = timestamp
            self.videoFrame.orientation = .up
            self.videoFrame.format = OTVideoFormat(argbWithWidth: UInt32(cgImage.width),
                                                   height: UInt32(cgImage.height))
            self.videoFrame.clearPlanes()
            self.videoFrame.planes?.addPointer(baseAddress)
            self.videoCaptureConsumer?.consumeFrame(self.videoFrame)
        }
    }

    
    private func snapshot(of view: UIView) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        var image = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }
        let sensitiveViews = view.sensitiveSubviews()
        for sensitiveView in sensitiveViews {
            var rect = sensitiveView.convert(sensitiveView.bounds, to: view)
            if let scrollView = sensitiveView.superview as? UIScrollView {
                rect.origin.x -= scrollView.contentOffset.x
                rect.origin.y -= scrollView.contentOffset.y
            }
            if let redacted = image.redact(rect: rect, color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)) {
                image = redacted
            }
        }
        return image
    }

    private func resizeAndPad(image: UIImage) -> CGImage? {
        guard let source = image.cgImage else {
            print("Error: Failed to get CGImage from UIImage")
            return nil
        }
        let sourceSize = CGSize(width: source.width, height: source.height)
        let (container, drawRect) = dimensions(forInputSize: sourceSize)
        UIGraphicsBeginImageContextWithOptions(container, true, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            print("Error: Failed to get CGContext")
            return nil
        }
        context.translateBy(x: 0, y: container.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.clear(CGRect(origin: .zero, size: container))
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: container))
        context.draw(source, in: drawRect)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let result = outputImage?.cgImage else {
            print("Error: Failed to create output CGImage")
            return nil
        }
        return result
    }

    private func cgImageToCVPixelBuffer(_ cgImage: CGImage) -> CVPixelBuffer? {
        let width = cgImage.width
        let height = cgImage.height
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferBytesPerRowAlignmentKey as String: width * 4,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("Error: Failed to create pixel buffer with status \(status)")
            return nil
        }
        let lockFlags = CVPixelBufferLockFlags(rawValue: 0)
        let lockStatus = CVPixelBufferLockBaseAddress(buffer, lockFlags)
        guard lockStatus == kCVReturnSuccess else {
            print("Error: Failed to lock pixel buffer with status \(lockStatus)")
            return nil
        }
        defer { CVPixelBufferUnlockBaseAddress(buffer, lockFlags) }
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            print("Error: Failed to get pixel buffer base address")
            return nil
        }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            print("Error: Failed to create CGContext")
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }

    private func dimensions(forInputSize size: CGSize) -> (container: CGSize, rect: CGRect) {
        let maxSize: CGFloat = 1280.0
        let aspect = size.width / size.height
        var container = CGSize.zero
        if size.width > size.height {
            container.width = maxSize
            container.height = maxSize / aspect
        } else {
            container.height = maxSize
            container.width = maxSize * aspect
        }
        let rect = CGRect(x: 0, y: 0, width: container.width, height: container.height)
        return (container, rect)
    }
}


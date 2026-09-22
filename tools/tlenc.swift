import AVFoundation
import VideoToolbox

// tlenc: re-encode a video as 240 fps HEVC with temporal sub-layers, the way macOS Aerial
// assets are encoded, so the Aerials engine can ramp playback down/up on lock/unlock.
//
// usage: tlenc <input.mov> <output.mov> <layers> <loops> <maxSeconds> <dupFactor> <baseFPS>
//   layers      requested temporal layers (hardware gives 3 at 4K)
//   loops       how many times to repeat the input
//   maxSeconds  hard cap on output length
//   dupFactor   how many times each decoded frame is repeated (24 fps input × 10 = 240 fps)
//   baseFPS     frame rate of the base temporal layer (15 → 15/30/60/120/240)
let a = CommandLine.arguments
guard a.count == 8 else {
    FileHandle.standardError.write("usage: tlenc <in> <out> <layers> <loops> <maxSeconds> <dupFactor> <baseFPS>\n".data(using: .utf8)!)
    exit(2)
}
let inURL = URL(fileURLWithPath: a[1]), outURL = URL(fileURLWithPath: a[2])
let layers = Int(a[3])!, loops = Int(a[4])!, maxSeconds = Double(a[5])!, dup = Int(a[6])!, baseFPS = Int(a[7])!
try? FileManager.default.removeItem(at: outURL)

let asset = AVURLAsset(url: inURL)
let track = asset.tracks(withMediaType: .video).first!
let fps = 240.0
let frameDur = CMTime(value: 1000, timescale: 240000)

let writer = try! AVAssetWriter(outputURL: outURL, fileType: .mov)
let comp: [String: Any] = [
    AVVideoAverageBitRateKey: 12_000_000,
    AVVideoProfileLevelKey: kVTProfileLevel_HEVC_Main10_AutoLevel,
    AVVideoAllowFrameReorderingKey: true,
    AVVideoExpectedSourceFrameRateKey: 240,
    AVVideoMaxKeyFrameIntervalKey: 1200,
    "NumberOfTemporalLayers": layers,
    kVTCompressionPropertyKey_BaseLayerFrameRate as String: baseFPS,
    "TemporalIDNestingFlag": false,
]
let settings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.hevc,
    AVVideoWidthKey: 3840, AVVideoHeightKey: 2160,
    AVVideoCompressionPropertiesKey: comp,
    AVVideoColorPropertiesKey: [AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                                AVVideoTransferFunctionKey: AVVideoTransferFunction_IEC_sRGB,
                                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2],
]
let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
input.expectsMediaDataInRealTime = false
input.mediaTimeScale = 240000
writer.movieTimeScale = 240000
writer.add(input)
writer.startWriting(); writer.startSession(atSourceTime: .zero)

var frameIndex: Int64 = 0
let maxFrames = Int64(maxSeconds * fps)
let q = DispatchQueue(label: "enc")
let done = DispatchSemaphore(value: 0)
var loop = 0
var reader: AVAssetReader! = nil
var output: AVAssetReaderTrackOutput! = nil
func openReader() {
    reader = try! AVAssetReader(asset: asset)
    output = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange])
    output.alwaysCopiesSampleData = false
    reader.add(output); reader.startReading()
}
openReader()
var finished = false
input.requestMediaDataWhenReady(on: q) {
    while input.isReadyForMoreMediaData && !finished {
        guard let sb = output.copyNextSampleBuffer() else {
            loop += 1
            if loop >= loops || frameIndex >= maxFrames { finished = true; break }
            openReader(); continue
        }
        if frameIndex >= maxFrames { finished = true; break }
        let pb = CMSampleBufferGetImageBuffer(sb)!
        var fmt: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pb, formatDescriptionOut: &fmt)
        for _ in 0..<dup {
            if frameIndex >= maxFrames { finished = true; break }
            let pts = CMTime(value: frameIndex * 1000, timescale: 240000)
            var timing = CMSampleTimingInfo(duration: frameDur, presentationTimeStamp: pts, decodeTimeStamp: .invalid)
            var nsb: CMSampleBuffer?
            CMSampleBufferCreateReadyWithImageBuffer(allocator: nil, imageBuffer: pb, formatDescription: fmt!, sampleTiming: &timing, sampleBufferOut: &nsb)
            while !input.isReadyForMoreMediaData { usleep(2000) }
            if !input.append(nsb!) { print("append failed:", writer.error ?? "?"); finished = true; break }
            frameIndex += 1
            if frameIndex % 12000 == 0 { print("encoded \(frameIndex/240) s"); fflush(stdout) }
        }
    }
    if finished {
        input.markAsFinished()
        writer.finishWriting {
            print("finished, status \(writer.status.rawValue), error: \(String(describing: writer.error)), frames \(frameIndex)")
            done.signal()
        }
    }
}
done.wait()

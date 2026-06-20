import Accelerate
import CoreML

class MultiArrayModel: ImageProcessingModel {
    private let mlmodel: MLModel
    private let inputName: String
    private let outputName: String
    private let shape: [NSNumber]
    private let blockSize: Int
    private let shrinkSize: Int
    private let scale: Int

    required init(model: MLModel, config: [String: Any]) {
        self.mlmodel = model
        self.inputName = (config["inputName"] as? String) ?? "input"
        self.outputName = (config["outputName"] as? String) ?? "output"
        self.blockSize = (config["blockSize"] as? Int) ?? 256
        self.shrinkSize = (config["shrinkSize"] as? Int) ?? 0
        self.scale = (config["scale"] as? Int) ?? 2
        if let customShape = config["shape"] as? [Int] {
            self.shape = customShape.map { NSNumber(value: $0) }
        } else {
            self.shape = [1, 3, NSNumber(value: blockSize), NSNumber(value: blockSize)]
        }
    }

    func process(_ image: CGImage) async -> CGImage? {
        let width = image.width
        let height = image.height
        let channels = 4
        let contentBlockSize = self.blockSize - shrinkSize * 2
        let outScale = scale

        // Pad image dimensions to multiples of the content block so that tiles
        // never overlap in the output. The extra area is filled by reflecting
        // the source image, matching Real-CUGAN's reference tiling behaviour.
        let paddedWidth = ((width + contentBlockSize - 1) / contentBlockSize) * contentBlockSize
        let paddedHeight = ((height + contentBlockSize - 1) / contentBlockSize) * contentBlockSize

        let outWidth = paddedWidth * outScale
        let outHeight = paddedHeight * outScale
        let outBlockSize = contentBlockSize * outScale

        // set up pool of buffers
        let poolSize = ProcessInfo.processInfo.activeProcessorCount
        let blockAndShrink = contentBlockSize + 2 * shrinkSize
        var bufferPool: [MLMultiArray] = (0..<poolSize).compactMap { _ in
            try? MLMultiArray(shape: shape, dataType: .float32)
        }
        let bufferSemaphore = DispatchSemaphore(value: poolSize)
        let bufferPoolLock = NSLock()

        func getBuffer() -> MLMultiArray {
            bufferSemaphore.wait()
            bufferPoolLock.lock()
            let buffer = bufferPool.removeLast()
            bufferPoolLock.unlock()
            return buffer
        }

        func returnBuffer(_ buffer: MLMultiArray) {
            bufferPoolLock.lock()
            bufferPool.append(buffer)
            bufferPoolLock.unlock()
            bufferSemaphore.signal()
        }

        // expand image by the shrink size using reflection
        let expwidth = paddedWidth + 2 * shrinkSize
        let expheight = paddedHeight + 2 * shrinkSize
        let expanded = image.expandReflect(
            shrinkSize: shrinkSize,
            paddedWidth: paddedWidth,
            paddedHeight: paddedHeight
        )

        // calculate image block rects over the padded canvas
        let rects = calculateRects(width: paddedWidth, height: paddedHeight, blockSize: contentBlockSize)

        // feed expanded image data into blocks of MLMultiArrays
        let multiArrayStream = AsyncStream<(Int, MLMultiArray)> { continuation in

            Task.detached {
                for (i, rect) in rects.enumerated() {
                    let x = Int(rect.origin.x)
                    let y = Int(rect.origin.y)
                    let multi = getBuffer()
                    let floatPtr = multi.dataPointer.assumingMemoryBound(to: Float32.self)
                    let inChannelStride = multi.strides[1].intValue
                    let inRowStride = multi.strides[2].intValue
                    for yExp in y..<(y + blockAndShrink) {
                        guard yExp >= 0 else { continue }
                        let inY = yExp - y
                        let srcYBase = yExp * expwidth
                        for xExp in x..<(x + blockAndShrink) {
                            guard xExp >= 0 else { continue }
                            let inX = xExp - x
                            let base = inY * inRowStride + inX
                            let srcIdx = srcYBase + xExp
                            // channel 0
                            floatPtr[base] = Float32(expanded[srcIdx])
                            // channel 1
                            floatPtr[base + inChannelStride] = Float32(
                                expanded[srcIdx + expwidth * expheight]
                            )
                            // channel 2
                            floatPtr[base + inChannelStride * 2] = Float32(
                                expanded[srcIdx + expwidth * expheight * 2]
                            )
                        }
                    }
                    continuation.yield((i, multi))
                }
                continuation.finish()
            }
        }

        // feed image block arrays into the model
        let predictionStream = AsyncStream<(Int, MLMultiArray)> { [inputName, outputName] continuation in
            Task.detached {
                for await (i, multi) in multiArrayStream {
                    var buffer = multi
                    if let prediction = try? self.mlmodel.prediction(inputName: inputName, outputName: outputName, input: buffer) {
                        buffer = prediction
                    } else {
                        print("Failed to get output from multiarray model")
                    }
                    continuation.yield((i, buffer))
                    returnBuffer(multi)
                }
                continuation.finish()
            }
        }

        // helper to send values from [0,1] to [0,255] and clamp
        func normalizeAccelerate(
            _ src: UnsafePointer<Float32>, _ dst: UnsafeMutablePointer<UInt8>, count: Int
        ) {
            var scale: Float32 = 255
            var minVal: Float32 = 0
            var maxVal: Float32 = 255
            var tempMul = [Float32](repeating: 0, count: count)
            var tempClip = [Float32](repeating: 0, count: count)
            // multiply by 255
            vDSP_vsmul(src, 1, &scale, &tempMul, 1, vDSP_Length(count))
            // clamp to [0,255]
            vDSP_vclip(&tempMul, 1, &minVal, &maxVal, &tempClip, 1, vDSP_Length(count))
            // convert to u8
            vDSP_vfixu8(&tempClip, 1, dst, 1, vDSP_Length(count))
        }

        // process final output
        var imgData: [UInt8] = [UInt8](repeating: 0, count: outWidth * outHeight * channels)

        await withTaskGroup(of: Void.self) { group in
            for await (i, prediction) in predictionStream {
                group.addTask {
                    let rect = rects[i]
                    let originX = Int(rect.origin.x) * outScale
                    let originY = Int(rect.origin.y) * outScale
                    let dataPointer = prediction.dataPointer.assumingMemoryBound(to: Float32.self)
                    let outChannelStride = prediction.strides[1].intValue
                    let outRowStride = prediction.strides[2].intValue
                    for channel in 0..<3 {
                        // CoreML may pad each row of the output multi-array, so copy
                        // the tile into a contiguous buffer using the model's strides.
                        var tempBlock = [Float32](repeating: 0, count: outBlockSize * outBlockSize)
                        let channelBase = dataPointer.advanced(by: channel * outChannelStride)
                        for srcY in 0..<outBlockSize {
                            let srcRow = channelBase.advanced(by: srcY * outRowStride)
                            let dstRowBase = srcY * outBlockSize
                            for srcX in 0..<outBlockSize {
                                tempBlock[dstRowBase + srcX] = srcRow[srcX]
                            }
                        }
                        var tempBlockU8 = [UInt8](repeating: 0, count: outBlockSize * outBlockSize)
                        normalizeAccelerate(tempBlock, &tempBlockU8, count: outBlockSize * outBlockSize)
                        // write to output image buffer
                        for srcY in 0..<outBlockSize {
                            for srcX in 0..<outBlockSize {
                                let destX = originX + srcX
                                let destY = originY + srcY
                                let destIndex = (destY * outWidth + destX) * channels + channel
                                let srcIndex = srcY * outBlockSize + srcX
                                guard destIndex >= 0, srcIndex >= 0 else { continue }
                                imgData[destIndex] = tempBlockU8[srcIndex]
                            }
                        }
                    }
                }
            }
        }

        // create final cgimage from imgData buffer
        guard
            let cfbuffer = CFDataCreate(nil, &imgData, outWidth * outHeight * channels),
            let dataProvider = CGDataProvider(data: cfbuffer)
        else {
            return nil
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipLast.rawValue // skip alpha
        guard let fullImage = CGImage(
            width: outWidth,
            height: outHeight,
            bitsPerComponent: 8,
            bitsPerPixel: 8 * channels,
            bytesPerRow: outWidth * channels,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent
        ) else {
            return nil
        }

        // Crop back to the original image dimensions (padded area was only added
        // to make the tile grid fit exactly).
        let cropRect = CGRect(
            x: 0,
            y: 0,
            width: width * outScale,
            height: height * outScale
        )
        return fullImage.cropping(to: cropRect)
    }

    // calculate the rects for the image blocks
    private func calculateRects(width: Int, height: Int, blockSize: Int) -> [CGRect] {
        var rects: [CGRect] = []
        let numW = width / blockSize
        let numH = height / blockSize

        // With padded dimensions this always produces a regular non-overlapping grid.
        for i in 0..<numW {
            for j in 0..<numH {
                rects.append(CGRect(x: i * blockSize, y: j * blockSize, width: blockSize, height: blockSize))
            }
        }
        return rects
    }
}

private class MLInput: MLFeatureProvider {
    var input: MLMultiArray
    var featureNames: Set<String>

    func featureValue(for featureName: String) -> MLFeatureValue? {
        MLFeatureValue(multiArray: input)
    }

    init(name: String, input: MLMultiArray) {
        self.input = input
        self.featureNames = [name]
    }
}

private extension MLModel {
    func prediction(inputName: String, outputName: String, input: MLMultiArray) throws -> MLMultiArray? {
        let inputProvider = MLInput(name: inputName, input: input)
        let outFeatures = try self.prediction(from: inputProvider)
        return outFeatures.featureValue(for: outputName)?.multiArrayValue
    }
}

private extension CGImage {
    // Reflect-pad the source image to the requested padded size and then add
    // a surrounding shrink-size border, also by reflection. This matches the
    // "reflect" padding used by Real-CUGAN / waifu2x style models.
    func expandReflect(shrinkSize: Int, paddedWidth: Int, paddedHeight: Int) -> [Float] {
        let clipEta8: Float = 0.00196078411

        let exwidth = paddedWidth + 2 * shrinkSize
        let exheight = paddedHeight + 2 * shrinkSize

        // extract rgba pixel data
        var u8Array = [UInt8](repeating: 0, count: width * height * 4)
        u8Array.withUnsafeMutableBytes { u8Pointer in
            let context = CGContext(
                data: u8Pointer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 4 * width,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            context?.draw(
                self,
                in: CGRect(
                    x: 0,
                    y: 0,
                    width: width,
                    height: height
                )
            )
        }

        var arr = [Float](repeating: 0, count: 3 * exwidth * exheight)

        var rArr = [Float](repeating: 0, count: width * height)
        var gArr = [Float](repeating: 0, count: width * height)
        var bArr = [Float](repeating: 0, count: width * height)

        u8Array.withUnsafeBufferPointer { buf in
            guard let src = buf.baseAddress else { return }
            var scale: Float = 1 / 255
            var eta = clipEta8
            // red
            var tempR = [Float](repeating: 0, count: width * height)
            var tempR2 = [Float](repeating: 0, count: width * height)
            vDSP_vfltu8(src, 4, &tempR, 1, vDSP_Length(width * height))
            vDSP_vsmsa(&tempR, 1, &scale, &eta, &tempR2, 1, vDSP_Length(width * height))
            rArr = tempR2
            // green
            var tempG = [Float](repeating: 0, count: width * height)
            var tempG2 = [Float](repeating: 0, count: width * height)
            vDSP_vfltu8(src.advanced(by: 1), 4, &tempG, 1, vDSP_Length(width * height))
            vDSP_vsmsa(&tempG, 1, &scale, &eta, &tempG2, 1, vDSP_Length(width * height))
            gArr = tempG2
            // blue
            var tempB = [Float](repeating: 0, count: width * height)
            var tempB2 = [Float](repeating: 0, count: width * height)
            vDSP_vfltu8(src.advanced(by: 2), 4, &tempB, 1, vDSP_Length(width * height))
            vDSP_vsmsa(&tempB, 1, &scale, &eta, &tempB2, 1, vDSP_Length(width * height))
            bArr = tempB2
        }

        func reflectIndex(_ index: Int, _ length: Int) -> Int {
            if length <= 1 { return 0 }
            var index = index
            while true {
                if index < 0 {
                    index = -index
                }
                if index < length {
                    return index
                }
                index = 2 * (length - 1) - index
            }
        }

        for channel in 0..<3 {
            let srcArr = channel == 0 ? rArr : (channel == 1 ? gArr : bArr)
            let base = channel * exwidth * exheight
            for y in 0..<exheight {
                let srcY = reflectIndex(y - shrinkSize, height)
                let srcRow = srcY * width
                let dstRowStart = base + y * exwidth
                for x in 0..<exwidth {
                    let srcX = reflectIndex(x - shrinkSize, width)
                    arr[dstRowStart + x] = srcArr[srcRow + srcX]
                }
            }
        }

        return arr
    }
}

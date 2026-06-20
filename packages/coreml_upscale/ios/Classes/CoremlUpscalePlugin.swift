import Foundation

#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

public class CoremlUpscalePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        let channel = FlutterMethodChannel(name: "coreml_upscale", binaryMessenger: messenger)
        let instance = CoremlUpscalePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "upscale":
            guard let args = call.arguments as? [String: Any],
                  let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let modelPath = args["modelPath"] as? String
            else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing inputPath, outputPath or modelPath", details: nil))
                return
            }

            let modelType = args["modelType"] as? String ?? "multiarray"
            let config = args["config"] as? [String: Any] ?? [:]

            Task {
                do {
                    try await self.upscale(
                        inputPath: inputPath,
                        outputPath: outputPath,
                        modelPath: modelPath,
                        modelType: modelType,
                        config: config
                    )
                    result(nil)
                } catch {
                    result(FlutterError(code: "UPSCALE_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func upscale(
        inputPath: String,
        outputPath: String,
        modelPath: String,
        modelType: String,
        config: [String: Any]
    ) async throws {
        let inputImage = try ImageIO.loadCGImage(from: inputPath)

        guard let model = try await ModelManager.shared.loadModel(
            fromPath: modelPath,
            type: modelType,
            config: config
        ) else {
            throw CoreMLUpscaleError.modelLoadFailed("Could not initialize model processor")
        }

        guard let outputImage = await model.process(inputImage) else {
            throw CoreMLUpscaleError.processingFailed("Model returned no output")
        }

        try ImageIO.writeCGImage(outputImage, to: outputPath)
    }
}

import ArgumentParser
import Foundation

@main
struct AidokuUpscaleCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "aidoku-upscale-cli",
        abstract: "Upscale images using Aidoku's CoreML super-resolution models.",
        version: "1.0.0"
    )

    @Flag(name: .long, help: "List available models and exit.")
    var listModels = false

    @Option(name: .long, help: "Model file name to use from Aidoku model list (e.g. waifu2x_photo_noise0_scale2x.mlmodel).")
    var model: String?

    @Option(name: .long, help: "Local model path (.mlmodel or .mlpackage). Bypasses the remote model list.")
    var modelPath: String?

    @Option(name: .long, help: "Model type when using --model-path (multiarray or image).")
    var modelType: String = "multiarray"

    @Option(name: .long, help: "Multiarray blockSize when using --model-path.")
    var blockSize: Int?

    @Option(name: .long, help: "Multiarray shrinkSize when using --model-path.")
    var shrinkSize: Int?

    @Option(name: .long, help: "Upscale scale when using --model-path.")
    var scale: Int = 2

    @Option(name: .long, help: "Model input feature name when using --model-path.")
    var inputName: String = "input"

    @Option(name: .long, help: "Model output feature name when using --model-path.")
    var outputName: String = "output"

    @Option(name: .shortAndLong, help: "Input image path.")
    var input: String?

    @Option(name: .shortAndLong, help: "Output image path.")
    var output: String = "output.png"

    @Option(name: .long, help: "Skip upscaling if image height is greater than or equal to this value.")
    var maxHeight: Int = 4000

    func run() async throws {
        if listModels {
            try await listAvailableModels()
            return
        }

        guard let input else {
            throw CLIError.invalidInput("--input is required unless using --list-models")
        }

        let inputImage = try ImageIO.loadCGImage(from: input)
        print("Loaded \(inputImage.width)x\(inputImage.height) image from \(input)")

        guard inputImage.height < maxHeight else {
            print("Image height >= \(maxHeight), skipping upscaling.")
            return
        }

        let imageModel: ImageProcessingModel
        if let modelPath {
            let fileURL = URL(fileURLWithPath: modelPath)
            let fileName = (modelPath as NSString).lastPathComponent
            let config = ModelConfig(
                inputName: inputName,
                outputName: outputName,
                blockSize: blockSize,
                shrinkSize: shrinkSize,
                scale: scale,
                shape: nil
            )
            let info = ModelInfo(name: fileName, type: modelType, config: config, file: fileName)
            guard let loaded = try await ModelManager.shared.loadModel(at: fileURL, info: info) else {
                throw CLIError.modelLoadFailed("Could not initialize model processor")
            }
            print("Using local model: \(fileName)")
            imageModel = loaded
        } else if let model {
            let list = try await ModelManager.shared.fetchModelList()
            guard let modelInfo = list.models.first(where: {
                ($0.file as NSString).lastPathComponent == (model as NSString).lastPathComponent
            }) else {
                throw CLIError.modelNotFound(model)
            }

            print("Using model: \(modelInfo.name ?? model)")

            let fileName = (modelInfo.file as NSString).lastPathComponent
            let modelsDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                .appendingPathComponent("aidoku-upscale-cli/Models", isDirectory: true)
            let localModelPath = modelsDir.appendingPathComponent(fileName).path

            if !FileManager.default.fileExists(atPath: localModelPath) {
                print("Model not found locally, downloading...")
                try await ModelManager.shared.downloadModel(modelInfo)
                print("Download complete.")
            } else {
                print("Model found locally.")
            }

            guard let loaded = try await ModelManager.shared.loadModel(named: fileName) else {
                throw CLIError.modelLoadFailed("Could not initialize model processor")
            }
            imageModel = loaded
        } else {
            throw CLIError.invalidInput("Either --model or --model-path is required")
        }

        print("Upscaling...")
        let start = Date()
        guard let outputImage = await imageModel.process(inputImage) else {
            throw CLIError.processingFailed("Model returned no output")
        }
        print("Done in \(String(format: "%.2f", -start.timeIntervalSinceNow))s")
        print("Output size: \(outputImage.width)x\(outputImage.height)")

        try ImageIO.writeCGImage(outputImage, to: output)
        print("Saved to \(output)")
    }

    private func listAvailableModels() async throws {
        let list = try await ModelManager.shared.fetchModelList()
        print("Available models:")
        for model in list.models {
            let sizeStr: String
            if let size = model.size {
                let mb = Double(size) / 1_048_576.0
                sizeStr = String(format: "%.1f MB", mb)
            } else {
                sizeStr = "unknown size"
            }
            print("  - \(model.name ?? model.file) [\(model.type ?? "unknown")] (\(sizeStr)) -> \(model.file)")
        }
    }
}

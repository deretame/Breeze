import Foundation
import CoreML
import ZIPFoundation

actor ModelManager {
    static let shared = ModelManager()

    static private let modelListUrl = URL(string: "https://upscale.aidoku.app/models.json")!
    static private let supportedModelTypes: Set<String> = ["multiarray", "image"]

    private var imageModelCache: [String: ImageProcessingModel] = [:]
    private var cachedModelList: ModelList?

    // MARK: - Model list

    func fetchModelList() async throws -> ModelList {
        if let cachedModelList {
            return cachedModelList
        }
        let (data, _) = try await URLSession.shared.data(from: Self.modelListUrl)
        let list = try JSONDecoder().decode(ModelList.self, from: data)
        cachedModelList = list
        return list
    }

    func availableModels() async throws -> [ModelInfo] {
        let list = try await fetchModelList()
        let installedFiles = Set(try installedModelFiles())
        return list.models.filter {
            guard let type = $0.type else { return false }
            return Self.supportedModelTypes.contains(type)
                && !installedFiles.contains(($0.file as NSString).lastPathComponent)
        }
    }

    // MARK: - Download / remove

    func downloadModel(_ model: ModelInfo) async throws {
        let url = URL(string: model.file, relativeTo: Self.modelListUrl)!
        let fileName = (model.file as NSString).lastPathComponent
        let fileURL = try modelsDirectory().appendingPathComponent(fileName)

        if fileName.hasSuffix(".mlpackage") {
            let tempZipURL = fileURL.appendingPathExtension("zip")
            let (data, _) = try await URLSession.shared.data(from: url.appendingPathExtension("zip"))
            try data.write(to: tempZipURL)

            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try fm.removeItem(at: fileURL)
            }
            try fm.unzipItem(at: tempZipURL, to: fileURL)
            try fm.removeItem(at: tempZipURL)
        } else {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: fileURL)
        }

        let metadataURL = try metadataURL(forModelFile: fileName)
        var meta = model
        meta.file = fileName
        meta.size = nil
        let metadataData = try JSONEncoder().encode(meta)
        try metadataData.write(to: metadataURL)
    }

    func removeModel(withFile modelFile: String) throws {
        let fileName = (modelFile as NSString).lastPathComponent
        let fileURL = try modelsDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
        if let metadataURL = try? metadataURL(forModelFile: fileName) {
            try? FileManager.default.removeItem(at: metadataURL)
        }
        imageModelCache[fileName] = nil
    }

    // MARK: - Loading

    func loadModel(named fileName: String) async throws -> ImageProcessingModel? {
        let name = (fileName as NSString).lastPathComponent
        let modelsDir = try modelsDirectory()
        let fileURL = modelsDir.appendingPathComponent(name)

        var info = ModelInfo(file: name)
        let metadataURL = try metadataURL(forModelFile: name)
        if let data = try? Data(contentsOf: metadataURL),
           let meta = try? JSONDecoder().decode(ModelInfo.self, from: data)
        {
            info = meta
            info.file = name
        }

        return try await loadModel(at: fileURL, info: info)
    }

    func loadModel(at fileURL: URL, info: ModelInfo) async throws -> ImageProcessingModel? {
        let name = (info.file as NSString).lastPathComponent
        if let cached = imageModelCache[name] {
            return cached
        }

        guard let modelType = info.type else {
            throw CLIError.modelLoadFailed("Unknown model type for \(name)")
        }

        let compiledUrl = try await MLModel.compileModel(at: fileURL)
        let mlModel = try MLModel(contentsOf: compiledUrl)

        var config: [String: Any] = [:]
        if let c = info.config {
            config["inputName"] = c.inputName
            config["outputName"] = c.outputName
            config["blockSize"] = c.blockSize
            config["shrinkSize"] = c.shrinkSize
            config["scale"] = c.scale
            config["shape"] = c.shape
        }

        let model: ImageProcessingModel?
        switch modelType.lowercased() {
        case "multiarray":
            model = MultiArrayModel(model: mlModel, config: config)
        case "image":
            model = ImageModel(model: mlModel, config: config)
        default:
            model = nil
        }

        if let model {
            imageModelCache[name] = model
        }
        return model
    }

    // MARK: - Helpers

    private func modelsDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let modelsDir = base.appendingPathComponent("aidoku-upscale-cli/Models", isDirectory: true)
        if !FileManager.default.fileExists(atPath: modelsDir.path) {
            try FileManager.default.createDirectory(
                at: modelsDir,
                withIntermediateDirectories: true
            )
        }
        return modelsDir
    }

    private func metadataURL(forModelFile fileName: String) throws -> URL {
        try modelsDirectory().appendingPathComponent(fileName + ".json")
    }

    private func installedModelFiles() throws -> [String] {
        let modelsDir = try modelsDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: modelsDir.path) else {
            return []
        }
        return files.filter { $0.hasSuffix(".mlpackage") || $0.hasSuffix(".mlmodel") }
    }
}

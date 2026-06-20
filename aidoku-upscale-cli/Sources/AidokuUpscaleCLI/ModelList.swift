import Foundation

struct ModelList: Decodable {
    let models: [ModelInfo]
}

struct ModelInfo: Codable {
    var name: String?
    var info: String?
    var tags: [String]?
    var type: String?
    var miniOS: Int?
    var config: ModelConfig?
    var file: String
    var size: Int?
}

struct ModelConfig: Codable {
    var inputName: String?
    var outputName: String?
    var blockSize: Int?
    var shrinkSize: Int?
    var scale: Int?
    var shape: [Int]?
}

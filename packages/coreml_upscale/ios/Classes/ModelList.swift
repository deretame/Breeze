import Foundation

struct ModelConfig: Codable {
    var inputName: String?
    var outputName: String?
    var blockSize: Int?
    var shrinkSize: Int?
    var scale: Int?
    var shape: [Int]?
}

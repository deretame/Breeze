import CoreML

protocol ImageProcessingModel {
    init?(model: MLModel, config: [String: Any])
    func process(_ image: CGImage) async -> CGImage?
}

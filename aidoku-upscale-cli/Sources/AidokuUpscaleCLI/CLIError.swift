import Foundation

enum CLIError: Error, CustomStringConvertible {
    case invalidInput(String)
    case modelNotFound(String)
    case modelListUnavailable
    case modelDownloadFailed(String)
    case modelLoadFailed(String)
    case processingFailed(String)
    case writeFailed(String)

    var description: String {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .modelNotFound(let name):
            return "Model not found: \(name)"
        case .modelListUnavailable:
            return "Could not fetch model list"
        case .modelDownloadFailed(let message):
            return "Model download failed: \(message)"
        case .modelLoadFailed(let message):
            return "Model load failed: \(message)"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .writeFailed(let message):
            return "Write failed: \(message)"
        }
    }
}

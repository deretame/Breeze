import Foundation
import CoreGraphics
import ImageIO

enum ImageIO {
    static func loadCGImage(from path: String) throws -> CGImage {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            throw CoreMLUpscaleError.invalidInput("Cannot read file at \(path)")
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw CoreMLUpscaleError.invalidInput("Cannot decode image at \(path)")
        }
        return image
    }

    static func writeCGImage(_ image: CGImage, to path: String) throws {
        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension.lowercased()
        let uti: CFString
        if ext == "jpg" || ext == "jpeg" {
            uti = "public.jpeg" as CFString
        } else {
            uti = "public.png" as CFString
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil) else {
            throw CoreMLUpscaleError.writeFailed("Cannot create image destination at \(path)")
        }
        CGImageDestinationAddImage(destination, image, nil)
        if !CGImageDestinationFinalize(destination) {
            throw CoreMLUpscaleError.writeFailed("Failed to write image to \(path)")
        }
    }
}

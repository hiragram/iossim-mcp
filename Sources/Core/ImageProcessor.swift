import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Processes images for size optimization
public struct ImageProcessor: Sendable {
    /// Maximum width for resized images
    public let maxWidth: Int
    /// Target maximum file size in bytes
    public let maxFileSize: Int
    /// Initial JPEG quality (0.0 - 1.0)
    public let initialQuality: Double

    public init(
        maxWidth: Int = 500,
        maxFileSize: Int = 256 * 1024,  // 256KB
        initialQuality: Double = 0.8
    ) {
        self.maxWidth = maxWidth
        self.maxFileSize = maxFileSize
        self.initialQuality = initialQuality
    }

    /// Resizes and compresses an image to fit within size constraints
    /// - Parameter inputPath: Path to the input image file
    /// - Returns: JPEG data that fits within maxFileSize
    public func processImage(at inputPath: URL) throws -> Data {
        // Load the image
        guard let imageSource = CGImageSourceCreateWithURL(inputPath as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ImageProcessorError.failedToLoadImage
        }

        // Calculate new size maintaining aspect ratio
        let originalWidth = cgImage.width
        let originalHeight = cgImage.height

        let scale: CGFloat
        if originalWidth > maxWidth {
            scale = CGFloat(maxWidth) / CGFloat(originalWidth)
        } else {
            scale = 1.0
        }

        let newWidth = Int(CGFloat(originalWidth) * scale)
        let newHeight = Int(CGFloat(originalHeight) * scale)

        // Resize the image
        let resizedImage: CGImage
        if scale < 1.0 {
            guard let resized = resizeImage(cgImage, to: CGSize(width: newWidth, height: newHeight)) else {
                throw ImageProcessorError.failedToResizeImage
            }
            resizedImage = resized
        } else {
            resizedImage = cgImage
        }

        // Compress to JPEG with adaptive quality
        var quality = initialQuality
        var jpegData = try createJPEGData(from: resizedImage, quality: quality)

        // Reduce quality until we're under the size limit
        while jpegData.count > maxFileSize && quality > 0.1 {
            quality -= 0.1
            jpegData = try createJPEGData(from: resizedImage, quality: quality)
        }

        return jpegData
    }

    private func resizeImage(_ image: CGImage, to size: CGSize) -> CGImage? {
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        context?.interpolationQuality = .high
        context?.draw(image, in: CGRect(origin: .zero, size: size))

        return context?.makeImage()
    }

    private func createJPEGData(from image: CGImage, quality: Double) throws -> Data {
        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageProcessorError.failedToCreateDestination
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageProcessorError.failedToFinalizeImage
        }

        return data as Data
    }
}

public enum ImageProcessorError: Error, LocalizedError {
    case failedToLoadImage
    case failedToResizeImage
    case failedToCreateDestination
    case failedToFinalizeImage

    public var errorDescription: String? {
        switch self {
        case .failedToLoadImage:
            return "Failed to load image"
        case .failedToResizeImage:
            return "Failed to resize image"
        case .failedToCreateDestination:
            return "Failed to create image destination"
        case .failedToFinalizeImage:
            return "Failed to finalize image"
        }
    }
}

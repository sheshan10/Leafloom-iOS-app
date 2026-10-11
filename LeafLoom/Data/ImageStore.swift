import ImageIO
import OSLog
import UIKit
import UniformTypeIdentifiers

enum ImageStoreError: LocalizedError {
    case invalidImage
    case tooLarge
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage: "That file isn’t an image LeafLoom can read."
        case .tooLarge: "That photo is too large. Please choose one under 25 MB."
        case .writeFailed: "The photo couldn’t be saved on this device."
        }
    }
}

/// Stores photos as downsampled JPEG files in Application Support. Core Data only keeps the file name,
/// which keeps the database small. Nothing leaves the device.
final class ImageStore: @unchecked Sendable {
    static let maxInputBytes = 25 * 1024 * 1024
    static let maxPixelSize: CGFloat = 1600
    private let directory: URL
    private let cache = NSCache<NSString, UIImage>()
    private let logger = Logger(subsystem: "com.leafloom.LeafLoom", category: "Images")

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.directory = base.appendingPathComponent("Images", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
        cache.countLimit = 60
    }

    func url(for filename: String) -> URL { directory.appendingPathComponent(filename) }

    /// Downsamples and saves image data; returns the new file name.
    func save(_ data: Data) throws -> String {
        guard data.count <= Self.maxInputBytes else { throw ImageStoreError.tooLarge }
        guard let image = Self.downsample(data: data, maxPixelSize: Self.maxPixelSize),
              let jpeg = image.jpegData(compressionQuality: 0.82) else { throw ImageStoreError.invalidImage }
        let filename = UUID().uuidString + ".jpg"
        do {
            try jpeg.write(to: url(for: filename), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            logger.error("Image write failed: \(error.localizedDescription, privacy: .public)")
            throw ImageStoreError.writeFailed
        }
        return filename
    }

    func save(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.9) else { throw ImageStoreError.invalidImage }
        return try save(data)
    }

    /// Loads a display-sized image, using a small in-memory cache.
    func image(named filename: String, maxPixelSize: CGFloat = 900) -> UIImage? {
        let key = "\(filename)@\(Int(maxPixelSize))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let data = try? Data(contentsOf: url(for: filename)),
              let image = Self.downsample(data: data, maxPixelSize: maxPixelSize) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    func delete(_ filename: String?) {
        guard let filename else { return }
        cache.removeAllObjects()
        try? FileManager.default.removeItem(at: url(for: filename))
    }

    func deleteAll() {
        cache.removeAllObjects()
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        files.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    /// ImageIO thumbnailing decodes only what is needed, so large photos don't spike memory.
    static func downsample(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

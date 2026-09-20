//
//  PhotoBoothKit.swift
//  PhotoBooth
//
//  Filters, photo-strip composition, and saving to the Photos library.
//

import CoreImage
import Photos
import UIKit

enum PhotoFilter: String, CaseIterable, Identifiable, Hashable {
    case none = "Original"
    case mono = "B&W"
    case sepia = "Sepia"
    case noir = "Noir"

    var id: String { rawValue }

    private static let context = CIContext()

    func apply(to image: UIImage) -> UIImage {
        guard self != .none, let ciImage = CIImage(image: image) else { return image }

        let filterName: String
        switch self {
        case .mono: filterName = "CIPhotoEffectMono"
        case .sepia: filterName = "CISepiaTone"
        case .noir: filterName = "CIPhotoEffectNoir"
        case .none: return image
        }

        guard let filter = CIFilter(name: filterName) else { return image }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        if filterName == "CISepiaTone" {
            filter.setValue(0.85, forKey: kCIInputIntensityKey)
        }

        guard let output = filter.outputImage,
              let cgImage = PhotoFilter.context.createCGImage(output, from: ciImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

enum PhotoStripComposer {
    static func compose(
        images: [UIImage],
        filter: PhotoFilter,
        captionText: String = "PhotoBooth",
        captionColor: UIColor = .black,
        backgroundColor: UIColor = .white
    ) -> UIImage? {
        guard !images.isEmpty else { return nil }

        let filtered = images.map { filter.apply(to: $0) }

        let stripWidth: CGFloat = 640
        let padding: CGFloat = 24
        let photoHeight: CGFloat = 420
        let footerHeight: CGFloat = 100
        let totalHeight = (photoHeight * CGFloat(filtered.count))
            + (padding * CGFloat(filtered.count + 1))
            + footerHeight

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: stripWidth, height: totalHeight))

        return renderer.image { ctx in
            backgroundColor.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: stripWidth, height: totalHeight))

            var y = padding
            for image in filtered {
                let frame = CGRect(x: padding, y: y, width: stripWidth - padding * 2, height: photoHeight)
                draw(image, aspectFillIn: frame, context: ctx.cgContext)
                y += photoHeight + padding
            }

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 26),
                .foregroundColor: captionColor
            ]
            let titleSize = captionText.size(withAttributes: titleAttrs)
            let titleRect = CGRect(
                x: (stripWidth - titleSize.width) / 2,
                y: totalHeight - footerHeight + (footerHeight - titleSize.height) / 2 - 10,
                width: titleSize.width,
                height: titleSize.height
            )
            captionText.draw(in: titleRect, withAttributes: titleAttrs)

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: Date())
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: captionColor.withAlphaComponent(0.65)
            ]
            let dateSize = dateString.size(withAttributes: dateAttrs)
            let dateRect = CGRect(
                x: (stripWidth - dateSize.width) / 2,
                y: titleRect.maxY + 6,
                width: dateSize.width,
                height: dateSize.height
            )
            dateString.draw(in: dateRect, withAttributes: dateAttrs)
        }
    }

    private static func draw(_ image: UIImage, aspectFillIn rect: CGRect, context: CGContext) {
        context.saveGState()
        context.clip(to: rect)

        let imageAspect = image.size.width / image.size.height
        let rectAspect = rect.width / rect.height
        var drawRect = rect

        if imageAspect > rectAspect {
            let scaledWidth = rect.height * imageAspect
            drawRect = CGRect(x: rect.midX - scaledWidth / 2, y: rect.minY, width: scaledWidth, height: rect.height)
        } else {
            let scaledHeight = rect.width / imageAspect
            drawRect = CGRect(x: rect.minX, y: rect.midY - scaledHeight / 2, width: rect.width, height: scaledHeight)
        }

        image.draw(in: drawRect)
        context.restoreGState()
    }
}

enum PhotoLibrarySaver {
    static func save(_ image: UIImage, completion: @escaping (Bool, String?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        completion(success, error?.localizedDescription)
                    }
                }
            default:
                DispatchQueue.main.async {
                    completion(false, "Photo library access is disabled. Enable it in Settings to save photos.")
                }
            }
        }
    }
}

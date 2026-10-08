import SwiftUI
import UIKit

/// Composites photos beneath the Philippine Independence Day artwork for review, saving, and sharing.
enum IndependenceDayStrip {
    static let photoCount = 4
    static let photoAspectRatio: CGFloat = 514.0 / 347.0

    static func compose(images: [UIImage], filter: PhotoFilter) -> UIImage? {
        guard images.count == photoCount,
              let artwork = UIImage(named: "IndependenceDayFrame") else { return nil }

        // Photo openings measured in the original 724 × 2172 artwork.
        // Extend beneath the printed borders to avoid seams around distressed edges.
        let frames = [
            CGRect(x: 98, y: 336, width: 530, height: 358),
            CGRect(x: 98, y: 760, width: 530, height: 358),
            CGRect(x: 98, y: 1184, width: 530, height: 362),
            CGRect(x: 98, y: 1610, width: 530, height: 358)
        ]
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: artwork.size, format: format).image { renderer in
            for (image, frame) in zip(images, frames) {
                PhotoStripComposer.draw(filter.apply(to: image), aspectFillIn: frame,
                                        context: renderer.cgContext)
            }
            artwork.draw(in: CGRect(origin: .zero, size: artwork.size))
        }
    }
}

#if DEBUG
#Preview("Independence Day — Commemorative Frame") {
    let samples = (1...IndependenceDayStrip.photoCount).map { index in
        UIGraphicsImageRenderer(size: CGSize(width: 592, height: 420)).image { renderer in
            UIColor(red: 0.80, green: 0.77, blue: 0.70, alpha: 1).setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: 592, height: 420))
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            "PHOTO 0\(index)".draw(in: CGRect(x: 0, y: 184, width: 592, height: 50),
                                 withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 28, weight: .medium),
                                                  .foregroundColor: UIColor.darkGray,
                                                  .paragraphStyle: paragraph])
        }
    }
    ScrollView {
        if let strip = IndependenceDayStrip.compose(images: samples, filter: .none) {
            Image(uiImage: strip)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320)
                .padding(24)
        }
    }
    .frame(maxWidth: .infinity)
    .background(Color.gray.opacity(0.15))
}
#endif

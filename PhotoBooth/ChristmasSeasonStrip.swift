import SwiftUI
import UIKit

/// Composites photos beneath the Christmas season artwork for review, saving, and sharing.
enum ChristmasSeasonStrip {
    static let photoCount = 4
    static let photoAspectRatio: CGFloat = 538.0 / 340.0

    static func compose(images: [UIImage], filter: PhotoFilter) -> UIImage? {
        guard images.count == photoCount,
              let artwork = UIImage(named: "ChristmasSeasonFrame") else { return nil }

        // Photo openings measured in the original 729 × 2158 artwork.
        // Extend beneath the printed borders to avoid seams around distressed edges.
        let frames = [
            CGRect(x: 94, y: 225, width: 545, height: 346),
            CGRect(x: 94, y: 651, width: 545, height: 346),
            CGRect(x: 94, y: 1076, width: 545, height: 346),
            CGRect(x: 94, y: 1499, width: 545, height: 324)
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
#Preview("Christmas Season — Festive Frame") {
    let samples = (1...ChristmasSeasonStrip.photoCount).map { index in
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
        if let strip = ChristmasSeasonStrip.compose(images: samples, filter: .none) {
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

import SwiftUI
import UIKit

/// Composites photos beneath the Christmas Eve artwork for review, saving, and sharing.
enum ChristmasEveStrip {
    static let photoCount = 4
    static let photoAspectRatio: CGFloat = 500.0 / 306.0

    static func compose(images: [UIImage], filter: PhotoFilter) -> UIImage? {
        guard images.count == photoCount,
              let artwork = UIImage(named: "ChristmasEveFrame") else { return nil }

        // Photo openings measured in the original 724 × 2172 artwork.
        // Extend beneath the printed borders to avoid seams around distressed edges.
        let frames = [
            CGRect(x: 106, y: 208, width: 512, height: 340),
            CGRect(x: 106, y: 608, width: 512, height: 334),
            CGRect(x: 106, y: 1005, width: 512, height: 332),
            CGRect(x: 106, y: 1399, width: 512, height: 338)
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
#Preview("Christmas Eve — Night Frame") {
    let samples = (1...ChristmasEveStrip.photoCount).map { index in
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
        if let strip = ChristmasEveStrip.compose(images: samples, filter: .none) {
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

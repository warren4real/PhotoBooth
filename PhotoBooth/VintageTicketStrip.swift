import SwiftUI
import UIKit

/// Composites photos beneath the approved ticket artwork for review, saving, and sharing.
enum VintageTicketStrip {
    static let photoCount = 4
    static let photoAspectRatio: CGFloat = 456.0 / 302.0

    static func compose(images: [UIImage], filter: PhotoFilter) -> UIImage? {
        guard images.count == photoCount,
              let artwork = UIImage(named: "VintageTicketFrame") else { return nil }

        // Photo openings measured in the original 724 × 2172 artwork.
        // Extend beneath the printed borders to avoid seams around distressed edges.
        let frames = [
            CGRect(x: 132, y: 284, width: 464, height: 310),
            CGRect(x: 132, y: 676, width: 464, height: 310),
            CGRect(x: 132, y: 1072, width: 464, height: 310),
            CGRect(x: 132, y: 1462, width: 464, height: 314)
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
#Preview("Everyday — Vintage Ticket") {
    let samples = (1...VintageTicketStrip.photoCount).map { index in
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
        if let strip = VintageTicketStrip.compose(images: samples, filter: .none) {
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

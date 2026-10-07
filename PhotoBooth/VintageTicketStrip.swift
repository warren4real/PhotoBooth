import SwiftUI
import UIKit

/// A ticket-inspired frame drawn into the final image, so saving and sharing match review.
enum VintageTicketStrip {
    static func compose(images: [UIImage], filter: PhotoFilter) -> UIImage? {
        guard !images.isEmpty else { return nil }
        let width = PhotoStripComposer.stripWidth
        let gap = PhotoStripComposer.padding
        let photoHeight = PhotoStripComposer.photoHeight
        let header: CGFloat = 204
        let footer: CGFloat = 180
        let height = header + CGFloat(images.count) * (photoHeight + gap) + footer
        let cream = UIColor(red: 0.98, green: 0.96, blue: 0.88, alpha: 1)
        let burgundy = UIColor(red: 0.40, green: 0.08, blue: 0.12, alpha: 1)

        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { renderer in
            let context = renderer.cgContext
            cream.setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: width, height: height))
            burgundy.setStroke()
            let border = UIBezierPath(roundedRect: CGRect(x: 12, y: 12, width: width - 24, height: height - 24), cornerRadius: 36)
            border.lineWidth = 3
            border.stroke()

            func label(_ text: String, y: CGFloat, font: UIFont, color: UIColor = burgundy) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                text.draw(in: CGRect(x: 32, y: y, width: width - 64, height: font.lineHeight + 8),
                          withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
            }
            label("P O C K E T   S T U D I O", y: 35, font: .monospacedSystemFont(ofSize: 15, weight: .medium))
            label("PHOTOBOOTH", y: 64, font: UIFont(name: "Georgia-Bold", size: 51) ?? .boldSystemFont(ofSize: 51))
            label("A TICKET TO THE GOOD TIMES", y: 127, font: .monospacedSystemFont(ofSize: 15, weight: .regular))
            label("★   ADMIT FOUR   ★", y: 163, font: .monospacedSystemFont(ofSize: 17, weight: .bold))

            for (index, image) in images.enumerated() {
                let frame = CGRect(x: gap, y: header + CGFloat(index) * (photoHeight + gap),
                                   width: width - gap * 2, height: photoHeight)
                let outline = UIBezierPath(roundedRect: frame, cornerRadius: 10)
                context.saveGState()
                outline.addClip()
                PhotoStripComposer.draw(filter.apply(to: image), aspectFillIn: frame, context: context)
                context.restoreGState()
                burgundy.setStroke()
                outline.lineWidth = 3
                outline.stroke()
            }

            let footerY = header + CGFloat(images.count) * (photoHeight + gap)
            label("KEEP THIS MOMENT", y: footerY + 5, font: UIFont(name: "Georgia-Bold", size: 26) ?? .boldSystemFont(ofSize: 26))
            // Decorative ticket bars; these intentionally do not encode personal data.
            burgundy.setFill()
            let bars: [CGFloat] = [2, 1, 3, 1, 2, 4, 1, 1, 3, 2, 1, 4, 2, 1, 3, 1]
            var x: CGFloat = 170
            for index in 0..<64 {
                let barWidth = bars[index % bars.count] * 1.5
                renderer.fill(CGRect(x: x, y: footerY + 50, width: barWidth, height: 42))
                x += barWidth + 1.5
            }
            let date = DateFormatter()
            date.locale = Locale(identifier: "en_PH")
            date.timeZone = TimeZone(identifier: "Asia/Manila")
            date.dateFormat = "dd MMM yyyy"
            label(date.string(from: Date()).uppercased(), y: footerY + 104, font: .monospacedSystemFont(ofSize: 17, weight: .medium))
            label("PHOTOBOOTH  /  ORIGINAL SERIES", y: footerY + 137, font: .monospacedSystemFont(ofSize: 11, weight: .regular))
        }
    }
}

#if DEBUG
#Preview("Everyday — Vintage Ticket") {
    let samples = (1...4).map { index in
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

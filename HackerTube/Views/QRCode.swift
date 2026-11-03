import CoreImage.CIFilterBuiltins
import SwiftUI

/// A QR code for a link, so a phone can open it.
struct QRCode: View {
    let url: URL

    var body: some View {
        if let image = Self.image(for: url.absoluteString) {
            Image(decorative: image, scale: 1)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(20)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    static func image(for text: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        return CIContext().createCGImage(output, from: output.extent)
    }
}

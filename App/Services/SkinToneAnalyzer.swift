import Foundation
import CoreImage
import Vision
import UIKit

enum SkinToneError: LocalizedError {
    case invalidImage
    case noFaceDetected
    case analysisFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return String(localized: "Immagine non valida.")
        case .noFaceDetected:
            return String(localized: "Nessun volto rilevato: inquadra il viso per confrontare il tono.")
        case .analysisFailed(let error):
            return String(localized: "Analisi del tono non riuscita: \(error.localizedDescription)")
        }
    }
}

/// Analizza il tono della pelle interamente on-device: individua il volto con
/// Vision e calcola la luminosità media dell'area, senza inviare nulla in rete.
enum SkinToneAnalyzer {
    static func skinLightness(of image: UIImage) async throws -> Double {
        guard let cgImage = image.cgImage else {
            throw SkinToneError.invalidImage
        }

        let faceRect = try await detectFace(in: cgImage)
        let ciImage = CIImage(cgImage: cgImage)
        let imageExtent = ciImage.extent

        // VNFaceObservation usa coordinate normalizzate con origine in basso a sinistra.
        let region = CGRect(
            x: faceRect.origin.x * imageExtent.width,
            y: faceRect.origin.y * imageExtent.height,
            width: faceRect.width * imageExtent.width,
            height: faceRect.height * imageExtent.height
        ).integral.intersection(imageExtent)

        guard !region.isNull, region.width > 0, region.height > 0 else {
            throw SkinToneError.noFaceDetected
        }

        return averageLightness(of: ciImage, in: region)
    }

    private static func detectFace(in cgImage: CGImage) async throws -> CGRect {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error {
                    continuation.resume(throwing: SkinToneError.analysisFailed(error))
                    return
                }
                guard let face = (request.results as? [VNFaceObservation])?.first else {
                    continuation.resume(throwing: SkinToneError.noFaceDetected)
                    return
                }
                continuation.resume(returning: face.boundingBox)
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: SkinToneError.analysisFailed(error))
            }
        }
    }

    /// Luminosità percepita media (0...1) della regione, via filtro CIAreaAverage.
    private static func averageLightness(of image: CIImage, in region: CGRect) -> Double {
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        let extentVector = CIVector(x: region.minX, y: region.minY, z: region.width, w: region.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: image,
            kCIInputExtentKey: extentVector,
        ]), let output = filter.outputImage else {
            return 0.5
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        // Luminanza percepita (Rec. 601), normalizzata 0...1.
        let r = Double(bitmap[0]) / 255
        let g = Double(bitmap[1]) / 255
        let b = Double(bitmap[2]) / 255
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
}

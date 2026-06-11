import Foundation
import SwiftData

/// Una foto del diario dell'abbronzatura. L'immagine è salvata come dato esterno
/// (resta su disco/iCloud privato, mai caricata su server).
@Model
final class TanPhoto {
    private(set) var capturedAt: Date
    @Attribute(.externalStorage) private(set) var imageData: Data
    /// Luminosità media della pelle rilevata (0 = scura, 1 = chiara); più bassa
    /// nel tempo = abbronzatura più intensa. `nil` se l'analisi non è riuscita.
    private(set) var skinLightness: Double?

    init(capturedAt: Date = .now, imageData: Data, skinLightness: Double?) {
        self.capturedAt = capturedAt
        self.imageData = imageData
        self.skinLightness = skinLightness
    }
}

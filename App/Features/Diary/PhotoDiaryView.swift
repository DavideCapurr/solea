import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct PhotoDiaryView: View {
    let hasSoleaPlus: Bool

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TanPhoto.capturedAt, order: .forward) private var photos: [TanPhoto]

    @State private var pickerItem: PhotosPickerItem?
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if hasSoleaPlus {
                    if photos.isEmpty {
                        ContentUnavailableView {
                            Label("Diario fotografico", systemImage: "camera")
                        } description: {
                            Text("Aggiungi una foto periodica per seguire l'evoluzione del tuo tono pelle. Le foto restano sul tuo dispositivo.")
                        } actions: {
                            photoPicker
                        }
                    } else {
                        content
                    }
                } else {
                    SoleaPlusLockedView(
                        title: "Foto-diario Plus",
                        message: "Sblocca timeline fotografica, confronto prima/dopo, analisi tono e condivisione premium.",
                        systemImage: "camera.filters",
                        source: "photo_diary"
                    )
                }
            }
            .navigationTitle("Diario fotografico")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if hasSoleaPlus {
                        if isImporting {
                            ProgressView()
                        } else {
                            photoPicker
                        }
                    }
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                importPhoto(newItem)
            }
            .alert(
                "Foto non aggiunta",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Label("Aggiungi foto", systemImage: "plus")
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                if photos.count >= 2, let first = photos.first, let last = photos.last {
                    ComparisonSlider(before: first, after: last)
                        .padding(.horizontal)
                }
                timeline
            }
            .padding(.vertical)
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cronologia")
                .font(.headline)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(photos) { photo in
                        thumbnail(photo)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func thumbnail(_ photo: TanPhoto) -> some View {
        VStack(spacing: 4) {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Text(photo.capturedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func importPhoto(_ item: PhotosPickerItem) {
        isImporting = true
        Task {
            defer {
                isImporting = false
                pickerItem = nil
            }
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    errorMessage = String(localized: "Impossibile leggere l'immagine selezionata.")
                    return
                }
                // L'analisi del tono è best-effort: se non rileva un volto la
                // foto si salva comunque, ma senza valore di luminosità.
                let lightness = try? await SkinToneAnalyzer.skinLightness(of: image)
                modelContext.insert(TanPhoto(imageData: data, skinLightness: lightness))
                try modelContext.save()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct ComparisonSlider: View {
    let before: TanPhoto
    let after: TanPhoto

    @State private var position: Double = 0.5
    @State private var sharePayload: SharePayload?

    var body: some View {
        VStack(spacing: 12) {
            Text("Prima / dopo")
                .font(.headline)
            if let beforeImage = UIImage(data: before.imageData),
               let afterImage = UIImage(data: after.imageData) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Image(uiImage: afterImage)
                            .resizable()
                            .scaledToFill()
                        Image(uiImage: beforeImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width * position)
                            .clipped()
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2)
                            .offset(x: geometry.size.width * position)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .frame(height: 360)
                Slider(value: $position, in: 0...1)
                toneTrend

                Button {
                    shareComparison(beforeImage: beforeImage, afterImage: afterImage)
                } label: {
                    Label("Condividi il prima / dopo", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Text("Condividerai solo queste due foto e le relative date, mai posizione o dati del profilo.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(payload: payload)
        }
    }

    @ViewBuilder
    private var toneTrend: some View {
        if let beforeTone = before.skinLightness, let afterTone = after.skinLightness {
            let delta = beforeTone - afterTone
            let trend = delta > 0.02
                ? String(localized: "Tono più scuro del \(Int((delta * 100).rounded()))% rispetto alla prima foto")
                : String(localized: "Tono stabile rispetto alla prima foto")
            Label(
                trend,
                systemImage: delta > 0.02 ? "arrow.down.right.circle" : "equal.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    @MainActor
    private func shareComparison(beforeImage: UIImage, afterImage: UIImage) {
        let card = PhotoComparisonShareCard(
            beforeImage: beforeImage,
            afterImage: afterImage,
            beforeDate: before.capturedAt,
            afterDate: after.capturedAt,
            trend: shareTrend
        )
        sharePayload = renderSharePayload(
            content: card,
            caption: String(localized: "Il mio prima / dopo con Abbronzo. Ho scelto io di condividere queste foto; gli originali restano sul dispositivo. ☀️"),
            source: "photo_comparison"
        )
    }

    private var shareTrend: String {
        guard let beforeTone = before.skinLightness, let afterTone = after.skinLightness else {
            return String(localized: "Il mio percorso, un check alla volta.")
        }
        let delta = beforeTone - afterTone
        if delta > 0.02 {
            return String(localized: "Tono più scuro del \(Int((delta * 100).rounded()))% rispetto alla prima foto")
        }
        return String(localized: "Tono stabile rispetto alla prima foto")
    }
}

private struct PhotoComparisonShareCard: View {
    let beforeImage: UIImage
    let afterImage: UIImage
    let beforeDate: Date
    let afterDate: Date
    let trend: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.96, blue: 0.86),
                    Color(red: 1.00, green: 0.69, blue: 0.24),
                    Color(red: 0.92, green: 0.30, blue: 0.17)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label("ABBRONZO", systemImage: "sun.max.fill")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Spacer()
                    Text("TAN SMARTER")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.8)
                }

                Text("IL MIO PRIMA / DOPO")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.82), in: Capsule())
                    .foregroundStyle(.white)

                Text("Il percorso si vede.")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.84))

                HStack(spacing: 8) {
                    storyPhoto(beforeImage, label: "PRIMA", date: beforeDate)
                    storyPhoto(afterImage, label: "DOPO", date: afterDate)
                }

                Label(trend, systemImage: "sparkles")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.72))
                    .lineLimit(2)

                Spacer(minLength: 0)

                HStack {
                    Text("Foto condivise su scelta dell'utente")
                    Spacer()
                    Image(systemName: "lock.fill")
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(14)
                .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(26)
        }
        .frame(width: 360, height: 640)
        .clipped()
        .environment(\.colorScheme, .light)
    }

    private func storyPhoto(_ image: UIImage, label: String, date: Date) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 300)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(1)
                Text(date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

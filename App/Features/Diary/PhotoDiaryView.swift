import SwiftUI
import SwiftData
import PhotosUI

struct PhotoDiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TanPhoto.capturedAt, order: .forward) private var photos: [TanPhoto]

    @State private var pickerItem: PhotosPickerItem?
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if photos.isEmpty {
                    ContentUnavailableView {
                        Label("Foto-diario", systemImage: "camera")
                    } description: {
                        Text("Aggiungi una foto periodica per seguire l'evoluzione del tuo tono pelle. Le foto restano sul tuo dispositivo.")
                    } actions: {
                        photoPicker
                    }
                } else {
                    content
                }
            }
            .navigationTitle("Foto-diario")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if isImporting {
                        ProgressView()
                    } else {
                        photoPicker
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
            }
        }
    }

    @ViewBuilder
    private var toneTrend: some View {
        if let beforeTone = before.skinLightness, let afterTone = after.skinLightness {
            let delta = beforeTone - afterTone
            Label(
                delta > 0.02
                    ? "Tono più scuro del \(Int((delta * 100).rounded()))% rispetto alla prima foto"
                    : "Tono stabile rispetto alla prima foto",
                systemImage: delta > 0.02 ? "arrow.down.right.circle" : "equal.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

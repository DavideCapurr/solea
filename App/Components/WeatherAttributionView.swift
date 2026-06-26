import SwiftUI

/// Attribuzione richiesta da Apple per le app che usano WeatherKit
/// (linea guida App Store 5.2.5): marchio "Apple Weather" + link alle fonti
/// legali dei dati meteo. Va mostrata ovunque Solea presenti dati WeatherKit
/// (indice UV e previsioni).
struct WeatherAttributionView: View {
    var body: some View {
        Link(destination: AppStoreLinks.weatherKitAttributionURL) {
            HStack(spacing: 4) {
                Image(systemName: "apple.logo")
                    .imageScale(.small)
                // Marchio: non localizzato.
                Text(verbatim: "Weather")
                Text(verbatim: "·")
                Text("Altre fonti dati")
                    .underline()
                Image(systemName: "arrow.up.right")
                    .imageScale(.small)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Apple Weather. Apri le fonti dei dati meteo.")
    }
}

#Preview {
    WeatherAttributionView()
        .padding()
}

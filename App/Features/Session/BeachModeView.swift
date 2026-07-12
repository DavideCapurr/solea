import SwiftUI
import SoleaCore
#if canImport(UIKit)
import UIKit
#endif

/// Modalità spiaggia super rapida: schermata a tutto schermo, leggibile a colpo
/// d'occhio e resistente ai tocchi accidentali. Mostra solo i 5 controlli
/// essenziali — Target, Lato, SPF, Acqua, Stop — mentre il telefono è poggiato
/// al sole. Tutto gratis: non richiede Abbronzo Plus.
struct BeachModeView: View {
    let manager: SessionManager
    /// Termina la sessione (stessa callback usata da ActiveSessionView).
    let onEnd: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var stopProgress: CGFloat = 0
    @State private var isHoldingStop = false
    @State private var sideToggleCount = 0
    @State private var spfReapplyCount = 0
    @State private var waterTapCount = 0

    private static let holdToStopDuration: Double = 1.5

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SoleaTheme.sunshine, SoleaTheme.sunset],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if let session = manager.active {
                content(session: session)
            } else {
                // Stato transitorio dopo end(): chiudi e lascia che il parent
                // mostri il riepilogo.
                Color.clear.onAppear { dismiss() }
            }
        }
        .preferredColorScheme(.light)
        .onAppear { setIdleTimerDisabled(true) }
        .onDisappear { setIdleTimerDisabled(false) }
    }

    private func content(session: SessionManager.ActiveSession) -> some View {
        VStack(spacing: 18) {
            topBar(session: session)
            targetHero(session: session)
            companions(session: session)
            Spacer(minLength: 0)
            stopButton
        }
        .padding(20)
    }

    // MARK: - Top bar

    private func topBar(session: SessionManager.ActiveSession) -> some View {
        HStack {
            Label(formattedElapsed(session.elapsedSeconds), systemImage: "timer")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.black.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white.opacity(0.5), in: Capsule())

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 34))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.black.opacity(0.65))
            }
            .accessibilityLabel("Chiudi modalità spiaggia")
        }
    }

    // MARK: - Target (hero)

    private func targetHero(session: SessionManager.ActiveSession) -> some View {
        let plannedSeconds = max(1, session.configuration.plannedDurationMinutes * 60)
        let progress = min(Double(session.elapsedSeconds) / Double(plannedSeconds), 1)
        let remaining = manager.goalRemainingSeconds
        let reached = (remaining ?? 0) == 0
        let tint = doseTint(session: session)

        return VStack(spacing: 12) {
            Label("TARGET", systemImage: "target")
                .font(.caption.bold())
                .tracking(1.4)
                .foregroundStyle(.black.opacity(0.55))

            Group {
                if session.isPaused {
                    Text("In pausa")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                } else if reached {
                    Label("Fatto", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                } else {
                    Text(formattedElapsed(remaining ?? plannedSeconds))
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(reached ? SoleaTheme.mint : tint)
            .minimumScaleFactor(0.6)
            .lineLimit(1)

            Text(reached ? "Obiettivo raggiunto" : "all'obiettivo di oggi")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black.opacity(0.6))

            ProgressView(value: progress)
                .tint(reached ? SoleaTheme.mint : tint)
                .scaleEffect(x: 1, y: 1.6, anchor: .center)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 28))
    }

    /// Tinta legata alla dose accumulata: stessa logica del doseRing in
    /// ActiveSessionView, così la sicurezza resta leggibile a colpo d'occhio.
    private func doseTint(session: SessionManager.ActiveSession) -> Color {
        let limit = SafeExposure.recommendedDoseLimit(phototype: session.phototype)
        let fraction = limit > 0 ? min(session.effectiveDose / limit, 1) : 0
        if fraction < 0.5 { return SoleaTheme.mint }
        if fraction < 0.8 { return SoleaTheme.sunset }
        return SoleaTheme.coral
    }

    // MARK: - Companion (Lato, SPF, Acqua)

    private func companions(session: SessionManager.ActiveSession) -> some View {
        HStack(spacing: 12) {
            sideTile(session: session)
            spfTile(session: session)
            waterTile(session: session)
        }
    }

    private func sideTile(session: SessionManager.ActiveSession) -> some View {
        let isFront = session.currentSide == .front
        return companionTile(
            icon: "arrow.triangle.2.circlepath",
            title: "LATO",
            value: isFront ? String(localized: "Fronte") : String(localized: "Retro"),
            subtitle: flipSubtitle(),
            valueColor: .black.opacity(0.85)
        ) {
            manager.setExposureSide(isFront ? .back : .front)
            sideToggleCount += 1
        }
        .sensoryFeedback(.selection, trigger: sideToggleCount)
    }

    private func flipSubtitle() -> String {
        guard let next = manager.nextFlipSeconds else {
            return String(localized: "Tocca per girarti")
        }
        return String(localized: "Gira tra \(formattedElapsed(next))")
    }

    private func spfTile(session: SessionManager.ActiveSession) -> some View {
        let hasSPF = session.configuration.spf > 1
        let needsReapply = manager.sunscreenNeedsReapplication
        let value: String
        let subtitle: String
        if !hasSPF {
            value = String(localized: "Nessuna")
            subtitle = String(localized: "Nessuna crema")
        } else if needsReapply {
            value = String(localized: "Ora")
            subtitle = String(localized: "Riapplica e tocca")
        } else if let next = manager.nextSunscreenReapplicationSeconds {
            value = formattedElapsed(next)
            subtitle = String(localized: "Riapplica tra")
        } else {
            value = "—"
            subtitle = String(localized: "Riapplica")
        }

        return companionTile(
            icon: "shield.lefthalf.filled",
            title: "SPF",
            value: value,
            subtitle: subtitle,
            valueColor: needsReapply ? SoleaTheme.coral : .black.opacity(0.85),
            isDisabled: !hasSPF
        ) {
            guard hasSPF else { return }
            Task { await manager.reapplySunscreen() }
            spfReapplyCount += 1
        }
        .sensoryFeedback(.success, trigger: spfReapplyCount)
    }

    private func waterTile(session: SessionManager.ActiveSession) -> some View {
        let subtitle: String
        if let next = manager.nextHydrationSeconds {
            subtitle = String(localized: "Bevi tra \(formattedElapsed(next))")
        } else {
            subtitle = String(localized: "Idratati")
        }
        return companionTile(
            icon: "drop.fill",
            title: "ACQUA",
            value: String(localized: "Bevi"),
            subtitle: subtitle,
            valueColor: .black.opacity(0.85)
        ) {
            Task { await manager.logHydration() }
            waterTapCount += 1
        }
        .sensoryFeedback(.impact(weight: .light), trigger: waterTapCount)
    }

    private func companionTile(
        icon: String,
        title: LocalizedStringKey,
        value: String,
        subtitle: String,
        valueColor: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.bold())
                    .foregroundStyle(.black.opacity(0.7))
                Text(title)
                    .font(.caption2.bold())
                    .tracking(1)
                    .foregroundStyle(.black.opacity(0.5))
                Text(value)
                    .font(.title2.weight(.heavy))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(valueColor)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.black.opacity(0.55))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .padding(14)
            .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.55 : 1)
        .disabled(isDisabled)
    }

    // MARK: - Stop (tieni premuto)

    private var stopButton: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(SoleaTheme.coral)

                // Riempimento progressivo durante il tieni-premuto.
                RoundedRectangle(cornerRadius: 24)
                    .fill(.black.opacity(0.28))
                    .frame(width: proxy.size.width * stopProgress)

                Label(
                    isHoldingStop
                        ? String(localized: "Continua a tenere premuto…")
                        : String(localized: "Tieni premuto per fermare"),
                    systemImage: "stop.circle.fill"
                )
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 72)
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .onLongPressGesture(minimumDuration: Self.holdToStopDuration) {
            stopProgress = 1
            isHoldingStop = false
            onEnd()
            dismiss()
        } onPressingChanged: { pressing in
            isHoldingStop = pressing
            withAnimation(.linear(duration: pressing ? Self.holdToStopDuration : 0.2)) {
                stopProgress = pressing ? 1 : 0
            }
        }
        .sensoryFeedback(.success, trigger: stopProgress == 1)
        .accessibilityLabel("Termina sessione")
        .accessibilityHint("Tieni premuto per fermare la sessione")
    }

    // MARK: - Helpers

    private func setIdleTimerDisabled(_ disabled: Bool) {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = disabled
        #endif
    }

    private func formattedElapsed(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}

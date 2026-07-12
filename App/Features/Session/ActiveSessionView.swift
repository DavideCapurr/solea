import SwiftUI
import SoleaCore

struct ActiveSessionView: View {
    let manager: SessionManager
    let hasSoleaPlus: Bool
    let onEnd: () -> Void

    @State private var showPaywall = false
    @State private var showBeachMode = false

    var body: some View {
        Group {
            if let session = manager.active {
                content(session: session)
            } else {
                // Stato transitorio tra end() e l'aggiornamento del parent.
                ProgressView()
            }
        }
        .sheet(isPresented: $showPaywall) {
            SoleaPlusPaywallView(source: "active_session")
        }
        .fullScreenCover(isPresented: $showBeachMode) {
            BeachModeView(manager: manager, onEnd: {
                showBeachMode = false
                onEnd()
            })
        }
    }

    private func content(session: SessionManager.ActiveSession) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                doseRing(session: session)
                beachModeButton
                if hasSoleaPlus {
                    goalProgress(session: session)
                    sideTracker(session: session)
                } else {
                    plusUpgradePanel
                }

                LabeledContent("Tempo trascorso") {
                    Text(formattedElapsed(session.elapsedSeconds))
                        .font(.title3.bold().monospacedDigit())
                }
                if !hasSoleaPlus {
                    LabeledContent("Timer obiettivo") {
                        Text("\(session.configuration.plannedDurationMinutes) min")
                            .bold()
                    }
                    LabeledContent("Tempo rimanente") {
                        targetRemainingLabel(session: session)
                    }
                }
                if session.pausedSeconds > 0 || session.isPaused {
                    LabeledContent("Pausa") {
                        Text(formattedElapsed(session.pausedSeconds))
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(session.isPaused ? Color.orange : Color.secondary)
                    }
                }
                LabeledContent("UV attuale") {
                    Text(session.currentUVIndex, format: .number.precision(.fractionLength(0)))
                        .bold()
                }
                LabeledContent("Stop sicurezza") {
                    remainingLabel
                }
                LabeledContent("SPF") {
                    Text(session.configuration.spf == 1
                         ? String(localized: "Nessuna")
                         : "SPF \(Int(session.configuration.spf))")
                }
                if hasSoleaPlus {
                    reminderTimeline
                }

                warnings
                pauseButton(session: session)
                if hasSoleaPlus {
                    reapplyButton(session: session)
                }

                Button(role: .destructive) {
                    onEnd()
                } label: {
                    Label("Termina sessione", systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .padding(.bottom, 96)
        }
        .navigationTitle("Sessione in corso")
    }

    private var beachModeButton: some View {
        Button {
            showBeachMode = true
        } label: {
            Label("Modalità spiaggia", systemImage: "beach.umbrella.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(SoleaTheme.sunset)
        .accessibilityHint("Schermata super rapida e leggibile al sole con solo target, lato, SPF, acqua e stop")
    }

    private var plusUpgradePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Timer Tanora attivo", systemImage: "timer")
                .font(.headline)
            Text("Tanora segue il timer scelto per il tuo obiettivo e continua a mostrarti UV e stop sicurezza. Plus aggiunge tracciamento fronte/retro, promemoria personalizzati e Live Activity avanzata.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                showPaywall = true
            } label: {
                Label("Sblocca strumenti Plus", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var reminderTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Prossimi promemoria", systemImage: "bell.badge")
                .font(.headline)

            if manager.active?.isPaused == true {
                Label("In pausa: i promemoria ripartono quando riprendi.", systemImage: "pause.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let nextFlip = manager.nextFlipSeconds {
                reminderRow("Girati", value: formattedElapsed(nextFlip), icon: "arrow.triangle.2.circlepath")
            }
            if let nextHydration = manager.nextHydrationSeconds {
                reminderRow("Acqua", value: formattedElapsed(nextHydration), icon: "drop.fill")
            }
            if let nextSPF = manager.nextSunscreenReapplicationSeconds {
                reminderRow("SPF", value: nextSPF == 0 ? String(localized: "ora") : formattedElapsed(nextSPF), icon: "shield.lefthalf.filled")
            }
            if let goalRemaining = manager.goalRemainingSeconds {
                reminderRow("Obiettivo", value: goalRemaining == 0 ? String(localized: "raggiunto") : formattedElapsed(goalRemaining), icon: "target")
            }
            if let remaining = manager.remainingSafeSeconds, remaining.isFinite {
                reminderRow("Stop sicurezza", value: formattedElapsed(Int(remaining)), icon: "exclamationmark.triangle.fill")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func reminderRow(_ title: LocalizedStringKey, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
        }
        .font(.subheadline)
    }

    private func goalProgress(session: SessionManager.ActiveSession) -> some View {
        let plannedSeconds = max(1, session.configuration.plannedDurationMinutes * 60)
        let progress = min(Double(session.elapsedSeconds) / Double(plannedSeconds), 1)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(goalTitle(session.configuration.goal), systemImage: "target")
                    .font(.headline)
                Spacer()
                Text("\(session.configuration.plannedDurationMinutes) min")
                    .font(.subheadline.bold().monospacedDigit())
            }

            ProgressView(value: progress)
                .tint(progress < 1 ? .orange : .green)

            Text(goalProgressText(session: session))
                .font(.caption)
                .foregroundStyle(progress < 1 ? Color.secondary : Color.green)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func goalProgressText(session: SessionManager.ActiveSession) -> String {
        if session.isPaused {
            return String(localized: "In pausa: l'obiettivo non avanza finché non riprendi l'esposizione.")
        }
        guard let remaining = manager.goalRemainingSeconds else {
            return String(localized: "Obiettivo di sessione non disponibile.")
        }
        if remaining == 0 {
            return String(localized: "Obiettivo raggiunto: valuta ombra, doposole o una pausa.")
        }
        return String(localized: "\(formattedElapsed(remaining)) al raggiungimento dell'obiettivo di oggi.")
    }

    @ViewBuilder
    private func targetRemainingLabel(session: SessionManager.ActiveSession) -> some View {
        let plannedSeconds = max(0, session.configuration.plannedDurationMinutes * 60)
        let remaining = max(0, plannedSeconds - session.elapsedSeconds)
        if session.isPaused {
            Text("In pausa")
                .bold()
                .foregroundStyle(.orange)
        } else if remaining == 0 {
            Text("raggiunto")
                .bold()
                .foregroundStyle(.green)
        } else {
            Text(formattedElapsed(remaining))
                .bold()
                .monospacedDigit()
        }
    }

    private func sideTracker(session: SessionManager.ActiveSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Distribuzione dell'abbronzatura", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)

            Picker("Lato al sole", selection: Binding(
                get: { session.currentSide },
                set: { manager.setExposureSide($0) }
            )) {
                Text("Fronte").tag(ExposureSide.front)
                Text("Retro").tag(ExposureSide.back)
            }
            .pickerStyle(.segmented)

            HStack {
                sideTime("Fronte", seconds: session.frontExposureSeconds)
                Divider()
                sideTime("Retro", seconds: session.backExposureSeconds)
            }

            Text(sideBalanceHint(session: session))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func sideTime(_ title: LocalizedStringKey, seconds: Int) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formattedElapsed(seconds))
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity)
    }

    private func sideBalanceHint(session: SessionManager.ActiveSession) -> String {
        let difference = abs(session.frontExposureSeconds - session.backExposureSeconds)
        if session.elapsedSeconds < 60 {
            return String(localized: "Parti da un lato e cambia quando arriva il promemoria.")
        }
        if difference >= 10 * 60 {
            return String(localized: "Un lato sta prendendo molto più sole: girati per ottenere un'abbronzatura più uniforme.")
        }
        if difference >= 5 * 60 {
            return String(localized: "Quasi equilibrato: il prossimo cambio aiuta a pareggiare fronte e retro.")
        }
        return String(localized: "Buon equilibrio tra fronte e retro.")
    }

    private func goalTitle(_ goal: SunExposureGoal) -> LocalizedStringKey {
        switch goal {
        case .vitaminD: return "Vitamina D"
        case .gradualTan: return "Abbronzatura graduale"
        case .lowRisk: return "Sessione leggera"
        }
    }

    private func doseRing(session: SessionManager.ActiveSession) -> some View {
        let limit = SafeExposure.recommendedDoseLimit(phototype: session.phototype)
        let fraction = min(session.effectiveDose / limit, 1)
        let warningFractionOfLimit = 0.8
        return Gauge(value: fraction) {
            Text("Dose UV")
        } currentValueLabel: {
            VStack {
                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .font(.title.bold())
                Text("della soglia UV")
                    .font(.caption2)
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(fraction < 0.5 ? .green : (fraction < warningFractionOfLimit ? .yellow : .red))
        .scaleEffect(2.2)
        .frame(width: 180, height: 180)
        .padding(.top, 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dose UV rispetto alla soglia prudente")
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }

    @ViewBuilder
    private var remainingLabel: some View {
        if let remaining = manager.remainingSafeSeconds {
            if manager.sunscreenNeedsReapplication {
                Text("Riapplica SPF o vai all'ombra")
                    .bold()
                    .foregroundStyle(.red)
            } else if remaining <= 0 {
                Text("Soglia raggiunta — mettiti all'ombra")
                    .bold()
                    .foregroundStyle(.red)
            } else if remaining.isInfinite {
                Text("UV trascurabile")
            } else {
                Text(formattedElapsed(Int(remaining)))
                    .bold()
                    .monospacedDigit()
            }
        } else if manager.active?.isPaused == true {
            Text("In pausa")
                .bold()
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private var warnings: some View {
        VStack(spacing: 8) {
            if let warning = manager.uvRefreshWarning {
                warningLabel(
                    String(localized: "Aggiornamento UV non riuscito (uso l'ultimo valore noto): \(warning)")
                )
            }
            if let warning = manager.reminderWarning {
                warningLabel(warning)
            }
            if let warning = manager.liveActivityWarning {
                warningLabel(warning)
            }
        }
    }

    private func warningLabel(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func pauseButton(session: SessionManager.ActiveSession) -> some View {
        let title: LocalizedStringKey = session.isPaused
            ? "Riprendi esposizione"
            : "Pausa all'ombra"
        Button {
            if session.isPaused {
                Task { await manager.resume() }
            } else {
                manager.pause()
            }
        } label: {
            Label(
                title,
                systemImage: session.isPaused ? "play.circle.fill" : "pause.circle.fill"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    @ViewBuilder
    private func reapplyButton(session: SessionManager.ActiveSession) -> some View {
        if session.configuration.spf > 1 {
            Button {
                Task { await manager.reapplySunscreen() }
            } label: {
                Label("Ho riapplicato la crema", systemImage: "checkmark.shield")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
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

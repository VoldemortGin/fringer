import SwiftUI

struct TriggerSettingsView: View {
    let appState: AppState
    @State private var showingNewTrigger = false
    @State private var selectedTriggerType: TriggerType = .battery
    @State private var editingTrigger: Trigger?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Triggers")
                    .font(.headline)
                Spacer()
                Menu {
                    ForEach(TriggerType.allCases) { type in
                        Button {
                            selectedTriggerType = type
                            showingNewTrigger = true
                        } label: {
                            Label(type.displayName, systemImage: type.systemImage)
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }

            if appState.triggerManager.triggers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bolt.circle")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No triggers configured")
                        .foregroundStyle(.secondary)
                    Text("Triggers automatically activate presets based on conditions like battery level, Wi-Fi, time, or app launches.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(appState.triggerManager.triggers) { trigger in
                        TriggerRow(trigger: trigger, appState: appState) {
                            editingTrigger = trigger
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingNewTrigger) {
            TriggerEditorView(
                appState: appState,
                trigger: Trigger(name: "\(selectedTriggerType.displayName) Trigger", type: selectedTriggerType),
                isNew: true
            )
        }
        .sheet(item: $editingTrigger) { trigger in
            TriggerEditorView(
                appState: appState,
                trigger: trigger,
                isNew: false
            )
        }
    }
}

struct TriggerRow: View {
    let trigger: Trigger
    let appState: AppState
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Image(systemName: trigger.type.systemImage)
                .frame(width: 24)
                .foregroundStyle(trigger.isEnabled ? .primary : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(trigger.name)
                    .font(.body)
                Text(triggerDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { trigger.isEnabled },
                set: { _ in appState.triggerManager.toggleTrigger(trigger) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
            }
            .controlSize(.small)

            Button(role: .destructive) {
                appState.triggerManager.deleteTrigger(trigger)
            } label: {
                Image(systemName: "trash")
            }
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private var triggerDescription: String {
        switch trigger.type {
        case .battery:
            return trigger.batteryCondition?.rawValue ?? "Battery"
        case .wifi:
            if trigger.wifiCondition == .specificNetwork, let name = trigger.wifiNetworkName {
                return "Network: \(name)"
            }
            return trigger.wifiCondition?.rawValue ?? "Wi-Fi"
        case .time:
            if let h = trigger.timeHour, let m = trigger.timeMinute {
                return String(format: "%02d:%02d", h, m)
            }
            return "Time"
        case .appLaunch:
            return trigger.appName ?? trigger.appBundleIdentifier ?? "App Launch"
        }
    }
}

struct TriggerEditorView: View {
    let appState: AppState
    @State var trigger: Trigger
    let isNew: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(isNew ? "New \(trigger.type.displayName) Trigger" : "Edit Trigger")
                .font(.headline)

            TextField("Trigger name", text: $trigger.name)
                .textFieldStyle(.roundedBorder)

            switch trigger.type {
            case .battery:
                batteryOptions
            case .wifi:
                wifiOptions
            case .time:
                timeOptions
            case .appLaunch:
                appLaunchOptions
            }

            Picker("Activate Preset", selection: $trigger.presetID) {
                Text("None").tag(nil as UUID?)
                ForEach(appState.presetManager.presets) { preset in
                    Text(preset.name).tag(preset.id as UUID?)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isNew ? "Add" : "Save") {
                    if isNew {
                        appState.triggerManager.addTrigger(trigger)
                    } else {
                        appState.triggerManager.updateTrigger(trigger)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trigger.name.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 380)
    }

    @ViewBuilder
    private var batteryOptions: some View {
        Picker("Condition", selection: Binding(
            get: { trigger.batteryCondition ?? .onBattery },
            set: { trigger.batteryCondition = $0 }
        )) {
            ForEach(BatteryCondition.allCases, id: \.self) { condition in
                Text(condition.rawValue).tag(condition)
            }
        }

        if trigger.batteryCondition == .belowPercent {
            HStack {
                Text("Threshold")
                Slider(
                    value: Binding(
                        get: { Double(trigger.batteryThreshold ?? 20) },
                        set: { trigger.batteryThreshold = Int($0) }
                    ),
                    in: 5...95,
                    step: 5
                )
                Text("\(trigger.batteryThreshold ?? 20)%")
                    .frame(width: 40)
            }
        }
    }

    @ViewBuilder
    private var wifiOptions: some View {
        Picker("Condition", selection: Binding(
            get: { trigger.wifiCondition ?? .connected },
            set: { trigger.wifiCondition = $0 }
        )) {
            ForEach(WiFiCondition.allCases, id: \.self) { condition in
                Text(condition.rawValue).tag(condition)
            }
        }

        if trigger.wifiCondition == .specificNetwork {
            TextField("Network name (SSID)", text: Binding(
                get: { trigger.wifiNetworkName ?? "" },
                set: { trigger.wifiNetworkName = $0 }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder
    private var timeOptions: some View {
        HStack {
            Picker("Hour", selection: Binding(
                get: { trigger.timeHour ?? 9 },
                set: { trigger.timeHour = $0 }
            )) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            .frame(width: 80)

            Text(":")

            Picker("Minute", selection: Binding(
                get: { trigger.timeMinute ?? 0 },
                set: { trigger.timeMinute = $0 }
            )) {
                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .frame(width: 80)
        }

        HStack(spacing: 4) {
            ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated().map { ($0.offset + 1, $0.element) }), id: \.0) { day, label in
                Toggle(label, isOn: Binding(
                    get: { trigger.timeDays?.contains(day) ?? false },
                    set: { isOn in
                        if trigger.timeDays == nil { trigger.timeDays = [] }
                        if isOn { trigger.timeDays?.insert(day) } else { trigger.timeDays?.remove(day) }
                    }
                ))
                .toggleStyle(.button)
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var appLaunchOptions: some View {
        TextField("App name", text: Binding(
            get: { trigger.appName ?? "" },
            set: { trigger.appName = $0 }
        ))
        .textFieldStyle(.roundedBorder)

        TextField("Bundle identifier (e.g. us.zoom.xos)", text: Binding(
            get: { trigger.appBundleIdentifier ?? "" },
            set: { trigger.appBundleIdentifier = $0 }
        ))
        .textFieldStyle(.roundedBorder)
    }
}

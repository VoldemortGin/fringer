import Foundation

@Observable
final class PresetManager {
    private(set) var presets: [Preset] = []
    private(set) var activePresetID: UUID?

    private let presetsKey = "savedPresets"
    private let activePresetKey = "activePresetID"

    init() {
        loadPresets()
    }

    var activePreset: Preset? {
        guard let id = activePresetID else { return nil }
        return presets.first(where: { $0.id == id })
    }

    func createPreset(name: String, from settingsManager: SettingsManager) -> Preset {
        let arrangement = settingsManager.loadArrangement() ?? ArrangementState(items: [])
        var sectionMap: [String: MenuBarSection] = [:]
        for item in arrangement.items {
            sectionMap[item.ownerName] = item.section
        }
        let preset = Preset(name: name, arrangements: sectionMap)
        presets.append(preset)
        savePresets()
        return preset
    }

    func activatePreset(_ preset: Preset, settingsManager: SettingsManager) {
        activePresetID = preset.id
        UserDefaults.standard.set(preset.id.uuidString, forKey: activePresetKey)

        // Apply preset arrangements
        for (ownerName, section) in preset.arrangements {
            settingsManager.setSection(section, for: ownerName)
        }
    }

    func deletePreset(_ preset: Preset) {
        presets.removeAll(where: { $0.id == preset.id })
        if activePresetID == preset.id {
            activePresetID = nil
            UserDefaults.standard.removeObject(forKey: activePresetKey)
        }
        savePresets()
    }

    func updatePreset(_ preset: Preset, name: String) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[index].name = name
        savePresets()
    }

    private func savePresets() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: presetsKey)
    }

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: presetsKey),
              let decoded = try? JSONDecoder().decode([Preset].self, from: data) else { return }
        presets = decoded

        if let idString = UserDefaults.standard.string(forKey: activePresetKey),
           let id = UUID(uuidString: idString) {
            activePresetID = id
        }
    }
}

import XCTest
@testable import Fringer

final class ItemArrangementTests: XCTestCase {

    func testMenuBarSectionRoundTrip() throws {
        for section in MenuBarSection.allCases {
            let data = try JSONEncoder().encode(section)
            let decoded = try JSONDecoder().decode(MenuBarSection.self, from: data)
            XCTAssertEqual(decoded, section)
        }
    }

    func testItemArrangementCodable() throws {
        let arrangement = ItemArrangement(
            ownerName: "TestApp",
            bundleIdentifier: "com.test.app",
            section: .hidden,
            sortOrder: 3
        )
        let data = try JSONEncoder().encode(arrangement)
        let decoded = try JSONDecoder().decode(ItemArrangement.self, from: data)
        XCTAssertEqual(decoded.ownerName, "TestApp")
        XCTAssertEqual(decoded.bundleIdentifier, "com.test.app")
        XCTAssertEqual(decoded.section, .hidden)
        XCTAssertEqual(decoded.sortOrder, 3)
    }

    func testItemArrangementID() {
        let a = ItemArrangement(ownerName: "App", bundleIdentifier: "com.app", section: .visible, sortOrder: 0)
        let b = ItemArrangement(ownerName: "App", bundleIdentifier: "com.app", section: .hidden, sortOrder: 1)
        XCTAssertEqual(a.id, b.id)

        let c = ItemArrangement(ownerName: "App", bundleIdentifier: nil, section: .visible, sortOrder: 0)
        XCTAssertNotEqual(a.id, c.id)
    }

    func testArrangementStateCodable() throws {
        let state = ArrangementState(items: [
            ItemArrangement(ownerName: "A", bundleIdentifier: nil, section: .visible, sortOrder: 0),
            ItemArrangement(ownerName: "B", bundleIdentifier: "com.b", section: .hidden, sortOrder: 1),
            ItemArrangement(ownerName: "C", bundleIdentifier: nil, section: .alwaysHidden, sortOrder: 2),
        ])
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(ArrangementState.self, from: data)
        XCTAssertEqual(decoded.items.count, 3)
        XCTAssertEqual(decoded.version, 1)
        XCTAssertEqual(decoded.items[1].section, .hidden)
    }
}

final class PresetTests: XCTestCase {

    func testPresetInit() {
        let preset = Preset(name: "Focus Mode")
        XCTAssertEqual(preset.name, "Focus Mode")
        XCTAssertTrue(preset.arrangements.isEmpty)
        XCTAssertFalse(preset.isDefault)
    }

    func testPresetCodable() throws {
        let preset = Preset(
            name: "Meeting",
            arrangements: ["Slack": .hidden, "Mail": .visible],
            isDefault: true
        )
        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(Preset.self, from: data)
        XCTAssertEqual(decoded.name, "Meeting")
        XCTAssertEqual(decoded.arrangements["Slack"], .hidden)
        XCTAssertEqual(decoded.arrangements["Mail"], .visible)
        XCTAssertTrue(decoded.isDefault)
        XCTAssertEqual(decoded.id, preset.id)
    }

    func testPresetHashable() {
        let a = Preset(name: "A")
        let b = Preset(name: "B")
        let set: Set<Preset> = [a, b, a]
        XCTAssertEqual(set.count, 2)
    }
}

final class TriggerTests: XCTestCase {

    func testBatteryTriggerDefaults() {
        let trigger = Trigger(name: "Low Battery", type: .battery)
        XCTAssertEqual(trigger.batteryCondition, .onBattery)
        XCTAssertTrue(trigger.isEnabled)
        XCTAssertNil(trigger.wifiCondition)
    }

    func testWiFiTriggerDefaults() {
        let trigger = Trigger(name: "At Office", type: .wifi)
        XCTAssertEqual(trigger.wifiCondition, .connected)
        XCTAssertNil(trigger.batteryCondition)
    }

    func testTimeTriggerDefaults() {
        let trigger = Trigger(name: "Morning", type: .time)
        XCTAssertEqual(trigger.timeHour, 9)
        XCTAssertEqual(trigger.timeMinute, 0)
        XCTAssertEqual(trigger.timeDays, Set(1...7))
    }

    func testAppLaunchTriggerDefaults() {
        let trigger = Trigger(name: "Zoom", type: .appLaunch)
        XCTAssertNil(trigger.appBundleIdentifier)
    }

    func testTriggerCodable() throws {
        var trigger = Trigger(name: "Test", type: .battery)
        trigger.batteryCondition = .belowPercent
        trigger.batteryThreshold = 20
        trigger.isEnabled = false

        let data = try JSONEncoder().encode(trigger)
        let decoded = try JSONDecoder().decode(Trigger.self, from: data)
        XCTAssertEqual(decoded.name, "Test")
        XCTAssertEqual(decoded.type, .battery)
        XCTAssertEqual(decoded.batteryCondition, .belowPercent)
        XCTAssertEqual(decoded.batteryThreshold, 20)
        XCTAssertFalse(decoded.isEnabled)
    }

    func testTriggerTypeProperties() {
        XCTAssertEqual(TriggerType.battery.displayName, "Battery")
        XCTAssertEqual(TriggerType.wifi.systemImage, "wifi")
        XCTAssertEqual(TriggerType.time.id, "time")
        XCTAssertEqual(TriggerType.allCases.count, 4)
    }
}

final class SettingsManagerTests: XCTestCase {

    private let testSuiteName = "com.fringer.tests.\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: testSuiteName)!
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        super.tearDown()
    }

    func testGetSectionDefaultsToVisible() {
        let manager = SettingsManager()
        XCTAssertEqual(manager.getSection(for: "NonExistentApp"), .visible)
    }

    func testSetAndGetSection() {
        let manager = SettingsManager()
        manager.setSection(.hidden, for: "TestApp")
        XCTAssertEqual(manager.getSection(for: "TestApp"), .hidden)

        manager.setSection(.alwaysHidden, for: "TestApp")
        XCTAssertEqual(manager.getSection(for: "TestApp"), .alwaysHidden)
    }

    func testSaveAndLoadArrangement() {
        let manager = SettingsManager()
        let state = ArrangementState(items: [
            ItemArrangement(ownerName: "App1", bundleIdentifier: nil, section: .visible, sortOrder: 0),
            ItemArrangement(ownerName: "App2", bundleIdentifier: nil, section: .hidden, sortOrder: 1),
        ])
        manager.saveArrangement(state)
        let loaded = manager.loadArrangement()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.items.count, 2)
    }
}

final class IconSpacingTests: XCTestCase {

    func testAllCases() {
        XCTAssertEqual(IconSpacing.allCases.count, 3)
    }

    func testCodable() throws {
        for spacing in IconSpacing.allCases {
            let data = try JSONEncoder().encode(spacing)
            let decoded = try JSONDecoder().decode(IconSpacing.self, from: data)
            XCTAssertEqual(decoded, spacing)
        }
    }
}

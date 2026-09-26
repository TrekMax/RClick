import Foundation
import SwiftData
import Testing
@testable import RClick

@MainActor
struct RCActionDefaultsTests {
    @Test func legacyActionsGainCutAndPasteWithoutLosingPreferences() throws {
        let container = try ModelContainer(
            for: AppEntity.self, ActionEntity.self, NewFileTypeEntity.self, CommonDirEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = ConfigService(modelContext: container.mainContext)
        let legacy = [
            RCAction(id: "delete-direct", name: "Delete Direct", enabled: false, idx: 0, icon: "trash"),
            RCAction(id: "copy-path", name: "Copy Path", idx: 1, icon: "doc.on.doc")
        ]
        try service.save(AppConfigData(actions: legacy))

        for _ in 0..<2 {
            let loaded = service.load()
            #expect(Array(loaded.actions.prefix(2).map(\.id)) == ["delete-direct", "copy-path"])
            #expect(loaded.actions.first?.enabled == false)
            #expect(loaded.actions.filter { $0.id == "cut" }.count == 1)
            #expect(loaded.actions.filter { $0.id == "paste" }.count == 1)
            #expect(Set(loaded.actions.map(\.idx)).count == loaded.actions.count)
            try service.save(loaded)
        }
    }

    @Test func freshStoreIncludesCutAndPaste() {
        let ids = ActionEntity.createDefaultActions().map(\.id)
        #expect(ids.contains("cut"))
        #expect(ids.contains("paste"))
        #expect(RCAction.all.contains { $0.id == "cut" })
        #expect(RCAction.all.contains { $0.id == "paste" })
    }
}

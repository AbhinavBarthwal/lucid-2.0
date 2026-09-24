//
//  AppBlockingViewModel.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import SwiftUI
import Combine
import FamilyControls
import ManagedSettings

@Observable
public final class AppBlockingViewModel {
    public var blocks: [ScheduledBlock] = []
    public var primarySelection: FamilyActivitySelection = FamilyActivitySelection()
    public var lastUpdated: Date = Date()

    public var showPopup: Bool = false
    public var showAppPicker: Bool = false
    public var isAuthorized: Bool = false
    public var errorMessage: String?
    public var isEditing: Bool = false

    // MARK: - Draft State for Popup Sheet
    public var draftId: UUID = UUID()
    public var draftName: String = "Focus Time"
    public var isRenaming: Bool = false

    public var draftFromDate: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date() {
        didSet {
            // End time cannot precede or equal start time
            if draftToDate <= draftFromDate {
                draftToDate = draftFromDate.addingTimeInterval(45 * 60)
            }
        }
    }

    public var draftToDate: Date = Calendar.current.date(bySettingHour: 18, minute: 45, second: 0, of: Date()) ?? Date() {
        didSet {
            // End time cannot precede or equal start time
            if draftToDate <= draftFromDate {
                draftToDate = draftFromDate.addingTimeInterval(30 * 60)
            }
        }
    }

    public var draftDays: Set<Weekday> = [.mon, .tue, .wed, .thu, .fri]
    public var draftHardMode: Bool = false
    public var draftSelection: FamilyActivitySelection = FamilyActivitySelection() {
        didSet {
            lastUpdated = Date()
        }
    }

    // Expanded states for pickers
    public var showFromTimePicker: Bool = false
    public var showToTimePicker: Bool = false

    private let repository = BlockRepository.shared
    private let service = ScreenTimeService.shared

    public init() {
        loadBlocks()
        checkAuthorization()
    }

    // MARK: - Authorization

    public func checkAuthorization() {
        self.isAuthorized = service.isAuthorized
    }

    public func requestAuthorization() async {
        do {
            try await service.requestAuthorization()
            await MainActor.run {
                self.isAuthorized = self.service.isAuthorized
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Screen Time access was not granted: \(error.localizedDescription)"
                print("[AppBlockingViewModel] Auth failed: \(error)")
            }
        }
    }

    // MARK: - Data Loading

    public func loadBlocks() {
        self.blocks = repository.fetchAllBlocks()
        if let firstId = self.blocks.first?.id {
            self.primarySelection = repository.fetchSelection(for: firstId) ?? FamilyActivitySelection()
        } else {
            self.primarySelection = FamilyActivitySelection()
        }
        self.lastUpdated = Date()
    }

    // MARK: - Modal Triggers

    public func openNewBlock() {
        self.draftId = UUID()
        self.draftName = "Focus Time"
        self.isRenaming = false
        self.isEditing = false

        let calendar = Calendar.current
        let from = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        let to = calendar.date(bySettingHour: 18, minute: 45, second: 0, of: Date()) ?? Date()
        self.draftFromDate = from
        self.draftToDate = to
        self.draftDays = [.mon, .tue, .wed, .thu, .fri]
        self.draftHardMode = false
        self.draftSelection = FamilyActivitySelection()
        self.showFromTimePicker = false
        self.showToTimePicker = false
        self.showPopup = true

        Task {
            if !isAuthorized {
                await requestAuthorization()
            }
        }
    }

    public func openEditBlock(_ block: ScheduledBlock) {
        self.draftId = block.id
        self.draftName = block.name
        self.isRenaming = false
        self.isEditing = true

        let calendar = Calendar.current
        var from = calendar.date(bySettingHour: block.fromHour, minute: block.fromMinute, second: 0, of: Date()) ?? Date()
        var to = calendar.date(bySettingHour: block.toHour, minute: block.toMinute, second: 0, of: Date()) ?? Date()
        if to <= from {
            to = from.addingTimeInterval(45 * 60)
        }
        self.draftFromDate = from
        self.draftToDate = to
        self.draftDays = block.days
        self.draftHardMode = block.hardMode

        if let selection = repository.fetchSelection(for: block.id) {
            self.draftSelection = selection
        } else {
            self.draftSelection = FamilyActivitySelection()
        }

        self.lastUpdated = Date()
        self.showFromTimePicker = false
        self.showToTimePicker = false
        self.showPopup = true

        Task {
            if !isAuthorized {
                await requestAuthorization()
            }
        }
    }

    // MARK: - Day Selection

    public func toggleDay(_ day: Weekday) {
        if draftDays.contains(day) {
            draftDays.remove(day)
        } else {
            draftDays.insert(day)
        }
    }

    public var selectedDaysSummary: String {
        if draftDays.count == 7 {
            return "Everyday"
        } else if draftDays == [.mon, .tue, .wed, .thu, .fri] {
            return "Weekdays"
        } else if draftDays == [.sun, .sat] {
            return "Weekends"
        } else if draftDays.isEmpty {
            return "Never"
        } else {
            return "Custom"
        }
    }

    // MARK: - Time Formatting

    public var draftFromFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: draftFromDate)
    }

    public var draftToFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: draftToDate)
    }

    // MARK: - App & Category Counts and Display Items

    /// Total count of categories selected (union of all four sets to handle simulator quirks)
    public static func rawCategoryCount(from selection: FamilyActivitySelection) -> Int {
        var tokens = Set(selection.categoryTokens)
        tokens.formUnion(Set(selection.categories.compactMap { $0.token }))
        let tokenCount = tokens.count
        // Fallback: if no tokens resolved but objects are present (simulator), count objects
        return tokenCount > 0 ? tokenCount : selection.categories.count
    }

    /// Total count of apps selected (union of all four sets to handle simulator quirks)
    public static func rawAppCount(from selection: FamilyActivitySelection) -> Int {
        var tokens = Set(selection.applicationTokens)
        tokens.formUnion(Set(selection.applications.compactMap { $0.token }))
        let tokenCount = tokens.count
        // Fallback: if no tokens resolved but objects are present (simulator), count objects
        return tokenCount > 0 ? tokenCount : selection.applications.count
    }

    public static func extractCategoryItems(from selection: FamilyActivitySelection) -> [BlockCategoryDisplayItem] {
        var items: [BlockCategoryDisplayItem] = []
        var seenKeys = Set<String>()

        // 1. From categories (Set<ActivityCategory>) - real device AND simulator objects
        for cat in selection.categories {
            let name = cat.localizedDisplayName ?? "Category"
            let tokenKey = cat.token.map { "\($0)" } ?? name
            if !seenKeys.contains(tokenKey) {
                seenKeys.insert(tokenKey)
                items.append(BlockCategoryDisplayItem(name: name, token: cat.token))
            }
        }

        // 2. From categoryTokens (Set<ActivityCategoryToken>) - real device
        for token in selection.categoryTokens {
            let key = "\(token)"
            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                items.append(BlockCategoryDisplayItem(name: "Category", token: token))
            }
        }

        // 3. Simulator fallback: if the picker returned nothing extractable but count > 0,
        //    generate synthetic placeholder items so the UI reflects the selection
        let rawCount = rawCategoryCount(from: selection)
        if items.isEmpty && rawCount > 0 {
            for i in 0..<rawCount {
                items.append(BlockCategoryDisplayItem(name: "Category \(i + 1)"))
            }
        }

        return items
    }

    public static func extractAppItems(from selection: FamilyActivitySelection) -> [BlockAppDisplayItem] {
        var items: [BlockAppDisplayItem] = []
        var seenIds = Set<String>()

        // 1. From applications (Set<Application>) - real device AND simulator objects
        for app in selection.applications {
            let name = app.localizedDisplayName ?? "App"
            let key = app.bundleIdentifier ?? (app.token.map { "\($0)" } ?? name)
            if !seenIds.contains(key) {
                seenIds.insert(key)
                items.append(BlockAppDisplayItem(name: name, token: app.token, bundleId: app.bundleIdentifier))
            }
        }

        // 2. From applicationTokens (Set<ApplicationToken>) - real device
        for token in selection.applicationTokens {
            let key = "\(token)"
            if !seenIds.contains(key) {
                seenIds.insert(key)
                items.append(BlockAppDisplayItem(name: "App", token: token))
            }
        }

        // 3. Simulator fallback: generate synthetic placeholder items
        let rawCount = rawAppCount(from: selection)
        if items.isEmpty && rawCount > 0 {
            for i in 0..<rawCount {
                items.append(BlockAppDisplayItem(name: "App \(i + 1)"))
            }
        }

        return items
    }

    public var draftCategoryItems: [BlockCategoryDisplayItem] {
        Self.extractCategoryItems(from: draftSelection)
    }

    public var draftAppItems: [BlockAppDisplayItem] {
        Self.extractAppItems(from: draftSelection)
    }

    /// True if anything was selected in the picker (checks all four property sets)
    public var draftHasSelection: Bool {
        let catCount = Self.rawCategoryCount(from: draftSelection)
        let appCount = Self.rawAppCount(from: draftSelection)
        return catCount > 0 || appCount > 0
    }

    /// The total number of selected items for summary display
    public var selectedAppsCount: Int {
        Self.rawCategoryCount(from: draftSelection) + Self.rawAppCount(from: draftSelection)
    }

    public var draftSelectionSummary: String {
        let cats = Self.rawCategoryCount(from: draftSelection)
        let apps = Self.rawAppCount(from: draftSelection)
        if cats == 0 && apps == 0 {
            return "Choose"
        } else if cats > 0 && apps > 0 {
            return "\(cats) Categor\(cats == 1 ? "y" : "ies"), \(apps) App\(apps == 1 ? "" : "s")"
        } else if cats > 0 {
            return "\(cats) Categor\(cats == 1 ? "y" : "ies")"
        } else {
            return "\(apps) App\(apps == 1 ? "" : "s")"
        }
    }

    // MARK: - Commit and Delete

    public func commitDraft(dismissImmediately: Bool = true) {
        let calendar = Calendar.current
        let fromHour = calendar.component(.hour, from: draftFromDate)
        let fromMinute = calendar.component(.minute, from: draftFromDate)

        // Safety enforcement: ending time cannot precede starting time
        var effectiveToDate = draftToDate
        if effectiveToDate <= draftFromDate {
            effectiveToDate = draftFromDate.addingTimeInterval(45 * 60)
        }
        let toHour = calendar.component(.hour, from: effectiveToDate)
        let toMinute = calendar.component(.minute, from: effectiveToDate)

        let selectionData = try? PropertyListEncoder().encode(draftSelection)

        let block = ScheduledBlock(
            id: draftId,
            name: draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Focus Time" : draftName,
            fromHour: fromHour,
            fromMinute: fromMinute,
            toHour: toHour,
            toMinute: toMinute,
            days: draftDays,
            hardMode: draftHardMode,
            selectionData: selectionData,
            isEnabled: true
        )

        // Persist block and selection
        repository.saveBlock(block)
        repository.saveSelection(draftSelection, for: block.id)

        // Schedule monitoring via DeviceActivity
        service.scheduleBlock(block, selection: draftSelection)

        // Update stored reactive state immediately
        self.primarySelection = draftSelection
        loadBlocks()

        if dismissImmediately {
            showPopup = false
        }
    }

    public func canDeleteBlock(_ block: ScheduledBlock) -> Bool {
        if block.hardMode && service.isBlockActiveNow(block) {
            // Hard Mode strictly locks out mid-session unblocking/deletion
            return false
        }
        return true
    }

    public func deleteBlock(id: UUID) {
        guard let block = blocks.first(where: { $0.id == id }) else { return }
        guard canDeleteBlock(block) else {
            print("[AppBlockingViewModel] Cannot delete block during active Hard Mode session.")
            return
        }

        service.stopMonitoringBlock(id: id)
        repository.deleteBlock(id: id)
        loadBlocks()
    }

    public func isBlockActiveNow(_ block: ScheduledBlock) -> Bool {
        service.isBlockActiveNow(block)
    }

    // MARK: - Active Block and Selection Helpers

    public var primaryBlock: ScheduledBlock? {
        blocks.first
    }

    public var primaryBlockSelection: FamilyActivitySelection? {
        primarySelection
    }

    public var selectedAppTokens: [ApplicationToken] {
        Array(primarySelection.applicationTokens)
    }

    public var selectedCategoryTokens: [ActivityCategoryToken] {
        Array(primarySelection.categoryTokens)
    }

    public var primaryCategoryItems: [BlockCategoryDisplayItem] {
        Self.extractCategoryItems(from: primarySelection)
    }

    public var primaryAppItems: [BlockAppDisplayItem] {
        Self.extractAppItems(from: primarySelection)
    }

    public var primaryHasSelection: Bool {
        Self.rawCategoryCount(from: primarySelection) > 0 || Self.rawAppCount(from: primarySelection) > 0
    }

    public var primaryCategoriesSummary: String {
        let names = primaryCategoryItems.map(\.name).filter { !$0.hasPrefix("Category") && !$0.hasPrefix("App") }
        if !names.isEmpty {
            if names.count == 1 {
                return names[0]
            } else if names.count == 2 {
                return "\(names[0]) & \(names[1])"
            } else {
                return "\(names[0]), \(names[1]) +\(names.count - 2)"
            }
        }
        let totalCats = Self.rawCategoryCount(from: primarySelection)
        let totalApps = Self.rawAppCount(from: primarySelection)
        if totalCats > 0 {
            return "\(totalCats) Categor\(totalCats == 1 ? "y" : "ies")"
        } else if totalApps > 0 {
            return "\(totalApps) App\(totalApps == 1 ? "" : "s")"
        }
        return "Social & Entertainment"
    }

    public var primaryBlockCategoriesCount: Int {
        Self.rawCategoryCount(from: primarySelection)
    }

    public var primaryBlockAppsCount: Int {
        Self.rawAppCount(from: primarySelection)
    }

    public var isPrimaryBlockActive: Bool {
        guard let block = primaryBlock else { return false }
        return isBlockActiveNow(block)
    }

    public func selection(for blockId: UUID) -> FamilyActivitySelection? {
        repository.fetchSelection(for: blockId)
    }
}

// MARK: - Display Models for Selected Categories & Apps

public struct BlockCategoryDisplayItem: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let token: ActivityCategoryToken?
    public let iconSymbol: String

    public init(name: String, token: ActivityCategoryToken? = nil, iconSymbol: String? = nil) {
        self.name = name
        self.token = token
        self.iconSymbol = iconSymbol ?? BlockCategoryDisplayItem.defaultIcon(for: name)
    }

    public static func defaultIcon(for categoryName: String) -> String {
        let lower = categoryName.lowercased()
        if lower.contains("game") { return "gamecontroller.fill" }
        if lower.contains("entertain") { return "film.fill" }
        if lower.contains("social") { return "bubble.left.and.bubble.right.fill" }
        if lower.contains("creat") { return "paintpalette.fill" }
        if lower.contains("educat") { return "graduationcap.fill" }
        if lower.contains("health") || lower.contains("fit") { return "heart.fill" }
        if lower.contains("read") || lower.contains("book") || lower.contains("info") { return "book.fill" }
        if lower.contains("product") || lower.contains("finan") { return "chart.pie.fill" }
        if lower.contains("shop") || lower.contains("food") { return "cart.fill" }
        if lower.contains("travel") { return "airplane" }
        if lower.contains("util") { return "wrench.and.screwdriver.fill" }
        return "square.grid.2x2.fill"
    }
}

public struct BlockAppDisplayItem: Identifiable, Hashable {
    public var id: String { bundleId ?? name }
    public let name: String
    public let token: ApplicationToken?
    public let bundleId: String?

    public init(name: String, token: ApplicationToken? = nil, bundleId: String? = nil) {
        self.name = name
        self.token = token
        self.bundleId = bundleId
    }
}

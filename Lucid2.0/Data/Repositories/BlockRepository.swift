//
//  BlockRepository.swift
//  Lucid2.0
//
//  Created by Antigravity on 20/09/26.
//

import Foundation
import FamilyControls

public final class BlockRepository: @unchecked Sendable {
    public static let shared = BlockRepository()

    public static let appGroupSuiteName = "group.com.lucid2.appgroup"
    private let blocksStorageKey = "lucid_scheduled_blocks"
    private let activeSelectionKey = "active_selection"
    private let selectionKeyPrefix = "selection_"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupSuiteName) ?? .standard
    }

    private init() {}

    // MARK: - Blocks Persistence

    public func fetchAllBlocks() -> [ScheduledBlock] {
        guard let data = defaults.data(forKey: blocksStorageKey) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([ScheduledBlock].self, from: data)
        } catch {
            print("[BlockRepository] Failed to decode blocks: \(error)")
            return []
        }
    }

    public func saveBlock(_ block: ScheduledBlock) {
        var existing = fetchAllBlocks()
        if let idx = existing.firstIndex(where: { $0.id == block.id }) {
            existing[idx] = block
        } else {
            existing.append(block)
        }
        saveAllBlocks(existing)
    }

    public func saveAllBlocks(_ blocks: [ScheduledBlock]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(blocks)
            defaults.set(data, forKey: blocksStorageKey)
        } catch {
            print("[BlockRepository] Failed to encode blocks: \(error)")
        }
    }

    public func deleteBlock(id: UUID) {
        var existing = fetchAllBlocks()
        existing.removeAll(where: { $0.id == id })
        saveAllBlocks(existing)
        deleteSelection(for: id)
        refreshActiveSelectionCache()
    }

    // MARK: - FamilyActivitySelection Persistence

    public func saveSelection(_ selection: FamilyActivitySelection, for blockId: UUID) {
        do {
            let data = try PropertyListEncoder().encode(selection)
            defaults.set(data, forKey: "\(selectionKeyPrefix)\(blockId.uuidString)")
        } catch {
            print("[BlockRepository] Failed to encode FamilyActivitySelection: \(error)")
        }
        refreshActiveSelectionCache()
    }

    /// Recomputes the `active_selection` convenience cache from whichever block is actually enabled
    /// and within its scheduled time window right now. Previously `active_selection` just mirrored
    /// whichever block was most recently saved/edited, which could point readers at the wrong
    /// block's app list whenever more than one schedule was configured.
    private func refreshActiveSelectionCache() {
        guard let activeBlock = fetchAllBlocks().first(where: isBlockActiveNow),
              let data = defaults.data(forKey: "\(selectionKeyPrefix)\(activeBlock.id.uuidString)") else {
            defaults.removeObject(forKey: activeSelectionKey)
            return
        }
        defaults.set(data, forKey: activeSelectionKey)
    }

    private func isBlockActiveNow(_ block: ScheduledBlock) -> Bool {
        guard block.isEnabled else { return false }
        let now = Date()
        let calendar = Calendar.current
        guard let currentWeekday = Weekday(rawValue: calendar.component(.weekday, from: now)),
              block.days.contains(currentWeekday) else { return false }

        let currentTotalMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let fromTotalMinutes = block.fromHour * 60 + block.fromMinute
        let toTotalMinutes = block.toHour * 60 + block.toMinute

        if fromTotalMinutes <= toTotalMinutes {
            return currentTotalMinutes >= fromTotalMinutes && currentTotalMinutes < toTotalMinutes
        } else {
            return currentTotalMinutes >= fromTotalMinutes || currentTotalMinutes < toTotalMinutes
        }
    }

    public func fetchSelection(for blockId: UUID) -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: "\(selectionKeyPrefix)\(blockId.uuidString)") else {
            return nil
        }
        do {
            return try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("[BlockRepository] Failed to decode FamilyActivitySelection: \(error)")
            return nil
        }
    }

    public func fetchActiveSelection() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: activeSelectionKey) else {
            return nil
        }
        do {
            return try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("[BlockRepository] Failed to decode active selection: \(error)")
            return nil
        }
    }

    public func deleteSelection(for blockId: UUID) {
        defaults.removeObject(forKey: "\(selectionKeyPrefix)\(blockId.uuidString)")
    }
}

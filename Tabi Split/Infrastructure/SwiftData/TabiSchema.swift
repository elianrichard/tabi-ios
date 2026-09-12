//
//  TabiSchema.swift
//  Tabi Split
//
//  Single source of truth for the SwiftData schema and for opening the one
//  on-disk container. Loading never crashes the app: a store that cannot be
//  opened (failed migration, corruption) is moved aside and recreated, because
//  the local store is a mirror of the server — Home rebuilds it on refresh.
//
//  SCHEMA RULES (docs/adr/0001-swiftdata-schema-migration.md):
//  - New stored properties must be Optional or carry a default value.
//  - Never rename / retype / drop-and-re-add a property without a migration stage.
//  - Every @Model change must open the previous release's fixture in
//    StoreMigrationTests before it ships.
//

import Foundation
import SwiftData
import os

enum TabiSchema {
    static let log = Logger(subsystem: ENV.APP_BUNDLE_ID, category: "swiftdata")

    /// Root models. Related models (Expense, ExpenseItem, ExpensePerson,
    /// AdditionalCharge, Author, SubNote) are pulled in through relationships.
    static let models: [any PersistentModel.Type] = [NoteData.self, EventData.self, UserData.self]

    static var schema: Schema { Schema(models) }

    enum LoadResult: Equatable {
        /// Existing store opened (lightweight-migrated in place if needed).
        case opened
        /// Store could not be opened; its files were moved to `Recovery/<timestamp>/`
        /// and a fresh store was created at the same URL.
        case recovered(movedTo: URL)
        /// Even a fresh on-disk store failed; running in memory for this launch.
        case inMemory
    }

    /// Opens the on-disk container at `url` (the app's default store when nil).
    /// Throws when the store exists but cannot be migrated to the current schema.
    static func makeContainer(at url: URL? = nil) throws -> ModelContainer {
        let schema = Self.schema
        return try ModelContainer(for: schema, configurations: [configuration(for: schema, at: url)])
    }

    /// Three-tier load used at launch: open → move aside + recreate → in-memory.
    static func loadOrRecover(at url: URL? = nil, fileManager: FileManager = .default) -> (ModelContainer, LoadResult) {
        let schema = Self.schema
        let onDisk = configuration(for: schema, at: url)

        do {
            return (try ModelContainer(for: schema, configurations: [onDisk]), .opened)
        } catch {
            log.error("Could not open store at \(onDisk.url.path, privacy: .public): \(String(describing: error), privacy: .public)")
        }

        let recoveryDir = moveStoreAside(at: onDisk.url, fileManager: fileManager)
        do {
            let container = try ModelContainer(for: schema, configurations: [onDisk])
            log.notice("Recreated store; previous files moved to \(recoveryDir?.path ?? "(nothing to move)", privacy: .public)")
            return (container, .recovered(movedTo: recoveryDir ?? onDisk.url.deletingLastPathComponent()))
        } catch {
            log.fault("Could not create a fresh store: \(String(describing: error), privacy: .public)")
        }

        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return (try ModelContainer(for: schema, configurations: [inMemory]), .inMemory)
        } catch {
            // Only reachable when the schema itself is invalid: a programming error,
            // caught by StoreMigrationTests.testOpensFreshStore, never a device state.
            fatalError("SwiftData schema is invalid: \(error)")
        }
    }

    /// SQLite writes the main file plus WAL/SHM side files next to it.
    static let storeFileSuffixes = ["", "-wal", "-shm"]

    /// Moves `<store>`, `<store>-wal`, `<store>-shm` into `<dir>/Recovery/<timestamp>/`
    /// (keeping the two most recent recovery folders). Returns the recovery folder,
    /// or nil when there was nothing to move or moving failed (files are then deleted
    /// so the retry starts clean).
    @discardableResult
    static func moveStoreAside(at storeURL: URL, fileManager: FileManager = .default) -> URL? {
        let existing = storeFileSuffixes
            .map { URL(fileURLWithPath: storeURL.path + $0) }
            .filter { fileManager.fileExists(atPath: $0.path) }
        guard !existing.isEmpty else { return nil }

        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let recoveryRoot = storeURL.deletingLastPathComponent().appendingPathComponent("Recovery", isDirectory: true)
        let recoveryDir = recoveryRoot.appendingPathComponent(stamp, isDirectory: true)
        do {
            try fileManager.createDirectory(at: recoveryDir, withIntermediateDirectories: true)
            for file in existing {
                try fileManager.moveItem(at: file, to: recoveryDir.appendingPathComponent(file.lastPathComponent))
            }
        } catch {
            log.error("Moving store aside failed: \(error.localizedDescription, privacy: .public)")
            for file in existing { try? fileManager.removeItem(at: file) }
            return nil
        }
        pruneRecoveryFolders(in: recoveryRoot, keep: 2, fileManager: fileManager)
        return recoveryDir
    }

    private static func configuration(for schema: Schema, at url: URL?) -> ModelConfiguration {
        if let url {
            return ModelConfiguration(schema: schema, url: url)
        }
        return ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    }

    private static func pruneRecoveryFolders(in root: URL, keep: Int, fileManager: FileManager) {
        guard let folders = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return }
        for folder in folders.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).dropFirst(keep) {
            try? fileManager.removeItem(at: folder)
        }
    }
}

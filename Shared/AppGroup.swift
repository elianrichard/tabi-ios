//
//  AppGroup.swift
//  Tabi Split + ShareExtension
//
//  Shared between the main app and the Share Extension (added to both targets).
//  Bridges the shared receipt image from the extension to the app via the App
//  Group container.
//

import UIKit

enum AppGroup {
    /// Must match the App Group id in both targets' entitlements and the portal.
    static let identifier = "group.com.sora.TabiSplit"

    /// Deep link the extension opens to hand off to the app.
    static let quickScanURL = URL(string: "tabisplit://quickscan")!

    private static let receiptFileName = "shared-receipt.jpg"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    private static var receiptFileURL: URL? {
        containerURL?.appendingPathComponent(receiptFileName)
    }

    /// Writes a shared receipt image (JPEG) into the App Group container.
    /// Returns true on success. Called by the Share Extension.
    @discardableResult
    static func saveSharedReceipt(_ image: UIImage) -> Bool {
        guard let url = receiptFileURL, let data = image.jpegData(compressionQuality: 0.9) else {
            return false
        }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Reads the shared receipt image, if any. Called by the app.
    static func loadSharedReceipt() -> UIImage? {
        guard let url = receiptFileURL, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Removes the shared receipt once consumed.
    static func clearSharedReceipt() {
        guard let url = receiptFileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static var hasSharedReceipt: Bool {
        guard let url = receiptFileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}

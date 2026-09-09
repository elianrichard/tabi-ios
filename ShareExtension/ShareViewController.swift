//
//  ShareViewController.swift
//  ShareExtension
//
//  Receives a shared image, saves it to the App Group container, then opens the
//  main app via tabisplit://quickscan. No UI — it processes and dismisses.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        handleSharedImage()
    }

    private func handleSharedImage() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) })
        else {
            complete()
            return
        }

        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] data, _ in
            let image = Self.image(from: data)
            if let image {
                AppGroup.saveSharedReceipt(image)
            }
            DispatchQueue.main.async {
                // Open the host app, then finish the extension. Completing first can
                // cancel the pending open, so open → complete in the callback.
                self?.openHostApp {
                    self?.complete()
                }
            }
        }
    }

    /// The shared item can arrive as a UIImage, a file URL, or raw Data.
    private static func image(from item: NSSecureCoding?) -> UIImage? {
        switch item {
        case let image as UIImage:
            return image
        case let url as URL:
            if let data = try? Data(contentsOf: url) { return UIImage(data: data) }
            return nil
        case let data as Data:
            return UIImage(data: data)
        default:
            return nil
        }
    }

    /// Opens the host app from the extension. Walks the responder chain and calls
    /// the correct open API for whatever it finds — UIApplication and UIScene have
    /// DIFFERENT `open` signatures (UIScene's options is an object, not a Dictionary;
    /// passing `[:]` there crashes with "universalLinksOnly unrecognized selector").
    private func openHostApp(completion: @escaping () -> Void) {
        let url = AppGroup.quickScanURL
        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url, options: [:]) { _ in completion() }
                return
            }
            if let scene = current as? UIScene, let windowScene = scene as? UIWindowScene {
                windowScene.open(url, options: nil) { _ in completion() }
                return
            }
            responder = current.next
        }
        completion()
    }

    private func complete() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

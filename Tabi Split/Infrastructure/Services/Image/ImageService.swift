//
//  ImageService.swift
//  Tabi Split
//
//  Uploads images to the backend object store (POST /upload) and resolves a
//  fresh signed URL for a stored image (GET /image/:id). The backend returns a
//  stable image `id` plus a presigned `full_path` that expires; callers persist
//  the `id` and re-resolve the URL at display time.
//

import Foundation
import UIKit

/// Mirrors the Go `model.ImageUploadResponse`.
struct ImageUploadResponse: Codable {
    let id: String
    let filename: String
    let full_path: String
    let alt: String
    let width: Int
    let height: Int
}

enum ImageServiceError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Could not process the selected image."
        }
    }
}

final class ImageService {
    static let shared = ImageService()
    private let apiClient: APIClient = APIService.shared

    /// JPEG-encodes and uploads an image, optionally into a named bucket folder
    /// (e.g. "receipt"). Returns the stored image metadata, including its id.
    func uploadImage(_ image: UIImage, folder: String? = nil) async throws -> ImageUploadResponse {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ImageServiceError.encodingFailed
        }
        var fields: [String: String] = [:]
        if let folder, !folder.isEmpty {
            fields["folder"] = folder
        }
        let response: ImageUploadResponse = try await apiClient.upload(
            endpoint: "/upload",
            fileData: data,
            fileName: "receipt.jpg",
            mimeType: "image/jpeg",
            fieldName: "image",
            fields: fields
        )
        return response
    }

    /// Resolves a fresh signed URL (and metadata) for a previously uploaded image.
    func imageDetail(id: String) async throws -> ImageUploadResponse {
        let response: ImageUploadResponse = try await apiClient.get(endpoint: "/image/\(id)")
        return response
    }

    /// Resolves a stored image id all the way to pixels: signed URL via `imageDetail`,
    /// then the bytes. Returns nil on any failure so callers (e.g. the PDF export)
    /// can skip a missing receipt instead of aborting.
    func downloadImage(id: String) async -> UIImage? {
        guard let detail = try? await imageDetail(id: id),
              let url = URL(string: detail.full_path),
              let (bytes, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: bytes)
    }
}

//
//  BackupService.swift
//  Tabi Split
//
//  Export/import SwiftData store to/from JSON file.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - DTOs

struct BackupPayload: Codable {
    var version: Int
    var exportedAt: Date
    var users: [UserDTO]
    var events: [EventDTO]
}

struct UserDTO: Codable {
    var userKey: String
    var userId: String
    var name: String
    var phone: String
    var image: String
    var imageUrl: String?
}

struct EventDTO: Codable {
    var eventId: String?
    var eventName: String
    var completionDate: Date?
    var eventIcon: String
    var userEventBalance: Float
    var createdAt: Date
    var creatorId: String
    var participantKeys: [String]
    var expenses: [ExpenseDTO]
}

struct ExpenseDTO: Codable {
    var expenseId: String?
    var name: String
    var covererKey: String
    var dateOfCreation: Date
    var price: Float
    var splitMethod: String
    var participantKeys: [String]
    var items: [ExpenseItemDTO]
    var additionalCharges: [AdditionalChargeDTO]
}

struct ExpenseItemDTO: Codable {
    var itemId: String?
    var itemName: String
    var itemPrice: Float
    var itemQuantity: Float
    var assignees: [ExpensePersonDTO]
}

struct ExpensePersonDTO: Codable {
    var userKey: String
    var share: Float
}

struct AdditionalChargeDTO: Codable {
    var additionalChargeId: String?
    var additionalChargeType: String
    var amount: Float
}

// MARK: - Service

enum BackupError: LocalizedError {
    case invalidFile
    case decodeFailed(String)
    case encodeFailed(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidFile: return "Could not access selected file."
        case .decodeFailed(let m): return "Decode failed: \(m)"
        case .encodeFailed(let m): return "Encode failed: \(m)"
        case .writeFailed(let m): return "Write failed: \(m)"
        }
    }
}

class BackupService {
    @MainActor static let shared = BackupService()

    private static let currentVersion = 1

    private func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // MARK: Export

    @MainActor
    func exportToTemporaryFile() throws -> URL {
        let payload = buildPayload()
        do {
            let data = try encoder().encode(payload)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            let stamp = formatter.string(from: Date())
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("tabi-backup-\(stamp).json")
            try data.write(to: url, options: .atomic)
            return url
        } catch let err as EncodingError {
            throw BackupError.encodeFailed(String(describing: err))
        } catch {
            throw BackupError.writeFailed(error.localizedDescription)
        }
    }

    @MainActor
    private func buildPayload() -> BackupPayload {
        let svc = SwiftDataService.shared
        let allUsers = svc.getAllUsers() ?? []
        let events = svc.fetchAllEvents() ?? []

        var keyByUser: [ObjectIdentifier: String] = [:]
        var userByKey: [String: UserData] = [:]

        func assignKey(_ u: UserData) -> String {
            let oid = ObjectIdentifier(u)
            if let existing = keyByUser[oid] { return existing }
            var base: String
            if !u.phone.isEmpty {
                base = "phone:\(u.phone)"
            } else if !u.userId.isEmpty {
                base = "uid:\(u.userId)"
            } else {
                base = "anon:\(UUID().uuidString)"
            }
            var key = base
            var n = 1
            while let other = userByKey[key], other !== u {
                n += 1
                key = "\(base)#\(n)"
            }
            keyByUser[oid] = key
            userByKey[key] = u
            return key
        }

        for u in allUsers { _ = assignKey(u) }
        for e in events {
            for p in e.participants { _ = assignKey(p) }
            for x in e.expenses {
                _ = assignKey(x.coverer)
                for p in x.participants { _ = assignKey(p) }
                for item in x.items {
                    for a in item.assignees { _ = assignKey(a.user) }
                }
            }
        }

        let userDTOs = userByKey.map { (key, u) in
            UserDTO(
                userKey: key,
                userId: u.userId,
                name: u.name,
                phone: u.phone,
                image: u.image,
                imageUrl: u.imageUrl
            )
        }

        let eventDTOs = events.map { e in
            EventDTO(
                eventId: e.eventId,
                eventName: e.eventName,
                completionDate: e.completionDate,
                eventIcon: e.eventIcon,
                userEventBalance: e.userEventBalance,
                createdAt: e.createdAt,
                creatorId: e.creatorId,
                participantKeys: e.participants.compactMap { keyByUser[ObjectIdentifier($0)] },
                expenses: e.expenses.map { expenseDTO(from: $0, keyByUser: keyByUser) }
            )
        }

        return BackupPayload(
            version: Self.currentVersion,
            exportedAt: Date(),
            users: userDTOs,
            events: eventDTOs
        )
    }

    private func expenseDTO(from x: Expense, keyByUser: [ObjectIdentifier: String]) -> ExpenseDTO {
        ExpenseDTO(
            expenseId: x.expenseId,
            name: x.name,
            covererKey: keyByUser[ObjectIdentifier(x.coverer)] ?? "",
            dateOfCreation: x.dateOfCreation,
            price: x.price,
            splitMethod: x.splitMethod,
            participantKeys: x.participants.compactMap { keyByUser[ObjectIdentifier($0)] },
            items: x.items.map { item in
                ExpenseItemDTO(
                    itemId: item.itemId,
                    itemName: item.itemName,
                    itemPrice: item.itemPrice,
                    itemQuantity: item.itemQuantity,
                    assignees: item.assignees.map {
                        ExpensePersonDTO(userKey: keyByUser[ObjectIdentifier($0.user)] ?? "", share: $0.share)
                    }
                )
            },
            additionalCharges: x.additionalCharges.map { c in
                AdditionalChargeDTO(
                    additionalChargeId: c.additionalChargeId,
                    additionalChargeType: c.additionalChargeType,
                    amount: c.amount
                )
            }
        )
    }

    // MARK: Import

    @MainActor
    func importFromFile(url: URL) throws {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BackupError.invalidFile
        }

        let payload: BackupPayload
        do {
            payload = try decoder().decode(BackupPayload.self, from: data)
        } catch {
            throw BackupError.decodeFailed(error.localizedDescription)
        }

        try apply(payload: payload)
    }

    @MainActor
    private func apply(payload: BackupPayload) throws {
        let svc = SwiftDataService.shared
        let ctx = svc.modelContext

        let currentUser = svc.getCurrentUser()
        let currentCreatorId = currentUser?.userId ?? ""

        let existingUsers = svc.getAllUsers() ?? []
        var phoneIndex: [String: UserData] = [:]
        var userIdIndex: [String: UserData] = [:]
        for u in existingUsers {
            if !u.phone.isEmpty, phoneIndex[u.phone] == nil { phoneIndex[u.phone] = u }
            if !u.userId.isEmpty, userIdIndex[u.userId] == nil { userIdIndex[u.userId] = u }
        }

        var keyToUser: [String: UserData] = [:]

        for dto in payload.users {
            let match: UserData?
            if !dto.phone.isEmpty, let u = phoneIndex[dto.phone] {
                match = u
            } else if !dto.userId.isEmpty, let u = userIdIndex[dto.userId] {
                match = u
            } else {
                match = nil
            }

            if let existing = match {
                if !dto.userId.isEmpty { existing.userId = dto.userId }
                existing.name = dto.name
                if !dto.phone.isEmpty { existing.phone = dto.phone }
                existing.image = dto.image
                existing.imageUrl = dto.imageUrl
                keyToUser[dto.userKey] = existing
            } else {
                let imageEnum = ProfileImageEnum(rawValue: dto.image)
                let user = UserData(
                    userId: dto.userId,
                    name: dto.name,
                    phone: dto.phone,
                    image: imageEnum,
                    imageUrl: dto.imageUrl
                )
                if imageEnum == nil { user.image = dto.image }
                ctx.insert(user)
                if !dto.phone.isEmpty { phoneIndex[dto.phone] = user }
                if !dto.userId.isEmpty { userIdIndex[dto.userId] = user }
                keyToUser[dto.userKey] = user
            }
        }

        let existingEvents = svc.fetchAllEvents() ?? []

        for eventDTO in payload.events {
            var participants: [UserData] = eventDTO.participantKeys.compactMap { keyToUser[$0] }
            if let cu = currentUser, !participants.contains(where: { $0 === cu }) {
                participants.append(cu)
            }

            let duplicate: EventData? = existingEvents.first { ev in
                if let id = eventDTO.eventId, let evId = ev.eventId, !id.isEmpty {
                    return id == evId
                }
                return ev.eventName == eventDTO.eventName && ev.createdAt == eventDTO.createdAt
            }
            if duplicate != nil { continue }

            let iconEnum = EventIconEnum(rawValue: eventDTO.eventIcon) ?? .icon1
            let newEvent = EventData(
                eventId: nil,
                eventName: eventDTO.eventName,
                completionDate: eventDTO.completionDate,
                eventIcon: iconEnum,
                userEventBalance: eventDTO.userEventBalance,
                participants: participants,
                expenses: [],
                createdAt: eventDTO.createdAt,
                creatorId: currentCreatorId
            )
            ctx.insert(newEvent)

            for expDTO in eventDTO.expenses {
                let coverer: UserData
                if let c = keyToUser[expDTO.covererKey] {
                    coverer = c
                } else if let cu = currentUser {
                    coverer = cu
                } else {
                    print("BackupService: expense skipped, no coverer + no current user name=\(expDTO.name)")
                    continue
                }
                let expParticipants: [UserData] = expDTO.participantKeys.compactMap { keyToUser[$0] }
                let splitMethod = SplitMethod(rawValue: expDTO.splitMethod) ?? .equally

                let charges = expDTO.additionalCharges.map { c -> AdditionalCharge in
                    let type = AdditionalChargeType(rawValue: c.additionalChargeType) ?? .other
                    return AdditionalCharge(
                        additionalChargeId: c.additionalChargeId,
                        additionalChargeType: type,
                        amount: c.amount
                    )
                }

                let items = expDTO.items.map { itemDTO -> ExpenseItem in
                    let assignees = itemDTO.assignees.compactMap { a -> ExpensePerson? in
                        guard let u = keyToUser[a.userKey] else { return nil }
                        return ExpensePerson(user: u, share: a.share)
                    }
                    return ExpenseItem(
                        itemId: itemDTO.itemId,
                        itemName: itemDTO.itemName,
                        itemPrice: itemDTO.itemPrice,
                        itemQuantity: itemDTO.itemQuantity,
                        assignees: assignees
                    )
                }

                let expense = Expense(
                    expenseId: expDTO.expenseId,
                    name: expDTO.name,
                    coverer: coverer,
                    dateOfCreation: expDTO.dateOfCreation,
                    price: expDTO.price,
                    splitMethod: splitMethod,
                    participants: expParticipants,
                    items: items,
                    additionalCharges: charges
                )
                ctx.insert(expense)
                newEvent.expenses.append(expense)
            }

            if let cu = currentUser {
                newEvent.calculateUserEventBalance(currentUser: cu)
            }
        }

        svc.saveModelContext()
    }
}

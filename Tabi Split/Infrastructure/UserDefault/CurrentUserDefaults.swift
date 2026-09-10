//
//  CurrentUserDefaults.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/11/24.
//

struct CurrentUserDefaults: Codable {
    let userName: String
    let userEmail: String
    let userImage: ProfileImageEnum.ID
    let userId: String
    /// Account type from the backend: "real", "dummy", or "guest". Drives the
    /// guest→provider merge on the next sign-in. Defaults to "real" so values
    /// persisted before this field existed decode cleanly.
    var kind: String = "real"

    var isGuest: Bool { kind == "guest" }

    /// Whether two stored users are the same account. userId is authoritative
    /// (every server-backed account, guests included, has one); email is only a
    /// fallback for legacy blobs saved before userId was stored. Two records
    /// with nothing comparable are treated as different accounts.
    static func isSameAccount(_ a: CurrentUserDefaults, _ b: CurrentUserDefaults) -> Bool {
        if !a.userId.isEmpty && !b.userId.isEmpty {
            return a.userId == b.userId
        }
        if !a.userEmail.isEmpty && !b.userEmail.isEmpty {
            return a.userEmail == b.userEmail
        }
        return false
    }

    init(userName: String, userEmail: String, userImage: ProfileImageEnum.ID, userId: String, kind: String = "real") {
        self.userName = userName
        self.userEmail = userEmail
        self.userImage = userImage
        self.userId = userId
        self.kind = kind
    }

    private enum CodingKeys: String, CodingKey {
        case userName, userEmail, userImage, userId, kind
    }

    // Custom decoding so an older stored blob without `kind` still decodes.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userName = try c.decode(String.self, forKey: .userName)
        userEmail = try c.decode(String.self, forKey: .userEmail)
        userImage = try c.decode(ProfileImageEnum.ID.self, forKey: .userImage)
        userId = try c.decode(String.self, forKey: .userId)
        kind = try c.decodeIfPresent(String.self, forKey: .kind) ?? "real"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(userName, forKey: .userName)
        try c.encode(userEmail, forKey: .userEmail)
        try c.encode(userImage, forKey: .userImage)
        try c.encode(userId, forKey: .userId)
        try c.encode(kind, forKey: .kind)
    }
}

extension UserDefaultsService {
    func saveCurrentUser (user: CurrentUserDefaults) {
        setValue(user, forKey: .currentUserDetails)
    }
    
    func getCurrentUser () -> CurrentUserDefaults? {
        return getValue(forKey: .currentUserDetails, ofType: CurrentUserDefaults.self)
    }
    
    func deleteCurrentUser () {
        deleteKeyValue(forKey: .currentUserDetails)
    }
}

//
//  AvatarStack.swift
//  Tabi Split
//

import SwiftUI

struct AvatarStack: View {
    var users: [UserData]
    var maxVisible: Int = 3
    var avatarSize: CGFloat = 40

    private var visibleUsers: [UserData] {
        Array(users.prefix(maxVisible))
    }

    private var overflow: Int {
        max(0, users.count - maxVisible)
    }

    var body: some View {
        HStack(spacing: -avatarSize * 0.15) {
            ForEach(Array(visibleUsers.enumerated()), id: \.offset) { index, user in
                UserAvatar(userData: user, size: avatarSize)
                    .zIndex(Double(maxVisible - index))
            }
            if overflow > 0 {
                Circle()
                    .fill(.uiGray)
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay {
                        Text("+\(overflow)")
                            .font(.tabiBody)
                    }
            }
        }
    }
}

#Preview {
    let users = (0..<6).map { UserData(name: "User \($0)", phone: "\($0)") }
    AvatarStack(users: users)
        .padding()
}

//
//  ElipsisMenu.swift
//  Tabi Split
//
//  Created by Elian Richard on 06/11/24.
//

import SwiftUI

struct ElipsisMenu<Content: View>: View {
    var content: Content
    var color: Color
    
    init(color: Color = .textBlack, @ViewBuilder ChildComponent: () -> Content) {
        self.content = ChildComponent()
        self.color = color
    }
    
    var body: some View {
        Menu {
            content
        } label: {
            Icon(systemName: "ellipsis", color: color, size: 20)
                .contentShape(Rectangle())
                .frame(width: 44, height: 44)
        }
        .padding(.vertical, -11)
        .padding(.horizontal, -11)
    }
}

#Preview {
    ElipsisMenu (color: .buttonBlue) {
        Button {
            print("Edit through menu")
        } label: {
            Label("Edit Expense", systemImage: "pencil")
        }
    }
}

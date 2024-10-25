//
//  InputWithLabel.swift
//  Tabi
//
//  Created by ahmad naufal alfakhar on 03/10/24.
//

import SwiftUI

struct DropDownInput<T: Identifiable & Hashable>: View {
    let label: String
    var label2: String?
    let items: [T]
    let keyPath: KeyPath<T, String>
    var isError: Bool = false
    var backgroundColor: Color = .uiWhite
    var cornerRadius: CGFloat = .infinity
    
    @Binding var selectedItem: T?
    var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.tabiBody)
            Menu {
                ForEach(items, id: \.self) { item in
                    Button(item[keyPath: keyPath], action: {
                        selectedItem = item
                    })
                    .frame(maxWidth: .infinity)
                }
            } label: {
                HStack {
                    if let selected = selectedItem {
                        Text(selected[keyPath: keyPath])
                    } else {
                        Text(label2 ?? label)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .foregroundStyle(.black)
                .font(.tabiBody)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.clear)
                        .stroke(isError ? .buttonRed : .bgGreyOverlay, lineWidth: 0.5)
                }
            }
            if let message = errorMessage {
                Text(message)
                    .font(.tabiBody)
                    .foregroundStyle(.buttonRed)
            }
        }
    }
}

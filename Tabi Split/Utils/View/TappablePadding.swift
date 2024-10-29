//
//  TappablePadding.swift
//  Tabi Split
//
//  Created by Elian Richard on 29/10/24.
//

import SwiftUI

struct TappablePadding: ViewModifier {
  let insets: EdgeInsets
  let onTap: () -> Void
    
    init(insets: EdgeInsets, onTap: @escaping () -> Void) {
        self.insets = insets
        self.onTap = onTap
    }

    init(insetValue: CGFloat, onTap: @escaping () -> Void) {
        self.insets = EdgeInsets(top: insetValue, leading: insetValue, bottom: insetValue, trailing: insetValue)
        self.onTap = onTap
    }
  
  func body(content: Content) -> some View {
    content
      .padding(insets)
      .contentShape(Rectangle())
      .onTapGesture {
        onTap()
      }
      .padding(insets.inverted)
  }
}

extension View {
  func tappablePadding(_ insets: EdgeInsets, onTap: @escaping () -> Void) -> some View {
    self.modifier(TappablePadding(insets: insets, onTap: onTap))
  }
}

extension EdgeInsets {
  var inverted: EdgeInsets {
    .init(top: -top, leading: -leading, bottom: -bottom, trailing: -trailing)
  }
}

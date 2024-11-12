//
//  SettlementOptimizationView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct SettlementOptimizationView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    
    @State private var contentSize: CGSize = .zero
    
    var body: some View {
        VStack (spacing: 0) {
            TopNavigation(title: "Optimization Details")
                .padding([.top, .horizontal])
            VStack (spacing: .spacingMedium) {
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach (eventViewModel.participantsBalance) { data in
                                OptimizationPersonCard(data: data)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                VStack (alignment: .leading) {
                    Text("Recapitulation")
                        .font(.tabiHeadline)
                    ScrollView (showsIndicators: false) {
                        VStack (spacing: .spacingMedium) {
                            ForEach (eventViewModel.participantsBalance) { data in
                                OptimizationRecapCard(recapData: data)
                            }
                        }
                        .padding(.vertical, .spacingTight)
                        .overlay(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    contentSize = geo.size
                                }
                            }
                        )
                    }
                    .padding(.horizontal, .spacingRegular)
                    .frame(maxWidth: .infinity, maxHeight: contentSize.height)
                    .overlay {
                        RoundedRectangle(cornerRadius: .radiusLarge)
                            .strokeBorder(.uiGray, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: .radiusLarge))
                    .padding(1)
                    Spacer()
                }
                .padding([.bottom, .horizontal])
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettlementOptimizationView()
        .environment(Routes())
}

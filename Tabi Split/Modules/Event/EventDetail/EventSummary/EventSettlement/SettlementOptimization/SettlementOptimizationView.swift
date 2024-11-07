//
//  SettlementOptimizationView.swift
//  Tabi Split
//
//  Created by Elian Richard on 16/10/24.
//

import SwiftUI

struct SettlementOptimizationView: View {
    @Environment(Routes.self) private var routes
    var personData: [OptimizationPersonData] = [
        OptimizationPersonData(user: UserData(name: "You", phone: "Phone"), debtAmount: 10_000, lentAmount: 50_000),
        OptimizationPersonData(user: UserData(name: "Elian", phone: "Phone"), debtAmount: 100_000, lentAmount: 50_000),
        OptimizationPersonData(user: UserData(name: "Dharma", phone: "Phone"), debtAmount: 100_000, lentAmount: 500_000)
    ]
    var recapData: [OptimizationRecapData] = [
        OptimizationRecapData(sender: UserData(name: "Dharma", phone: "Phone"), recipient: UserData(name: "You", phone: "Phone"), amount: 50_000),
        OptimizationRecapData(sender: UserData(name: "Dharma", phone: "Phone"), recipient: UserData(name: "Mario", phone: "Phone"), amount: 100_000),
        OptimizationRecapData(sender: UserData(name: "Vina", phone: "Phone"), recipient: UserData(name: "Ferry", phone: "Phone"), amount: 200_000),
        OptimizationRecapData(sender: UserData(name: "You", phone: "Phone"), recipient: UserData(name: "Ferry", phone: "Phone"), amount: 300_000),
        OptimizationRecapData(sender: UserData(name: "Dharma", phone: "Phone"), recipient: UserData(name: "You", phone: "Phone"), amount: 400_000),
        OptimizationRecapData(sender: UserData(name: "Dharma", phone: "Phone"), recipient: UserData(name: "You", phone: "Phone"), amount: 10_000),
    ]
    
    @State private var contentSize: CGSize = .zero
    
    var body: some View {
        VStack (spacing: 24) {
            TopNavigation(title: "Optimization Details")
                .padding([.top, .horizontal])
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach (personData) { data in
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
                        ForEach (recapData) { data in
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
            }
            .padding([.bottom, .horizontal])
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettlementOptimizationView()
        .environment(Routes())
}

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
        OptimizationPersonData(name: "You", debtAmount: 10_000, lentAmount: 50_000),
        OptimizationPersonData(name: "Elian", debtAmount: 100_000, lentAmount: 50_000),
        OptimizationPersonData(name: "Naufal", debtAmount: 100_000, lentAmount: 500_000)
    ]
    var recapData: [OptimizationRecapData] = [
        OptimizationRecapData(sender: "Naufal", recipient: "You", amount: 50_000),
        OptimizationRecapData(sender: "Naufal", recipient: "Mario", amount: 100_000),
        OptimizationRecapData(sender: "Vina", recipient: "Ferry", amount: 200_000),
        OptimizationRecapData(sender: "You", recipient: "Ferry", amount: 300_000),
        OptimizationRecapData(sender: "Naufal", recipient: "You", amount: 400_000),
        OptimizationRecapData(sender: "Naufal", recipient: "You", amount: 10_000),
    ]
    
    @State private var contentSize: CGSize = .zero
    
    var body: some View {
        VStack (spacing: 24) {
            ZStack {
                Text("Optimization Details")
                    .font(.title2)
                HStack {
                    Button {
                        routes.navigateBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach (personData) { data in
                            OptimizationPersonCard(data: data)
                        }
                    }
                }
            }
            VStack (alignment: .leading) {
                Text("Optimization Recapitulation")
                    .font(.title3)
                ScrollView (showsIndicators: false) {
                    VStack {
                        ForEach (recapData) { data in
                            OptimizationRecapCard(recapData: data)
                        }
                    }
                    .overlay(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                contentSize = geo.size
                            }
                        }
                    )
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: contentSize.height)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color(UIColor(hex: "#C9C9C9")), lineWidth: 1)
                }
                .padding(1)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettlementOptimizationView()
        .environment(Routes())
}

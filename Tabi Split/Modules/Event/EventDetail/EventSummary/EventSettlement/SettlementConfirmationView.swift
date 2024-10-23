//
//  SettlementConfirmationView.swift
//  Tabi Split
//
//  Created by Elian Richard on 17/10/24.
//

import SwiftUI

struct SettlementConfirmationView: View {
    @Environment(Routes.self) private var routes
    @State var status: SettlementCardTypeEnum = .WaitingPayment
    @State var imageName: UIImage? = nil
    
    var body: some View {
        VStack (spacing: 24) {
            ZStack {
                Text("Confirm Payment")
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
            VStack (alignment: .leading, spacing: 28) {
                HStack (spacing: 12) {
                    Circle()
                        .fill(.gray)
                        .frame(width: 40)
                    VStack (alignment: .leading, spacing: 4) {
                        Text("Naufal")
                            .font(.title3)
                        Text("KFC")
                            .font(.subheadline)
                    }
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.gray)
                    if status == .WaitingPayment && imageName == nil {
                        VStack (spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title)
                            Text("Upload an image")
                        }
                    } else if status == .WaitingPayment, let image = imageName {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else if status == .WaitingConfirmation{
                        Image(.samplePaymentReceipt)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    if (status == .WaitingPayment && imageName == nil) {
                        imageName = UIImage(resource: .samplePaymentReceipt)
                    } else {
                        routes.navigate(to: .SettlementReceiptView)
                    }
                }
                Button {
                    routes.mutlipleNavigate(to: [.HomeView, .EventDetailView, .EventSettlementView])
                } label: {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: .infinity))
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SettlementConfirmationView()
        .environment(Routes())
}

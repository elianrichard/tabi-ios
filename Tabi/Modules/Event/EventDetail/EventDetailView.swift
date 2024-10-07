//
//  EventDetailView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var routes: Routes
    
    let rect = CGRect(x: 0, y: 0, width: 500, height: 100)
    var body: some View {
        ZStack {
            VStack (spacing: 0) {
                Rectangle()
                    .fill(Color(UIColor(hex: "#F1F1F1")))
                    .frame(maxWidth: .infinity, maxHeight: 250)
                Circle()
                    .fill(Color(UIColor(hex: "#D9D9D9")))
                    .frame(width: 40)
                    .padding(.top, -20)
                VStack (alignment: .center, spacing: 10) {
                    Text("You are the only member in this group")
                        .padding(.top, 200)
                    Text("Invite Friend")
                        .underline(true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                Spacer(minLength: 50)
            }
            .ignoresSafeArea()
            
            VStack {
                ZStack {
                    Text("Trip Name")
                        .font(.title2)
                    HStack {
                        Button {
                            routes.navigateBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.black)
                        }
                        Spacer()
                        Menu {
                            Button("Edit Event") {
                                print("Edit Event")
                            }
                            Button("Complete Event") {
                                print("Complete Event")
                            }
                            Button("Delete Event") {
                                print("Delete Event")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .padding()
            
            VStack {
                HStack {
                    Button {
                        routes.navigate(to: .EventFormView)
                    } label: {
                        Label("Add Expenses", systemImage: "plus")
                            .padding(.vertical, 20)
                            .padding(.horizontal, 20)
                            .background(Color(UIColor(hex: "#EBEBEB")))
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 50))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(20)
            .ignoresSafeArea()
        }
    }
}

#Preview {
    EventDetailView()
}

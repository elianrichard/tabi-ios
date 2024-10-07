//
//  ExpensePage.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 03/10/24.
//

import Foundation
import SwiftUI

struct ExpenseView: View {
    @State var eventName: String = "Japan Trip"
    @State var peoples: [People] = [
        People(name: "Dharma"),
        People(name: "Mario"),
        People(name: "Renaldi"),
        People(name: "Leo"),
    ]
    @State var selectedScreen = "Expenses"
    @State var screens = ["Expenses", "Totals", "Group Info"]
    @State var expenses: [Expense] = [
        Expense(name: "Sate", coverer: "Naufal", dateOfCreation: .now, price: 100000),
        Expense(name: "Bakso", coverer: "Elian", dateOfCreation: .distantPast, price: 100000),
        Expense(name: "Micin", coverer: "Rafael Mario Omar Zhang", dateOfCreation: Date.now.addingTimeInterval(-86400), price: 100000),
        Expense(name: "Hotel", coverer: "Dharmawan Ruslan", dateOfCreation: Date.now.addingTimeInterval(-86400*2), price: 100000),
        Expense(name: "Tayo tayo tayo", coverer: "Elvina", dateOfCreation: Date.now.addingTimeInterval(-86400*3), price: 100000),
    ]
    @State var loggedUser: String = "Dharmawan Ruslan"
    @EnvironmentObject var routes: Routes
    
    var body: some View {
//        NavigationView {
            VStack{
                ZStack{
                    VStack{
                        Image(systemName: "Elipses")
                            .frame(width: UIScreen.main.bounds.width, height: 150)
                            .background(Color(.lightGray))
                        VStack{
                            Text("You Owe")
                            Text("Rp200.000")
                                .font(.title2)
                        }
                        .frame(width: UIScreen.main.bounds.width - 120, height: 80)
                        .background(Color(.midLightGray))
                        .cornerRadius(20)
                        .offset(CGSize(width: 0, height: -50))
                    }
                }
                .frame(width: UIScreen.main.bounds.width, height: 50)
                .background(
                )
                .padding([.bottom], 50)
                HStack(alignment: .top){
                    VStack(alignment: .leading){
                        HStack(alignment: .center, spacing: UIScreen.main.bounds.maxX/6){
                            ForEach(screens, id: \.self) { screen in
                                Text(screen)
                                    .onTapGesture {
                                        selectedScreen = screen
                                    }
                                    .border(width: 2, edges: [.bottom], color: selectedScreen == screen ? .black : .clear)
                            }
                        }
                        .padding([.bottom, .top], 20)
                        .frame(maxWidth: .infinity)
                        ZStack{
                            NavigationView {
                                if selectedScreen == "Expenses"{
                                    ExpenseListView(expenses: expenses, loggedUser: loggedUser)
                                } else if selectedScreen == "Totals"{
                                    EmptyView()
                                }
                            }
                            .zIndex(3)
                            ScrollView{
                                
                            }
                            Text("This event has no expenses yet")
                        }
                        HStack(alignment: .center){
                            Spacer()
                            Text("+ Add Expenses")
                                .padding([.trailing, .leading], 20)
                                .padding([.top, .bottom], 15)
                                .background(.gray)
                                .cornerRadius(100)
                                .onTapGesture {
                                    routes.navigate(to: .AddExpenseView)
                                }
                        }
                        .padding([.trailing], 20)
                        .padding([.top, .bottom], 10)
                        .frame(maxWidth: .infinity)
                    }
                    
                }
                .padding()
                .navigationTitle(eventName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Menu {
                        Button(action: {
                            // Action for "Edit"
                        }) {
                            Label("Edit Event", systemImage: "pencil")
                        }
                        Button(action: {
                            // Action for "Share"
                        }) {
                            Label("Share Event", systemImage: "square.and.arrow.up")
                        }
                        Button(action: {
                            // Action for "Delete"
                        }) {
                            Label("Delete Event", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .foregroundColor(.black)
                    }
                }
//            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ExpenseView()
}

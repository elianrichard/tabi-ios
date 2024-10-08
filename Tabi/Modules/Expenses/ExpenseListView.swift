//
//  ExpenseList.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 04/10/24.
//

import Foundation
import SwiftUI

struct ExpenseListView: View {
    @State var expenses: [Expense] = [
        Expense(name: "Sate", coverer: "Naufal", dateOfCreation: .now, price: 100000),
        Expense(name: "Bakso", coverer: "Elian", dateOfCreation: .distantPast, price: 100000),
        Expense(name: "Micin", coverer: "Rafael Mario Omar Zhang", dateOfCreation: Date.now.addingTimeInterval(-86400), price: 100000),
        Expense(name: "Hotel", coverer: "Dharmawan Ruslan", dateOfCreation: Date.now.addingTimeInterval(-86400*2), price: 100000),
        Expense(name: "Tayo tayo tayo", coverer: "Elvina", dateOfCreation: Date.now.addingTimeInterval(-86400*3), price: 100000),
    ]
    @State var loggedUser: String = "Dharmawan Ruslan"
    
    var body: some View {
        VStack(alignment: .leading){
            ScrollView{
                ForEach(expenses, id: \.id) { expense in
                    VStack{
                        HStack{
                            HStack(alignment: .center){
                                Circle()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading){
                                    Text(expense.name)
                                        .font(.title2)
                                    Text((expense.coverer == loggedUser ? "You" : expense.coverer)  + " Paid this bill")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing){
                            Text(String(expense.price))
                            if Calendar.current.isDateInToday(expense.dateOfCreation){
                                Text("Today")
                            }else if Calendar.current.isDateInYesterday(expense.dateOfCreation){
                                Text("Yesterday")
                            }else{
                                Text(expense.dateOfCreation.formatted(date: .abbreviated, time: .omitted))
                            }
                        }
                        .padding([.leading], 10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.midLightGray))
                .cornerRadius(20)
            }
        }
    }
}


#Preview {
    ExpenseListView()
}

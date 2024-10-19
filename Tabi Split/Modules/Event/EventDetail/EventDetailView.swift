//
//  EventDetailView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI

struct EventDetailView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @State private var showingCompletionAlert = false
    
    let rect = CGRect(x: 0, y: 0, width: 500, height: 100)
    var body: some View {
        ZStack {
            VStack (spacing: 0) {
                Rectangle()
                    .fill(Color(UIColor(hex: "#F1F1F1")))
                    .frame(maxWidth: .infinity, maxHeight: 200)
                HStack {
                    if let selectedEvent = eventViewModel.selectedEvent {
                        ForEach (Array(selectedEvent.participants.enumerated()), id: \.offset) { index, person in
                            if index < 4 {
                                Circle()
                                    .fill(Color(UIColor(hex: "#D9D9D9")))
                                    .frame(width: 40)
                            }
                        }
                        if selectedEvent.participants.count > 4 {
                            ZStack {
                                Circle()
                                    .fill(Color(UIColor(hex: "#D9D9D9")))
                                    .frame(width: 40)
                                Text("+\(selectedEvent.participants.count - 4)")
                            }
                        }
                    }                }
                .padding(.top, -20)
                VStack {
                    if false {
                        VStack (alignment: .center, spacing: 10) {
                            Text("You are the only member in this group")
                                .padding(.top, 200)
                            Text("Invite Friend")
                                .underline(true)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } else {
                        VStack (spacing: 40) {
                            VStack (spacing: 16) {
                                HStack (spacing: 0) {
                                    ForEach(EventSectionEnum.allCases) { section in
                                        Text("\(section.displayName)")
                                            .padding(.vertical, 10)
                                            .frame(width: 150)
                                            .background(eventViewModel.selectedSection == section ? .white : .clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 40))
                                            .onTapGesture {
                                                withAnimation {
                                                    eventViewModel.selectedSection = section
                                                }
                                            }
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 8)
                                .background(Color(UIColor(hex: "#EBEBEB")))
                                .clipShape(RoundedRectangle(cornerRadius: 40))
                                
                                VStack{
                                    if eventViewModel.selectedSection == .expenses {
                                        EventDetailExpenseView()
                                    } else {
                                        EventSummaryView()
                                    }
                                }
                                .transaction { transaction in
                                    transaction.animation = nil
                                }
                            }
                        }
                    }
                }
                .padding()
                Spacer(minLength: 80)
            }
            .ignoresSafeArea()
            
            VStack {
                ZStack {
                    Text("\(eventViewModel.selectedEvent?.eventName ?? "undefined")")
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
                                routes.navigate(to: .EventFormView)
                            }
                            if !eventViewModel.isEventCompleted {
                                Button("Complete Event") {
                                    showingCompletionAlert = true
                                }
                            }
                            Button("Delete Event") {
                                eventViewModel.handleDeleteEvent()
                                routes.navigateBack()
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.black)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .padding()
            
            VStack {
                if eventViewModel.isEventCompleted {
                    VStack {
                        Text("This event has been completed")
                            .font(.headline)
                        if let completionDate = eventViewModel.completionDate {
                            Text("on \(completionDate, style: .date)")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                } else {
                    HStack {
                        Button {
                            eventExpenseViewModel.resetViewModel()
                            routes.navigate(to: .AddExpenseView)
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
            }
            .frame(maxWidth: .infinity,
                   alignment: eventViewModel.isEventCompleted ? .center : .trailing)
            .padding(20)
            .ignoresSafeArea()
            
        }
        .navigationBarBackButtonHidden(true)
        .alert("Do you want to completed this event?",
               isPresented: $showingCompletionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes") {
                eventViewModel.completeEvent()
            }
        } message: {
            Text("You cannot undo this action")
        }
    }
}

#Preview {
    EventDetailView()
        .environment(EventViewModel())
        .environment(Routes())
        .environment(EventExpenseViewModel())
}

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
    
    var body: some View {
        ZStack {
            TopNavigation (title: eventViewModel.eventName, titleColor: .textWhite, isCircleBackButton: true, isInline: false, RightToolbar: {
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
                    Icon(systemName: "ellipsis", color: .textWhite)
                        .contentShape(Rectangle())
                        .frame(width: 44, height: 44)
                }
                .padding(.vertical, -11)
                .padding(.horizontal, -11)
            })
            
            VStack (spacing: 0) {
                EventBanner()
                EventParticipantsList()
                VStack {
                    if eventViewModel.isNoParticipants {
                        EventNoParticipants()
                    } else if (eventViewModel.selectedEvent?.expenses.count == 0) {
                        EventNoExpenses()
                    } else {
                        VStack (spacing: 40) {
                            VStack (spacing: 16) {
                                EventNavigation()
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
                } else if (!eventViewModel.isNoParticipants) {
                    HStack {
                        CustomButton(text: "Add Manually", iconResource: .receiptCheckIcon, iconSize: 26) {
                            eventExpenseViewModel.resetViewModel()
                            routes.navigate(to: .AddExpenseView)
                        }
                        CustomButton(text: "Quick Scan", iconResource: .scanIcon, iconSize: 18, customBackgroundColor: .buttonDarkBlue) {
                            print("OCR")
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
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

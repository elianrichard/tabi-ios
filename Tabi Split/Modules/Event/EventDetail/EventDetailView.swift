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
    
    @State private var isShowCompleteSheet = false
    @State private var isShowDeleteSheet = false
    
    var body: some View {
        ZStack {
            TopNavigation (title: eventViewModel.eventName, titleColor: .textWhite, isCircleBackButton: true, isInline: false, RightToolbar: {
                Menu {
                    Button {
                        routes.navigate(to: .EventFormView)
                    } label: {
                        Label("Edit Event", systemImage: "pencil")
                    }
                    if !eventViewModel.isEventCompleted {
                        Button {
                            isShowCompleteSheet = true
                        } label: {
                            Label("Complete Event", systemImage: "flag")
                        }
                    }
                    Button (role: .destructive) {
                        isShowDeleteSheet = true
                    } label: {
                        Label("Delete Event", systemImage: "trash")
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
        .sheet(isPresented: $isShowCompleteSheet) {
            VStack (alignment: .center, spacing: 0) {
                VStack (spacing: 0) {
                    Image(.eventComplete)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    VStack (spacing: .spacingSmall) {
                        Text("Do you want to complete this event?")
                            .font(.tabiSubtitle)
                            .multilineTextAlignment(.center)
                        Text("The expenses on this event can’t be edited or added anymore.")
                            .font(.tabiBody)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxHeight: .infinity)
                HStack {
                    CustomButton(text: "Cancel", type: .secondary) {
                        isShowCompleteSheet = false
                    }
                    CustomButton(text: "Complete") {
                        eventViewModel.completeEvent()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowDeleteSheet) {
            VStack (alignment: .center, spacing: 0) {
                VStack (spacing: 0) {
                    Image(.eventDelete)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                    VStack (spacing: .spacingSmall) {
                        Text("Do you want to delete this event?")
                            .font(.tabiSubtitle)
                            .multilineTextAlignment(.center)
                        Text("This event can no longer be accessed and can’t be recovered.")
                            .font(.tabiBody)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxHeight: .infinity)
                HStack {
                    CustomButton(text: "Cancel", type: .secondary) {
                        isShowDeleteSheet = false
                    }
                    CustomButton(text: "Delete", customBackgroundColor: .buttonRed) {
                        eventViewModel.handleDeleteEvent()
                        routes.navigateBack()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    EventDetailView()
        .environment(EventViewModel())
        .environment(Routes())
        .environment(EventExpenseViewModel())
}

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
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    @State private var isShowCompleteSheet = false
    @State private var isShowIncompleteSheet = false
    @State private var isShowDeleteSheet = false
    @State private var isShowQuickScanSheet = false
    @State private var sheetHeight: CGFloat = 0
    @State private var hasPreviewed: Bool = false
    @State private var toggleSeeAllParticipantsSheet: Bool = false
    
    var body: some View {
        ZStack {
            TopNavigation (title: eventViewModel.eventName, titleColor: .textWhite, isCircleBackButton: true, isInline: false, RightToolbar: {
                ElipsisMenu (color: .textWhite) {
                    Button {
                        routes.navigate(to: .EventFormView)
                    } label: {
                        Label("Edit Event", systemImage: "pencil")
                    }
                    if !eventViewModel.isEventCompleted {
                        Button {
                            isShowCompleteSheet = true
                        } label: {
                            Label("Mark as Completed", systemImage: "flag")
                        }
                    } else {
                        Button {
                            isShowIncompleteSheet = true
                        } label: {
                            Label("Mark as Incomplete", systemImage: "flag.slash")
                        }
                    }
                    Button (role: .destructive) {
                        isShowDeleteSheet = true
                    } label: {
                        Label("Delete Event", systemImage: "trash")
                    }
                }
            })
            .padding(.bottom, 36)
            
            VStack (spacing: 0) {
                EventBanner()
                EventParticipantsList(toggleSeeAllParticipants: $toggleSeeAllParticipantsSheet)
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
                                    } else if eventViewModel.selectedSection == .summary {
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
                if eventViewModel.isEventCompleted {
                    Spacer(minLength: 60)
                } else if eventViewModel.selectedSection == .expenses {
                    Spacer(minLength: 80)
                }
            }
            .ignoresSafeArea()
            
            VStack {
                if eventViewModel.isEventCompleted, let event = eventViewModel.selectedEvent, let date = event.completionDate {
                    VStack (spacing: .spacingXSmall) {
                        Text("This event has been completed on")
                            .font(.tabiHeadline)
                            .foregroundStyle(.textGrey)
                        Text("\(Date().customDateFormat("dd MMM YYYY").string(from: date))")
                            .font(.tabiBody2)
                            .foregroundStyle(.textGrey)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                } else if (!eventViewModel.isNoParticipants && eventViewModel.selectedSection == .expenses) {
                    HStack(spacing: .spacingTight){
                        CustomButton(text: "Add Manually", iconResource: .receiptCheckIcon, iconSize: 26) {
                            eventExpenseViewModel.isQuickScanned = false
                            eventExpenseViewModel.resetViewModel()
                            routes.navigate(to: .AddExpenseView)
                        }
                        CustomButton(text: "Quick Scan", iconResource: .scanIcon, iconSize: 18, customBackgroundColor: .buttonDarkBlue) {
                            eventExpenseViewModel.isQuickScanned = true
                            isShowQuickScanSheet = true
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .padding(.vertical, .spacingMedium)
            .padding(.horizontal, 20)
            .ignoresSafeArea()
            .transaction { transaction in
                transaction.animation = nil
            }
            
        }
        .onAppear {
            hasPreviewed = false
            eventViewModel.calculateOptimization(currentUser: profileViewModel.user)
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
                        Text("Mark this event as completed?")
                            .font(.tabiSubtitle)
                            .multilineTextAlignment(.center)
                        Text("You can’t add or edit the expenses on this event anymore.")
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
                        isShowCompleteSheet = false
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
        .sheet(isPresented: $isShowIncompleteSheet) {
            VStack (alignment: .center, spacing: 0) {
                VStack (spacing: 0) {
                    Image(.eventComplete)
                        .resizable()
                        .scaledToFit()
                        .saturation(0)
                        .frame(width: 200, height: 200)
                    VStack (spacing: .spacingSmall) {
                        Text("Mark this event as incomplete?")
                            .font(.tabiSubtitle)
                            .multilineTextAlignment(.center)
                        Text("The expenses on this event can be edited or added again.")
                            .font(.tabiBody)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxHeight: .infinity)
                HStack {
                    CustomButton(text: "Cancel", type: .secondary) {
                        isShowIncompleteSheet = false
                    }
                    CustomButton(text: "Yes") {
                        isShowIncompleteSheet = false
                        eventViewModel.incompleteEvent()
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
                VStack (spacing: .spacingLarge) {
                    Image(.eventDelete)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
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
                        isShowDeleteSheet = false
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
        .sheet(isPresented: $isShowQuickScanSheet){
            ReceiptUploadSheet(height: $sheetHeight, isPresented: $isShowQuickScanSheet)
                .presentationDetents([.height(sheetHeight)])
        }
        .sheet(isPresented: $toggleSeeAllParticipantsSheet){
            SeeAllParticipantSheet(isPresented: $toggleSeeAllParticipantsSheet, participantsList: eventViewModel.selectedEvent?.participants ?? [])
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: eventExpenseViewModel.uploadedReceiptImage){
            if !hasPreviewed && eventExpenseViewModel.uploadedReceiptImage != nil{
                hasPreviewed.toggle()
                routes.navigate(to: .ReceiptUploadReview)
            }
        }
    }
}

#Preview {
    EventDetailView()
        .environment(EventViewModel())
        .environment(Routes())
        .environment(EventExpenseViewModel())
        .environment(ProfileViewModel())
}

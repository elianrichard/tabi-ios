//
//  EventDetailView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI
import Lottie

struct EventDetailView: View {
    @Environment(Router.self) private var router
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    @State private var hasPreviewed: Bool = false
    @State private var quickScanSheetHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            TopNavigation (title: eventViewModel.eventName, titleColor: .textWhite, isCircleBackButton: true, isInline: false, RightToolbar: {
                if eventViewModel.isUserCreator {
                    ElipsisMenu (color: .textWhite) {
                        Button {
                            eventViewModel.isDirectInvite = false
                            router.push(.eventForm)
                        } label: {
                            Label("Edit Event", systemImage: "pencil")
                        }
                        if !eventViewModel.isEventCompleted {
                            Button {
                                router.present(.eventComplete)
                            } label: {
                                Label("Mark as Completed", systemImage: "flag")
                            }
                        } else {
                            Button {
                                router.present(.eventIncomplete)
                            } label: {
                                Label("Mark as Incomplete", systemImage: "flag.slash")
                            }
                        }
                        Button (role: .destructive) {
                            router.present(.eventDelete)
                        } label: {
                            Label("Delete Event", systemImage: "trash")
                        }
                    }
                }
            })
            
            VStack (spacing: 0) {
                EventBanner(resource: EventIconEnum(rawValue: eventViewModel.selectedEvent?.eventIcon ?? "")?.bannerResource ?? .eventBanner1)
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
                        CustomButton(text: "Add Manually", iconResource: .receiptCheckIcon, iconSize: 26, vPadding: 14) {
                            eventExpenseViewModel.isQuickScanned = false
                            eventExpenseViewModel.resetViewModel()
                            router.push(.addExpense)
                        }
                        CustomButton(text: "Quick Scan", iconResource: .scanIcon, iconSize: 18, customBackgroundColor: .buttonDarkBlue) {                            
                            eventExpenseViewModel.resetViewModel()
                            eventExpenseViewModel.isQuickScanned = true
                            router.present(.eventQuickScan)
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
            eventInviteViewModel.selectedContacts = eventViewModel.selectedEvent?.participants ?? []
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: router.sheetBinding(for: .eventComplete)) {
            VStack (alignment: .center, spacing: 0) {
                VStack (spacing: 0) {
                    LottieView(animation: .named("CompletedEvent"))
                        .looping()
                        .resizable()
                        .frame(width: 200, height: 200)
                        .scaledToFit()
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
                        router.dismissSheet()
                    }
                    CustomButton(text: "Complete") {
                        Task {
                            if await eventViewModel.completeEvent(isGuest: profileViewModel.isGuest) {
                                router.dismissSheet()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: router.sheetBinding(for: .eventIncomplete)) {
            VStack (alignment: .center, spacing: 0) {
                VStack (spacing: 0) {
                    LottieView(animation: .named("CompletedEvent"))
                        .looping()
                        .resizable()
                        .frame(width: 200, height: 200)
                        .saturation(0)
                        .scaledToFit()
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
                        router.dismissSheet()
                    }
                    CustomButton(text: "Yes") {
                        Task {
                            if await eventViewModel.incompleteEvent(isGuest: profileViewModel.isGuest) {
                                router.dismissSheet()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: router.sheetBinding(for: .eventDelete)) {
            VStack (alignment: .center, spacing: 0) {
                VStack (spacing: 0) {
                    LottieView(animation: .named("DeleteEvent"))
                        .looping()
                        .scaleEffect(1.4)
                        .frame(width: 300, height: 200)
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
                        router.dismissSheet()
                    }
                    CustomButton(text: "Delete", customBackgroundColor: .buttonRed) {
                        Task {
                            if await eventViewModel.handleDeleteEvent(isGuest: profileViewModel.isGuest) {
                                router.dismissSheet()
                                router.pop()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: router.sheetBinding(for: .eventQuickScan)){
            ReceiptUploadSheet(height: $quickScanSheetHeight, isPresented: router.sheetBinding(for: .eventQuickScan))
                .presentationDetents([.height(quickScanSheetHeight)])
        }
        .sheet(isPresented: router.sheetBinding(for: .eventAllParticipants)){
            SeeAllParticipantSheet(isPresented: router.sheetBinding(for: .eventAllParticipants), participantsList: eventViewModel.selectedEvent?.participants ?? [])
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: eventExpenseViewModel.uploadedReceiptImage){
            if !hasPreviewed && eventExpenseViewModel.uploadedReceiptImage != nil {
                hasPreviewed.toggle()
                router.push(.receiptUploadReview)
            }
        }
    }
}

#Preview {
    EventDetailView()
        .environment(EventViewModel())
        .environment(Router())
        .environment(EventExpenseViewModel())
        .environment(ProfileViewModel())
}

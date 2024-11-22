//
//  EventDetailView.swift
//  Tabi
//
//  Created by Elian Richard on 07/10/24.
//

import SwiftUI
import Lottie

enum EventSheets {
    case complete, incomplete, delete, quickScan, toggleSeeAll
}

struct EventDetailView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    
    @State var sheetViewModel = SheetViewModel<EventSheets>()
    @State private var hasPreviewed: Bool = false
    
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
                            sheetViewModel.setSheet(.complete)
                        } label: {
                            Label("Mark as Completed", systemImage: "flag")
                        }
                    } else {
                        Button {
                            sheetViewModel.setSheet(.incomplete)
                        } label: {
                            Label("Mark as Incomplete", systemImage: "flag.slash")
                        }
                    }
                    Button (role: .destructive) {
                        sheetViewModel.setSheet(.delete)
                    } label: {
                        Label("Delete Event", systemImage: "trash")
                    }
                }
            })
            .padding(.bottom, 36)
            
            VStack (spacing: 0) {
                EventBanner()
                EventParticipantsList(sheetViewModel: $sheetViewModel)
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
                            sheetViewModel.setSheet(.quickScan)
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
        .sheet(isPresented: sheetViewModel.getIsPresentedBinding(.complete)) {
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
                        sheetViewModel.clearSheet()
                    }
                    CustomButton(text: "Complete") {
                        eventViewModel.completeEvent()
                        sheetViewModel.clearSheet()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: sheetViewModel.getIsPresentedBinding(.incomplete)) {
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
                        sheetViewModel.clearSheet()
                    }
                    CustomButton(text: "Yes") {
                        eventViewModel.incompleteEvent()
                        sheetViewModel.clearSheet()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: sheetViewModel.getIsPresentedBinding(.delete)) {
            VStack (alignment: .center, spacing: 0) {
                VStack (spacing: .spacingLarge) {
                    LottieView(animation: .named("DeleteEvent"))
                        .looping()
                        .resizable()
                        .frame(width: 200, height: 200)
                        .scaledToFit()
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
                        sheetViewModel.clearSheet()
                    }
                    CustomButton(text: "Delete", customBackgroundColor: .buttonRed) {
                        sheetViewModel.clearSheet()
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
        .sheet(isPresented: sheetViewModel.getIsPresentedBinding(.quickScan)){
            ReceiptUploadSheet(height: $sheetViewModel.sheetHeight, isPresented: sheetViewModel.getIsPresentedBinding(.quickScan))
                .presentationDetents([.height(sheetViewModel.sheetHeight)])
        }
        .sheet(isPresented: sheetViewModel.getIsPresentedBinding(.toggleSeeAll)){
            SeeAllParticipantSheet(isPresented: sheetViewModel.getIsPresentedBinding(.toggleSeeAll), participantsList: eventViewModel.selectedEvent?.participants ?? [])
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

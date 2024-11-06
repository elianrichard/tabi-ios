//
//  EventInviteView.swift
//  Tabi
//
//  Created by Elian Richard on 08/10/24.
//

import SwiftUI
import Contacts
import UniformTypeIdentifiers


struct EventInviteView: View {
    @Environment(Routes.self) private var routes
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventInviteViewModel.self) private var eventInviteViewModel
    
    @State private var isLinkCopied = false
    @State private var isShowQrSheet = false
    
    var body: some View {
        VStack {
            TopNavigation(title: "Add Participants", additionalBackFunction: {
                eventInviteViewModel.searchUserText = ""
            })
            HStack (spacing: .spacingMedium) {
                EventInviteShareButtonView(text: isLinkCopied ? "Copied!" : "Copy Link",
                                           icon: isLinkCopied ? .checkIcon : .linkIcon,
                                           action: {
                    if !isLinkCopied {
                        withAnimation (nil) {
                            isLinkCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(nil)  {
                                isLinkCopied = false
                            }
                        }
                        UIPasteboard.general.setValue("https://tabieventinvitelink.com", forPasteboardType: UTType.plainText.identifier)
                    }
                })
                ShareLink(item: URL(filePath: "https://tabieventinvitelink.com")!) {
                    EventInviteShareButtonView(text: "Share Link", icon: .shareIcon)
                }
                EventInviteShareButtonView(text: "QR Code",
                                           icon: .qrIcon,
                                           action: {
                    isShowQrSheet = true
                })
            }
            VStack (spacing: .spacingTight) {
                HStack (spacing: .spacingSmall) {
                    Image(systemName: "magnifyingglass")
                    TextField("Search", text: Bindable(eventInviteViewModel).searchUserText)
                        .font(.tabiBody)
                }
                .padding(.spacingTight)
                .background(.uiWhite)
                .clipShape(RoundedRectangle(cornerRadius: .infinity))
                .overlay {
                    RoundedRectangle(cornerRadius: .infinity)
                        .fill(.clear)
                        .strokeBorder(.uiGray, lineWidth: 1)
                }
                
                ScrollView (showsIndicators: false) {
                    VStack {
                        ForEach(eventInviteViewModel.filteredContacts) { contact in
                            ForEach(contact.phoneNumbers, id: \.identifier) { number in
                                EventInviteCardView(name: "\(contact.givenName) \(contact.familyName)", number: number.value.stringValue, label: CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: number.label ?? "").capitalized)
                            }
                        }
                    }
                }
                
                CustomButton(text: "Add", isEnabled: eventInviteViewModel.selectedContacts.count > 0) {
                    eventViewModel.selectedEvent?.participants = eventInviteViewModel.selectedContacts
                    eventInviteViewModel.searchUserText = ""
                    routes.navigateBack()
                }
            }
        }
        .padding()
        .onAppear {
            if (eventInviteViewModel.allContacts.count == 0) {
                print("Fetching contacts")
                DispatchQueue.global(qos: .background).async {
                    eventInviteViewModel.fetchContacts()
                }
            }
            if let selectedEvent = eventViewModel.selectedEvent {
                eventInviteViewModel.selectedContacts = selectedEvent.participants
            }
        }
        .sheet(isPresented: $isShowQrSheet) {
            VStack (spacing: 0) {
                HStack{
                    Spacer()
                    Button {
                        isShowQrSheet = false
                    } label : {
                        Icon(systemName: "xmark", color: .textGrey, size: 12)
                            .frame(width: 32, height: 32)
                            .background(.uiGray)
                            .clipShape(Circle())
                    }
                }
                VStack (alignment: .center, spacing: .spacingSmall) {
                    Text("Show QR Code")
                        .font(.tabiTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack (alignment: .center, spacing: .spacingSmall) {
                        Image(.sampleBarcodeQr)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .background(.red)
                        Text("Let your friends scan it to participate in your event")
                            .font(.tabiHeadline)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding()
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .navigationBarBackButtonHidden(true)
    }
    
}

#Preview {
    EventInviteView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventInviteViewModel())
}

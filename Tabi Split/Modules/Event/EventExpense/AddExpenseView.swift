//
//  AddExpense.swift
//  Tabi
//
//  Created by Dharmawan Ruslan on 02/10/24.
//

import Foundation
import SwiftUI
import PhotosUI
import Combine

struct AddExpenseView: View {
    @Environment(EventViewModel.self) private var eventViewModel
    @Environment(EventExpenseViewModel.self) private var eventExpenseViewModel
    @Environment(Routes.self) private var routes
    @State var viewModel: AddExpenseViewModel?
    
    var images: [ImageResource] = [.samplePersonProfile1, .samplePersonProfile2, .samplePersonProfile3]
    
    var body: some View {
        VStack (spacing: .spacingRegular) {
            TopNavigation(title: "Add New Expenses")
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20){
                    InputWithLabel(label: "Expense Name",
                                   placeholder: "Expense Name",
                                   text: Bindable(eventExpenseViewModel).expenseName,
                                   errorMessage: viewModel?.expenseNameError,
                                   inputBackgroundColor: .bgWhite,
                                   inputCornerRadius: 16
                    )
                    DropDownInput(
                        label: "Paid by",
                        items: eventViewModel.selectedEvent?.participants ?? [],
                        keyPath: \UserData.name,
                        backgroundColor: .bgWhite,
                        cornerRadius: 16,
                        selectedItem: Bindable(eventExpenseViewModel).selectedCoverer,
                        errorMessage: viewModel?.paidByError
                    )
                    VStack(alignment: .leading, spacing: 8){
                        HStack{
                            Text("Participants")
                                .font(.tabiBody)
                            Spacer()
                        }
                        HStack(alignment: .center){
                            if eventExpenseViewModel.selectedParticipants != [] {
                                
                                HStack (spacing: -6) {
                                    ForEach(Array(eventExpenseViewModel.selectedParticipants.enumerated()), id: \.offset) { index, user in
                                        if (index < 4) {
                                            if (eventExpenseViewModel.selectedParticipants.count > 4 && index == 3) {
                                                Circle()
                                                    .fill(.uiGray)
                                                    .frame(width: 40)
                                                    .overlay {
                                                        Text("+\(eventExpenseViewModel.selectedParticipants.count - 3)")
                                                            .font(.tabiBody)
                                                    }
                                            } else {
                                                Image(images.randomElement() ?? images[0])
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 40)
                                                    .clipShape(Circle())
                                                    .zIndex(Double(4-index))
                                            }
                                        }
                                    }
                                    if (eventExpenseViewModel.selectedParticipants.count < 4) {
                                        ForEach(Array(0 ..< (4-eventExpenseViewModel.selectedParticipants.count)), id: \.self) { _ in
                                            Circle()
                                                .frame(width: 40)
                                                .opacity(0)
                                        }
                                    }
                                }
                                Spacer()
                                Button{
                                    viewModel?.toggleSeeAll.toggle()
                                }label:{
                                    HStack{
                                        Text("Edit")
                                            .font(.tabiBody)
                                            .foregroundColor(.textBlue)
                                        Icon(systemName: "chevron.right", color: .textBlue, size: 18)
                                    }
                                }
                            }else{
                                Button{
                                    viewModel?.toggleSeeAll.toggle()
                                }label:{
                                    HStack{
                                        Text("Select Participants")
                                            .font(.tabiBody)
                                            .foregroundColor(.textBlue)
                                        Spacer()
                                        Icon(systemName: "chevron.right", color: .textBlue, size: 18)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(.bgWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.black)
                        .font(.tabiBody)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.clear)
                                .stroke(viewModel?.participantsError != nil ? .buttonRed : .bgGreyOverlay, lineWidth: 0.5)
                                .padding(0.5)
                        }
                        if let message = viewModel?.participantsError {
                            Text(message)
                                .font(.tabiBody)
                                .foregroundStyle(.buttonRed)
                        }
                    } // Participants
                    DropDownInput(
                        label: "Split Bill Method",
                        placeholder: "Split by",
                        items: SplitMethod.allCases,
                        keyPath: \.splitDescription,
                        backgroundColor: .bgWhite,
                        cornerRadius: 16,
                        selectedItem: Bindable(eventExpenseViewModel).selectedMethod,
                        errorMessage: viewModel?.splitBillMethodError
                    )
                    if eventExpenseViewModel.selectedMethod ==  .equally {
                        VStack(alignment: .leading){
                            InputWithLabel(label: "Total Bill",
                                           placeholder: "0",
                                           price: Bindable( eventExpenseViewModel).expenseTotalInput,
                                           errorMessage: viewModel?.totalBillError,
                                           inputBackgroundColor: .bgWhite,
                                           inputCornerRadius: 16)
                        }
                    } // Input nominal kalau equally
                    VStack(alignment: .leading, spacing: 8){
                        HStack(spacing: 0){
                            Text("Purchase Receipt ")
                                .font(.tabiBody)
                            Text("(optional)")
                                .font(.tabiBody)
                                .foregroundColor(.textGrey)
                        }
                        CustomButton(text: viewModel?.receiptImage == nil ? "Upload Image" : viewModel?.receiptImageFromGallery?.itemIdentifier ?? "Uploaded Image", type: .secondary, icon: "square.and.arrow.up", iconSize: 20){
                            viewModel?.toggleReceiptSheet.toggle()
                        }
                        .lineLimit(1)
                        .frame(width: 180)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            CustomButton(text: "Next") {
                viewModel?.validateInput()
                if let isValid = viewModel?.isValid {
                    if (eventExpenseViewModel.selectedMethod == .custom && isValid) {
                        routes.navigate(to: .ExpenseAddItemsView)
                    } else if (eventExpenseViewModel.selectedMethod == .equally && isValid) {
                        eventExpenseViewModel.totalSpending = eventExpenseViewModel.expenseTotalInput
                        routes.navigate(to: .ExpenseResultView)
                    }
                }
            }
        }
        .onAppear{
            viewModel = AddExpenseViewModel(eventExpenseViewModel: eventExpenseViewModel)
            if eventExpenseViewModel.selectedParticipants == [] {
                eventExpenseViewModel.selectedParticipants = eventViewModel.selectedEvent?.participants ?? []
            }
        }
        .sheet(isPresented: viewModel != nil ? Bindable(viewModel!).toggleSeeAll : .constant(false)) {
            ShowAllParticipants(isPresented: viewModel != nil ? Bindable(viewModel!).toggleSeeAll : .constant(false))
                .presentationDetents(
                    [.medium, .large],
                    selection: viewModel != nil ? Bindable(viewModel!).settingsDetent : .constant(PresentationDetent.medium)
                )
        }
        .sheet(isPresented: viewModel != nil ? Bindable(viewModel!).toggleReceiptSheet : .constant(false)){
            VStack(spacing: 0){
                SheetXButton(toggle: viewModel != nil ? Bindable(viewModel!).toggleReceiptSheet : .constant(false))
                VStack(spacing: .spacingMedium){
                    Text("Upload Image")
                        .font(.tabiTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: .spacingTight){
                        PhotosPicker(selection: Bindable(viewModel!).receiptImageFromGallery, matching: .images, photoLibrary: .shared()){
                            VStack(spacing: .spacingTight){
                                Icon(systemName: "photo", color: .buttonBlue, size: 20)
                                Text("Open Library")
                                    .font(.tabiHeadline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                        }
                        .accentColor(.buttonBlue)
                        .overlay {
                            RoundedRectangle(cornerRadius: .radiusLarge)
                                .fill(.clear)
                                .stroke(.buttonBlue, lineWidth: 1.5)
                        }
                        .onChange(of: viewModel?.receiptImageFromGallery) {
                            Task{
                                if viewModel?.receiptImageFromGallery != nil {
                                    await viewModel?.getImage()
                                    viewModel?.straightenDocument(in: viewModel?.receiptImage ?? UIImage()) { image in
                                        viewModel?.receiptImage = image
                                    }
                                }
                            }
                        }
                        Button{
                            viewModel?.toggleScannerSheet.toggle()
                        }label:{
                            VStack(spacing: .spacingTight){
                                Icon(systemName: "camera.fill", color: .buttonBlue, size: 20)
                                Text("Take Photo")
                                    .font(.tabiHeadline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                        }
                        .accentColor(.buttonBlue)
                        .overlay {
                            RoundedRectangle(cornerRadius: .radiusLarge)
                                .fill(.clear)
                                .stroke(.buttonBlue, lineWidth: 1.5)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    CustomButton(text: "Upload", isEnabled: viewModel?.receiptImage != nil){
                        if (viewModel?.receiptImage != nil) {
                            do {
                                try eventExpenseViewModel.performOCROnImage(viewModel?.receiptImage ?? UIImage())
                            } catch {
                                print(error)
                            }
                            
                            eventExpenseViewModel.uploadedReceiptImage = viewModel?.receiptImage ?? UIImage()
                            viewModel?.toggleReceiptSheet.toggle()
                        }
                    }

                }
            }
            .presentationDetents([.height(viewModel?.receiptSheetHeight ?? 0)])
            .sheet(isPresented: viewModel != nil ? Bindable(viewModel!).toggleScannerSheet : .constant(false)) {
                DocumentScannerView { image in
                    viewModel?.receiptImageFromGallery = nil
                    viewModel?.receiptImage = image
                }
            }
            .navigationBarBackButtonHidden(true)
            .padding()
            .padding([.top], 10)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            viewModel?.receiptSheetHeight = geometry.size.height
                        }
                }
            )
        }
        .padding()
        .background(.bgWhite)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    AddExpenseView()
        .environment(Routes())
        .environment(EventViewModel())
        .environment(EventExpenseViewModel())
}

//
//  SwiftDataTesting.swift
//  Tabi
//
//  Created by Elian Richard on 02/10/24.
//

import SwiftUI
import SwiftData


// MODEL
struct PostListModel: Encodable ,Decodable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

@Model
class NoteData {
    var name: String
    var authors: [Author]
    var subNotes: [SubNote]
    
    init(name: String = "", authors: [Author] = [], subNotes: [SubNote] = []) {
        self.name = name
        self.authors = authors
        self.subNotes = subNotes
    }
}

@Model
class Author {
    var name: String
    var age: Int
    
    init(name: String = "", age: Int = 0) {
        self.name = name
        self.age = age
    }
}

@Model
class SubNote {
    var name: String
    var authors: [Author]
    var subNoteDescription: String
    
    init(name: String = "", authors: [Author] = [], subNoteDescription: String = "") {
        self.name = name
        self.authors = authors
        self.subNoteDescription = subNoteDescription
    }
}

// VIEW
struct SwiftDataTestingView: View {
    @Environment(Routes.self) private var routes
    @State var swiftDataTestingViewModel = SwiftDataTestingViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(swiftDataTestingViewModel.notes) { note in
                    NavigationLink {
                        SwiftDataTestingNoteDetailView(swiftDataTestingViewModel: swiftDataTestingViewModel)
                            .onAppear {
                                swiftDataTestingViewModel.textField = note.name
                                swiftDataTestingViewModel.selectedNote = note
                            }
                    } label: {
                        Text("\(note.name)")
                    }
                }
                .onDelete(perform: { offsetIndex in
                    swiftDataTestingViewModel.deleteNote(offsetIndex)
                })
                ForEach(swiftDataTestingViewModel.posts) { post in
                    NavigationLink {
                        VStack {
                            Text("\(post.title)")
                            Text("\(post.body)")
                        }
                        .padding()
                    } label: {
                        Text("\(post.title)")
                    }
                }
            }
            
            
            .toolbar {
                ToolbarItemGroup (placement: .bottomBar) {
                    Button(action: {
                        routes.navigate(to: .HomeView)
                    }) {
                        Label("Home", systemImage: "house.fill")
                    }
                    Spacer()
                    Button(action: {
                        swiftDataTestingViewModel.fetchPosts()
                    }) {
                        Text("Fetch")
                    }
                    Button(action: {
                        swiftDataTestingViewModel.createPost()
                    }) {
                        Text("Post")
                    }
                    Spacer()
                    Button(action: {
                        swiftDataTestingViewModel.addNote()
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
    }
}

struct SwiftDataTestingNoteDetailView: View {
    @Bindable var swiftDataTestingViewModel: SwiftDataTestingViewModel
    
    var body : some View {
        VStack {
            if let note = swiftDataTestingViewModel.selectedNote {
                VStack {
                    Text("Note:")
                    TextField("Note Name", text: $swiftDataTestingViewModel.textField )
                        .border(.black)
                        .multilineTextAlignment(.center)
                    CustomButton(text: "Rename Note") {
                        swiftDataTestingViewModel.updateNoteName()
                    }
                    HStack {
                        CustomButton(text: "Add Authors") {
                            swiftDataTestingViewModel.addNoteAuthors()
                        }
                        CustomButton(text: "Delete Authors") {
                            swiftDataTestingViewModel.deleteNoteAuthors()
                        }
                    }
                    Text("Authors")
                    HStack {
                        ForEach(note.authors) { author in
                            Text("\(author.name)")
                        }
                    }
                }
                .padding()
                List {
                    ForEach (note.subNotes) { subnote in
                        NavigationLink {
                            SwiftDataTestingSubNoteDetailView(swiftDataTestingViewModel: swiftDataTestingViewModel)
                                .onAppear {
                                    swiftDataTestingViewModel.subNoteTextField = subnote.name
                                    swiftDataTestingViewModel.selectedSubNote = subnote
                                }
                        } label: {
                            Text("\(subnote.name)")
                        }
                    }
                    .onDelete(perform: { offsetIndex in
                        swiftDataTestingViewModel.deleteSubNote(offsetIndex)
                    })
                }
                CustomButton(text: "Add Sub Note") {
                    swiftDataTestingViewModel.addSubNote()
                }
            }
        }
    }
}

struct SwiftDataTestingSubNoteDetailView: View {
    @Bindable var swiftDataTestingViewModel: SwiftDataTestingViewModel
    
    var body : some View {
        VStack {
            if let subnote = swiftDataTestingViewModel.selectedSubNote,
               let note = swiftDataTestingViewModel.selectedNote {
                VStack {
                    Text("Note:")
                    TextField("SubNote Name", text: $swiftDataTestingViewModel.subNoteTextField )
                        .border(.black)
                        .multilineTextAlignment(.center)
                    CustomButton(text: "Rename SubNote") {
                        swiftDataTestingViewModel.updateSubNoteName()
                    }
                    Text("Authors: ")
                    ForEach (note.authors) { author in
                        HStack {
                            CustomButton(text: "Add \(author.name)") {
                                swiftDataTestingViewModel.addSubNoteAuthor(author: author)
                            }
                            CustomButton(text: "Delete \(author.name)") {
                                swiftDataTestingViewModel.deleteSubNoteAuthor(author: author)
                            }
                        }
                    }
                    HStack {
                        ForEach(subnote.authors) { author in
                            Text("\(author.name)")
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    SwiftDataTestingView()
        .environment(Routes())
}

// VIEW MODEL
@Observable
final class SwiftDataTestingViewModel {
    var notes: [NoteData] = []
    var posts: [PostListModel] = []
    var selectedNote: NoteData?
    var textField: String = ""
    var selectedSubNote: SubNote?
    var subNoteTextField = ""
    
    @MainActor
    init() {
        self.notes = SwiftDataService.shared.fetchAllNotes() ?? []
        self.textField = ""
        self.posts = []
    }
    
    @MainActor
    func addNote() {
        let new = NoteData(name: "New Note")
        notes.append(new)
        SwiftDataService.shared.addNote(new)
    }
    
    @MainActor
    func addSubNote() {
        let new = SubNote(name: "New Subnote")
        if let note = selectedNote {
            note.subNotes.append(new)
            SwiftDataService.shared.saveModelContext()
        }
    }
    
    @MainActor
    func deleteNote(_ indexSet: IndexSet) {
        for index in indexSet {
            SwiftDataService.shared.deleteNote(at: index)
        }
    }
    
    @MainActor
    func deleteSubNote(_ indexSet: IndexSet) {
        for index in indexSet {
            if let currentNote = selectedNote {
//                delete sub note does not require its own modelcontext delete because it depends on NoteData model
                currentNote.subNotes.remove(at: index)
                SwiftDataService.shared.saveModelContext()
            }
        }
    }
    
    @MainActor
    func addNoteAuthors () {
        let authors: [Author] = [
            Author(name: "Author 1", age: 30),
            Author(name: "Author 2", age: 23),
            Author(name: "Author 3", age: 50),
        ]
        
        if let note = selectedNote {
            note.authors = authors
            SwiftDataService.shared.saveModelContext()
        }
    }
    
    @MainActor
    func deleteNoteAuthors () {
        if let note = selectedNote {
            note.authors = []
            SwiftDataService.shared.saveModelContext()
        }
    }
    
    @MainActor
    func addSubNoteAuthor (author: Author) {
        if let subnote = selectedSubNote {
            subnote.authors.append(author)
            SwiftDataService.shared.saveModelContext()
        }
    }
    
    @MainActor
    func deleteSubNoteAuthor (author: Author) {
        if let subnote = selectedSubNote {
            subnote.authors.remove(author)
            SwiftDataService.shared.saveModelContext()
        }
    }
    
    @MainActor
    func updateSubNoteName () {
        if let subNote = selectedSubNote {
            subNote.name = subNoteTextField
            SwiftDataService.shared.saveModelContext()
        }
    }
    
    @MainActor
    func updateNoteName() {
        if let note = selectedNote {
            note.name = textField
            SwiftDataService.shared.saveModelContext()
        }
    }
    
    func fetchPosts() {
        APIServiceOld.shared.getRequest(urlString: "https://jsonplaceholder.typicode.com/posts") { (result: Result<[PostListModel], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.posts.append(contentsOf: data)
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }
            }
        }
    }
    
    func createPost () {
        APIServiceOld.shared.postRequest(urlString: "https://jsonplaceholder.typicode.com/posts", body: PostListModel(id: 1, userId: 1, title: "title", body: "body")) { (result: Result<PostListModel, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.posts.append(data)
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }
            }
            
        }
    }
}

extension SwiftDataService {
    func addNote (_ note: NoteData) {
        modelContext.insert(note)
        saveModelContext()
    }
    
    func fetchAllNotes () -> [NoteData]? {
        let fetchDescriptor = FetchDescriptor<NoteData>()
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func updateNote (_ note: NoteData, index: Int) {
        if var allNotes = fetchAllNotes() {
            allNotes[index] = note
            saveModelContext()
        }
    }
    
    func deleteNote (at index: Int) {
        if let allNotes = fetchAllNotes() {
            let note = allNotes[index]
            modelContext.delete(note)
            saveModelContext()
        }
    }
    
    func deleteAllNotes () {
        do {
            try modelContext.delete(model: NoteData.self)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

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
    
    init(name: String) {
        self.name = name
    }
}

// VIEW
struct SwiftDataTestingView: View {
    @Environment(Routes.self) private var routes
    @State var swiftDataTestingViewModel = SwiftDataTestingViewModel()
    
    var body: some View {
            List {
                ForEach(swiftDataTestingViewModel.notes) { note in
                    NavigationLink {
                        VStack {
                            Text("Note:")
                            TextField("Note Name", text: $swiftDataTestingViewModel.textField )
                                .border(.black)
                                .multilineTextAlignment(.center)
                            Button (action: {
                                swiftDataTestingViewModel.updateNoteName(note)
                            }) {
                                Text("Rename Note")
                            }
                        }
                        .padding()
                        .onAppear {
                            swiftDataTestingViewModel.textField = note.name
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

#Preview {
    SwiftDataTestingView()
}

// VIEW MODEL
@Observable class SwiftDataTestingViewModel {
    var notes: [NoteData] = []
    var textField: String = ""
    var posts: [PostListModel] = []
    
    @MainActor
    init() {
        self.notes = SwiftDataService.shared.fetchAllNotes() ?? []
        self.textField = ""
        self.posts = []
    }
    
    @MainActor
    func addNote() {
        let new = NoteData(name: "New Note")
        SwiftDataService.shared.addNote(new)
        notes.append(new)
    }
    
    @MainActor
    func deleteNote(_ indexSet: IndexSet) {
        for index in indexSet {
            SwiftDataService.shared.deleteNote(at: index)
            notes.remove(at: index)
        }
    }
    
    @MainActor
    func updateNoteName(_ note: NoteData) {
        note.name = textField
        SwiftDataService.shared.saveModelContext()
    }
    
    func fetchPosts() {
        APIService.shared.getRequest(urlString: "https://jsonplaceholder.typicode.com/posts") { (result: Result<[PostListModel], Error>) in
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
        APIService.shared.postRequest(urlString: "https://jsonplaceholder.typicode.com/posts", body: PostListModel(id: 1, userId: 1, title: "title", body: "body")) { (result: Result<PostListModel, Error>) in
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
    func deleteNote (_ note: NoteData) {
        modelContext.delete(note)
    }
    
    func deleteAllNotes () {
        do {
            try modelContext.delete(model: NoteData.self)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

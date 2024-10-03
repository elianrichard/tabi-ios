//
//  SwiftDataTesting.swift
//  Tabi
//
//  Created by Elian Richard on 02/10/24.
//

import SwiftUI
import SwiftData

struct SwiftDataTestingView: View {
    @EnvironmentObject var routes: Routes
    @StateObject var swiftDataTestingViewModel = SwiftDataTestingViewModel()
    
    var body: some View {
            List {
                ForEach(swiftDataTestingViewModel.events) { event in
                    NavigationLink {
                        VStack {
                            Text("Event:")
                            TextField("Event Name", text: $swiftDataTestingViewModel.textField )
                                .border(.black)
                                .multilineTextAlignment(.center)
                            Button (action: {
                                swiftDataTestingViewModel.updateEventName(event)
                            }) {
                                Text("Rename Event")
                            }
                        }
                        .padding()
                        .onAppear {
                            swiftDataTestingViewModel.textField = event.name
                        }
                    } label: {
                        Text("\(event.name)")
                    }
                }
                .onDelete(perform: { offsetIndex in
                    swiftDataTestingViewModel.deleteEvent(offsetIndex)
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
                        routes.navigateToRoot()
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
                        swiftDataTestingViewModel.addEvent()
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

@Observable class SwiftDataTestingViewModel: ObservableObject {
    var events: [EventData] = []
    var textField: String = ""
    var posts: [PostListModel] = []
    
    @MainActor
    init() {
        self.events = SwiftDataService.shared.fetchAllEvents() ?? []
        self.textField = ""
        self.posts = []
    }
    
    @MainActor
    func addEvent() {
        let new = EventData(name: "New Event")
        SwiftDataService.shared.addEvent(new)
        events.append(new)
    }
    
    @MainActor
    func deleteEvent(_ indexSet: IndexSet) {
        for index in indexSet {
            SwiftDataService.shared.deleteEvent(at: index)
            events.remove(at: index)
        }
    }
    
    @MainActor
    func updateEventName(_ event: EventData) {
        event.name = textField
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

struct PostListModel: Encodable ,Decodable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

import SwiftUI

struct UserSearchView<Actions: View>: View {
    @State var searchText: String = ""
    @State var searchResults = [Profile]()

    let actions: (_ userId: UUID) -> Actions

    var body: some View {

        NavigationStack {
            List {
                ForEach(searchResults, id: \.id) { profile in
                        HStack {
                            NavigationLink(value: profile) {
                                
                                AvatarView(avatarUrl: profile.getAvatarURL(), size: 32, id: profile.id)
                                Text(profile.username)
                            }
                            Spacer()
                            HStack {
                                self.actions(profile.id)
                            }
                        }
                }
            }
            .navigationTitle("Search users")
            .searchable(text: $searchText)
            .onSubmit(of: .search, searchUsers)
            
        }
    }
    
    func searchUsers() {
        Task {
            do {
                let searchResults = try await SupabaseProfileRepository().search(searchTerm: searchText)
                DispatchQueue.main.async {
                    self.searchResults = searchResults
                }
            } catch {
                print("error: \(error.localizedDescription)")
            }
        }
    }
}
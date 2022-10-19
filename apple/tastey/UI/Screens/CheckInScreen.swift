import SwiftUI

struct CheckInPageView: View {
    let checkIn: CheckIn
    @StateObject private var model = CheckInPageViewModel()
    @EnvironmentObject private var navigator: Navigator

    var body: some View {
            ScrollView {
                CheckInCardView(checkIn: checkIn, onDelete: {
                    _ in  navigator.removeLast()  
                })
                    .task {
                        model.getCheckInCommets(checkInId: checkIn.id)
                    }

                VStack(spacing: 10) {
                    ForEach(model.checkInComments.reversed(), id: \.id) {
                        comment in CommentItemView(comment: comment, content: comment.content, onDelete: { id in
                            model.deleteComment(commentId: id)
                        }, onUpdate: {
                            updatedComment in model.editComment(updateCheckInComment: updatedComment)
                        })
                    }
                }
                .padding([.leading, .trailing], 15)
            }

            HStack {
                TextField("Leave a comment!", text: $model.comment)
                Button(action: { model.sendComment(checkInId: checkIn.id) }) {
                    Image(systemName: "paperplane.fill")
                }
            }
            .padding(.all, 10)
            
        }
    }

extension CheckInPageView {
    @MainActor class CheckInPageViewModel: ObservableObject {
        @Published var checkInComments = [CheckInComment]()
        @Published var comment = ""

        func getCheckInCommets(checkInId: Int) {
            Task {
                let checkIns = try await SupabaseCheckInCommentRepository().loadByCheckInId(id: checkInId)
                DispatchQueue.main.async {
                    self.checkInComments = checkIns
                }
            }
        }

        func deleteComment(commentId: Int) {
            Task {
                try await SupabaseCheckInCommentRepository().deleteById(id: commentId)
                DispatchQueue.main.async {
                    self.checkInComments.removeAll(where: {
                        $0.id == commentId
                    })
                }
            }
        }

        func sendComment(checkInId: Int) {
            let newCheckInComment = NewCheckInComment(content: comment, checkInId: checkInId)

            Task {
                let newCheckInComment = try await SupabaseCheckInCommentRepository().insert(newCheckInComment: newCheckInComment)
                DispatchQueue.main.async {
                    self.checkInComments.append(newCheckInComment)
                    self.comment = ""
                }
            }
        }

        func editComment(updateCheckInComment: UpdateCheckInComment) {
            Task {
                let updatedComment = try await SupabaseCheckInCommentRepository().update(updateCheckInComment: updateCheckInComment)

                if let at = self.checkInComments.firstIndex(where: { $0.id == updateCheckInComment.id }) {
                    DispatchQueue.main.async {
                        self.checkInComments.remove(at: at)
                        self.checkInComments.insert(updatedComment, at: at)
                    }
                }
            }
        }
    }
}

struct CommentItemView: View {
    let comment: CheckInComment
    @State var content: String
    @State var showEditCommentPrompt = false
    let onDelete: (_ commentId: Int) -> Void
    let onUpdate: (_ update: UpdateCheckInComment) -> Void

    var updateComment: () -> Void {
        return {
            guard !content.isEmpty else {
                return
            }

            let updatedComment = UpdateCheckInComment(id: comment.id, content: content)
            onUpdate(updatedComment)
            content = ""
        }
    }

    var body: some View {
        HStack {
            AvatarView(avatarUrl: comment.profile.getAvatarURL(), size: 32, id: comment.profile.id)
            VStack(alignment: .leading) {
                HStack {
                    Text(comment.profile.username).font(.system(size: 12, weight: .medium, design: .default))
                    Spacer()
                    Text(comment.createdAt.formatted()).font(.system(size: 8, weight: .medium, design: .default))
                }
                Text(comment.content).font(.system(size: 14, weight: .light, design: .default))
            }
            Spacer()
        }
        .contextMenu {
            Button {
                self.showEditCommentPrompt = true
            } label: {
                Label("Edit Comment", systemImage: "pencil")
            }

            Button {
                onDelete(comment.id)
            } label: {
                Label("Delete Comment", systemImage: "trash.fill")
            }
        }
        .frame(maxWidth: .infinity)
        .alert("Edit Comment", isPresented: $showEditCommentPrompt, actions: {
            TextField("TextField", text: $content)
            Button("Cancel", role: .cancel, action: {})
            Button("Edit", action: {
                updateComment()
            })
        })
    }
}
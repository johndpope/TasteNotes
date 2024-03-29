import AlertToast
import SwiftUI

struct SubcategorySheetView: View {
    let availableSubcategories: [Subcategory]
    @Binding var subcategories: [Subcategory]
    @State var showToast = false
    @Environment(\.dismiss) var dismiss
    let maxSubcategories = 4
    
    func toggleSubcategory(subcategory: Subcategory) {
        DispatchQueue.main.async {
            if subcategories.contains(subcategory) {
                self.subcategories.remove(object: subcategory)
            } else if subcategories.count < maxSubcategories {
                self.subcategories.append(subcategory)
            } else {
                showToast = true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(availableSubcategories, id: \.self) { subcategory in
                Button(action: {
                    toggleSubcategory(subcategory: subcategory)
                }) {
                    HStack {
                        Text(subcategory.name)
                        Spacer()
                        if subcategories.contains(subcategory) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Subcategories")
            .navigationBarItems(trailing: Button(action: {
                dismiss()
            }) {
                Text("Done").bold()
            })
            .toast(isPresenting: $showToast, duration: 2, tapToDismiss: true) {
                AlertToast(type: .error(.red), title: "You can only add \(maxSubcategories) subcategories")
            }
        }
    }
}

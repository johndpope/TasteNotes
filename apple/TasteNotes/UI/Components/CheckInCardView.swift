
import CachedAsyncImage
import GoTrue
import SwiftUI
import WrappingHStack

struct CheckInCardView: View {
    let checkIn: CheckIn
    let loadedFrom: LoadedFrom
    let onDelete: (_ checkIn: CheckIn) -> Void
    let onUpdate: (_ checkIn: CheckIn) -> Void
    @StateObject var viewModel = ViewModel()
    @State var showDeleteCheckInConfirmationDialog = false
    
    func isOwnedByCurrentUser() -> Bool {
        return checkIn.profile.id == repository.auth.getCurrentUserId()
    }

    func avoidStackingCheckInPage() -> Bool {
        var isCurrentProfile: Bool

        switch loadedFrom {
        case let .profile(profile):
            isCurrentProfile = profile.id == checkIn.profile.id
        default:
            isCurrentProfile = false
        }

        return isCurrentProfile
    }

    var body: some View {
        VStack {
            VStack {
                    header
                    productSection
                    if !checkIn.isEmpty() {
                        checkInSection
                    }
                    footer
                }
                .padding(.all, 10)
                .background(.ultraThinMaterial)
                .background(
                    backgroundImage
                )
                .clipped()
        }
        .cornerRadius(10)
        .padding(.all, 10)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
        .sheet(isPresented: $viewModel.showingSheet) {
            CheckInSheetView(checkIn: checkIn, onUpdate: {
                updatedCheckIn in onUpdate(updatedCheckIn)
            })
        }
        .contextMenu {
            if isOwnedByCurrentUser() {
                Button(action: {
                    viewModel.toggleSheet()
                }) { 
                    Label("Edit", systemImage: "pencil")
                }

                Button(action: {
                    showDeleteCheckInConfirmationDialog.toggle()
                }) {
                    Label("Delete", systemImage: "trash.fill")
                }
            }
        }
        .confirmationDialog("delete_check_in",
                            isPresented: $showDeleteCheckInConfirmationDialog
        ) {
            Button("Delete the check-in", role: .destructive, action: {
                    viewModel.delete(checkIn: checkIn, onDelete: onDelete)
            })
        }
    }

    var header: some View {
        NavigationLink(value: checkIn.profile) {
            HStack {
                AvatarView(avatarUrl: checkIn.profile.getAvatarURL(), size: 30, id: checkIn.profile.id)
                Text(checkIn.profile.getPreferredName())
                    .font(.system(size: 12, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .disabled(avoidStackingCheckInPage())
    }

    var backgroundImage: some View {
        HStack {
            if let imageUrl = checkIn.getImageUrl() {
                HStack {
                    CachedAsyncImage(url: imageUrl, urlCache: .imageCache) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        EmptyView()
                    }
                }
            } else {
                EmptyView()
            }
        }
    }

    var productSection: some View {
        NavigationLink(value: checkIn.product) {
            VStack(alignment: .leading) {
                Text(checkIn.product.getDisplayName(.fullName))
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.primary)

                HStack {
                    NavigationLink(value: checkIn.product.subBrand.brand.brandOwner) {
                        Text(checkIn.product.getDisplayName(.brandOwner))
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }

                    if let manufacturer = checkIn.variant?.manufacturer, manufacturer.id != checkIn.product.subBrand.brand.brandOwner.id {
                        NavigationLink(value: manufacturer) {
                            Text("(\(manufacturer.name))")
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }

                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }

    var checkInSection: some View {
        NavigationLink(value: checkIn) {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        if let rating = checkIn.rating {
                            RatingView(rating: rating)
                        }
                        
                        if let review = checkIn.review {
                            Text(review)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        if let flavors = checkIn.flavors {
                            WrappingHStack(flavors, id: \.self) {
                                flavor in
                                ChipView(title: flavor.name.capitalized, cornerRadius: 5).padding(.all, 2)
                            }
                        }
                    }
                }
                .padding(.all, 10)
                .opacity(1)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5)

                if checkIn.taggedProfiles.count > 0 {
                    VStack {
                        HStack {
                            Text(verbatim: "Tagged friends")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        HStack {
                            ForEach(checkIn.taggedProfiles, id: \.id) {
                                taggedProfile in
                                NavigationLink(value: taggedProfile) {
                                    AvatarView(avatarUrl: taggedProfile.getAvatarURL(), size: 32, id: taggedProfile.id)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    var footer: some View {
        HStack {
            NavigationLink(value: checkIn) {
                Text(checkIn.createdAt.formatted())
                    .font(.system(size: 12, weight: .medium, design: .default))

                Spacer()
            }
            .buttonStyle(.plain)
            Spacer()
            ReactionsView(checkIn: checkIn)
        }
    }
}

extension CheckInCardView {
    enum LoadedFrom: Equatable {
        case checkIn
        case product
        case profile(Profile)
        case activity(Profile)
    }

    @MainActor class ViewModel: ObservableObject {
        @Published var showingSheet = false

        func toggleSheet() {
            showingSheet.toggle()
        }

        func delete(checkIn: CheckIn, onDelete: @escaping (_ checkIn: CheckIn) -> Void) {
            Task {
                switch await repository.checkIn.delete(id: checkIn.id) {
                case .success():
                    onDelete(checkIn)
                case let .failure(error):
                    print(error)
                }
            }
        }
    }
}


struct CheckInCardView_Previews: PreviewProvider {
    static let company = Company(id: 0, name: "The Coca Cola Company", logoUrl: nil)

    static let product = ProductJoined(id: 0, name: "Coca Cola", description: "Original Taste", subBrand: subBrand, subcategories: subcategories)
    
    static let profile = Profile(id: UUID(uuidString: "82c34cc0-4795-4478-99ad-38003fdb65fd") ?? UUID(), username: "villeheikkila", firstName: "Ville", lastName: "Heikkilä", avatarUrl: "avatar.jpeg", nameDisplay: .fullName, notifications: nil, roles: nil, settings: nil)

    static let servingStyle = ServingStyle(id: 0, name: .bottle)

    static let hartwallCompany = Company(id: 0, name: "Hartwall", logoUrl: nil)

    static let variant = ProductVariant(id: 0, manufacturer: hartwallCompany)
        
    static let category = Category(id: 0, name: .beverage)
        
    static let flavors = [Flavor(id: 0, name: "Cola")]

    static let checkInReactions = [CheckInReaction(id: 0, profile: profile)]

    static let subcategories = [SubcategoryJoinedWithCategory(id: 0, name: "Soda", category: category)]

    static let brand = BrandJoinedWithCompany(id: 0, name: "Coca Cola", brandOwner: company)

    static let subBrand = SubBrandJoinedWithBrand(id: 0, name: "Zero", brand: brand)
    
    static let country = Country(countryCode: "FI", name: "Finland", emoji: "🇫🇮")
    
    static let location = Location(id: UUID(), name: "McDonalds", title: "Mäkkäri", location: nil, countryCode: "FI", country: country)
    
    static let checkIn = CheckIn(id: 0, rating: 2.5, review: "Pretty Good!", imageUrl: "IMG_3155.jpeg", createdAt: Date(), profile: profile, product: product, checkInReactions: checkInReactions, taggedProfiles: [profile], flavors: flavors, variant: variant , servingStyle: servingStyle, location: location)
                                                   
    static var previews: some View {
        CheckInCardView(checkIn: checkIn, loadedFrom: .checkIn, onDelete: { _ in print("delete")}, onUpdate: { _ in print("update") })
    }
}




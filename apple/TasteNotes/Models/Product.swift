struct Product: Identifiable, Decodable, Hashable {
    let id: Int
    let name: String
    let description: String?
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ProductJoined: Identifiable {
    let id: Int
    let name: String
    let description: String?
    let subBrand: SubBrandJoinedWithBrand
    let subcategories: [SubcategoryJoinedWithCategory]
    
    func getCategory() -> CategoryName? {
        return subcategories.first?.category.name
    }
    
    func getDisplayName(_ part: ProductNameParts) -> String {
        switch part {
        case .full:
            return [subBrand.brand.brandOwner.name, subBrand.brand.name, subBrand.name, name]
                .compactMap({ $0 })
                .joined(separator: " ")
        case .brandOwner:
            return subBrand.brand.brandOwner.name
        case .fullName:
            return [subBrand.brand.name, subBrand.name, name]
                .compactMap({ $0 })
                .joined(separator: " ")
        }
    }
}

extension ProductJoined {
    enum ProductNameParts {
        case brandOwner
        case fullName
        case full
    }
}

extension ProductJoined: Hashable {
    static func == (lhs: ProductJoined, rhs: ProductJoined) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ProductJoined: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case subBrand = "sub_brands"
        case subcategories
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.description = try values.decodeIfPresent(String.self, forKey: .description)
        self.subBrand = try values.decode(SubBrandJoinedWithBrand.self, forKey: .subBrand)
        self.subcategories = try values.decode([SubcategoryJoinedWithCategory].self, forKey: .subcategories)
    }
}

extension ProductJoined {
    init(company: Company, product: ProductJoinedCategory, subBrand: SubBrandJoinedProduct, brand: BrandJoinedSubBrandsJoinedProduct) {
        self.id = product.id
        self.name = product.name
        self.description = product.name
        self.subBrand = SubBrandJoinedWithBrand(id: subBrand.id, name: subBrand.name, brand: BrandJoinedWithCompany(id: brand.id, name: brand.name, brandOwner: company))
        self.subcategories = product.subcategories
    }
}

struct ProductJoinedCategory: Identifiable, Decodable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let subcategories: [SubcategoryJoinedWithCategory]
    
    static func == (lhs: ProductJoinedCategory, rhs: ProductJoinedCategory) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case subcategories
    }
    
    init(id: Int, name: String, description: String?, subcategories: [SubcategoryJoinedWithCategory]) {
        self.id = id
        self.name = name
        self.description = description
        self.subcategories = subcategories
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.name = try values.decode(String.self, forKey: .name)
        self.description = try values.decodeIfPresent(String.self, forKey: .description)
        self.subcategories = try values.decode([SubcategoryJoinedWithCategory].self, forKey: .subcategories)
    }
}

struct NewProductParams: Encodable {
    let p_name: String
    let p_description: String?
    let p_category_id: Int
    let p_brand_id: Int
    let p_sub_category_ids: [Int]
    let p_sub_brand_id: Int?
    
    
    init(name: String, description: String?, categoryId: Int, brandId: Int, subBrandId: Int?, subCategoryIds: [Int]) {
        self.p_name = name
        self.p_description = description
        self.p_category_id = categoryId
        self.p_sub_brand_id = subBrandId
        self.p_sub_category_ids = subCategoryIds
        self.p_brand_id = brandId
    }
    
}

struct NewProductEditSuggestionParams: Encodable {
    let p_product_id: Int
    let p_name: String
    let p_description: String?
    let p_category_id: Int
    let p_sub_category_ids: [Int]
    let p_sub_brand_id: Int?
    
    
    init(productId: Int, name: String, description: String?, categoryId: Int, subBrandId: Int?, subCategoryIds: [Int]) {
        self.p_product_id = productId
        self.p_name = name
        self.p_description = description
        self.p_category_id = categoryId
        self.p_sub_brand_id = subBrandId
        self.p_sub_category_ids = subCategoryIds
    }
    
}

struct ProductSummary {
    let totalCheckIns: Int
    let averageRating: Double?
    let currentUserAverageRating: Double?
}

struct GetProductSummaryParams: Encodable {
    let p_product_id: Int
    
    init(id: Int) {
        p_product_id = id
    }
}

extension ProductSummary: Decodable {
    enum CodingKeys: String, CodingKey {
        case totalCheckIns = "total_check_ins"
        case averageRating = "average_rating"
        case currentUserAverageRating = "current_user_average_rating"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        totalCheckIns = try values.decode(Int.self, forKey: .totalCheckIns)
        averageRating = try values.decodeIfPresent(Double.self, forKey: .averageRating)
        currentUserAverageRating = try values.decodeIfPresent(Double.self, forKey: .currentUserAverageRating)
    }
}
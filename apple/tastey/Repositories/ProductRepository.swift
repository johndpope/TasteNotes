import Foundation
import Supabase

protocol ProductRepository {
    func search(searchTerm: String) async throws -> [Product]
    func create(newProductParams: NewProductParams) async throws -> Product
}

struct SupabaseProductRepository: ProductRepository {
    let client: SupabaseClient
    private let tableName = "companies"
    private let joined = "id, name, description, sub_brands (id, name, brands (id, name, companies (id, name))), subcategories (id, name, categories (id, name))"
    
    
    func search(searchTerm: String) async throws -> [Product] {
        struct SearchProductsParams: Encodable {
            let p_search_term: String
            init(searchTerm: String) {
                self.p_search_term = "%\(searchTerm.trimmingCharacters(in: .whitespacesAndNewlines))%"
            }
        }
        
        return try await client
            .database
            .rpc(fn: "fnc__search_products", params: SearchProductsParams(searchTerm: searchTerm))
            .select(columns: joined)
            .execute()
            .decoded(to: [Product].self)
    }
    
    func getProductById(id: Int) async throws -> Product {
        return try await client
            .database
            .from("products")
            .select(columns: joined)
            .eq(column: "id", value: id)
            .limit(count: 1)
            .single()
            .execute()
            .decoded(to: Product.self)
    }
    
    func create(newProductParams: NewProductParams) async throws -> Product {
        let product = try await client
            .database
            .rpc(fn: "fnc__create_product", params: newProductParams)
            .select(columns: "id")
            .limit(count: 1)
            .single()
            .execute()
            .decoded(to: DecodableId.self)
        /**
         TODO: Investigate if it is possible to somehow join sub_brands immediately after it has been created as part of the fnc__create_product function. 22.10.2022
         */
        return try await getProductById(id: product.id)
    }
}

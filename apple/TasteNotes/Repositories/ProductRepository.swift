import Foundation
import Supabase

protocol ProductRepository {
    func search(searchTerm: String) async -> Result<[ProductJoined], Error>
    func delete(id: Int) async -> Result<Void, Error>
    func create(newProductParams: NewProductParams) async -> Result<ProductJoined, Error>
    func getSummaryById(id: Int) async -> Result<ProductSummary, Error>
    func createUpdateSuggestion(productEditSuggestionParams: NewProductEditSuggestionParams) async -> Result<DecodableId, Error>
}

struct SupabaseProductRepository: ProductRepository {
    let client: SupabaseClient

    func search(searchTerm: String) async -> Result<[ProductJoined], Error> {
        struct SearchProductsParams: Encodable {
            let p_search_term: String
            init(searchTerm: String) {
                p_search_term = "%\(searchTerm.trimmingCharacters(in: .whitespacesAndNewlines))%"
            }
        }

        do {
            let response = try await client
                .database
                .rpc(fn: "fnc__search_products", params: SearchProductsParams(searchTerm: searchTerm))
                .select(columns: Product.getQuery(.joinedBrandSubcategories(false)))
                .execute()
                .decoded(to: [ProductJoined].self)

            return .success(response)
        } catch {
            return .failure(error)
        }
    }

    func getProductById(id: Int) async throws -> ProductJoined {
        return try await client
            .database
            .from(Product.getQuery(.tableName))
            .select(columns: Product.getQuery(.joinedBrandSubcategories(false)))
            .eq(column: "id", value: id)
            .limit(count: 1)
            .single()
            .execute()
            .decoded(to: ProductJoined.self)
    }

    func delete(id: Int) async -> Result<Void, Error> {
        do {
            try await client
                .database
                .from(Product.getQuery(.tableName))
                .delete()
                .eq(column: "id", value: id)
                .execute()

            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func create(newProductParams: NewProductParams) async -> Result<ProductJoined, Error> {
        do {
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
            let response = try await getProductById(id: product.id)

            return .success(response)
        } catch {
            return .failure(error)
        }
    }

    func createUpdateSuggestion(productEditSuggestionParams: NewProductEditSuggestionParams) async -> Result<DecodableId, Error> {
        do {
            let productEditSuggestion = try await client
                .database
                .rpc(fn: "fnc__create_product_edit_suggestion", params: productEditSuggestionParams)
                .select(columns: "id")
                .limit(count: 1)
                .single()
                .execute()
                .decoded(to: DecodableId.self)

            return .success(productEditSuggestion)
        } catch {
            return .failure(error)
        }
    }

    func getSummaryById(id: Int) async -> Result<ProductSummary, Error> {
        do {
            let response = try await client
                .database
                .rpc(fn: "fnc__get_product_summary", params: GetProductSummaryParams(id: id))
                .select()
                .limit(count: 1)
                .single()
                .execute()
                .decoded(to: ProductSummary.self)

            return .success(response)
        } catch {
            return .failure(error)
        }
    }
}

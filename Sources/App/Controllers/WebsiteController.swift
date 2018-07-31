import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return try req.view().render("index")
    }
}

struct IndexContent: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

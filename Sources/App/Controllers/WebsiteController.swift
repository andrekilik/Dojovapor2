import Vapor
import Leaf

struct IndexContent: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
}

struct CreateAcronymContent: Encodable {
    let title = "Create An Acronym"
}

struct EditAcronymContent: Encodable {
    let title = "Edit Acronym"
    let acronym: Acronym
    let editing = true
}

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
        router.get("acronyms", "create", use: createAcronymHandler)
        router.post(Acronym.self, at: "acronyms", "create", use: createAcronymPostHandler)
        router.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        router.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        router.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)

    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return Acronym.query(on: req)
            .all()
            .flatMap(to: View.self) { acronyms in
                let acronymsData = acronyms.isEmpty ? nil : acronyms
                let content = IndexContent(title: "Homepage",
                                           acronyms: acronymsData)
                return try req.view().render("index", content)
        }
    }
    
    func acronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                        let context = AcronymContext(title: acronym.short,
                                                     acronym: acronym)
                        return try req.view().render("acronym", context)
        }
    }
    func createAcronymHandler(_ req: Request) throws
        -> Future<View> {
            
            let content = CreateAcronymContent()
            return try req.view().render("createAcronym", content)
    }
    
    func createAcronymPostHandler(_ req: Request, acronym: Acronym) throws-> Future<Response> {
            return acronym.save(on: req).map(to: Response.self) { acronym in
                guard let id = acronym.id else {
                    throw Abort(.internalServerError)
                }
                return req.redirect(to: "/acronyms/\(id)")
            }
    }
    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                let content = EditAcronymContent(acronym: acronym)
                return try req.view().render("createAcronym", content)
        }
    }
    
    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
            return try flatMap(to: Response.self,
                               req.parameters.next(Acronym.self),
                               req.content.decode(Acronym.self)) {
                                acronym, data in
                                acronym.short = data.short
                                acronym.long = data.long
                                return acronym.save(on: req).map(to: Response.self) {
                                    savedAcronym in
                                    guard let id = savedAcronym.id else {
                                        throw Abort(.internalServerError)
                                    }
                                    return req.redirect(to: "/acronyms/\(id)")
                                }
            }
    }
    func deleteAcronymHandler(_ req: Request) throws -> Future<Response> {
            return try req.parameters.next(Acronym.self).delete(on: req)
                .transform(to: req.redirect(to: "/"))
    }

}

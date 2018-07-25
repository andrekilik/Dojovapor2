import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoute = router.grouped("api", "acronym")
        acronymsRoute.get(use: getAllHandler)
        acronymsRoute.post(use: createHandler)
        acronymsRoute.get(Acronym.parameter, use: getHandler)
        acronymsRoute.delete(Acronym.parameter, use: deleteHandler)
        acronymsRoute.put(Acronym.parameter, use: updateHandler)
        acronymsRoute.get("search", use: searchHandler)
        acronymsRoute.get("first", use: getFirstHandler)
        acronymsRoute.get("sorted", use: sortedHandler)
        acronymsRoute.get(Acronym.parameter, "user", use: getUserHandler)
    }
    func createHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.content.decode(Acronym.self).flatMap(to: Acronym.self) { (acronym) in
            return acronym.save(on: req)
        }
    }
    //    Here’s what this does:
    //    Register a new route at /api/acronyms/ that accepts a POST request and returns Future<Acronym>.
    //    Decode the request’s JSON into an Acronym. This is made simple because Acronym conforms to Content. decode(_:) returns a Future; use flatMap(to:) to extract the acronym when decoding completes.
    //    Save the model using Fluent. When the save completes, it returns the model as a Future — in this case, Future<Acronym>.
    
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    //    Here’s what this does:
    //    Register a new route handler for the request which returns Future<[Acronym]>, a future array of Acronyms.
    //    Perform a query to get all the acronyms.
    //    Fluent adds functions to models to be able to perform queries on them. You must give the query a DatabaseConnectable. This is almost always the request and provides a thread to perform the work. all() returns all the models of that type in the database. This is equivalent to the SQL query SELECT * FROM Acronyms;
    
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    //    Here’s what this does:
    //    Register a route at /api/acronyms/<ID> to handle a GET request. The route takes the acronym’s id property as the final path segment. This returns Future<Acronym>.
    //    Extract the acronym from the request using the parameter function. This function performs all the work necessary to get the acronym from the database. It also handles the error cases when the acronym does not exist, or the ID type is wrong, for example, when you pass it an integer when the ID is a UUID
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(Acronym.self)) { (acronym, updatedAcronym) in
                            acronym.short = updatedAcronym.short
                            acronym.long = updatedAcronym.long
                            acronym.userID = updatedAcronym.userID
                            return acronym.save(on: req)
        }
    }
    //    Here’s the play-by-play:
    //    Register a route for a PUT request to /api/acronyms/<ID> that returns Future<Acronym>.
    //    Use flatMap(to:_:_:), the dual future form of flatMap, to wait for both the parameter extraction and content decoding to complete. This provides both the acronym from the database and acronym from the request body to the closure.
    //    Update the acronym’s properties with the new values.
    //    Save the acronym and return the result
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters
            .next(Acronym.self)
            .delete(on: req)
            .transform(to: HTTPStatus.noContent)
    }
    //    Extract the acronym to delete from the request’s parameters.
    //    Delete the acronym using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future. This helps tidy up code and reduce nesting. Fluent provides convenience functions for delete, update, create and save.
    //    Transform the result into a 204 No Content response. This tells the client the request has successfully completed but there’s no content to return.
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return try Acronym.query(on: req).group(.or) { or in
            try or.filter(\.short == searchTerm)
            try or.filter(\.long == searchTerm)
            }.all()
    }
    //    Retrieve the search term from the URL query string. You can do this with any Codable object by calling req.query.decode(_:). If this fails, throw a 400 Bad Request error.
    //    Query strings in URLs allow clients to pass information to the server that doesn’t fit sensibly in the path. For example, they are commonly used for defining the page number of a search result.
    //    Use filter(_:) to find all acronyms whose short property matches the searchTerm. Because this uses key paths, the compiler can enforce type-safety on the properties and filter terms. This prevents run-time issues caused by specifying an invalid column name or invalid type to filter on.
    //    Create a filter group using the .or relation.
    //    Add a filter to the group to filter for acronyms whose short property matches the search term.
    //    Add a filter to the group to filter for acronyms whose long property matches the search term.
    //    Return all the results.
    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req).first().map(to: Acronym.self) {
            acronym in
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            return acronym
        }
    }
    //    Perform a query to get the first acronym. Use the map(to:) function to unwrap the result of the query.
    //    Ensure an acronym exists. first() returns an optional as there may be no acronyms in the database. Throw a 404 Not Found error if no acronym is returned.
    //    Return the first acronym.
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try Acronym.query(on: req)
            .sort(\.short, .ascending)
            .all()
    }
    //    Create a query for Acronym and use sort(_:_:) to perform the sort. This function takes the field to sort on and the direction to sort in. Finally use all() to return all the results of the query.
    //    Build and run the application, then create a new request in RESTed:
    
    func getUserHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: User.self) { (acronym) in
                try acronym.user.get(on: req)
            }
    }
    
}


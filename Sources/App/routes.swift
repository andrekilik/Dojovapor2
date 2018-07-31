import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    let acronymsController = AcronymsController()
    let usersController = UsersController()
    let websiteController = WebsiteController()
    try router.register(collection: acronymsController)
    try router.register(collection: usersController)
    try router.register(collection: websiteController)

}

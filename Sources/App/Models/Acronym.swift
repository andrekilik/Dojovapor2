import Vapor
import FluentPostgreSQL

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    
    init(short: String, long: String) {
        self.short = short
        self.long = long
    }
}

extension Acronym: PostgreSQLModel {}
extension Acronym: Migration {
//
//    static func prepare(on connection: PostgreSQLConnection)
//        -> Future<Void> {
//
//            return Database.create(self, on: connection) { builder in
//
//                try addProperties(to: builder)
//
//                try builder.reference(from: \.userID, to: \User.id)
//            }
//    }
}
extension Acronym: Content {}
extension Acronym: Parameter {}

import Foundation

nonisolated enum Section { case drinks, food }

nonisolated struct Order: Hashable {
    var id = UUID()
    var dish: String
    var quantity: Int
    var isDrink: Bool
}

nonisolated extension Order: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case dish
        case quantity
        case isDrink
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        dish = try container.decode(String.self, forKey: .dish)
        quantity = try container.decode(Int.self, forKey: .quantity)
        isDrink = try container.decodeIfPresent(Bool.self, forKey: .isDrink) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dish, forKey: .dish)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(isDrink, forKey: .isDrink)
    }
}

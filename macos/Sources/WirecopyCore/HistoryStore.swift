import Foundation

public actor HistoryStore {
    private let defaults: UserDefaults
    private let key: String
    private let limit: Int
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard, key: String = "publishedLinks.v1", limit: Int = 50) {
        self.defaults = defaults
        self.key = key
        self.limit = limit
    }

    public func all() -> [PublishedLink] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? decoder.decode([PublishedLink].self, from: data)) ?? []
    }

    public func add(_ link: PublishedLink) {
        var links = all()
        links.removeAll { $0.url == link.url }
        links.insert(link, at: 0)
        if links.count > limit { links.removeLast(links.count - limit) }
        if let data = try? encoder.encode(links) { defaults.set(data, forKey: key) }
    }

    public func remove(id: UUID) {
        let links = all().filter { $0.id != id }
        if let data = try? encoder.encode(links) { defaults.set(data, forKey: key) }
    }
}

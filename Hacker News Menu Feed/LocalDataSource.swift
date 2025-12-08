import Foundation

class LocalDataSource {
    static func savePosts(value: [StoryFetchResponse]) {
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: "Posts")
        }
    }

    static func getPosts() -> [StoryFetchResponse] {
        var posts: [StoryFetchResponse] = []

        if let data = UserDefaults.standard.data(forKey: "Posts") {
            if let decoded = try? JSONDecoder().decode([StoryFetchResponse].self, from: data) {
                posts = decoded
            }
        }

        return posts
    }

    static func saveOriginalPostIDs(value: [Int]) {
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: "OriginalPostIDs")
        }
    }

    static func getOriginalPostIDs() -> [Int] {
        var originalPostIDs: [Int] = []

        if let data = UserDefaults.standard.data(forKey: "OriginalPostIDs") {
            if let decoded = try? JSONDecoder().decode([Int].self, from: data) {
                originalPostIDs = decoded
            }
        }

        return originalPostIDs
    }

    static func saveTitle(value: String?) {
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: "Title")
        }
    }

    static func getTitle() -> String? {
        var title: String?

        if let data = UserDefaults.standard.data(forKey: "Title") {
            if let decoded = try? JSONDecoder().decode(String?.self, from: data) {
                title = decoded
            }
        }

        return title
    }

    static func saveSortKey(value: SortKey) {
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: "SortKey")
        }
    }

    static func getSortKey() -> SortKey {
        var sortKey: SortKey = .original

        if let data = UserDefaults.standard.data(forKey: "SortKey") {
            if let decoded = try? JSONDecoder().decode(SortKey.self, from: data) {
                sortKey = decoded
            }
        }

        return sortKey
    }

    static func saveShowHeadline(value: Bool) {
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: "ShowHeadline")
        }
    }

    static func getShowHeadline() -> Bool {
        var result: Bool = true

        if let data = UserDefaults.standard.data(forKey: "ShowHeadline") {
            if let decoded = try? JSONDecoder().decode(Bool.self, from: data) {
                result = decoded
            }
        }

        return result
    }
}

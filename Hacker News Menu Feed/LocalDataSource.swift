import Foundation

class LocalDataSource {
  public static func savePosts(value: [StoryFetchResponse]) {
    if let encoded = try? JSONEncoder().encode(value) {
      UserDefaults.standard.set(encoded, forKey: "Posts")
    }
  }

  public static func getPosts() -> [StoryFetchResponse] {
    var posts: [StoryFetchResponse] = []

    if let data = UserDefaults.standard.data(forKey: "Posts") {
      if let decoded = try? JSONDecoder().decode([StoryFetchResponse].self, from: data) {
        posts = decoded
      }
    }

    return posts
  }

  public static func saveSortKey(value: SortKey) {
    if let encoded = try? JSONEncoder().encode(value) {
      UserDefaults.standard.set(encoded, forKey: "SortKey")
    }
  }

  public static func getSortKey() -> SortKey {
    var sortKey: SortKey = .original

    if let data = UserDefaults.standard.data(forKey: "SortKey") {
      if let decoded = try? JSONDecoder().decode(SortKey.self, from: data) {
        sortKey = decoded
      }
    }

    return sortKey
  }

  public static func saveShowHeadline(value: Bool) {
    if let encoded = try? JSONEncoder().encode(value) {
      UserDefaults.standard.set(encoded, forKey: "ShowHeadline")
    }
  }

  public static func getShowHeadline() -> Bool {
    var result: Bool = true

    if let data = UserDefaults.standard.data(forKey: "ShowHeadline") {
      if let decoded = try? JSONDecoder().decode(Bool.self, from: data) {
        result = decoded
      }
    }

    return result
  }
}

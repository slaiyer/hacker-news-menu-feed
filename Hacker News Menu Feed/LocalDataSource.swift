import Foundation

class LocalDataSource {

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

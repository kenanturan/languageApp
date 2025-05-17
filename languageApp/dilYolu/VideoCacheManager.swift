import Foundation

/// Video API verilerini önbelleğe alarak API kullanımını minimize etmeye yarayan sınıf
class VideoCacheManager {
    static let shared = VideoCacheManager()
    
    private let userDefaults = UserDefaults.standard
    private let cacheUpdateKey = "videoCacheLastUpdate" // Sadece bilgi amaçlı saklanıyor
    private let videosCacheKey = "cachedVideos"
    
    private init() {}
    
    /// Video verisini önbelleğe alır
    func cacheVideos(_ videos: [PlaylistItem]) {
        do {
            let encoder = JSONEncoder()
            let videosData = try encoder.encode(videos)
            userDefaults.set(videosData, forKey: videosCacheKey)
            userDefaults.set(Date(), forKey: cacheUpdateKey)
            userDefaults.synchronize()
            print("[VideoCacheManager] \(videos.count) video önbelleğe alındı")
        } catch {
            print("[VideoCacheManager] Video önbelleğe alma hatası: \(error.localizedDescription)")
        }
    }
    
    /// Önbelleğe alınmış videoları getirir
    func getCachedVideos() -> [PlaylistItem]? {
        guard let cachedData = userDefaults.data(forKey: videosCacheKey) else {
            print("[VideoCacheManager] Önbellekte video verisi bulunamadı")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let videos = try decoder.decode([PlaylistItem].self, from: cachedData)
            print("[VideoCacheManager] \(videos.count) video önbellekten yüklendi")
            return videos
        } catch {
            print("[VideoCacheManager] Video önbellek okuma hatası: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Önbellekteki videoların varlığını kontrol eder
    func hasCachedVideos() -> Bool {
        let hasCache = userDefaults.data(forKey: videosCacheKey) != nil
        
        if hasCache, let lastUpdate = userDefaults.object(forKey: cacheUpdateKey) as? Date {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            print("[VideoCacheManager] Önbellek mevcut - Son güncelleme: \(Int(timeSinceLastUpdate/86400)) gün \(Int((timeSinceLastUpdate.truncatingRemainder(dividingBy: 86400))/3600)) saat önce")
        } else {
            print("[VideoCacheManager] Önbellek bulunamadı")
        }
        
        return hasCache
    }
    
    /// Önbelleği temizler
    func clearCache() {
        userDefaults.removeObject(forKey: videosCacheKey)
        userDefaults.removeObject(forKey: cacheUpdateKey)
        userDefaults.synchronize()
        print("[VideoCacheManager] Önbellek temizlendi")
    }
}

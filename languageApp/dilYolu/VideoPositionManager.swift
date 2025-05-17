import Foundation

class VideoPositionManager {
    static let shared = VideoPositionManager()
    
    private let userDefaults = UserDefaults.standard
    private let videoPositionsKey = "saved_video_positions"
    
    private init() {}
    
    // Video pozisyonunu kaydet (videoId ve saniye cinsinden pozisyon)
    func savePosition(for videoId: String, position: Double) {
        var positions = getVideoPositions()
        positions[videoId] = position
        userDefaults.set(positions, forKey: videoPositionsKey)
    }
    
    // Video pozisyonunu al
    func getPosition(for videoId: String) -> Double {
        let positions = getVideoPositions()
        return positions[videoId] ?? 0.0
    }
    
    // Kaydedilmiş tüm video pozisyonlarını al
    private func getVideoPositions() -> [String: Double] {
        return userDefaults.dictionary(forKey: videoPositionsKey) as? [String: Double] ?? [:]
    }
    
    // Bir videonun pozisyonunu sıfırla
    func resetPosition(for videoId: String) {
        var positions = getVideoPositions()
        positions.removeValue(forKey: videoId)
        userDefaults.set(positions, forKey: videoPositionsKey)
    }
    
    // Tüm video pozisyonlarını sıfırla
    func resetAllPositions() {
        userDefaults.removeObject(forKey: videoPositionsKey)
    }
}

import Foundation

class FlashcardManager {
    static let shared = FlashcardManager()
    
    private let userDefaults = UserDefaults.standard
    private let currentIndexKey = "flashcard_current_index"
    private let studySessionActiveKey = "flashcard_session_active"
    private let lastStudiedWordsKey = "flashcard_last_studied_words"
    
    init() {
        // Uygulama açılışında log mesajı ile durumu göster
        let active = userDefaults.bool(forKey: studySessionActiveKey)
        let index = userDefaults.integer(forKey: currentIndexKey)
        let wordCount = userDefaults.stringArray(forKey: lastStudiedWordsKey)?.count ?? 0
        print("FlashcardManager yüklendi - Aktif oturum: \(active), İndeks: \(index), Kelime sayısı: \(wordCount)")
    }
    
    // Mevcut kelime indeksini kaydet
    func saveCurrentIndex(_ index: Int) {
        userDefaults.set(index, forKey: currentIndexKey)
        userDefaults.synchronize() // Hemen kaydet
    }
    
    // Mevcut kelime indeksini getir
    func getCurrentIndex() -> Int {
        return userDefaults.integer(forKey: currentIndexKey)
    }
    
    // Aktif bir çalışma oturumu olup olmadığını kaydet
    func saveSessionActive(_ active: Bool) {
        userDefaults.set(active, forKey: studySessionActiveKey)
        userDefaults.synchronize() // Hemen kaydet
        print("Oturum durumu kaydedildi: \(active)")
    }
    
    // Aktif bir çalışma oturumu olup olmadığını kontrol et
    func isSessionActive() -> Bool {
        let isActive = userDefaults.bool(forKey: studySessionActiveKey)
        print("Oturum durumu kontrol ediliyor: \(isActive)")
        return isActive
    }
    
    // Çalışılan kelimelerin ID'lerini kaydet (hangi kelimelerin çalışıldığını takip etmek için)
    func saveStudiedWords(_ wordIDs: [String]) {
        print("Kelimeler kaydediliyor: \(wordIDs.count) adet")
        userDefaults.set(wordIDs, forKey: lastStudiedWordsKey)
        userDefaults.synchronize() // Hemen kaydet
    }
    
    // Son çalışılan kelimelerin ID'lerini getir
    func getStudiedWordIDs() -> [String] {
        let wordIDs = userDefaults.stringArray(forKey: lastStudiedWordsKey) ?? []
        print("Yüklenen kelime ID'leri: \(wordIDs.count) adet")
        return wordIDs
    }
    
    // Çalışma oturumunu sıfırla
    func resetSession() {
        print("Oturum sıfırlanıyor...")
        userDefaults.removeObject(forKey: currentIndexKey)
        userDefaults.removeObject(forKey: studySessionActiveKey)
        userDefaults.removeObject(forKey: lastStudiedWordsKey)
        userDefaults.synchronize() // Hemen kaydet
        print("Oturum sıfırlandı.")
    }
}

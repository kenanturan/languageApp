import Foundation

// TÜM HATIRLANAN KELİMELER İÇİN SABİT VE TUTARLI BİR ANAHTAR KULLANAN YÖNETİCİ
class RememberedFlashcardManager {
    static let shared = RememberedFlashcardManager()
    
    // Kullanıcının kaldığı son kelime indeksi
    private(set) var currentIndex: Int = 0
    
    // Sabit ilerleme anahtarı - Hatırlanan kelimeler için her zaman aynı kullanılacak
    private var progressKey = "remembered_words_progress_index"
    
    private init() {
        // Başlangıçta mevcut ilerlemeyi yükle
        loadCurrentProgress()
    }
    
    // Başlangıçta ve gerektiğinde mevcut ilerlemeyi yükler
    private func loadCurrentProgress() {
        currentIndex = UserDefaults.standard.integer(forKey: progressKey)
        print("[FlashcardManager] İlerleme yüklendi: \(progressKey) = \(currentIndex)")
    }
    
    // İlerlemeyi hemen senkronize ederek kaydet
    func saveProgress() {
        UserDefaults.standard.set(currentIndex, forKey: progressKey)
        UserDefaults.standard.synchronize() // Hemen senkronize et
        print("[FlashcardManager] İlerleme kaydedildi: \(progressKey) = \(currentIndex)")
        
        // Doğrulama için kaydedilen değeri kontrol et
        let saved = UserDefaults.standard.integer(forKey: progressKey)
        if saved != currentIndex {
            print("[HATA] İlerleme kaydı başarısız! Beklenen: \(currentIndex), UserDefaults: \(saved)")
        }
    }
    
    // İndeksi doğrudan ayarla
    func setIndex(_ newIndex: Int) {
        if currentIndex != newIndex {
            currentIndex = newIndex
            saveProgress()
        }
    }
    
    // NOT: Bu fonksiyon artık kullanılmayacak, sabit bir anahtar kullanıyoruz
    // Eski kodla uyumluluk için korundu
    func setProgressKey(_ key: String) {
        print("[FlashcardManager] setProgressKey çağrıldı, fakat sabit anahtar kullanıldığı için değişiklik yok: \(progressKey)")
        
        // Kaydedilmiş ilerlemeyi yükle
        let currentValue = currentIndex
        loadCurrentProgress()
        
        // Değişiklik olup olmadığını bildir
        if currentValue != currentIndex {
            print("[FlashcardManager] İlerleme yeniden yüklendi: \(currentValue) -> \(currentIndex)")
        }
    }
    
    // Bir sonraki kelimeye geç
    func moveToNextIndex(maxIndex: Int) {
        if currentIndex < maxIndex - 1 {
            currentIndex += 1
            saveProgress()
        }
    }
    
    // Önceki kelimeye geç
    func moveToPreviousIndex() {
        if currentIndex > 0 {
            currentIndex -= 1
            saveProgress()
        }
    }
    
    // İlerlemeyi sıfırla
    func resetProgress() {
        let oldValue = currentIndex
        currentIndex = 0
        saveProgress()
        print("[Hafıza] İndeks sıfırlandı: \(oldValue) -> \(currentIndex)")
    }
    
    // Şu anki ilerleme anahtarını al
    func getProgressKey() -> String {
        return progressKey
    }
}

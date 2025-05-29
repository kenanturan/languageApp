import Foundation

struct Config {
    // GitHub'daki yapılandırma dosyasının URL'si
    static let configUrl = "https://raw.githubusercontent.com/kenanturan/english-words/refs/heads/main/api.json"
    static let wordsBaseUrl = "https://raw.githubusercontent.com/kenanturan/english-words/refs/heads/main"
    
    // Varsayılan değerler
    private static let defaultChannelId = "UCASGyre6VNuPsF5f9f9nm8g"
    private static let defaultBaseUrl = "https://www.googleapis.com/youtube/v3"
    
    // Yapılandırma değerlerini saklayacak değişkenler
    private static var _apiKey: String? = nil
    private static var _channelId: String? = nil
    private static var _baseUrl: String? = nil
    
    // GitHub'dan en son ne zaman yapılandırma çekildiğini takip etmek için
    private static var lastConfigFetchTime: Date? = nil
    private static var isConfigLoading = false
    private static var configLoadSemaphore = DispatchSemaphore(value: 1)
    
    // API anahtarı önbelleğini temizle
    static func clearCache() {
        print("[Config] Önbellek temizleniyor...")
        _apiKey = nil
        _channelId = nil
        _baseUrl = nil
        lastConfigFetchTime = nil
    }
    
    // Yapılandırma değerlerini getirir
    static var apiKey: String {
        get {
            // Önbellekte geçerli bir API anahtarı varsa onu kullan
            if let key = _apiKey, !key.isEmpty {
                return key
            }
            
            // Eş zamanlılık kontrolü - sadece bir thread girsin
            configLoadSemaphore.wait()
            defer {
                configLoadSemaphore.signal()
            }
            
            // Önbellek boş - ilk kez veya hata sonrası GitHub'dan çek
            // API key boşsa ve yükleme işlemi devam etmiyorsa, yapılandırmayı yükle
            if !isConfigLoading {
                print("[Config] API anahtarı henüz yüklenmedi. GitHub'dan çekiliyor...")
                // Senkron olarak yapılandırmayı yükle
                let loadSemaphore = DispatchSemaphore(value: 0)
                
                // Yükleme durumunu değiştir
                isConfigLoading = true
                
                // GitHub'dan yapılandırma dosyasının URL'si
                if let url = URL(string: configUrl) {
                    print("[Config] GitHub'dan yapılandırma çekiliyor: \(configUrl)")
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.timeoutInterval = 10 // 10 saniye zaman aşımı
                    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                    
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        defer {
                            isConfigLoading = false
                            loadSemaphore.signal() // Her durumda sinyal gönder
                        }
                        
                        // HTTP yanıt kodunu kontrol et
                        if let httpResponse = response as? HTTPURLResponse {
                            print("[Config] GitHub yanıt kodu: \(httpResponse.statusCode)")
                        }
                        
                        guard let data = data, error == nil else {
                            print("[Config] Yapılandırma çekilemedi: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                            return
                        }
                        
                        // JSON verilerini yazdır
                        if let jsonStr = String(data: data, encoding: .utf8) {
                            print("[Config] Alınan JSON verileri: \(jsonStr)")
                        }
                        
                        do {
                            // JSON ayrıştırma
                            let decoder = JSONDecoder()
                            
                            struct ConfigModel: Codable {
                                let apiKey: String
                                let channelId: String?
                                let baseUrl: String?
                            }
                            
                            do {
                                let config = try decoder.decode(ConfigModel.self, from: data)
                                
                                // API key boş değilse senkron olarak değişkeni güncelle
                                if !config.apiKey.isEmpty {
                                    _apiKey = config.apiKey
                                    
                                    if let channelId = config.channelId {
                                        _channelId = channelId
                                    }
                                    
                                    if let baseUrl = config.baseUrl {
                                        _baseUrl = baseUrl
                                    }
                                    
                                    lastConfigFetchTime = Date()
                                    print("[Config] API key güncellendi: \(_apiKey ?? "boş")")
                                    print("[Config] API anahtarı başarıyla yüklendi: \(_apiKey ?? "null")")
                                } else {
                                    print("[Config] GitHub'dan alınan API anahtarı boş!")
                                }
                            } catch {
                                print("[Config] Codable ayrıştırma başarısız, JSONSerialization deneniyor: \(error)")
                                
                                // Alternatif olarak JSONSerialization dene
                                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                                   let apiKey = json["apiKey"] as? String, !apiKey.isEmpty {
                                    _apiKey = apiKey
                                    
                                    if let channelId = json["channelId"] as? String {
                                        _channelId = channelId
                                    }
                                    
                                    if let baseUrl = json["baseUrl"] as? String {
                                        _baseUrl = baseUrl
                                    }
                                    
                                    lastConfigFetchTime = Date()
                                    print("[Config] API key güncellendi (JSONSerialization): \(apiKey)")
                                    print("[Config] API anahtarı başarıyla yüklendi: \(_apiKey ?? "null")")
                                } else {
                                    print("[Config] Geçersiz yapılandırma verisi: JSON dönüştürme başarısız")
                                }
                            }
                        } catch {
                            print("[Config] Yapılandırma ayrıştırılamadı: \(error)")
                        }
                    }.resume()
                }
                
                // Maksimum 10 saniye bekle
                _ = loadSemaphore.wait(timeout: .now() + 10)
            }
            
            // Son bir kontrol
            if let key = _apiKey, !key.isEmpty {
                return key
            }
            
            // Hala yüklenemedi, hata mesajı
            print("[Config] HATA: API anahtarı yüklenemedi ve varsayılan bir değer de yok!")
            return ""
        }
    }
    
    static var channelId: String {
        get {
            // Önbellekte geçerli bir channel ID varsa onu kullan
            if let id = _channelId, !id.isEmpty {
                return id
            }
            
            // Channel ID önbellekte yoksa API key'in yüklenmesini sağla
            // Bu şekilde channel ID de yüklenebilir
            if _apiKey == nil {
                let _ = apiKey
            }
            
            if let id = _channelId, !id.isEmpty {
                return id
            }
            return defaultChannelId
        }
    }
    
    static var baseUrl: String {
        get {
            // Önbellekte geçerli bir baseURL varsa onu kullan
            if let url = _baseUrl, !url.isEmpty {
                return url
            }
            
            // Base URL önbellekte yoksa API key'in yüklenmesini sağla
            // Bu şekilde base URL de yüklenebilir
            if _apiKey == nil {
                let _ = apiKey
            }
            
            if let url = _baseUrl, !url.isEmpty {
                return url
            }
            return defaultBaseUrl
        }
    }
    
    // Uygulama başlangıcında yapılandırmayı yükleme (splash screen sırasında)
    static func preloadConfiguration() {
        // apiKey'e erişerek konfigürasyonun yüklenmesini zorla
        let _ = apiKey
    }
    
    // Kanal ID'sini manuel olarak değiştirmek için fonksiyon
    static func setChannelId(_ newChannelId: String) {
        _channelId = newChannelId
    }
    
    // YouTube API hatası durumunda çağrılacak fonksiyon
    static func refreshAfterAPIFailure(completion: @escaping (Bool) -> Void) {
        print("[Config] YouTube API hatası nedeniyle API anahtarı yenileniyor...")
        // Önbelleği temizle ve yeni anahtar çek
        clearCache()
        loadAPIKey(completion: completion)
    }
    
    // GitHub'dan API anahtarını yükle (eğer belirtilirse önbelleği temizleyerek)
    static func loadAPIKey(completion: @escaping (Bool) -> Void) {
        // Yükleme durumunu değiştir
        isConfigLoading = true
        
        // GitHub'dan yapılandırma çekme
        if let url = URL(string: configUrl) {
            print("[Config] GitHub'dan yapılandırma zorla çekiliyor: \(configUrl)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData // Önbelleği atla
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                defer {
                    isConfigLoading = false
                }
                
                // HTTP yanıt kodunu kontrol et
                if let httpResponse = response as? HTTPURLResponse {
                    print("[Config] GitHub yanıt kodu: \(httpResponse.statusCode)")
                }
                
                guard let data = data, error == nil else {
                    print("[Config] Yapılandırma çekilemedi: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                // JSON verilerini yazdır
                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("[Config] Alınan JSON verileri: \(jsonStr)")
                }
                
                do {
                    // JSON ayrıştırma
                    let decoder = JSONDecoder()
                    
                    struct ConfigModel: Codable {
                        let apiKey: String
                        let channelId: String?
                        let baseUrl: String?
                    }
                    
                    do {
                        let config = try decoder.decode(ConfigModel.self, from: data)
                        
                        // API key boş değilse senkron olarak değişkeni güncelle
                        if !config.apiKey.isEmpty {
                            _apiKey = config.apiKey
                            
                            if let channelId = config.channelId {
                                _channelId = channelId
                            }
                            
                            if let baseUrl = config.baseUrl {
                                _baseUrl = baseUrl
                            }
                            
                            lastConfigFetchTime = Date()
                            print("[Config] API key zorla güncellendi: \(_apiKey ?? "boş")")
                            print("[Config] API anahtarı başarıyla zorla yüklendi: \(_apiKey ?? "null")")
                            
                            DispatchQueue.main.async {
                                completion(true)
                            }
                        } else {
                            print("[Config] GitHub'dan alınan API anahtarı boş!")
                            DispatchQueue.main.async {
                                completion(false)
                            }
                        }
                    } catch {
                        print("[Config] Codable ayrıştırma başarısız, JSONSerialization deneniyor: \(error)")
                        
                        // Alternatif olarak JSONSerialization dene
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let apiKey = json["apiKey"] as? String, !apiKey.isEmpty {
                            _apiKey = apiKey
                            
                            if let channelId = json["channelId"] as? String {
                                _channelId = channelId
                            }
                            
                            if let baseUrl = json["baseUrl"] as? String {
                                _baseUrl = baseUrl
                            }
                            
                            lastConfigFetchTime = Date()
                            print("[Config] API key güncellendi (JSONSerialization): \(apiKey)")
                            print("[Config] API anahtarı başarıyla yüklendi: \(_apiKey ?? "null")")
                            
                            DispatchQueue.main.async {
                                completion(true)
                            }
                        } else {
                            print("[Config] Geçersiz yapılandırma verisi: JSON dönüştürme başarısız")
                            DispatchQueue.main.async {
                                completion(false)
                            }
                        }
                    }
                } catch {
                    print("[Config] Yapılandırma ayrıştırılamadı: \(error)")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }.resume()
        } else {
            print("[Config] Geçersiz yapılandırma URL'si")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}

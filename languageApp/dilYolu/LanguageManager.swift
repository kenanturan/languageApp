import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case turkish = "tr"
    case german = "de"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case arabic = "ar"
    case chinese = "zh"

    var nativeName: String {
        switch self {
        case .arabic: return "العربية"
        case .german: return "Deutsch"
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .turkish: return "Türkçe"
        case .chinese: return "中文"
        }
    }

    var displayName: String {
        switch self {
        case .arabic: return "Arabic"
        case .german: return "German"
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .russian: return "Russian"
        case .turkish: return "Turkish"
        case .chinese: return "Chinese"
        }
    }

    var id: String { rawValue }
}

class LanguageManager {
    static let shared = LanguageManager()
    
    private init() {}
    
    func getCurrentLanguage() -> AppLanguage {
        let current = Locale.current.language.languageCode?.identifier ?? "tr"
        return AppLanguage(rawValue: current) ?? .turkish
    }
    
    func setLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: "AppLanguage")
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Bundle'ı zorla yeniden yükle
        if let languageBundlePath = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let languageBundle = Bundle(path: languageBundlePath) {
            // Tüm string'leri yeniden yükle
            Bundle.main.localizations.forEach { _ in
                let _ = languageBundle.localizedString(forKey: "dummy", value: nil, table: nil)
            }
        }
        
        // Notification gönder
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
    }
    
    func getStoredLanguage() -> AppLanguage {
        if let lang = UserDefaults.standard.string(forKey: "AppLanguage"),
           let appLang = AppLanguage(rawValue: lang) {
            return appLang
        }
        return .turkish
    }
}

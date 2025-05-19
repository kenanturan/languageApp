import Foundation
import Combine

class TextGenerationService {
    static let shared = TextGenerationService()
    private init() {}
    
    private var apiKey: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    // API anahtarını GitHub'dan al
    func fetchApiKey(completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://raw.githubusercontent.com/kenanturan/english-words/refs/heads/main/metin.json")!
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    print("API anahtarı alma hatası: \(error.localizedDescription)")
                    completion(nil)
                }
            }, receiveValue: { response in
                // API anahtar formatını düzeltme
                var formattedKey = response.apiKey
                // "sk-" önekini kaldır (Groq API anahtarları gsk_ ile başlar)
                if formattedKey.hasPrefix("sk-") {
                    formattedKey = String(formattedKey.dropFirst(3))
                }
                self.apiKey = formattedKey
                print("API anahtarı başarıyla alındı ve düzeltildi: \(formattedKey)")
                completion(formattedKey)
            })
            .store(in: &cancellables)
    }
    
    // DeepSeek'e istek gönder ve yanıtı al
    func generateText(from words: [String], completion: @escaping (Result<String, Error>) -> Void) {
        // API anahtarını kontrol et, yoksa fetch et
        if apiKey.isEmpty {
            print("API anahtarı boş, GitHub'dan alınıyor...")
            fetchApiKey { [weak self] key in
                guard let key = key else {
                    completion(.failure(NSError(domain: "TextGenerationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "API anahtarı alınamadı"])))
                    return
                }
                self?.sendRequest(words: words, completion: completion)
            }
        } else {
            sendRequest(words: words, completion: completion)
        }
    }
    
    private func sendRequest(words: [String], completion: @escaping (Result<String, Error>) -> Void) {
        // Groq API endpoint'i
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Kelimelerden bir metin oluşturma promtu hazırla
        let wordsText = words.joined(separator: ", ")
        let combinedPrompt = "You are a helpful language tutor assistant that creates short, engaging texts for BEGINNER level students. Create a short interesting text at BEGINNER level that includes SOME OR ALL of these words: \(wordsText). You don't have to use every word, focus on creating a natural, coherent text using whichever words fit well. The text should be very simple and educational for beginner language learners. Use basic vocabulary and simple sentence structures. IMPORTANT: Start directly with the story content, do not include phrases like 'Here is a short text' or any other introductory statements."
        
        // Groq API formatına uygun JSON gövdesi - sadece bir user mesajı gönderiyoruz
        let body: [String: Any] = [
            "model": "meta-llama/llama-4-scout-17b-16e-instruct",
            "messages": [
                ["role": "user", "content": combinedPrompt]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("JSON formatlama hatası: \(error)")
            completion(.failure(error))
            return
        }
        
        print("Groq'a istek gönderiliyor. Prompt: \(combinedPrompt)")
        
        // URLSession.dataTask ile istek gönder (örnek koda benzer)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // HTTP yanıt kodunu kontrol et
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP yanıt kodu: \(httpResponse.statusCode)")
            }
            
            if let error = error {
                print("Bağlantı hatası: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                print("Veri gelmedi")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "TextGenerationService", code: 1, 
                                             userInfo: [NSLocalizedDescriptionKey: "API'den veri gelmedi"])))
                }
                return
            }
            
            // Ham yanıtı göster
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Groq API yanıtı:\n\(jsonString)")
                
                // Hata kontrolleri
                if jsonString.contains("error") {
                    print("Groq API hata döndürdü")
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "TextGenerationService", code: 2, 
                                                 userInfo: [NSLocalizedDescriptionKey: "API hata döndürdü: \(jsonString)"])))  
                    }
                    return
                }
                
                // Groq API yanıt formatını işle (OpenAI formatına benzerdir)
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = jsonDict["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        // Başarılı şekilde metin elde edildi
                        DispatchQueue.main.async {
                            completion(.success(content))
                        }
                    } else {
                        // JSON formatı beklenenden farklı, ham yanıtı döndür
                        print("Groq yanıt formatı beklenenden farklı")
                        DispatchQueue.main.async {
                            completion(.success(jsonString))
                        }
                    }
                } catch {
                    print("JSON ayrıştırma hatası: \(error)")
                    // JSON ayrıştırma başarısız olsa bile ham metni gönder
                    DispatchQueue.main.async {
                        completion(.success(jsonString))
                    }
                }
            } else {
                print("Yanıt metin olarak ayrıştırılamadı")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "TextGenerationService", code: 3, 
                                             userInfo: [NSLocalizedDescriptionKey: "Yanıt metin olarak ayrıştırılamadı"])))  
                }
            }
        }
        
        task.resume()
    }
    
    // İngilizce metni Türkçe'ye çevirme fonksiyonu
    func translateText(_ englishText: String, completion: @escaping (Result<String, Error>) -> Void) {
        // API anahtarını kontrol et, yoksa fetch et
        if apiKey.isEmpty {
            print("API anahtarı boş, GitHub'dan alınıyor...")
            fetchApiKey { [weak self] key in
                guard let key = key else {
                    completion(.failure(NSError(domain: "TextGenerationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "API anahtarı alınamadı"])))
                    return
                }
                self?.sendTranslationRequest(englishText: englishText, completion: completion)
            }
        } else {
            sendTranslationRequest(englishText: englishText, completion: completion)
        }
    }
    
    private func sendTranslationRequest(englishText: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Groq API endpoint'i
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Çeviri promtu hazırla
        let combinedTranslationPrompt = "You are a professional translator specialized in translating English to Turkish. Translate the following English text to Turkish. Provide ONLY the translation without any additional comments or explanations:\n\n\(englishText)"
        
        // Groq API formatına uygun JSON gövdesi - sadece bir user mesajı gönderiyoruz
        let body: [String: Any] = [
            "model": "meta-llama/llama-4-scout-17b-16e-instruct",
            "messages": [
                ["role": "user", "content": combinedTranslationPrompt]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("JSON formatlama hatası: \(error)")
            completion(.failure(error))
            return
        }
        
        print("Groq'a çeviri isteği gönderiliyor...")
        
        // URLSession.dataTask ile istek gönder
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // HTTP yanıt kodunu kontrol et
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP yanıt kodu: \(httpResponse.statusCode)")
            }
            
            if let error = error {
                print("Bağlantı hatası: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                print("Veri gelmedi")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "TextGenerationService", code: 1, 
                                             userInfo: [NSLocalizedDescriptionKey: "API'den veri gelmedi"])))
                }
                return
            }
            
            // Ham yanıtı işle
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Groq API çeviri yanıtı alındı")
                
                // Hata kontrolleri
                if jsonString.contains("error") {
                    print("Groq API hata döndürdü")
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "TextGenerationService", code: 2, 
                                                 userInfo: [NSLocalizedDescriptionKey: "API hata döndürdü: \(jsonString)"])))
                    }
                    return
                }
                
                // Groq API yanıt formatını işle
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = jsonDict["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        // Başarılı şekilde çeviri elde edildi
                        DispatchQueue.main.async {
                            completion(.success(content))
                        }
                    } else {
                        // JSON formatı beklenenden farklı, ham yanıtı döndür
                        print("Groq yanıt formatı beklenenden farklı")
                        DispatchQueue.main.async {
                            completion(.success(jsonString))
                        }
                    }
                } catch {
                    print("JSON ayrıştırma hatası: \(error)")
                    // JSON ayrıştırma başarısız olsa bile ham metni gönder
                    DispatchQueue.main.async {
                        completion(.success(jsonString))
                    }
                }
            } else {
                print("Yanıt metin olarak ayrıştırılamadı")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "TextGenerationService", code: 3, 
                                             userInfo: [NSLocalizedDescriptionKey: "Yanıt metin olarak ayrıştırılamadı"])))
                }
            }
        }
        
        task.resume()
    }
}

// API yanıtı modellemesi
struct ApiResponse: Codable {
    let apiKey: String
}

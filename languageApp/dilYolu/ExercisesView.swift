import SwiftUI
import CoreData

struct ExercisesView: View {
    @FetchRequest(
        entity: RememberedWord.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RememberedWord.date, ascending: false)]
    ) var rememberedWords: FetchedResults<RememberedWord>
    
    @State private var generatedText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showTranslation = false
    @State private var translatedText: String = ""
    @State private var isTranslationLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    if rememberedWords.isEmpty {
                        // Ezberlenen kelime yoksa
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 70))
                                .foregroundColor(.gray.opacity(0.7))
                            Text(NSLocalizedString("no_words_memorized", comment: "No words memorized yet"))
                                .font(.title2.bold())
                            Text(NSLocalizedString("memorize_words_first", comment: "Instruction to memorize words first"))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 50)
                    } else {
                        // Ezberlenen kelime varsa
                        VStack {
                            // Ezberlenen kelime sayısı bilgisi
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.yellow)
                                
                                Text(String(format: NSLocalizedString("can_practice_with_words", comment: "Number of words available for practice"), rememberedWords.count))
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .padding(.bottom, 10)
                            
                            // Metin oluşturma butonu
                            Button(action: {
                                generateTextFromAllWords()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "text.badge.plus")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(NSLocalizedString("generate_text", comment: "Generate text button"))
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(#colorLiteral(red: 0.2, green: 0.8, blue: 0.4, alpha: 1)), Color(#colorLiteral(red: 0.1, green: 0.7, blue: 0.3, alpha: 1))]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .disabled(isLoading)
                            .padding(.bottom, 10)
                            
                            if isLoading {
                                ProgressView(NSLocalizedString("generating_text", comment: "Text generation progress"))
                                    .padding()
                            }
                            
                            if !generatedText.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(NSLocalizedString("exercise_text", comment: "Exercise text title"))
                                        .font(.headline)
                                    
                                    Text(generatedText)
                                        .padding()
                                        .background(Color.yellow.opacity(0.1))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                        )
                                    
                                    HStack(spacing: 10) {
                                        Button(action: {
                                            // Türkçe çevirisini göster/gizle
                                            if showTranslation && !translatedText.isEmpty {
                                                // Zaten çeviri görünüyorsa gizle
                                                showTranslation = false
                                            } else if translatedText.isEmpty {
                                                // Çeviri henüz yoksa, yeni çeviri iste
                                                translateGeneratedText()
                                            } else {
                                                // Çeviri var ama gizliyse, göster
                                                showTranslation = true
                                            }
                                        }) {
                                            HStack(spacing: 10) {
                                                Image(systemName: showTranslation ? "eye.slash" : "eye")
                                                    .font(.system(size: 15, weight: .medium))
                                                Text(showTranslation ? NSLocalizedString("hide_translation", comment: "Hide translation button") : NSLocalizedString("show_turkish_translation", comment: "Show Turkish translation button"))
                                                    .font(.system(size: 15, weight: .medium))
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color(#colorLiteral(red: 0.2, green: 0.5, blue: 0.9, alpha: 1)), Color(#colorLiteral(red: 0.1, green: 0.4, blue: 0.8, alpha: 1))]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .cornerRadius(16)
                                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                                        }
                                        .disabled(isLoading || isTranslationLoading)
                                    }
                                    
                                    if isTranslationLoading {
                                        ProgressView("Çeviriliyor...")
                                            .padding()
                                    }
                                    
                                    if showTranslation && !translatedText.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(NSLocalizedString("turkish_translation", comment: "Turkish translation label"))
                                                .font(.headline)
                                                .padding(.top, 8)
                                            
                                            Text(translatedText)
                                                .padding()
                                                .background(Color.green.opacity(0.1))
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(15)
                            }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }
    
    // Tüm ezberlenen kelimelerden metin oluştur
    private func generateTextFromAllWords() {
        guard !rememberedWords.isEmpty else {
            errorMessage = "Ezberlenmiş kelime bulunamadı"
            return
        }
        
        // Tüm ezberlenen kelimeleri çıkar
        let wordArray = rememberedWords.compactMap { $0.word }
        guard !wordArray.isEmpty else {
            errorMessage = "Geçerli kelime bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        TextGenerationService.shared.generateText(from: Array(wordArray)) { result in
            isLoading = false
            
            switch result {
            case .success(let text):
                generatedText = text
            case .failure(let error):
                errorMessage = "Metin oluşturulurken hata: \(error.localizedDescription)"
                print("Metin oluşturma hatası: \(error)")
            }
        }
    }
    
    // Oluşturulan metni Türkçe'ye çevir
    private func translateGeneratedText() {
        guard !generatedText.isEmpty else {
            errorMessage = "Çevrilecek metin bulunamadı"
            return
        }
        
        isTranslationLoading = true
        
        TextGenerationService.shared.translateText(generatedText) { result in
            isTranslationLoading = false
            
            switch result {
            case .success(let text):
                translatedText = text
                showTranslation = true
            case .failure(let error):
                errorMessage = "Çeviri sırasında hata: \(error.localizedDescription)"
                print("Çeviri hatası: \(error)")
            }
        }
    }
}

#Preview {
    ExercisesView()
}

import SwiftUI

struct GoalRow: View {
    let goal: Goal
    @FetchRequest(
        entity: WatchedVideo.entity(),
        sortDescriptors: []
    ) var watchedVideos: FetchedResults<WatchedVideo>
    @FetchRequest(
        entity: RememberedWord.entity(),
        sortDescriptors: []
    ) var rememberedWords: FetchedResults<RememberedWord>
    
    // Kutlamayı yerel bir state yerine kalıcı takip sistemiyle izliyoruz
    @State private var isCheckingCompletion = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                // Hedef tür ikonu
                ZStack {
                    Circle()
                        .fill(goalTypeColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: (goal.type ?? "") == "video" ? "play.rectangle.fill" : "text.book.closed.fill")
                        .foregroundColor(goalTypeColor)
                        .font(.system(size: 18, weight: .medium))
                }
                .padding(.trailing, 6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.type == "video" ? "Video İzleme" : "Kelime Ezberleme")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let deadline = goal.deadline {
                        Text("Son tarih: \(dateString(deadline))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Hedef Sayısı Rozeti
                ZStack {
                    Capsule()
                        .fill(goalTypeColor.opacity(0.15))
                        .frame(height: 30)
                    Text("Hedef: \(goal.targetCount)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(goalTypeColor)
                        .padding(.horizontal, 10)
                }
            }
            
            // İlerleme Çubuğu
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("İlerleme: %\(Int(progress * 100))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(currentCount)/\(goal.targetCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Arkaplan
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 10)
                        
                        // İlerleme
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    goalTypeColor.opacity(0.7), 
                                    goalTypeColor
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(0, min(geometry.size.width * CGFloat(progress), geometry.size.width)), height: 10)
                    }
                }
                .frame(height: 10)
            }
            
            // Alt Detaylar
            HStack(spacing: 16) {
                if (goal.type ?? "") == "video" {
                    let watchedCount = watchedVideos.filter { video in
                        if let start = goal.createDate, let end = goal.deadline, let date = video.watchedDate {
                            return date >= start && date <= end
                        } else if let start = goal.createDate, let date = video.watchedDate {
                            return date >= start
                        } else if let end = goal.deadline, let date = video.watchedDate {
                            return date <= end
                        }
                        return true
                    }.count
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("İzlenen: \(watchedCount)")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "circle")
                            .foregroundColor(.orange)
                        Text("Kalan: \(max(0, goal.targetCount - Int32(watchedCount)))")
                    }
                } else if (goal.type ?? "") == "kelime" {
                    let rememberedCount = rememberedWords.count
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Ezberlenen: \(rememberedCount)")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "circle")
                            .foregroundColor(.orange)
                        Text("Kalan: \(max(0, goal.targetCount - Int32(rememberedCount)))")
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        // Görünüm oluşturulduğunda hedef tamamlanma durumunu kontrol et
        .onAppear {
            checkGoalCompletion()
        }
        // Progress değiştiğinde hedef tamamlanma durumunu takip et
        .onChange(of: progress) { newProgress in
            checkGoalCompletion()
        }
    }
    
    // Hedef tamamlanma durumunu kontrol et ve kutlama göster
    private func checkGoalCompletion() {
        // İki defa çağrılmasını önlemek için bayrak kullan
        if isCheckingCompletion {
            return
        }
        
        isCheckingCompletion = true
        
        // Hedef tamamlandıysa ve daha önce kutlanmadıysa
        if progress >= 1.0 && !GoalCelebrationTracker.shared.hasGoalBeenCelebrated(goal) {
            // Hedef türüne göre mesajı belirle
            let message = (goal.type ?? "") == "video" ?
                "Tebrikler! \(goal.targetCount) Video İzleme Hedefine Ulaştın! 🎉" :
                "Tebrikler! \(goal.targetCount) Kelime Ezberleme Hedefine Ulaştın! 🎉"
            
            // Hedefi kutlandı olarak işaretle
            GoalCelebrationTracker.shared.markGoalAsCelebrated(goal)
            
            // Kısa bir gecikme ile kutlama animasyonunu göster
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                CelebrationManager.shared.showCelebration(message: message)
                self.isCheckingCompletion = false
            }
        } else {
            // Kutlama gösterilmeyecekse bayrağı sıfırla
            isCheckingCompletion = false
        }
    }
    
    // Progress hesaplama
    private var currentCount: Int32 {
        if (goal.type ?? "") == "video" {
            let watchedCount = watchedVideos.filter { video in
                if let start = goal.createDate, let end = goal.deadline, let date = video.watchedDate {
                    return date >= start && date <= end
                } else if let start = goal.createDate, let date = video.watchedDate {
                    return date >= start
                } else if let end = goal.deadline, let date = video.watchedDate {
                    return date <= end
                }
                return true
            }.count
            return Int32(watchedCount)
        } else if (goal.type ?? "") == "kelime" {
            return Int32(rememberedWords.count)
        }
        return 0
    }
    
    private var progress: Double {
        return Double(currentCount) / max(1, Double(goal.targetCount))
    }
    
    // Hedef tipine göre renk
    private var goalTypeColor: Color {
        return (goal.type ?? "") == "video" ? Color.blue : Color.purple
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

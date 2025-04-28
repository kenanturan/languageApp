import SwiftUI

struct DaySummarySheet: View {
    let date: Date
    let goals: [Goal]
    let watchedVideoCount: Int
    let rememberedWordCount: Int
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(formattedDate)
                .font(.title3)
                .bold()
                .padding(.top)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Toplam Hedef: \(goals.count)")
                Text("İzlenen Video: \(watchedVideoCount)")
                Text("Ezberlenen Kelime: \(rememberedWordCount)")
            }
            .font(.headline)
            Spacer()
        }
        .padding()
        .presentationDetents([.height(220)])
    }
}

#Preview {
    DaySummarySheet(date: Date(), goals: [], watchedVideoCount: 2, rememberedWordCount: 5)
}

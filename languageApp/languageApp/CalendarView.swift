import SwiftUI

struct CalendarView: View {
    @State private var selectedDate: Date = Date()
    var onDateSelected: ((Date) -> Void)? = nil
    
    // Tamamlanan günlerin listesi
    var completedDates: [Date] = []
    // Tüm hedefler
    var allGoals: [Goal] = []
    
    var body: some View {
    // Use Turkish locale for the calendar
    let turkishLocale = Locale(identifier: "tr_TR")
    let turkishCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = turkishLocale
        calendar.firstWeekday = 2 // Monday
        return calendar
    }()
    let daySymbols = turkishCalendar.veryShortStandaloneWeekdaySymbols // ["P", "S", "Ç", ...]

        VStack {
            // Turkish day-of-week header, starting from Monday
            HStack(spacing: 0) {
                ForEach(0..<7) { i in
                    let index = (i + turkishCalendar.firstWeekday - 1) % 7
                    Text(daySymbols[index].capitalized)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 2)

            ZStack(alignment: .topLeading) {
                // Ana DatePicker
                DatePicker(
                    "Tarih Seç",
                    selection: Binding(
                        get: { selectedDate },
                        set: { newDate in
                            selectedDate = newDate
                            onDateSelected?(newDate)
                        }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .environment(\.locale, turkishLocale)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .scaleEffect(0.85)
                .frame(height: 300)
                
                // Tamamlanan günler için işaretleri göster
                GeometryReader { geometry in
                    ForEach(0..<42) { index in // Takvimde maksimum 42 gün görüntülenebilir (6 hafta x 7 gün)
                        let dayDate = self.dateFor(dayIndex: index, baseDate: selectedDate)
                        if self.isDateCompleted(dayDate) {
                            // Yeşil tik işareti
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                                .position(self.positionFor(dayIndex: index, in: geometry))
                        }
                    }
                }
                .frame(height: 300)
            }
        }
        .navigationTitle("Takvim")
    }
    
    // Bir tarihin hedeflerinin tamamlanıp tamamlanmadığını kontrol et
    private func isDateCompleted(_ date: Date) -> Bool {
        return GoalsView.areGoalsCompletedForDate(allGoals, date: date)
    }
    
    // Belirli bir gün indeksi için tarih hesapla (görüntülenen ay bazında)
    private func dateFor(dayIndex: Int, baseDate: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "tr_TR")
        calendar.firstWeekday = 2 // Monday

        // Ay başlangıcını bul
        let components = calendar.dateComponents([.year, .month], from: baseDate)
        guard let startOfMonth = calendar.date(from: components) else { return Date() }

        // Ayın ilk gününün haftanın hangi günü olduğunu bul
        let weekdayOfFirstDay = calendar.component(.weekday, from: startOfMonth)

        // Haftanın ilk günü Pazartesi olacak şekilde kaydırma
        let shift = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
        let dayOffset = dayIndex - shift

        return calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) ?? Date()
    }
    
    // Gün indeksi için yaklaşık pozisyon hesapla
    private func positionFor(dayIndex: Int, in geometry: GeometryProxy) -> CGPoint {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "tr_TR")
        calendar.firstWeekday = 2 // Monday
        let width = geometry.size.width
        let height = geometry.size.height
        
        // Takvim matrisindeki satır ve sütun hesapla (0-indexed)
        let column = dayIndex % 7
        let row = dayIndex / 7
        
        // Yaklaşık konum
        let cellWidth = width / 7
        let cellHeight = height / 6 // 6 haftalık maksimum takvim yüksekliği
        
        // Haftanın günlerine göre düzenle (Pazar-Cumartesi)
        return CGPoint(
            x: cellWidth * CGFloat(column) + cellWidth * 0.5 + 20,
            y: cellHeight * CGFloat(row) + cellHeight * 0.5 + 40
        )
    }
}

// CalendarView'ın yeni initializerını ekle
extension CalendarView {
    init(onDateSelected: ((Date) -> Void)? = nil, allGoals: [Goal] = []) {
        self.onDateSelected = onDateSelected
        self.allGoals = allGoals
    }
}

#Preview {
    CalendarView()
}

//
//  ContentView.swift
//  languageApp
//
//  Created by testing on 22.04.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VideoListView()
                .tabItem {
                    Label("Videolar", systemImage: "play.rectangle.fill")
                }
                .tag(0)
            
            RememberedWordsView()
                .tabItem {
                    Label("Kelimeler", systemImage: "text.book.closed.fill")
                }
                .tag(1)
            
            GoalsView(isActive: selectedTab == 2)
                .tabItem {
                    Label("Hedefler", systemImage: "target")
                }
                .tag(2)
        }
        .accentColor(.blue) // Aktif sekme rengi
        .celebration() // Kutlama animasyonunu tüm uygulamaya ekle
        .onAppear {
            // TabBar görünümünü iyileştir
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Normal TabBar arkaplanı için gölge ve çizgi ekleme
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
            
            // TabBar öğelerinin stilini ayarla
            let itemAppearance = UITabBarItemAppearance()
            
            // Seçili durum (normal, seçili, vb.)
            itemAppearance.normal.iconColor = UIColor.gray
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
            
            itemAppearance.selected.iconColor = UIColor.systemBlue
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
            
            appearance.stackedLayoutAppearance = itemAppearance
            
            // Ayarları uygula
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}

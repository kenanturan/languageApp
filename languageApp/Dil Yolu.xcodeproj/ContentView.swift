//
//  ContentView.swift
//  languageApp
//
//  Created by testing on 22.04.2025.
//

import SwiftUI
import Combine
import CoreData

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var languageManager = AppLanguageManager.shared
    @State private var languageUpdateTrigger = false  // Dil değişikliğini tetiklemek için
    
    var body: some View {
        VStack(spacing: 0) {
            // Language Dropdown Menu moved to VideoListViewController
            
            TabView(selection: $selectedTab) {
                VideoListView()
                    .tabItem {
                        Label(NSLocalizedString("tab_videos", comment: "Videos tab"), systemImage: "play.rectangle.fill")
                    }
                    .tag(0)
                
                RememberedWordsView()
                    .tabItem {
                        Label(NSLocalizedString("tab_words", comment: "Words tab"), systemImage: "text.book.closed.fill")
                    }
                    .tag(1)
                
                GoalsView(isActive: selectedTab == 2)
                    .tabItem {
                        Label(NSLocalizedString("tab_goals", comment: "Goals tab"), systemImage: "target")
                    }
                    .tag(2)
                
                ExercisesView()
                    .tabItem {
                        Label(NSLocalizedString("tab_exercises", comment: "Exercises tab"), systemImage: "figure.run")
                    }
                    .tag(3)
            }
            .accentColor(.blue) // Active tab color
            .celebration() // Add celebration animation to the entire app
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            languageUpdateTrigger.toggle()  // View'u yeniden render et
        }
            .onAppear {
                // Improve TabBar appearance
                let appearance = UITabBarAppearance()
                appearance.backgroundColor = UIColor.systemBackground
                
                // Add shadow and line for normal TabBar background
                appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
                
                // Set style for TabBar items
                let itemAppearance = UITabBarItemAppearance()
                
                // Selected state (normal, selected, etc.)
                itemAppearance.normal.iconColor = UIColor.gray
                itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
                
                itemAppearance.selected.iconColor = UIColor.systemBlue
                itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
                
                appearance.stackedLayoutAppearance = itemAppearance
                
                // Apply settings
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }

#Preview {
    ContentView()
}

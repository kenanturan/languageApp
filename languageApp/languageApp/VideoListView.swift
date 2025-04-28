import SwiftUI

struct VideoListView: View {
    var body: some View {
        // UIKit kontrolcüsünü SwiftUI NavigationView içinde sarmalama
        NavigationView {
            VideoListViewControllerWrapper()
                .edgesIgnoringSafeArea(.all) // Ekranın tamamını kullan
                .navigationBarHidden(true) // SwiftUI navigation bar'ı gizle, UIKit'inkini kullan
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// UIKit kontrolcüsünü sarmalayan yapı
struct VideoListViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = VideoListViewController()
        
        // UINavigationController içine yerleştir
        // böylece butonlar görünür olacak
        let navController = UINavigationController(rootViewController: viewController)
        navController.navigationBar.prefersLargeTitles = true
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Updates handled by the view controller itself
    }
}

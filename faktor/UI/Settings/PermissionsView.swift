import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        
        OnboardingTaskList()
            .padding(40)
        
    }
}

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsView()
            .frame(width: 600, height: 500)
            .fixedSize()
        
        
    }
    
}

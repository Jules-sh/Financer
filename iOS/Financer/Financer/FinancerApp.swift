//
//  FinancerApp.swift
//  Financer
//
//  Created by Julian Schumacher on 21.12.22.
//

import SwiftUI

/// The main Struct in this App.
/// This has the @main Annotation, indicating, that
/// this is the entrance point for this App.
@main
struct FinancerApp: App {
    
    /// The Persistence Controller used in this App.
    ///
    /// The Context of this Controller is injeected into the
    /// environment via the .environment modifier which is available on
    /// the view struct.
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            Home()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    SettingsBundleHelper.shared.setValues()
                }
        }
    }
}

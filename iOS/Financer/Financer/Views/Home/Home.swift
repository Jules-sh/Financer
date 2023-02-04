//
//  ContentView.swift
//  Financer
//
//  Created by Julian Schumacher as ContentView.swift on 21.12.22.
//  Renamed by Julian Schumacher to Home.swift on 02.01.23
//

import Charts
import CoreData
import SwiftUI

/// The first View shown to the User when opening
/// the App.
internal struct Home: View {
    /// The ViewContext to use when interacting with the Core Data Framework
    @Environment(\.managedObjectContext) private var viewContext
    
    /// The Wrapper of the User of this App
    @EnvironmentObject private var userWrapper : UserWrapper
    
    /// The Environment Object which contains the current Finance
    @EnvironmentObject private var financeWrapper : FinanceWrapper
    
    /// The Legal Person Wrapper to contain the Legal Person
    /// this Finance belongs to.
    @StateObject private var legalPersonWrapper : LegalPersonWrapper = LegalPersonWrapper()
    
    // Preview Code Start
    // (Comment to build)
    //
    // This Code is used in development because it works with the preview.
    // Solution from: https://developer.apple.com/forums/thread/654126
    
    /// The Finances fetched from
    /// the Core Database
    @FetchRequest(fetchRequest: financeFetchRequest)
    private var finances : FetchedResults<Finance>
    
    /// This is the fetch Request to fetch all the Finances
    /// from the Core Data Persistence Storage
    static private var financeFetchRequest : NSFetchRequest<Finance> {
        let request = Finance.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \Finance.date,
                ascending: false
            )
        ]
        return request
    }
    // Preview Code End
    
    
    // Production Code Start
    // (Uncomment to build)
    //
    // This Code is used in production, becasue this Code
    // is generated by Apple and it is shorter.
    // This just doesn't work with the Preview
    
    /// The Finances fetched form the
    /// Code Database.
    //    @FetchRequest(
    //        sortDescriptors: [
    //            SortDescriptor(\Finance.date, order: .reverse)
    //        ]
    //    ) private var finances : FetchedResults<Finance>
    // Production Code End
    
    /// Whether the Add View is presented or not.
    @State private var addPresented : Bool = false
    
    /// Whether the details View for a finance is presented or not.
    @State private var detailsPresented : Bool = false
    
    /// Whether the Chart Details View is presented or not.
    @State private var chartsPresented : Bool = false
    
    /// Whether the User Details are presented or not
    @State private var userDetailsPresented : Bool = false
    
    /// Whether the Dialog to confirm a delete is shown or not
    @State private var deletePeriodicalFinancePresented : Bool = false
    
    /// Whether the User currently wants to delete the periodical finances or not
    @State private var periodicalFinanceToDeleteAfterConfirmation : Finance? = nil
    
    /// Whether to delete the Finance from the Details View or not
    @State private var deleteFinanceFromDetails : Bool = false
    
    /// Whether the Error Alert Dialog when saving data is presented or not.
    @State private var errSavingPresented : Bool = false
    
    /// The Boolean value indicating to delete the Finance
    @State private var delete : Bool = false
    
    var body: some View {
        NavigationStack {
            homeBuilder()
            
            Button {
                addPresented.toggle()
            } label: {
                Label("Add Finance", systemImage: "plus")
            }
            .sheet(
                isPresented: $addPresented,
                content: {
                    AddFinance()
                        .environmentObject(legalPersonWrapper)
                        .environmentObject(userWrapper)
                }
            )
            .onAppear {
                setPeriodicalFinances()
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbarRole(.navigationStack)
            .toolbar(.automatic, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        UserDetails()
                            .environmentObject(userWrapper)
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .renderingMode(.original)
                            .foregroundColor(.black)
                    }
                }
            }
            .alert(
                "Error",
                isPresented: $errSavingPresented
            ) {
                
            } message: {
                Text(
                    "Error processing Data\nPlease restard the App\n\nIf this Error occurs again, please contact the support."
                )
            }
        }
    }
    
    /// Builds, renders and returns the Home
    /// depending on the List of Finances
    @ViewBuilder
    private func homeBuilder() -> some View {
        if finances.isEmpty {
            Spacer()
            VStack {
                Text("No Finances added yet.")
                Button("Add one") {
                    addPresented.toggle()
                }
            }
            Spacer()
        } else {
            List {
                Section {
                    Button {
                        chartsPresented.toggle()
                    } label: {
                        // Date comparing from: https://www.hackingwithswift.com/example-code/language/how-to-compare-dates
                        // Date calculation from: https://stackoverflow.com/questions/29465205/how-to-add-minutes-to-current-time-in-swift
                        // Answer here: https://stackoverflow.com/a/29465300/16376071
                        chart()
                    }
                    .sheet(isPresented: $chartsPresented) {
                        ChartDetails(balances: userWrapper.balance(with: finances))
                    }
                }
                Section {
                    ForEach(finances) {
                        finance in
                        Button {
                            financeWrapper.finance = finance
                            legalPersonWrapper.legalPerson = finance.legalPerson
                            detailsPresented.toggle()
                        } label: {
                            label(finance)
                        }
                        .foregroundColor(.black)
                        // Solution: https://peterfriese.dev/posts/swiftui-listview-part4/
                        .swipeActions {
                            DeleteButton {
                                deleteFinance(for: finance)
                            }
                        }
                    }
                } header: {
                    Text("Finances")
                } footer: {
                    financeFooter()
                }
                .alert("Are you sure?", isPresented: $deletePeriodicalFinancePresented) {
                    Button("Delete", role: .destructive) {
                        delete = true
                        deleteFinance(for: periodicalFinanceToDeleteAfterConfirmation!)
                    }
                    // From: https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:actions:message:)-8dvt8
                    Button("Cancel", role: .cancel) {
                        delete = false
                        periodicalFinanceToDeleteAfterConfirmation = nil
                    }
                } message: {
                    Text("This is a periodical Finance. \nDeleting it will also delete all connected periodical Finances")
                }
                .sheet(isPresented: $detailsPresented) {
                    // On dismiss
                    if deleteFinanceFromDetails {
                        deleteFinance(for: financeWrapper.finance!)
                    }
                } content: {
                    FinanceDetails(deleteFinanceFromDetails: $deleteFinanceFromDetails)
                        .environmentObject(legalPersonWrapper)
                        .environmentObject(financeWrapper)
                        .environmentObject(userWrapper)
                }
            }
        }
    }
    
    /// Builds, renders and returns the
    /// Chart shown on the Homescreen
    @ViewBuilder
    private func chart() -> some View {
        let balances = userWrapper.balance(days: 7, with: finances)
        if !balances.isEmpty {
            BalancesChart(balances: balances)
                .padding(.vertical, 10)
        } else {
            Section {
                Text("Charts will appear when Data are entered.")
                    .foregroundColor(.black)
            }
        }
    }
    
    /// Builds and returns the Label
    /// of a specific Finance List Object
    @ViewBuilder
    private func label(_ finance : Finance) -> some View {
        HStack {
            Image(systemName: finance is Income ? "plus" : "minus")
                .renderingMode(.original)
                .padding(.trailing, 8)
            VStack(alignment: .leading) {
                let amount : String = String(format: "%.2f$", finance.amount)
                Text(amount)
                    .font(.headline)
                    .foregroundColor(finance is Income ? .green : .red)
                // Legal Person isn't an optional Parameter, but still you have to use the ? because Swift Optional and Core Data Optional aren't the same thing
                Text(finance.legalPerson!.name!)
                // Same with the Date as above with the legal Person.
                // Only with the difference that I'm enforcing the Date here.
                Text(finance.date!, format: .dateTime.day().month().year())
                    .foregroundColor(.gray)
            }
        }
    }
    
    
    
    /// Builds, renders and returns the
    /// Footer of the Finance Section depending
    /// on the length of the FInance List
    /// => small easter egg :)
    @ViewBuilder
    private func financeFooter() -> some View {
        if finances.count > 50 {
            VStack(alignment: .leading) {
                Text("Congratulations!🎉")
                Text("You reached the End of the List of all Finances you ever added.")
            }
        } else {
            Text("Contains all the Finances you ever added to the App")
        }
    }
    
    /// Scans all the Finances and adds Finances which have periodical payments to it, if
    /// so nessecary
    private func setPeriodicalFinances() -> Void {
        let periodicalFinances : [Finance] = finances.filter { $0.isPeriodical && !$0.automaticGenerated }
        guard !periodicalFinances.isEmpty else { return }
        
        for finance in periodicalFinances {
            let timeIntervalDays : Int
            if let setOfFinances =  finance.periodicallyConnectedFinances, setOfFinances.count != 0 {
                timeIntervalDays = Int( Date.now.timeIntervalSince(   (finance.periodicallyConnectedFinances!.allObjects as! [Finance]).latest()!.date!) / 86400)
            } else {
                timeIntervalDays = Int(Date.now.timeIntervalSince(finance.date!) / 86000)
            }
            let timeInterval : Int = timeIntervalDays / Int(finance.periodDuration)
            guard timeInterval > 0 else { continue }
            for index in 0..<timeInterval {
                let newFinance : Finance
                if finance is Income {
                    newFinance = Income(context: viewContext)
                } else {
                    newFinance = Expense(context: viewContext)
                }
                newFinance.periodDuration = finance.periodDuration
                newFinance.amount = finance.amount
                newFinance.legalPerson = finance.legalPerson
                var dateComponents : DateComponents = DateComponents()
                dateComponents.day = (index + 1) * Int(finance.periodDuration)
                newFinance.date = Calendar.current.date(byAdding: dateComponents, to: finance.date!)
                newFinance.notes = finance.notes
                newFinance.automaticGenerated = true
                finance.addToPeriodicallyConnectedFinances(newFinance)
                userWrapper.addFinance(newFinance)
            }
            for periodicalFinance in finance.periodicallyConnectedFinances?.allObjects as! [Finance] {
                // Solution from: https://www.hackingwithswift.com/forums/swiftui/adding-an-array-of-objects-to-an-nsset-relationship/10081
                // Answer: https://www.hackingwithswift.com/forums/swiftui/adding-an-array-of-objects-to-an-nsset-relationship/10081/10084
                let periodicalFinancesToAdd : NSSet = NSSet(array: (finance.periodicallyConnectedFinances!.allObjects as! [Finance]).filter { $0 != periodicalFinance && $0 != finance })
                periodicalFinance.addToPeriodicallyConnectedFinances(periodicalFinancesToAdd)
            }
        }
        do {
            try viewContext.save()
        } catch _ {
            errSavingPresented.toggle()
        }
    }
    
    /// Deletes the specified Finance from the System.
    /// This does also show a message if the finance is periodical
    /// to warn to user, that deleting this Finance will also delete all
    /// the connected finances
    private func deleteFinance(for finance : Finance) -> Void {
        if finance.isPeriodical {
            guard periodicalFinanceToDeleteAfterConfirmation == finance else {
                periodicalFinanceToDeleteAfterConfirmation = finance
                deletePeriodicalFinancePresented.toggle()
                return
            }
            guard delete else {
                return
            }
        }
        do {
            try PersistenceController.shared.deleteFinance(
                finance,
                userWrapper: _userWrapper,
                financeWrapper: _financeWrapper
            )
        } catch _ {
            errSavingPresented.toggle()
        }
    }
}

internal struct ContentView_Previews: PreviewProvider {
    
    /// The User Wrapper Environment Object
    /// used in this Environment
    @StateObject private static var userWrapperPreview : UserWrapper = UserWrapper(user: User.anonymous)
    
    static var previews: some View {
        Home()
            .environmentObject(userWrapperPreview)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

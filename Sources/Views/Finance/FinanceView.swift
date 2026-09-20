import SwiftUI
import Charts

struct FinanceView: View {
    @StateObject private var viewModel = FinanceViewModel()
    @State private var invoiceToDelete: Invoice?
    @State private var expenseToDelete: Expense?
    @State private var invoiceToEdit: Invoice?
    @State private var showCreateInvoice = false
    @State private var showEditInvoice = false
    @State private var showAddExpense = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Picker("Tab", selection: $viewModel.selectedTab) {
                ForEach(FinanceTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch viewModel.selectedTab {
                case .invoices:
                    invoicesView
                case .expenses:
                    expensesView
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .confirmationDialog("Delete Invoice", isPresented: .init(get: { invoiceToDelete != nil }, set: { if !$0 { invoiceToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let invoice = invoiceToDelete {
                    viewModel.deleteInvoice(invoice)
                    invoiceToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                invoiceToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this invoice? This action cannot be undone.")
        }
        .confirmationDialog("Delete Expense", isPresented: .init(get: { expenseToDelete != nil }, set: { if !$0 { expenseToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    viewModel.deleteExpense(expense)
                    expenseToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                expenseToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
        .alert("Error", isPresented: .init(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showCreateInvoice) {
            CreateInvoiceView(customers: viewModel.customers) { invoice in
                viewModel.saveInvoice(invoice)
                showCreateInvoice = false
            }
        }
        .sheet(isPresented: $showEditInvoice) {
            if let invoice = invoiceToEdit {
                EditInvoiceView(invoice: invoice, customers: viewModel.customers) { updated in
                    viewModel.saveInvoice(updated)
                    showEditInvoice = false
                    invoiceToEdit = nil
                }
            }
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView { expense in
                viewModel.saveExpense(expense)
                showAddExpense = false
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Finance Management")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            HStack(spacing: 16) {
                VStack(alignment: .trailing) {
                    Text("Total Revenue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(viewModel.totalRevenue))
                        .font(.headline)
                        .foregroundColor(.green)
                }

                VStack(alignment: .trailing) {
                    Text("Total Expenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(viewModel.totalExpenses))
                        .font(.headline)
                        .foregroundColor(.red)
                }

                VStack(alignment: .trailing) {
                    Text("Outstanding")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(viewModel.outstandingAmount))
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
    }

    private var invoicesView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: createInvoice) {
                    Label("Create Invoice", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            if viewModel.invoices.isEmpty {
                emptyState(message: "No invoices found", icon: "doc.text")
            } else {
                Table(viewModel.invoices) {
                    TableColumn("Invoice #") { invoice in
                        Text(invoice.invoiceNumber)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                    }
                    .width(140)

                    TableColumn("Customer") { invoice in
                        Text(viewModel.customerName(for: invoice))
                    }
                    .width(min: 150, ideal: 200)

                    TableColumn("Date") { invoice in
                        Text(invoice.invoiceDate, style: .date)
                    }
                    .width(100)

                    TableColumn("Due Date") { invoice in
                        Text(invoice.dueDate, style: .date)
                    }
                    .width(100)

                    TableColumn("Amount") { invoice in
                        Text(formatCurrency(invoice.total))
                            .fontWeight(.medium)
                    }
                    .width(100)

                    TableColumn("Status") { invoice in
                        StatusBadge(status: invoice.status.rawValue, color: invoice.status.color)
                    }
                    .width(100)

                    TableColumn("Actions") { invoice in
                        HStack(spacing: 8) {
                            Button(action: {
                                invoiceToEdit = invoice
                                showEditInvoice = true
                            }) {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)

                            Button(action: { invoiceToDelete = invoice }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .width(80)
                }
            }
        }
    }

    private var expensesView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: addExpense) {
                    Label("Add Expense", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            if viewModel.expenses.isEmpty {
                emptyState(message: "No expenses found", icon: "creditcard")
            } else {
                VStack(spacing: 16) {
                    expenseSummary

                    Table(viewModel.expenses) {
                        TableColumn("Date") { expense in
                            Text(expense.date, style: .date)
                        }
                        .width(100)

                        TableColumn("Category") { expense in
                            Text(expense.category.rawValue)
                        }
                        .width(100)

                        TableColumn("Description") { expense in
                            Text(expense.description)
                        }
                        .width(min: 150, ideal: 200)

                        TableColumn("Vendor") { expense in
                            Text(expense.vendor ?? "-")
                        }
                        .width(120)

                        TableColumn("Amount") { expense in
                            Text(formatCurrency(expense.amount))
                                .fontWeight(.medium)
                        }
                        .width(100)

                        TableColumn("Actions") { expense in
                            HStack(spacing: 8) {
                                Button(action: { expenseToDelete = expense }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .width(60)
                    }
                }
                .padding()
            }
        }
    }

    private var expenseSummary: some View {
        HStack(spacing: 16) {
            ForEach(viewModel.expensesByCategory.prefix(4), id: \.0) { category, amount in
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(amount))
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }

    private func emptyState(message: String, icon: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func createInvoice() {
        showCreateInvoice = true
    }

    private func addExpense() {
        showAddExpense = true
    }

    private func formatCurrency(_ value: Double) -> String {
        value.formattedAsCurrency()
    }
}

// MARK: - Create Invoice Sheet
struct CreateInvoiceView: View {
    @Environment(\.dismiss) var dismiss
    let customers: [Customer]
    let onSave: (Invoice) -> Void

    @State private var selectedCustomerId: UUID
    @State private var invoiceDate: Date = Date()
    @State private var dueDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60)
    @State private var subtotal: Double = 0
    @State private var taxRate: Double = 0
    @State private var notes: String = ""

    private var taxAmount: Double { subtotal * taxRate / 100 }
    private var total: Double { subtotal + taxAmount }

    init(customers: [Customer], onSave: @escaping (Invoice) -> Void) {
        self.customers = customers
        self.onSave = onSave
        _selectedCustomerId = State(initialValue: customers.first?.id ?? UUID())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Create Invoice")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Form {
                Section("Customer") {
                    Picker("Customer", selection: $selectedCustomerId) {
                        ForEach(customers) { customer in
                            Text(customer.companyName).tag(customer.id)
                        }
                    }
                }

                Section("Dates") {
                    DatePicker("Invoice Date", selection: $invoiceDate, displayedComponents: .date)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }

                Section("Amounts") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        TextField("0", value: $subtotal, format: .currency(code: "USD"))
                            .frame(width: 120)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Tax Rate (%)")
                        Spacer()
                        TextField("0", value: $taxRate, format: .number)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                    }
                    Divider()
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(total, format: .currency(code: "USD"))
                            .fontWeight(.bold)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Button("Save") {
                    let invoice = Invoice(
                        invoiceNumber: Invoice.generateInvoiceNumber(),
                        customerId: selectedCustomerId,
                        tripIds: [],
                        invoiceDate: invoiceDate,
                        dueDate: dueDate,
                        subtotal: subtotal,
                        tax: taxAmount,
                        total: total,
                        status: .draft,
                        notes: notes.isEmpty ? nil : notes
                    )
                    onSave(invoice)
                }
                .buttonStyle(.borderedProminent)
                .disabled(customers.isEmpty || subtotal <= 0 || taxRate < 0)
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }
}

// MARK: - Edit Invoice Sheet
struct EditInvoiceView: View {
    @Environment(\.dismiss) var dismiss
    let invoice: Invoice
    let customers: [Customer]
    let onSave: (Invoice) -> Void

    @State private var selectedCustomerId: UUID
    @State private var invoiceDate: Date
    @State private var dueDate: Date
    @State private var subtotal: Double
    @State private var taxRate: Double
    @State private var notes: String
    @State private var status: InvoiceStatus

    private var taxAmount: Double { subtotal * taxRate / 100 }
    private var total: Double { subtotal + taxAmount }

    init(invoice: Invoice, customers: [Customer], onSave: @escaping (Invoice) -> Void) {
        self.invoice = invoice
        self.customers = customers
        self.onSave = onSave
        _selectedCustomerId = State(initialValue: invoice.customerId)
        _invoiceDate = State(initialValue: invoice.invoiceDate)
        _dueDate = State(initialValue: invoice.dueDate)
        _subtotal = State(initialValue: invoice.subtotal)
        _taxRate = State(initialValue: invoice.subtotal > 0 ? (invoice.tax / invoice.subtotal * 100) : 0)
        _notes = State(initialValue: invoice.notes ?? "")
        _status = State(initialValue: invoice.status)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit Invoice")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Form {
                Section("Customer") {
                    Picker("Customer", selection: $selectedCustomerId) {
                        ForEach(customers) { customer in
                            Text(customer.companyName).tag(customer.id)
                        }
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(InvoiceStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }

                Section("Dates") {
                    DatePicker("Invoice Date", selection: $invoiceDate, displayedComponents: .date)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }

                Section("Amounts") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        TextField("0", value: $subtotal, format: .currency(code: "USD"))
                            .frame(width: 120)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Tax Rate (%)")
                        Spacer()
                        TextField("0", value: $taxRate, format: .number)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                    }
                    Divider()
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(total, format: .currency(code: "USD"))
                            .fontWeight(.bold)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Button("Save") {
                    var updated = invoice
                    updated.customerId = selectedCustomerId
                    updated.invoiceDate = invoiceDate
                    updated.dueDate = dueDate
                    updated.subtotal = subtotal
                    updated.tax = taxAmount
                    updated.total = total
                    updated.status = status
                    updated.notes = notes.isEmpty ? nil : notes
                    onSave(updated)
                }
                .buttonStyle(.borderedProminent)
                .disabled(customers.isEmpty || subtotal <= 0 || taxRate < 0)
            }
            .padding()
        }
        .frame(width: 450, height: 550)
    }
}

// MARK: - Add Expense Sheet
struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (Expense) -> Void

    @State private var category: ExpenseCategory = .fuel
    @State private var description: String = ""
    @State private var amount: Double = 0
    @State private var date: Date = Date()
    @State private var vendor: String = ""
    @State private var notes: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Expense")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Form {
                Section("Expense Details") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    TextField("Description", text: $description)
                    TextField("Vendor", text: $vendor)
                }

                Section("Amount") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0", value: $amount, format: .currency(code: "USD"))
                            .frame(width: 120)
                            .textFieldStyle(.roundedBorder)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Button("Save") {
                    let expense = Expense(
                        category: category,
                        vendor: vendor.isEmpty ? nil : vendor,
                        description: description,
                        amount: amount,
                        date: date,
                        notes: notes.isEmpty ? nil : notes
                    )
                    onSave(expense)
                }
                .buttonStyle(.borderedProminent)
                .disabled(description.isEmpty || amount <= 0)
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }
}
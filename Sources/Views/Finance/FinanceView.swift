import SwiftUI
import Charts

struct FinanceView: View {
    @StateObject private var viewModel = FinanceViewModel()

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
                        StatusBadge(status: invoice.status.rawValue, color: statusColor(invoice.status))
                    }
                    .width(100)

                    TableColumn("Actions") { invoice in
                        HStack(spacing: 8) {
                            Button(action: { viewModel.deleteInvoice(invoice) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .width(60)
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
                                Button(action: { viewModel.deleteExpense(expense) }) {
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
        let invoice = Invoice(
            invoiceNumber: Invoice.generateInvoiceNumber(),
            customerId: UUID(),
            tripIds: [],
            invoiceDate: Date(),
            dueDate: Date().addingTimeInterval(Double(viewModel.customers.first?.paymentTerms ?? 30) * 24 * 60 * 60),
            subtotal: 0,
            tax: 0,
            total: 0,
            status: .draft
        )
        viewModel.saveInvoice(invoice)
    }

    private func addExpense() {
        let expense = Expense(
            category: .other,
            description: "New Expense",
            amount: 0,
            date: Date()
        )
        viewModel.saveExpense(expense)
    }

    private func statusColor(_ status: InvoiceStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .sent: return .blue
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .gray
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
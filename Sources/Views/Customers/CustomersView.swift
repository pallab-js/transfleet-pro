import SwiftUI

struct CustomersView: View {
    @StateObject private var viewModel = CustomerViewModel()
    @State private var showAddCustomer = false
    @State private var selectedCustomer: Customer?

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredCustomers.isEmpty {
                emptyState
            } else {
                customerTable
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showAddCustomer) {
            CustomerFormView(customer: selectedCustomer) { customer in
                viewModel.saveCustomer(customer)
                selectedCustomer = nil
                showAddCustomer = false
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    private var toolbar: some View {
        HStack {
            Text("Customer Management")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            SearchField(text: $viewModel.searchText, placeholder: "Search customers...")

            Picker("Type", selection: $viewModel.filterType) {
                Text("All").tag(Optional<CustomerType>.none)
                ForEach(CustomerType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(Optional(type))
                }
            }
            .frame(width: 150)

            Button(action: {
                selectedCustomer = nil
                showAddCustomer = true
            }) {
                Label("Add Customer", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var customerTable: some View {
        Table(viewModel.filteredCustomers) {
            TableColumn("Company") { customer in
                VStack(alignment: .leading, spacing: 2) {
                    Text(customer.companyName)
                        .fontWeight(.medium)
                    Text(customer.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .width(min: 150, ideal: 200)

            TableColumn("Contact") { customer in
                VStack(alignment: .leading, spacing: 2) {
                    Text(customer.contactName)
                    Text(customer.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .width(min: 180, ideal: 220)

            TableColumn("Phone") { customer in
                Text(customer.phone)
            }
            .width(120)

            TableColumn("Location") { customer in
                Text("\(customer.city), \(customer.state)")
            }
            .width(120)

            TableColumn("Credit Limit") { customer in
                Text(formatCurrency(customer.creditLimit))
            }
            .width(100)

            TableColumn("Terms") { customer in
                Text("Net \(customer.paymentTerms)")
            }
            .width(80)

            TableColumn("Actions") { customer in
                HStack(spacing: 8) {
                    Button(action: {
                        selectedCustomer = customer
                        showAddCustomer = true
                    }) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)

                    Button(action: {
                        viewModel.deleteCustomer(customer)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .width(80)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No customers found")
                .font(.headline)
            Text("Add your first customer to get started")
                .foregroundColor(.secondary)
            Button("Add Customer") {
                showAddCustomer = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct CustomerFormView: View {
    @Environment(\.dismiss) var dismiss
    let customer: Customer?
    let onSave: (Customer) -> Void

    @State private var companyName: String = ""
    @State private var contactName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var type: CustomerType = .commercial
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""
    @State private var creditLimit: Double = 10000
    @State private var paymentTerms: Int = 30

    var body: some View {
        VStack(spacing: 0) {
            header

            Form {
                Section("Company Information") {
                    TextField("Company Name", text: $companyName)
                    TextField("Contact Name", text: $contactName)
                    Picker("Type", selection: $type) {
                        ForEach(CustomerType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section("Contact Details") {
                    TextField("Email", text: $email)
                    TextField("Phone", text: $phone)
                }

                Section("Address") {
                    TextField("Street Address", text: $address)
                    HStack {
                        TextField("City", text: $city)
                        TextField("State", text: $state)
                            .frame(width: 60)
                        TextField("ZIP", text: $zip)
                            .frame(width: 80)
                    }
                }

                Section("Billing") {
                    HStack {
                        Text("Credit Limit")
                        Spacer()
                        TextField("10000", value: $creditLimit, format: .currency(code: "USD"))
                            .frame(width: 120)
                            .textFieldStyle(.roundedBorder)
                    }
                    Picker("Payment Terms", selection: $paymentTerms) {
                        Text("Net 15").tag(15)
                        Text("Net 30").tag(30)
                        Text("Net 45").tag(45)
                        Text("Net 60").tag(60)
                    }
                }
            }
            .formStyle(.grouped)

            footer
        }
        .frame(width: 500, height: 550)
        .onAppear {
            if let customer = customer {
                companyName = customer.companyName
                contactName = customer.contactName
                email = customer.email
                phone = customer.phone
                type = customer.type
                address = customer.address
                city = customer.city
                state = customer.state
                zip = customer.zip
                creditLimit = customer.creditLimit
                paymentTerms = customer.paymentTerms
            }
        }
    }

    private var header: some View {
        HStack {
            Text(customer == nil ? "Add Customer" : "Edit Customer")
                .font(.headline)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            Button("Save") {
                var customerToSave = customer ?? Customer(
                    companyName: companyName,
                    contactName: contactName,
                    email: email,
                    phone: phone,
                    type: type,
                    address: address,
                    city: city,
                    state: state,
                    zip: zip,
                    creditLimit: creditLimit,
                    paymentTerms: paymentTerms
                )
                customerToSave.companyName = companyName
                customerToSave.contactName = contactName
                customerToSave.email = email
                customerToSave.phone = phone
                customerToSave.type = type
                customerToSave.address = address
                customerToSave.city = city
                customerToSave.state = state
                customerToSave.zip = zip
                customerToSave.creditLimit = creditLimit
                customerToSave.paymentTerms = paymentTerms
                onSave(customerToSave)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
        }
        .padding()
    }
}
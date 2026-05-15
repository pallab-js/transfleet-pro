import SwiftUI

struct DriversView: View {
    @StateObject private var viewModel = DriverViewModel()
    @State private var showAddDriver = false
    @State private var selectedDriver: Driver?

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredDrivers.isEmpty {
                emptyState
            } else {
                driverTable
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showAddDriver) {
            DriverFormView(driver: selectedDriver) { driver in
                viewModel.saveDriver(driver)
                selectedDriver = nil
                showAddDriver = false
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    private var toolbar: some View {
        HStack {
            Text("Driver Management")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            SearchField(text: $viewModel.searchText, placeholder: "Search drivers...")

            Picker("Status", selection: $viewModel.filterStatus) {
                Text("All").tag(Optional<DriverStatus>.none)
                ForEach(DriverStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(Optional(status))
                }
            }
            .frame(width: 150)

            Button(action: {
                selectedDriver = nil
                showAddDriver = true
            }) {
                Label("Add Driver", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var driverTable: some View {
        Table(viewModel.filteredDrivers) {
            TableColumn("Name") { driver in
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading) {
                        Text(driver.fullName)
                            .fontWeight(.medium)
                        Text(driver.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .width(min: 200, ideal: 250)

            TableColumn("Phone") { driver in
                Text(driver.phone)
            }
            .width(120)

            TableColumn("License") { driver in
                VStack(alignment: .leading, spacing: 2) {
                    Text(driver.licenseNumber)
                        .font(.system(.body, design: .monospaced))
                    Text("\(driver.licenseState) - Exp: \(driver.licenseExpiry, style: .date)")
                        .font(.caption)
                        .foregroundColor(viewModel.isLicenseExpiring(driver) ? .red : .secondary)
                }
            }
            .width(min: 150, ideal: 180)

            TableColumn("Status") { driver in
                StatusBadge(status: driver.status.rawValue, color: statusColor(driver.status))
            }
            .width(100)

            TableColumn("Rating") { driver in
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", driver.rating))
                }
            }
            .width(80)

            TableColumn("Actions") { driver in
                HStack(spacing: 8) {
                    Button(action: {
                        selectedDriver = driver
                        showAddDriver = true
                    }) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)

                    Button(action: {
                        viewModel.deleteDriver(driver)
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
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No drivers found")
                .font(.headline)
            Text("Add your first driver to get started")
                .foregroundColor(.secondary)
            Button("Add Driver") {
                showAddDriver = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statusColor(_ status: DriverStatus) -> Color {
        switch status {
        case .active: return .green
        case .onLeave: return .orange
        case .suspended: return .red
        case .terminated: return .gray
        }
    }
}

struct DriverFormView: View {
    @Environment(\.dismiss) var dismiss
    let driver: Driver?
    let onSave: (Driver) -> Void

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var licenseNumber: String = ""
    @State private var licenseState: String = ""
    @State private var licenseExpiry: Date = Date().addingTimeInterval(365*24*60*60)
    @State private var status: DriverStatus = .active
    @State private var hireDate: Date = Date()
    @State private var rating: Double = 4.0

    var body: some View {
        VStack(spacing: 0) {
            header

            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                    TextField("Phone", text: $phone)
                    TextField("Address", text: $address)
                }

                Section("License Information") {
                    TextField("License Number", text: $licenseNumber)
                    TextField("State", text: $licenseState)
                    DatePicker("Expiry Date", selection: $licenseExpiry, displayedComponents: .date)
                }

                Section("Employment") {
                    Picker("Status", selection: $status) {
                        ForEach(DriverStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    DatePicker("Hire Date", selection: $hireDate, displayedComponents: .date)
                    Slider(value: $rating, in: 0...5, step: 0.1) {
                        Text("Rating")
                    }
                    Text(String(format: "%.1f", rating))
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)

            footer
        }
        .frame(width: 500, height: 600)
        .onAppear {
            if let driver = driver {
                firstName = driver.firstName
                lastName = driver.lastName
                email = driver.email
                phone = driver.phone
                address = driver.address ?? ""
                licenseNumber = driver.licenseNumber
                licenseState = driver.licenseState
                licenseExpiry = driver.licenseExpiry
                status = driver.status
                hireDate = driver.hireDate
                rating = driver.rating
            }
        }
    }

    private var header: some View {
        HStack {
            Text(driver == nil ? "Add Driver" : "Edit Driver")
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
                var driverToSave = driver ?? Driver(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    phone: phone,
                    licenseNumber: licenseNumber,
                    licenseState: licenseState,
                    licenseExpiry: licenseExpiry,
                    status: status,
                    hireDate: hireDate,
                    rating: rating
                )
                driverToSave.firstName = firstName
                driverToSave.lastName = lastName
                driverToSave.email = email
                driverToSave.phone = phone
                driverToSave.address = address.isEmpty ? nil : address
                driverToSave.licenseNumber = licenseNumber
                driverToSave.licenseState = licenseState
                driverToSave.licenseExpiry = licenseExpiry
                driverToSave.status = status
                driverToSave.hireDate = hireDate
                driverToSave.rating = rating
                onSave(driverToSave)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
        }
        .padding()
    }
}
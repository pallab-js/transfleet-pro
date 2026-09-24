import SwiftUI

struct TripsView: View {
    @StateObject private var viewModel = TripViewModel()
    @State private var showAddTrip = false
    @State private var selectedTrip: Trip?
    @State private var tripToDelete: Trip?
    @State private var pagination = PaginationState()

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredTrips.isEmpty {
                emptyState
            } else {
                tripTable
                PaginationView(state: $pagination, totalItems: viewModel.filteredTrips.count)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showAddTrip) {
            TripFormView(trip: selectedTrip, customers: viewModel.customers, drivers: viewModel.drivers, vehicles: viewModel.vehicles) { trip in
                viewModel.saveTrip(trip)
                selectedTrip = nil
                showAddTrip = false
            }
        }
        .confirmationDialog("Delete Trip", isPresented: .init(get: { tripToDelete != nil }, set: { if !$0 { tripToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let trip = tripToDelete {
                    viewModel.deleteTrip(trip)
                    tripToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                tripToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this trip? This action cannot be undone.")
        }
        .alert("Error", isPresented: .init(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.loadData()
        }
        .onChange(of: viewModel.searchText) { _, _ in pagination.reset() }
        .onChange(of: viewModel.filterStatus) { _, _ in pagination.reset() }
    }

    private var toolbar: some View {
        HStack {
            Text("Trip Management")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            SearchField(text: $viewModel.searchText, placeholder: "Search trips...")

            Picker("Status", selection: $viewModel.filterStatus) {
                Text("All").tag(Optional<TripStatus>.none)
                ForEach(TripStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(Optional(status))
                }
            }
            .frame(width: 150)

            Button(action: {
                selectedTrip = nil
                showAddTrip = true
            }) {
                Label("New Trip", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var tripTable: some View {
        Table(Array(pagination.page(viewModel.filteredTrips))) {
            TableColumn("Job #") { trip in
                Text(trip.jobNumber)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
            }
            .width(120)

            TableColumn("Customer") { trip in
                Text(viewModel.customerName(for: trip))
            }
            .width(min: 120, ideal: 150)

            TableColumn("Route") { trip in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(trip.pickupCity), \(trip.pickupState)")
                        .font(.caption)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(trip.deliveryCity), \(trip.deliveryState)")
                        .font(.caption)
                }
            }
            .width(min: 150, ideal: 180)

            TableColumn("Driver") { trip in
                Text(viewModel.driverName(for: trip))
            }
            .width(120)

            TableColumn("Vehicle") { trip in
                Text(viewModel.vehicleName(for: trip))
            }
            .width(100)

            TableColumn("Status") { trip in
                StatusBadge(status: trip.status.rawValue, color: trip.status.color)
            }
            .width(100)

            TableColumn("Date") { trip in
                Text(trip.pickupDate, style: .date)
            }
            .width(100)

            TableColumn("Amount") { trip in
                Text(formatCurrency(trip.totalAmount))
                    .fontWeight(.medium)
            }
            .width(100)

            TableColumn("Actions") { trip in
                HStack(spacing: 8) {
                    Button(action: {
                        selectedTrip = trip
                        showAddTrip = true
                    }) {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit trip \(trip.jobNumber)")
                    .buttonStyle(.borderless)

                    Button(action: {
                        tripToDelete = trip
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Delete trip \(trip.jobNumber)")
                    .buttonStyle(.borderless)
                }
            }
            .width(80)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No trips found")
                .font(.headline)
            Text("Create your first trip to get started")
                .foregroundColor(.secondary)
            Button("New Trip") {
                showAddTrip = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatCurrency(_ value: Double) -> String {
        value.formattedAsCurrency()
    }
}

struct TripFormView: View {
    @Environment(\.dismiss) var dismiss
    let trip: Trip?
    let customers: [Customer]
    let drivers: [Driver]
    let vehicles: [Vehicle]
    let onSave: (Trip) -> Void

    @State private var customerId: UUID = UUID()
    @State private var driverId: UUID?
    @State private var vehicleId: UUID?
    @State private var status: TripStatus = .pending
    @State private var pickupAddress: String = ""
    @State private var pickupCity: String = ""
    @State private var pickupState: String = ""
    @State private var pickupZip: String = ""
    @State private var pickupDate: Date = Date()
    @State private var deliveryAddress: String = ""
    @State private var deliveryCity: String = ""
    @State private var deliveryState: String = ""
    @State private var deliveryZip: String = ""
    @State private var distance: Double = 0
    @State private var rate: Double = 0
    @State private var fuelSurcharge: Double = 0

    var totalAmount: Double {
        rate + fuelSurcharge
    }

    private var isValid: Bool {
        !pickupAddress.trimmingCharacters(in: .whitespaces).isEmpty &&
        !pickupCity.trimmingCharacters(in: .whitespaces).isEmpty &&
        !pickupState.trimmingCharacters(in: .whitespaces).isEmpty &&
        !pickupZip.trimmingCharacters(in: .whitespaces).isEmpty &&
        !deliveryAddress.trimmingCharacters(in: .whitespaces).isEmpty &&
        !deliveryCity.trimmingCharacters(in: .whitespaces).isEmpty &&
        !deliveryState.trimmingCharacters(in: .whitespaces).isEmpty &&
        !deliveryZip.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Form {
                Section("Customer") {
                    Picker("Customer", selection: $customerId) {
                        ForEach(customers) { customer in
                            Text(customer.companyName).tag(customer.id)
                        }
                    }
                }

                Section("Pickup Location") {
                    TextField("Address", text: $pickupAddress)
                    HStack {
                        TextField("City", text: $pickupCity)
                        TextField("State", text: $pickupState)
                            .frame(width: 60)
                        TextField("ZIP", text: $pickupZip)
                            .frame(width: 80)
                    }
                    DatePicker("Pickup Date", selection: $pickupDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Delivery Location") {
                    TextField("Address", text: $deliveryAddress)
                    HStack {
                        TextField("City", text: $deliveryCity)
                        TextField("State", text: $deliveryState)
                            .frame(width: 60)
                        TextField("ZIP", text: $deliveryZip)
                            .frame(width: 80)
                    }
                }

                Section("Assignment") {
                    Picker("Driver", selection: $driverId) {
                        Text("Unassigned").tag(Optional<UUID>.none)
                        ForEach(drivers.filter { $0.status == .active }) { driver in
                            Text(driver.fullName).tag(Optional(driver.id))
                        }
                    }

                    Picker("Vehicle", selection: $vehicleId) {
                        Text("Unassigned").tag(Optional<UUID>.none)
                        ForEach(vehicles.filter { $0.status == .available || $0.status == .inUse }) { vehicle in
                            Text(vehicle.name).tag(Optional(vehicle.id))
                        }
                    }

                    Picker("Status", selection: $status) {
                        ForEach(TripStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Pricing") {
                    HStack {
                        Text("Distance (miles)")
                        Spacer()
                        TextField("0", value: $distance, format: .number)
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Rate ($)")
                        Spacer()
                        TextField("0", value: $rate, format: .currency(code: "USD"))
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("Fuel Surcharge ($)")
                        Spacer()
                        TextField("0", value: $fuelSurcharge, format: .currency(code: "USD"))
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                    }
                    Divider()
                    HStack {
                        Text("Total Amount")
                            .fontWeight(.bold)
                        Spacer()
                        Text(totalAmount.formattedAsCurrency())
                            .fontWeight(.bold)
                    }
                }
            }
            .formStyle(.grouped)

            footer
        }
        .frame(width: 550, height: 700)
        .onAppear {
            if let trip = trip {
                customerId = trip.customerId
                driverId = trip.driverId
                vehicleId = trip.vehicleId
                status = trip.status
                pickupAddress = trip.pickupAddress
                pickupCity = trip.pickupCity
                pickupState = trip.pickupState
                pickupZip = trip.pickupZip
                pickupDate = trip.pickupDate
                deliveryAddress = trip.deliveryAddress
                deliveryCity = trip.deliveryCity
                deliveryState = trip.deliveryState
                deliveryZip = trip.deliveryZip
                distance = trip.distance ?? 0
                rate = trip.rate
                fuelSurcharge = trip.fuelSurcharge
            } else if let firstCustomer = customers.first {
                customerId = firstCustomer.id
            }
        }
    }

    private var header: some View {
        HStack {
            Text(trip == nil ? "New Trip" : "Edit Trip")
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
                var tripToSave = trip ?? Trip(jobNumber: Trip.generateJobNumber(), customerId: customerId, status: .pending, pickupAddress: "", pickupCity: "", pickupState: "", pickupZip: "", pickupDate: Date(), deliveryAddress: "", deliveryCity: "", deliveryState: "", deliveryZip: "", rate: 0, fuelSurcharge: 0, totalAmount: 0)
                tripToSave.customerId = customerId
                tripToSave.driverId = driverId
                tripToSave.vehicleId = vehicleId
                if (status == .delivered || status == .completed) && tripToSave.deliveryDate == nil {
                    tripToSave.deliveryDate = Date()
                } else if status == .pending || status == .assigned || status == .inTransit {
                    tripToSave.deliveryDate = nil
                }
                tripToSave.status = status
                tripToSave.pickupAddress = pickupAddress
                tripToSave.pickupCity = pickupCity
                tripToSave.pickupState = pickupState
                tripToSave.pickupZip = pickupZip
                tripToSave.pickupDate = pickupDate
                tripToSave.deliveryAddress = deliveryAddress
                tripToSave.deliveryCity = deliveryCity
                tripToSave.deliveryState = deliveryState
                tripToSave.deliveryZip = deliveryZip
                tripToSave.distance = distance > 0 ? distance : nil
                tripToSave.rate = rate
                tripToSave.fuelSurcharge = fuelSurcharge
                tripToSave.totalAmount = totalAmount
                onSave(tripToSave)
            }
            .disabled(customers.isEmpty || !isValid)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
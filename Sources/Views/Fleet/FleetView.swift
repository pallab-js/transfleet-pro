import SwiftUI

struct FleetView: View {
    @StateObject private var viewModel = FleetViewModel()
    @State private var showAddVehicle = false
    @State private var selectedVehicle: Vehicle?
    @State private var vehicleToDelete: Vehicle?
    @State private var pagination = PaginationState()

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredVehicles.isEmpty {
                emptyState
            } else {
                vehicleTable
                PaginationView(state: $pagination, totalItems: viewModel.filteredVehicles.count)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showAddVehicle) {
            VehicleFormView(vehicle: selectedVehicle) { vehicle in
                viewModel.saveVehicle(vehicle)
                selectedVehicle = nil
                showAddVehicle = false
            }
        }
        .confirmationDialog("Delete Vehicle", isPresented: .init(get: { vehicleToDelete != nil }, set: { if !$0 { vehicleToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let vehicle = vehicleToDelete {
                    viewModel.deleteVehicle(vehicle)
                    vehicleToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                vehicleToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this vehicle? This action cannot be undone.")
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
            Text("Fleet Management")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            SearchField(text: $viewModel.searchText, placeholder: "Search vehicles...")

            Picker("Status", selection: $viewModel.filterStatus) {
                Text("All").tag(Optional<VehicleStatus>.none)
                ForEach(VehicleStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(Optional(status))
                }
            }
            .frame(width: 150)

            Button(action: {
                selectedVehicle = nil
                showAddVehicle = true
            }) {
                Label("Add Vehicle", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var vehicleTable: some View {
        Table(Array(pagination.page(viewModel.filteredVehicles))) {
            TableColumn("Name") { vehicle in
                Text(vehicle.name)
                    .fontWeight(.medium)
            }
            .width(min: 100, ideal: 150)

            TableColumn("Type") { vehicle in
                Label(vehicle.type.rawValue, systemImage: vehicle.type.icon)
            }
            .width(80)

            TableColumn("License Plate") { vehicle in
                Text(vehicle.licensePlate)
                    .font(.system(.body, design: .monospaced))
            }
            .width(120)

            TableColumn("Vehicle") { vehicle in
                Text(vehicle.displayName)
                    .foregroundColor(.secondary)
            }
            .width(min: 150, ideal: 200)

            TableColumn("Status") { vehicle in
                StatusBadge(status: vehicle.status.rawValue, color: vehicle.status.color)
            }
            .width(100)

            TableColumn("Odometer") { vehicle in
                Text("\(vehicle.currentOdometer) mi")
                    .foregroundColor(.secondary)
            }
            .width(100)

            TableColumn("Actions") { vehicle in
                HStack(spacing: 8) {
                    Button(action: {
                        selectedVehicle = vehicle
                        showAddVehicle = true
                    }) {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit \(vehicle.name)")
                    .buttonStyle(.borderless)

                    Button(action: {
                        vehicleToDelete = vehicle
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Delete \(vehicle.name)")
                    .buttonStyle(.borderless)
                }
            }
            .width(80)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No vehicles found")
                .font(.headline)
            Text("Add your first vehicle to get started")
                .foregroundColor(.secondary)
            Button("Add Vehicle") {
                showAddVehicle = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}

struct VehicleFormView: View {
    @Environment(\.dismiss) var dismiss
    let vehicle: Vehicle?
    let onSave: (Vehicle) -> Void

    @State private var name: String = ""
    @State private var type: VehicleType = .truck
    @State private var licensePlate: String = ""
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: Int = 2024
    @State private var vin: String = ""
    @State private var status: VehicleStatus = .available
    @State private var currentOdometer: Int = 0
    @State private var fuelType: FuelType = .diesel

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !licensePlate.trimmingCharacters(in: .whitespaces).isEmpty &&
        year >= 1900 && year <= Calendar.current.component(.year, from: Date()) + 1
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Form {
                Section("Basic Information") {
                    TextField("Vehicle Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(VehicleType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("License Plate", text: $licensePlate)
                }

                Section("Details") {
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    TextField("Year", value: $year, format: .number)
                    TextField("VIN", text: $vin)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(VehicleStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    TextField("Current Odometer", value: $currentOdometer, format: .number)

                    Picker("Fuel Type", selection: $fuelType) {
                        ForEach(FuelType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            footer
        }
        .frame(width: 500, height: 600)
        .onAppear {
            if let vehicle = vehicle {
                name = vehicle.name
                type = vehicle.type
                licensePlate = vehicle.licensePlate
                make = vehicle.make
                model = vehicle.model
                year = vehicle.year
                vin = vehicle.vin
                status = vehicle.status
                currentOdometer = vehicle.currentOdometer
                fuelType = vehicle.fuelType
            }
        }
    }

    private var header: some View {
        HStack {
            Text(vehicle == nil ? "Add Vehicle" : "Edit Vehicle")
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
                var vehicleToSave = vehicle ?? Vehicle(name: "", type: .truck, licensePlate: "", make: "", model: "", year: 0, vin: "", status: .available, currentOdometer: 0, fuelType: .diesel)
                vehicleToSave.name = name
                vehicleToSave.type = type
                vehicleToSave.licensePlate = licensePlate
                vehicleToSave.make = make
                vehicleToSave.model = model
                vehicleToSave.year = year
                vehicleToSave.vin = vin
                vehicleToSave.status = status
                vehicleToSave.currentOdometer = currentOdometer
                vehicleToSave.fuelType = fuelType
                onSave(vehicleToSave)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
        .padding()
    }
}


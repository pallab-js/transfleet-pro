import SwiftUI

struct FleetView: View {
    @StateObject private var viewModel = FleetViewModel()
    @State private var showAddVehicle = false
    @State private var selectedVehicle: Vehicle?

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
        .onAppear {
            viewModel.loadData()
        }
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
        Table(viewModel.filteredVehicles) {
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
                StatusBadge(status: vehicle.status.rawValue, color: statusColor(vehicle.status))
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
                    .buttonStyle(.borderless)

                    Button(action: {
                        viewModel.deleteVehicle(vehicle)
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

    private func statusColor(_ status: VehicleStatus) -> Color {
        switch status {
        case .available: return .green
        case .inUse: return .blue
        case .maintenance: return .orange
        case .retired: return .gray
        }
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
                var vehicleToSave = vehicle ?? Vehicle(
                    name: name,
                    type: type,
                    licensePlate: licensePlate,
                    make: make,
                    model: model,
                    year: year,
                    vin: vin,
                    status: status,
                    currentOdometer: currentOdometer,
                    fuelType: fuelType
                )
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
            .keyboardShortcut(.return)
        }
        .padding()
    }
}

struct StatusBadge: View {
    let status: String
    let color: Color

    var body: some View {
        Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

struct SearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .frame(width: 200)
    }
}
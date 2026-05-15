import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showExportSuccess = false
    @State private var showResetSuccess = false
    @State private var showSaveSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                businessInfoSection

                preferencesSection

                dataManagementSection

                aboutSection
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            viewModel.loadData()
        }
        .overlay(alignment: .bottom) {
            if showSaveSuccess || showExportSuccess || showResetSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(showSaveSuccess ? "Settings saved!" : showExportSuccess ? "Data exported successfully!" : "Settings reset to defaults")
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .shadow(radius: 4)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showSaveSuccess = false
                            showExportSuccess = false
                            showResetSuccess = false
                        }
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
        }
    }

    private var businessInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Business Information", icon: "building.2")

            VStack(spacing: 12) {
                HStack {
                    Text("Company Name")
                        .frame(width: 150, alignment: .leading)
                    TextField("Company Name", text: $viewModel.settings.companyName)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Address")
                        .frame(width: 150, alignment: .leading)
                    TextField("Address", text: $viewModel.settings.address)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("City")
                        .frame(width: 150, alignment: .leading)
                    TextField("City", text: $viewModel.settings.city)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("State")
                        .frame(width: 150, alignment: .leading)
                    TextField("State", text: $viewModel.settings.state)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("ZIP")
                        .frame(width: 40)
                    TextField("ZIP", text: $viewModel.settings.zip)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                HStack {
                    Text("Phone")
                        .frame(width: 150, alignment: .leading)
                    TextField("Phone", text: $viewModel.settings.phone)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Email")
                        .frame(width: 150, alignment: .leading)
                    TextField("Email", text: $viewModel.settings.email)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            Button("Save Business Information") {
                viewModel.saveSettings()
                showSaveSuccess = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Preferences", icon: "slider.horizontal.3")

            VStack(spacing: 12) {
                HStack {
                    Text("Tax Rate (%)")
                        .frame(width: 150, alignment: .leading)
                    TextField("0", value: $viewModel.settings.taxRate, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Spacer()
                }

                HStack {
                    Text("Currency")
                        .frame(width: 150, alignment: .leading)
                    Picker("Currency", selection: $viewModel.settings.currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                        Text("CAD").tag("CAD")
                    }
                    .frame(width: 150)
                    Spacer()
                }

                HStack {
                    Text("Distance Unit")
                        .frame(width: 150, alignment: .leading)
                    Picker("Distance", selection: $viewModel.settings.distanceUnit) {
                        Text("Miles").tag("miles")
                        Text("Kilometers").tag("km")
                    }
                    .frame(width: 150)
                    Spacer()
                }

                HStack {
                    Text("Invoice Prefix")
                        .frame(width: 150, alignment: .leading)
                    TextField("INV", text: $viewModel.settings.invoicePrefix)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Spacer()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            Button("Save Preferences") {
                viewModel.saveSettings()
                showSaveSuccess = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Data Management", icon: "externaldrive")

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Export Data")
                            .font(.headline)
                        Text("Export all your data as JSON file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Export") {
                        if let url = viewModel.exportData() {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                            showExportSuccess = true
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Reset Settings")
                            .font(.headline)
                        Text("Reset all settings to default values")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Reset") {
                        viewModel.resetToDefaults()
                        showResetSuccess = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "About", icon: "info.circle")

            VStack(spacing: 8) {
                HStack {
                    Text("Application")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("TransFleet Pro")
                }

                HStack {
                    Text("Version")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1.0.0")
                }

                HStack {
                    Text("Platform")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("macOS")
                }

                Divider()

                Text("Transportation Business Management Application")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
        }
    }
}
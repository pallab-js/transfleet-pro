# TransFleet Pro - Specification Document

## 1. Project Overview

### Project Name
**TransFleet Pro** - Transportation Business Management Desktop Application

### Project Type
macOS Desktop Application (Swift + SwiftUI)

### Core Functionality
A comprehensive, offline-first desktop application for managing all aspects of a mixed-fleet transportation business. The app serves as the central hub for fleet managers, dispatchers, and business owners to manage vehicles, drivers, trips, customers, finances, and generate insightful reports.

### Target Users
- **Primary User**: Owner/Admin/Manager of the transportation business
- **Business Scale**: Large fleet (50+ vehicles/drivers)

---

## 2. Technical Specification

### Tech Stack
- **Language**: Swift 6.0+
- **UI Framework**: SwiftUI (macOS 14+)
- **Database**: SQLite.swift (for offline-first, local storage)
- **Architecture**: MVVM (Model-View-ViewModel) with Repository Pattern
- **Charts**: Swift Charts (native Apple framework)
- **Build System**: Swift Package Manager
- **Code Generation**: XcodeGen for project.yml

### Dependencies
- **SQLite.swift** (~> 0.15.0): Type-safe SQLite wrapper

---

## 3. UI/UX Specification

### Window Structure
- **Main Window**: Single-window application with sidebar navigation
- **Window Size**: Minimum 1200x800, default 1400x900
- **Window Style**: `.titled`, `.closable`, `.miniaturizable`, `.resizable`

### Navigation Structure
- **Primary**: Sidebar navigation (NavigationSplitView)
- **Sidebar Items**: Icon + Label with selection indicator
- **Content Area**: Main content with header and detail views

### Visual Design

#### Color Palette
| Role | Color | Hex Code |
|------|-------|----------|
| Primary | System Blue | #007AFF |
| Secondary | System Gray | #8E8E93 |
| Accent | System Teal | #5AC8FA |
| Success | System Green | #34C759 |
| Warning | System Orange | #FF9500 |
| Danger | System Red | #FF3B30 |
| Background | Window Background | System Default |
| Surface | Secondary System Background | System Default |
| Text Primary | Label Color | System Default |
| Text Secondary | Secondary Label Color | System Default |

#### Typography
- **Title Large**: .largeTitle (34pt, Bold)
- **Title**: .title (28pt, Bold)
- **Title 2**: .title2 (22pt, Bold)
- **Title 3**: .title3 (20pt, Semibold)
- **Headline**: .headline (17pt, Semibold)
- **Body**: .body (17pt, Regular)
- **Callout**: .callout (16pt, Regular)
- **Subheadline**: .subheadline (15pt, Regular)
- **Footnote**: .footnote (13pt, Regular)
- **Caption**: .caption (12pt, Regular)

#### Spacing System (8pt Grid)
- **XS**: 4pt
- **S**: 8pt
- **M**: 16pt
- **L**: 24pt
- **XL**: 32pt
- **XXL**: 48pt

### Component Library

#### Navigation Sidebar
- Width: 240pt (collapsible to 60pt icon-only)
- Items: Dashboard, Fleet, Drivers, Trips, Customers, Finance, Reports, Settings
- Selected state: System accent color background
- Hover state: 5% opacity overlay

#### Data Tables
- Row height: 44pt
- Alternating row colors: Yes (subtle)
- Selection: Single-click row selection
- Sorting: Click column header
- Pagination: 25/50/100 items per page

#### Cards
- Corner radius: 12pt
- Shadow: subtle (0.5pt, 10% opacity)
- Padding: 16pt
- Background: Surface color

#### Forms
- Field height: 36pt
- Label: Above field (Subheadline)
- Corner radius: 8pt
- Focus ring: System accent

#### Buttons
- Primary: Filled, accent color
- Secondary: Outlined
- Destructive: Red filled
- Corner radius: 8pt
- Height: 36pt (standard), 28pt (compact)

---

## 4. Functional Specification

### Module 1: Dashboard

#### Purpose
Overview of business operations with key metrics and quick actions

#### Features
- **KPI Cards**: Total Vehicles, Active Drivers, Today's Trips, Revenue (MTD)
- **Charts**: Weekly trip trends, Fleet utilization pie chart
- **Recent Activity**: Last 10 activities (trips, maintenance, etc.)
- **Quick Actions**: New Trip, Add Vehicle, Add Driver
- **Alerts**: Overdue maintenance, expiring licenses

#### Data Display
- Real-time counts from database
- Date range filters for charts (7 days, 30 days, 90 days, custom)

### Module 2: Fleet Management

#### Purpose
Manage all vehicles in the fleet

#### Features
- **Vehicle List**: Table view with columns: ID, Name, Type, License Plate, Status, Last Maintenance, Next Maintenance Due
- **Vehicle Types**: Truck, Van, Car, Bike, Bus
- **Vehicle Status**: Available, In Use, Maintenance, Retired
- **Add/Edit Vehicle**: Form with all vehicle details
- **Vehicle Detail View**: Full history, maintenance logs, fuel logs
- **Maintenance Tracking**: Schedule, record, cost tracking
- **Fuel Logs**: Date, odometer, quantity, cost, fuel type

#### Vehicle Data Model
```
Vehicle:
  - id: UUID (primary key)
  - name: String
  - type: VehicleType (enum)
  - licensePlate: String
  - make: String
  - model: String
  - year: Int
  - vin: String
  - status: VehicleStatus (enum)
  - purchaseDate: Date?
  - purchasePrice: Double?
  - currentOdometer: Int
  - fuelType: FuelType (enum)
  - notes: String?
  - createdAt: Date
  - updatedAt: Date

MaintenanceRecord:
  - id: UUID (primary key)
  - vehicleId: UUID (foreign key)
  - type: MaintenanceType (enum)
  - description: String
  - date: Date
  - odometer: Int
  - cost: Double
  - vendor: String?
  - notes: String?
  - createdAt: Date

FuelLog:
  - id: UUID (primary key)
  - vehicleId: UUID (foreign key)
  - date: Date
  - odometer: Int
  - quantity: Double
  - pricePerUnit: Double
  - totalCost: Double
  - fuelType: FuelType
  - location: String?
  - notes: String?
  - createdAt: Date
```

### Module 3: Driver Management

#### Purpose
Manage driver profiles, certifications, and performance

#### Features
- **Driver List**: Table with columns: ID, Name, Phone, Email, License #, Status, Rating
- **Driver Status**: Active, On Leave, Suspended, Terminated
- **Add/Edit Driver**: Complete profile form
- **Driver Detail View**: Assigned vehicles, trip history, performance metrics
- **License Tracking**: License number, expiry date, endorsements
- **Certifications**: Type, issue date, expiry date
- **Availability Calendar**: Weekly schedule view
- **Performance Metrics**: On-time delivery %, trips completed, accidents

#### Driver Data Model
```
Driver:
  - id: UUID (primary key)
  - firstName: String
  - lastName: String
  - email: String
  - phone: String
  - address: String?
  - emergencyContact: String?
  - emergencyPhone: String?
  - licenseNumber: String
  - licenseState: String
  - licenseExpiry: Date
  - status: DriverStatus (enum)
  - hireDate: Date
  - terminationDate: Date?
  - notes: String?
  - rating: Double (0-5)
  - createdAt: Date
  - updatedAt: Date

Certification:
  - id: UUID (primary key)
  - driverId: UUID (foreign key)
  - type: CertificationType (enum)
  - name: String
  - issuedDate: Date
  - expiryDate: Date?
  - documentNumber: String?
  - createdAt: Date

Availability:
  - id: UUID (primary key)
  - driverId: UUID (foreign key)
  - dayOfWeek: Int (1-7)
  - startTime: String
  - endTime: String
  - isAvailable: Bool
```

### Module 4: Trips/Jobs

#### Purpose
Create, assign, track, and manage all trips/jobs

#### Features
- **Trip List**: Table with columns: ID, Job #, Customer, Driver, Vehicle, Origin, Destination, Status, Date, Revenue
- **Trip Status**: Pending, Assigned, In Transit, Delivered, Completed, Cancelled
- **Create Trip**: Form with customer, route, vehicle, driver, pricing
- **Trip Detail View**: Full journey details, updates, documents
- **Dispatch**: Assign driver and vehicle to pending trips
- **Status Updates**: Real-time status changes with timestamps
- **Trip History**: Searchable archive with filters

#### Trip Data Model
```
Trip:
  - id: UUID (primary key)
  - jobNumber: String (auto-generated)
  - customerId: UUID (foreign key)
  - driverId: UUID? (foreign key, nullable)
  - vehicleId: UUID? (foreign key, nullable)
  - status: TripStatus (enum)
  - pickupAddress: String
  - pickupCity: String
  - pickupState: String
  - pickupZip: String
  - pickupDate: Date
  - deliveryAddress: String
  - deliveryCity: String
  - deliveryState: String
  - deliveryZip: String
  - deliveryDate: Date?
  - distance: Double? (miles)
  - cargoDescription: String?
  - cargoWeight: Double?
  - rate: Double
  - fuelSurcharge: Double
  - totalAmount: Double
  - notes: String?
  - createdAt: Date
  - updatedAt: Date

TripUpdate:
  - id: UUID (primary key)
  - tripId: UUID (foreign key)
  - status: TripStatus (enum)
  - timestamp: Date
  - location: String?
  - notes: String?
```

### Module 5: Customers

#### Purpose
Manage customer contacts and billing information

#### Features
- **Customer List**: Table with columns: ID, Company, Contact, Phone, Email, Balance, Last Trip
- **Customer Types**: Commercial, Residential, Government
- **Add/Edit Customer**: Full profile with billing info
- **Customer Detail View**: Contact info, billing, trip history
- **Credit Limit**: Configurable per customer
- **Payment Terms**: Net 15/30/45/60
- **Notes**: Internal notes about customer

#### Customer Data Model
```
Customer:
  - id: UUID (primary key)
  - companyName: String
  - contactName: String
  - email: String
  - phone: String
  - type: CustomerType (enum)
  - address: String
  - city: String
  - state: String
  - zip: String
  - creditLimit: Double
  - paymentTerms: Int (days)
  - taxId: String?
  - notes: String?
  - createdAt: Date
  - updatedAt: Date
```

### Module 6: Finance

#### Purpose
Track invoices, expenses, revenue, and profitability

#### Features
- **Invoice List**: Table with columns: Invoice #, Customer, Date, Due Date, Amount, Status
- **Invoice Status**: Draft, Sent, Paid, Overdue, Cancelled
- **Create Invoice**: Auto-generate from completed trips
- **Expense Tracking**: Categories, vendors, amounts, dates
- **Revenue Dashboard**: Monthly/quarterly/yearly views
- **Profit Margins**: By trip, by customer, by route
- **Expense Categories**: Fuel, Maintenance, Insurance, Payroll, Other

#### Finance Data Model
```
Invoice:
  - id: UUID (primary key)
  - invoiceNumber: String (auto-generated)
  - customerId: UUID (foreign key)
  - tripIds: [UUID] (array of foreign keys)
  - invoiceDate: Date
  - dueDate: Date
  - subtotal: Double
  - tax: Double
  - total: Double
  - status: InvoiceStatus (enum)
  - paidDate: Date?
  - notes: String?
  - createdAt: Date
  - updatedAt: Date

Expense:
  - id: UUID (primary key)
  - category: ExpenseCategory (enum)
  - vendor: String?
  - description: String
  - amount: Double
  - date: Date
  - vehicleId: UUID? (foreign key, nullable)
  - driverId: UUID? (foreign key, nullable)
  - receiptNumber: String?
  - notes: String?
  - createdAt: Date
```

### Module 7: Reports

#### Purpose
Generate analytics and insights from business data

#### Report Types
1. **Fleet Utilization Report**: Vehicle usage %, idle time, total miles
2. **Driver Performance Report**: Trips, on-time %, miles, incidents
3. **Revenue Report**: By period, by customer, by route
4. **Expense Report**: By category, by vehicle, trends
5. **Profit & Loss Statement**: Income, expenses, net profit
6. **Customer Analytics**: Revenue by customer, payment patterns

#### Features
- **Date Range Selection**: Custom date pickers
- **Export Options**: PDF, CSV
- **Visual Charts**: Bar, line, pie charts
- **Print-friendly**: Formatted for printing

### Module 8: Settings

#### Purpose
Configure application and business preferences

#### Features
- **Business Profile**: Company name, address, contact, logo
- **User Preferences**: Default views, date format, currency
- **Data Management**: Backup, restore, export all data
- **Units**: Distance (miles/km), Currency (USD)
- **Invoice Settings**: Prefix, numbering format, tax rate
- **About**: Version, licenses, support info

---

## 5. Implementation Notes

### Database Schema
All tables use UUID primary keys with indexed foreign keys for performance. Foreign key constraints enabled for data integrity.

### Offline-First Architecture
- All data stored locally in SQLite database
- No network dependency
- Data persists across app restarts
- File-based backup system

### Performance Considerations
- Lazy loading for large datasets
- Background processing for heavy operations
- Efficient queries with proper indexing
- Pagination for list views (25 items default)

### Security
- Local-only data (no cloud sync in v1)
- No sensitive data transmitted
- Database file stored in Application Support

---

## 6. Acceptance Criteria

### Functional Requirements
- [ ] Application launches without errors
- [ ] All 8 modules are accessible and functional
- [ ] CRUD operations work for all entities
- [ ] Data persists across app restarts
- [ ] Charts display correct data

### UI Requirements
- [ ] Sidebar navigation works correctly
- [ ] Forms validate input properly
- [ ] Tables sort and paginate correctly
- [ ] Responsive to window resizing
- [ ] Dark mode support (system-based)

### Performance Requirements
- [ ] App launches in under 3 seconds
- [ ] List operations handle 1000+ records smoothly
- [ ] No memory leaks during extended use

### Code Quality
- [ ] Clean architecture separation
- [ ] Proper error handling
- [ ] No compiler warnings
- [ ] Follows Swift API guidelines
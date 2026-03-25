import SwiftUI
import UIKit

// MARK: - Garage View
struct GarageView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddVehicle = false
    @State private var selectedVehicle: Vehicle? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DNSpacing.lg) {
                    // Header
                    HStack {
                        DNSectionHeader(title: "My Garage", subtitle: "\(dataStore.vehicles.count) vehicle\(dataStore.vehicles.count == 1 ? "" : "s")")
                        Spacer()
                        Button(action: { showAddVehicle = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color.dnAccentBlue)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "plus")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, DNSpacing.md)
                    .padding(.top, DNSpacing.md)
                    
                    if dataStore.vehicles.isEmpty {
                        DNEmptyState(
                            icon: "car.2.fill",
                            title: "No Vehicles Yet",
                            message: "Add your car to start tracking maintenance, expenses, and more.",
                            actionTitle: "Add Vehicle",
                            action: { showAddVehicle = true }
                        )
                    } else {
                        ForEach(dataStore.vehicles) { vehicle in
                            GarageVehicleCard(vehicle: vehicle, selectedVehicle: $selectedVehicle)
                                .padding(.horizontal, DNSpacing.md)
                        }
                    }
                    
                    Color.clear.frame(height: 90)
                }
            }
            .background(Color.dnBackground.ignoresSafeArea())
            .sheet(isPresented: $showAddVehicle) { AddVehicleView() }
            .sheet(item: $selectedVehicle) { v in VehicleDetailView(vehicle: v) }
            .navigationBarHidden(true)
        }
    }
}

struct GarageVehicleCard: View {
    let vehicle: Vehicle
    @Binding var selectedVehicle: Vehicle?
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showDeleteAlert = false
    @State private var appear = false
    
    var lastService: ServiceRecord? {
        dataStore.serviceRecords.filter { $0.vehicleId == vehicle.id }.sorted { $0.date > $1.date }.first
    }
    
    var body: some View {
        Button(action: {
            appState.selectedVehicleId = vehicle.id
            selectedVehicle = vehicle
        }) {
            DNCard {
                VStack(spacing: DNSpacing.md) {
                    HStack(spacing: DNSpacing.md) {
                        // Vehicle photo / icon
                        ZStack {
                            RoundedRectangle(cornerRadius: DNRadius.md)
                                .fill(Color.dnCardElevated)
                                .frame(width: 80, height: 60)
                            
                            if let img = vehicle.photoImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 60)
                                    .cornerRadius(DNRadius.md)
                                    .clipped()
                            } else {
                                Image(systemName: "car.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(LinearGradient.dnBlueGradient)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(vehicle.displayName)
                                .font(DNFont.heading(16))
                                .foregroundColor(.dnText)
                            Text("\(vehicle.year) • \(vehicle.transmission.rawValue)")
                                .font(DNFont.body(12))
                                .foregroundColor(.dnTextSecondary)
                            
                            HStack(spacing: 6) {
                                DNBadge(text: vehicle.fuelType.rawValue, color: .dnAccentOrange)
                                if !vehicle.licensePlate.isEmpty {
                                    DNBadge(text: vehicle.licensePlate, color: .dnAccentBlue)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Active indicator
                        if appState.selectedVehicleId == vehicle.id {
                            Circle()
                                .fill(Color.dnGreen)
                                .frame(width: 10, height: 10)
                                .dnShadow(color: .dnGreen.opacity(0.5), radius: 4)
                        }
                    }
                    
                    Divider().background(Color.dnBorder)
                    
                    HStack {
                        VehicleInfoMini(label: "Mileage", value: NumberHelper.distance(vehicle.currentMileage, unit: appState.distanceUnit))
                        Spacer()
                        VehicleInfoMini(label: "Last Service", value: lastService != nil ? NumberHelper.shortDate(lastService!.date) : "Never")
                        Spacer()
                        VehicleInfoMini(label: "Services", value: "\(dataStore.vehicleServices(vehicle.id).count)")
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(appear ? 1 : 0.95)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.dnSpring.delay(0.1)) { appear = true }
        }
        .contextMenu {
            Button(action: { appState.selectedVehicleId = vehicle.id }) {
                Label("Set as Active", systemImage: "checkmark.circle")
            }
            Button(action: { selectedVehicle = vehicle }) {
                Label("View Details", systemImage: "info.circle")
            }
            Button(role: .destructive, action: { showDeleteAlert = true }) {
                Label("Delete Vehicle", systemImage: "trash")
            }
        }
        .alert("Delete Vehicle", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                withAnimation(.dnSpring) { dataStore.deleteVehicle(vehicle) }
            }
        } message: {
            Text("This will permanently delete \(vehicle.displayName) and all its data.")
        }
    }
}

struct VehicleInfoMini: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(DNFont.mono(12))
                .foregroundColor(.dnText)
            Text(label)
                .font(DNFont.label(10))
                .foregroundColor(.dnTextSecondary)
        }
    }
}

// MARK: - Vehicle Detail View
struct VehicleDetailView: View {
    let vehicle: Vehicle
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showEditVehicle = false
    @State private var showServiceLog = false
    @State private var showFuelLog = false
    @State private var showProblems = false
    @State private var showDocuments = false
    @State private var showInsurance = false
    @State private var showTires = false
    @State private var showParts = false
    @State private var showChecklist = false
    @State private var showTrips = false
    @State private var showPhotos = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                // Nav
                DNNavBar(title: vehicle.displayName, subtitle: String(vehicle.year),
                         trailingContent: AnyView(
                            Button(action: { showEditVehicle = true }) {
                                ZStack {
                                    Circle().fill(Color.dnCardElevated).frame(width: 36, height: 36)
                                    Image(systemName: "pencil").font(.system(size: 14)).foregroundColor(.dnText)
                                }
                            }
                         ))
                
                // Photo
                ZStack {
                    if let img = vehicle.photoImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    } else {
                        LinearGradient(colors: [Color.dnCard, Color.dnBackground], startPoint: .top, endPoint: .bottom)
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: "car.fill")
                                    .font(.system(size: 72))
                                    .foregroundStyle(LinearGradient.dnBlueGradient)
                            )
                    }
                }
                .cornerRadius(DNRadius.xl)
                .padding(.horizontal, DNSpacing.md)
                
                // Vehicle Info
                DNCard {
                    VStack(spacing: 0) {
                        DNInfoRow(label: "Brand", value: vehicle.brand)
                        DNInfoRow(label: "Model", value: vehicle.model)
                        DNInfoRow(label: "Year", value: String(vehicle.year))
                        DNInfoRow(label: "Engine", value: vehicle.engine.isEmpty ? "—" : vehicle.engine)
                        DNInfoRow(label: "Fuel Type", value: vehicle.fuelType.rawValue)
                        DNInfoRow(label: "Transmission", value: vehicle.transmission.rawValue)
                        DNInfoRow(label: "License Plate", value: vehicle.licensePlate.isEmpty ? "—" : vehicle.licensePlate)
                        DNInfoRow(label: "VIN", value: vehicle.vin.isEmpty ? "—" : vehicle.vin)
                        DNInfoRow(label: "Current Mileage", value: NumberHelper.distance(vehicle.currentMileage, unit: appState.distanceUnit))
                        if !vehicle.notes.isEmpty {
                            DNInfoRow(label: "Notes", value: vehicle.notes)
                        }
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                
                // Quick Nav Grid
                DNSectionHeader(title: "Vehicle Sections")
                    .padding(.horizontal, DNSpacing.md)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DNSpacing.sm) {
                    VehicleNavButton(icon: "wrench.fill", title: "Services", color: .dnAccentBlue) { showServiceLog = true }
                    VehicleNavButton(icon: "fuelpump.fill", title: "Fuel Log", color: .dnAccentOrange) { showFuelLog = true }
                    VehicleNavButton(icon: "exclamationmark.triangle.fill", title: "Problems", color: .dnRed) { showProblems = true }
                    VehicleNavButton(icon: "map.fill", title: "Trips", color: .dnGreen) { showTrips = true }
                    VehicleNavButton(icon: "doc.fill", title: "Documents", color: Color(hex: "#9B59B6")) { showDocuments = true }
                    VehicleNavButton(icon: "shield.fill", title: "Insurance", color: Color(hex: "#3498DB")) { showInsurance = true }
                    VehicleNavButton(icon: "circle.fill", title: "Tires", color: Color(hex: "#E67E22")) { showTires = true }
                    VehicleNavButton(icon: "gearshape.fill", title: "Parts", color: Color(hex: "#1ABC9C")) { showParts = true }
                    VehicleNavButton(icon: "camera.fill", title: "Photos", color: Color(hex: "#E91E63")) { showPhotos = true }
                }
                .padding(.horizontal, DNSpacing.md)
                
                Color.clear.frame(height: 60)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showEditVehicle) { EditVehicleView(vehicle: vehicle) }
        .sheet(isPresented: $showServiceLog) { ServiceLogView(vehicleId: vehicle.id) }
        .sheet(isPresented: $showFuelLog) { FuelLogView(vehicleId: vehicle.id) }
        .sheet(isPresented: $showProblems) { ProblemLogView(vehicleId: vehicle.id) }
        .sheet(isPresented: $showTrips) { TripListView(vehicleId: vehicle.id) }
        .sheet(isPresented: $showDocuments) { DocumentsView(vehicleId: vehicle.id) }
        .sheet(isPresented: $showInsurance) { InsuranceView(vehicleId: vehicle.id) }
        .sheet(isPresented: $showTires) { TiresView(vehicleId: vehicle.id) }
        .sheet(isPresented: $showParts) { PartsLibraryView(vehicleId: vehicle.id) }
        .sheet(isPresented: $showPhotos) { PhotoJournalView(vehicleId: vehicle.id) }
    }
}

struct VehicleNavButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.dnFast) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.dnFast) { isPressed = false }
            }
            action()
        }) {
            VStack(spacing: DNSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: DNRadius.md)
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(DNFont.label(11))
                    .foregroundColor(.dnText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DNSpacing.md)
            .background(Color.dnCard)
            .cornerRadius(DNRadius.lg)
            .scaleEffect(isPressed ? 0.93 : 1.0)
        }
    }
}

// MARK: - Add Vehicle View
struct AddVehicleView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var brand = ""
    @State private var model = ""
    @State private var year = String(Calendar.current.component(.year, from: Date()))
    @State private var engine = ""
    @State private var licensePlate = ""
    @State private var vin = ""
    @State private var mileage = ""
    @State private var fuelType = Vehicle.FuelType.petrol
    @State private var transmission = Vehicle.TransmissionType.manual
    @State private var notes = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var showError = false
    @State private var errorMsg = ""
    @State private var showSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Vehicle", trailingContent: AnyView(EmptyView()))
                
                // Photo area
                Button(action: { showImagePicker = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DNRadius.xl)
                            .fill(Color.dnCard)
                            .frame(height: 160)
                        
                        if let img = selectedImage {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .cornerRadius(DNRadius.xl)
                                .clipped()
                        } else {
                            VStack(spacing: DNSpacing.sm) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.dnAccentBlue)
                                Text("Add Car Photo")
                                    .font(DNFont.label(14))
                                    .foregroundColor(.dnTextSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                
                // Form
                VStack(spacing: DNSpacing.md) {
                    DNTextField(title: "Brand", text: $brand, placeholder: "e.g. Toyota", icon: "car.fill")
                    DNTextField(title: "Model", text: $model, placeholder: "e.g. Corolla", icon: "car.rear.fill")
                    DNTextField(title: "Year", text: $year, placeholder: "2020", icon: "calendar", keyboardType: .numberPad)
                    DNTextField(title: "Engine", text: $engine, placeholder: "e.g. 1.6L", icon: "engine.combustion.fill")
                    DNTextField(title: "License Plate", text: $licensePlate, icon: "rectangle.fill")
                    DNTextField(title: "VIN / Chassis Number", text: $vin, icon: "barcode")
                    DNTextField(title: "Current Mileage (\(appState.distanceUnit))", text: $mileage, placeholder: "0", icon: "speedometer", keyboardType: .decimalPad)
                    
                    // Fuel Type Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fuel Type")
                            .font(DNFont.label(12))
                            .foregroundColor(.dnTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Vehicle.FuelType.allCases, id: \.self) { type in
                                    Button(action: { fuelType = type }) {
                                        Text(type.rawValue)
                                            .font(DNFont.label(13))
                                            .foregroundColor(fuelType == type ? .white : .dnTextSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(fuelType == type ? Color.dnAccentOrange : Color.dnCardElevated)
                                            .cornerRadius(DNRadius.pill)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Transmission Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Transmission")
                            .font(DNFont.label(12))
                            .foregroundColor(.dnTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Vehicle.TransmissionType.allCases, id: \.self) { type in
                                    Button(action: { transmission = type }) {
                                        Text(type.rawValue)
                                            .font(DNFont.label(13))
                                            .foregroundColor(transmission == type ? .white : .dnTextSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(transmission == type ? Color.dnAccentBlue : Color.dnCardElevated)
                                            .cornerRadius(DNRadius.pill)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(DNFont.label(12))
                            .foregroundColor(.dnTextSecondary)
                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color.dnCardElevated)
                            .cornerRadius(DNRadius.md)
                            .foregroundColor(.dnText)
                            .font(DNFont.body(15))
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                
                if showError {
                    DNAlertCard(title: "Error", message: errorMsg, type: .danger)
                        .padding(.horizontal, DNSpacing.md)
                        .transition(.scale.combined(with: .opacity))
                }
                if showSuccess {
                    DNAlertCard(title: "Vehicle Added!", message: "Your vehicle has been saved.", type: .success)
                        .padding(.horizontal, DNSpacing.md)
                }
                
                DNButton("Save Vehicle", gradient: .dnBlueGradient) { saveVehicle() }
                    .padding(.horizontal, DNSpacing.md)
                    .padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    private func saveVehicle() {
        guard !brand.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError = true; errorMsg = "Please enter the vehicle brand."; return
        }
        guard !model.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError = true; errorMsg = "Please enter the vehicle model."; return
        }
        guard let yearInt = Int(year), yearInt > 1900, yearInt <= Calendar.current.component(.year, from: Date()) + 1 else {
            showError = true; errorMsg = "Please enter a valid year."; return
        }
        let mileageDouble = Double(mileage) ?? 0
        
        var vehicle = Vehicle(
            brand: brand.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            year: yearInt,
            engine: engine,
            licensePlate: licensePlate,
            vin: vin,
            currentMileage: mileageDouble,
            fuelType: fuelType,
            transmission: transmission,
            notes: notes,
            nickname: "\(brand) \(model)"
        )
        
        if let img = selectedImage {
            vehicle.photoData = img.jpegData(compressionQuality: 0.7)
        }
        
        showError = false
        dataStore.addVehicle(vehicle)
        appState.selectedVehicleId = vehicle.id
        
        withAnimation(.dnSpring) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Edit Vehicle View
struct EditVehicleView: View {
    let vehicle: Vehicle
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var brand: String
    @State private var model: String
    @State private var year: String
    @State private var engine: String
    @State private var licensePlate: String
    @State private var vin: String
    @State private var mileage: String
    @State private var fuelType: Vehicle.FuelType
    @State private var transmission: Vehicle.TransmissionType
    @State private var notes: String
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showSuccess = false
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _brand = State(initialValue: vehicle.brand)
        _model = State(initialValue: vehicle.model)
        _year = State(initialValue: String(vehicle.year))
        _engine = State(initialValue: vehicle.engine)
        _licensePlate = State(initialValue: vehicle.licensePlate)
        _vin = State(initialValue: vehicle.vin)
        _mileage = State(initialValue: String(format: "%.0f", vehicle.currentMileage))
        _fuelType = State(initialValue: vehicle.fuelType)
        _transmission = State(initialValue: vehicle.transmission)
        _notes = State(initialValue: vehicle.notes)
        _selectedImage = State(initialValue: vehicle.photoImage)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Edit Vehicle", trailingContent: AnyView(EmptyView()))
                
                Button(action: { showImagePicker = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DNRadius.xl).fill(Color.dnCard).frame(height: 160)
                        if let img = selectedImage {
                            Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                                .frame(height: 160).cornerRadius(DNRadius.xl).clipped()
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill").font(.system(size: 36)).foregroundColor(.dnAccentBlue)
                                Text("Tap to change photo").font(DNFont.label(13)).foregroundColor(.dnTextSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                
                VStack(spacing: DNSpacing.md) {
                    DNTextField(title: "Brand", text: $brand, icon: "car.fill")
                    DNTextField(title: "Model", text: $model, icon: "car.rear.fill")
                    DNTextField(title: "Year", text: $year, icon: "calendar", keyboardType: .numberPad)
                    DNTextField(title: "Engine", text: $engine, icon: "engine.combustion.fill")
                    DNTextField(title: "License Plate", text: $licensePlate, icon: "rectangle.fill")
                    DNTextField(title: "VIN", text: $vin, icon: "barcode")
                    DNTextField(title: "Current Mileage", text: $mileage, icon: "speedometer", keyboardType: .decimalPad)
                }
                .padding(.horizontal, DNSpacing.md)
                
                if showSuccess {
                    DNAlertCard(title: "Saved!", message: "Vehicle updated successfully.", type: .success)
                        .padding(.horizontal, DNSpacing.md)
                }
                
                DNButton("Save Changes") {
                    var updated = vehicle
                    updated.brand = brand
                    updated.model = model
                    updated.year = Int(year) ?? vehicle.year
                    updated.engine = engine
                    updated.licensePlate = licensePlate
                    updated.vin = vin
                    updated.currentMileage = Double(mileage) ?? vehicle.currentMileage
                    updated.fuelType = fuelType
                    updated.transmission = transmission
                    updated.notes = notes
                    if let img = selectedImage { updated.photoData = img.jpegData(compressionQuality: 0.7) }
                    dataStore.updateVehicle(updated)
                    withAnimation(.dnSpring) { showSuccess = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
                }
                .padding(.horizontal, DNSpacing.md)
                .padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showImagePicker) { ImagePicker(image: $selectedImage) }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

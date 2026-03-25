import SwiftUI
import UIKit

// MARK: - Documents View
struct DocumentsView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @State private var showAdd = false
    
    var docs: [CarDocument] { dataStore.documents.filter { $0.vehicleId == vehicleId }.sorted { $0.uploadedAt > $1.uploadedAt } }
    
    var body: some View {
        VStack(spacing: 0) {
            DNNavBar(title: "Documents", subtitle: "\(docs.count) files",
                     trailingContent: AnyView(
                        Button(action: { showAdd = true }) {
                            ZStack {
                                Circle().fill(Color(hex: "#9B59B6")).frame(width: 34, height: 34)
                                Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                        }
                     ))
            
            if docs.isEmpty {
                DNEmptyState(icon: "doc.fill", title: "No Documents", message: "Store insurance, registration, and service receipts.", actionTitle: "Add Document", action: { showAdd = true })
            } else {
                ScrollView {
                    VStack(spacing: DNSpacing.sm) {
                        ForEach(docs) { doc in DocumentCard(doc: doc) }
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, DNSpacing.md).padding(.top, DNSpacing.sm)
                }
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAdd) { AddDocumentView(vehicleId: vehicleId) }
    }
}

struct DocumentCard: View {
    let doc: CarDocument
    @EnvironmentObject var dataStore: DataStore
    @State private var showDelete = false
    
    var statusColor: Color {
        if doc.isExpired { return .dnRed }
        if doc.isExpiringSoon { return .dnAccentOrange }
        return .dnGreen
    }
    
    var statusText: String {
        if doc.isExpired { return "Expired" }
        if doc.isExpiringSoon { return "Expiring Soon" }
        if doc.expiryDate != nil { return "Valid" }
        return "No Expiry"
    }
    
    var body: some View {
        DNCard {
            HStack(spacing: DNSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DNRadius.sm).fill(Color(hex: "#9B59B6").opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: doc.type.icon).font(.system(size: 20)).foregroundColor(Color(hex: "#9B59B6"))
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(doc.title).font(DNFont.label(14)).foregroundColor(.dnText)
                    Text(doc.type.rawValue).font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                    if let expiry = doc.expiryDate {
                        HStack(spacing: 4) {
                            Circle().fill(statusColor).frame(width: 7, height: 7)
                            Text("\(statusText) · \(NumberHelper.shortDate(expiry))").font(DNFont.body(11)).foregroundColor(statusColor)
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.dnTextSecondary)
            }
        }
        .contextMenu {
            Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
        }
        .alert("Delete Document", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dataStore.deleteDocument(doc) }
        }
    }
}

struct AddDocumentView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var type = CarDocument.DocumentType.insurance
    @State private var title = ""
    @State private var expiryDate = Date()
    @State private var hasExpiry = false
    @State private var notes = ""
    @State private var showSuccess = false
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Document", trailingContent: AnyView(EmptyView()))
                
                VStack(spacing: DNSpacing.md) {
                    // Type selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Document Type").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(CarDocument.DocumentType.allCases, id: \.self) { t in
                                Button(action: { type = t }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: t.icon).font(.system(size: 15))
                                        Text(t.rawValue).font(DNFont.label(13))
                                    }
                                    .foregroundColor(type == t ? .white : .dnTextSecondary)
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(type == t ? Color(hex: "#9B59B6") : Color.dnCardElevated)
                                    .cornerRadius(DNRadius.md)
                                }
                            }
                        }
                    }
                    
                    DNTextField(title: "Document Title", text: $title, icon: "doc.fill")
                    
                    HStack {
                        Text("Has Expiry Date").font(DNFont.label(14)).foregroundColor(.dnText)
                        Spacer()
                        Toggle("", isOn: $hasExpiry).tint(.dnAccentBlue)
                    }
                    .padding(.horizontal, DNSpacing.md).padding(.vertical, 13)
                    .background(Color.dnCardElevated).cornerRadius(DNRadius.md)
                    
                    if hasExpiry {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Expiry Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                            DatePicker("", selection: $expiryDate, displayedComponents: .date)
                                .datePickerStyle(.compact).labelsHidden()
                                .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                                .background(Color.dnCardElevated).cornerRadius(DNRadius.md).colorScheme(.dark)
                        }
                    }
                    
                    DNTextField(title: "Notes", text: $notes, icon: "note.text")
                }
                .padding(.horizontal, DNSpacing.md)
                
                if showError { DNAlertCard(title: "Error", message: "Please enter a document title.", type: .danger).padding(.horizontal, DNSpacing.md) }
                if showSuccess { DNAlertCard(title: "Document Added!", message: "Document saved.", type: .success).padding(.horizontal, DNSpacing.md) }
                
                DNButton("Save Document") { saveDocument() }
                    .padding(.horizontal, DNSpacing.md).padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
    
    private func saveDocument() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { showError = true; return }
        let doc = CarDocument(vehicleId: vehicleId, type: type, title: title,
                              expiryDate: hasExpiry ? expiryDate : nil, notes: notes)
        dataStore.addDocument(doc)
        withAnimation(.dnSpring) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
    }
}

// MARK: - Photo Journal View
struct PhotoJournalView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedCategory: CarPhoto.PhotoCategory? = nil
    @State private var showAdd = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var newCaption = ""
    @State private var newCategory = CarPhoto.PhotoCategory.exterior
    
    var photos: [CarPhoto] {
        let base = dataStore.photos.filter { $0.vehicleId == vehicleId }
        if let cat = selectedCategory { return base.filter { $0.category == cat } }
        return base.sorted { $0.takenAt > $1.takenAt }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DNNavBar(title: "Photo Journal", subtitle: "\(photos.count) photos",
                     trailingContent: AnyView(
                        Button(action: { showAdd = true }) {
                            ZStack {
                                Circle().fill(Color(hex: "#E91E63")).frame(width: 34, height: 34)
                                Image(systemName: "camera.fill").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                        }
                     ))
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                    ForEach(CarPhoto.PhotoCategory.allCases, id: \.self) { cat in
                        FilterChip(title: cat.rawValue, color: .dnAccentBlue, isSelected: selectedCategory == cat) { selectedCategory = cat }
                    }
                }
                .padding(.horizontal, DNSpacing.md)
            }
            .padding(.vertical, DNSpacing.sm)
            
            if photos.isEmpty {
                DNEmptyState(icon: "photo.fill", title: "No Photos", message: "Document your car with photos by category.", actionTitle: "Add Photo", action: { showAdd = true })
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        ForEach(photos) { photo in
                            PhotoThumbnail(photo: photo)
                        }
                    }
                    Color.clear.frame(height: 30)
                }
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAdd) { AddPhotoView(vehicleId: vehicleId) }
    }
}

struct PhotoThumbnail: View {
    let photo: CarPhoto
    @EnvironmentObject var dataStore: DataStore
    @State private var showDelete = false
    
    var body: some View {
        if let img = UIImage(data: photo.imageData) {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: img)
                    .resizable().aspectRatio(1, contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity).clipped()
                
                LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                Text(photo.category.rawValue)
                    .font(DNFont.label(9)).foregroundColor(.white)
                    .padding(4)
            }
            .aspectRatio(1, contentMode: .fit)
            .contextMenu {
                Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
            }
            .alert("Delete Photo", isPresented: $showDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { dataStore.deletePhoto(photo) }
            }
        }
    }
}

struct AddPhotoView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var caption = ""
    @State private var category = CarPhoto.PhotoCategory.exterior
    @State private var showSuccess = false
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Photo", trailingContent: AnyView(EmptyView()))
                
                // Photo area
                Button(action: { showImagePicker = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DNRadius.xl).fill(Color.dnCard).frame(height: 220)
                        if let img = selectedImage {
                            Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                                .frame(height: 220).cornerRadius(DNRadius.xl).clipped()
                        } else {
                            VStack(spacing: DNSpacing.sm) {
                                Image(systemName: "camera.fill").font(.system(size: 44)).foregroundColor(.dnAccentBlue)
                                Text("Tap to select photo").font(DNFont.label(14)).foregroundColor(.dnTextSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, DNSpacing.md)
                
                VStack(spacing: DNSpacing.md) {
                    // Category
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(CarPhoto.PhotoCategory.allCases, id: \.self) { cat in
                                    Button(action: { category = cat }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: cat.icon).font(.system(size: 12))
                                            Text(cat.rawValue).font(DNFont.label(12))
                                        }
                                        .foregroundColor(category == cat ? .white : .dnTextSecondary)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(category == cat ? Color(hex: "#E91E63") : Color.dnCardElevated)
                                        .cornerRadius(DNRadius.pill)
                                    }
                                }
                            }
                        }
                    }
                    
                    DNTextField(title: "Caption", text: $caption, icon: "text.bubble.fill")
                }
                .padding(.horizontal, DNSpacing.md)
                
                if showError { DNAlertCard(title: "Error", message: "Please select a photo first.", type: .danger).padding(.horizontal, DNSpacing.md) }
                if showSuccess { DNAlertCard(title: "Photo Added!", message: "Photo saved to journal.", type: .success).padding(.horizontal, DNSpacing.md) }
                
                DNButton("Save Photo") { savePhoto() }
                    .padding(.horizontal, DNSpacing.md).padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showImagePicker) { ImagePicker(image: $selectedImage) }
    }
    
    private func savePhoto() {
        guard let img = selectedImage, let data = img.jpegData(compressionQuality: 0.7) else { showError = true; return }
        let photo = CarPhoto(vehicleId: vehicleId, category: category, imageData: data, caption: caption, takenAt: Date())
        dataStore.addPhoto(photo)
        withAnimation(.dnSpring) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
    }
}

// MARK: - Parts Library View
struct PartsLibraryView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showAdd = false
    
    var parts: [CarPart] { dataStore.parts.filter { $0.vehicleId == vehicleId }.sorted { $0.installDate > $1.installDate } }
    
    var body: some View {
        VStack(spacing: 0) {
            DNNavBar(title: "Parts Library", subtitle: "\(parts.count) parts",
                     trailingContent: AnyView(
                        Button(action: { showAdd = true }) {
                            ZStack {
                                Circle().fill(Color(hex: "#1ABC9C")).frame(width: 34, height: 34)
                                Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                        }
                     ))
            
            if parts.isEmpty {
                DNEmptyState(icon: "gearshape.fill", title: "No Parts", message: "Track installed parts, their costs and install dates.", actionTitle: "Add Part", action: { showAdd = true })
            } else {
                ScrollView {
                    VStack(spacing: DNSpacing.sm) {
                        ForEach(parts) { part in PartCard(part: part) }
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, DNSpacing.md).padding(.top, DNSpacing.sm)
                }
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAdd) { AddPartView(vehicleId: vehicleId) }
    }
}

struct PartCard: View {
    let part: CarPart
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showDelete = false
    
    var body: some View {
        DNCard {
            HStack(spacing: DNSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DNRadius.sm).fill(Color(hex: "#1ABC9C").opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: "gearshape.fill").font(.system(size: 20)).foregroundColor(Color(hex: "#1ABC9C"))
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(part.name).font(DNFont.label(14)).foregroundColor(.dnText)
                    Text(part.brand.isEmpty ? "Unknown Brand" : part.brand).font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                    if !part.partNumber.isEmpty { Text("P/N: \(part.partNumber)").font(DNFont.mono(11)).foregroundColor(.dnAccentBlue) }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NumberHelper.currency(part.cost, appState.currency)).font(DNFont.mono(14)).foregroundColor(.dnAccentOrange)
                    Text(NumberHelper.shortDate(part.installDate)).font(DNFont.body(11)).foregroundColor(.dnTextSecondary)
                }
            }
        }
        .contextMenu {
            Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
        }
        .alert("Delete Part", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dataStore.deletePart(part) }
        }
    }
}

struct AddPartView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var partNumber = ""
    @State private var brand = ""
    @State private var installDate = Date()
    @State private var cost = ""
    @State private var notes = ""
    @State private var showSuccess = false
    @State private var showError = false
    
    let suggestions = ["Oil Filter", "Spark Plugs", "Brake Pads", "Air Filter", "Battery", "Crankshaft Sensor", "Cabin Filter", "Timing Belt"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Part", trailingContent: AnyView(EmptyView()))
                
                VStack(spacing: DNSpacing.md) {
                    // Quick suggestions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { s in
                                Button(action: { name = s }) {
                                    Text(s).font(DNFont.label(12)).foregroundColor(.dnText)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(name == s ? Color(hex: "#1ABC9C").opacity(0.2) : Color.dnCardElevated)
                                        .cornerRadius(DNRadius.pill)
                                }
                            }
                        }
                    }
                    
                    DNTextField(title: "Part Name", text: $name, icon: "gearshape.fill")
                    DNTextField(title: "Part Number / Article", text: $partNumber, icon: "barcode")
                    DNTextField(title: "Brand", text: $brand, icon: "tag.fill")
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Install Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        DatePicker("", selection: $installDate, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md).colorScheme(.dark)
                    }
                    
                    DNTextField(title: "Cost (\(appState.currency))", text: $cost, icon: "dollarsign.circle.fill", keyboardType: .decimalPad)
                    DNTextField(title: "Notes", text: $notes, icon: "note.text")
                }
                .padding(.horizontal, DNSpacing.md)
                
                if showError { DNAlertCard(title: "Error", message: "Please enter a part name.", type: .danger).padding(.horizontal, DNSpacing.md) }
                if showSuccess { DNAlertCard(title: "Part Added!", message: "Part saved to library.", type: .success).padding(.horizontal, DNSpacing.md) }
                
                DNButton("Save Part", gradient: LinearGradient(colors: [Color(hex: "#1ABC9C"), Color(hex: "#16A085")], startPoint: .leading, endPoint: .trailing)) { savePart() }
                    .padding(.horizontal, DNSpacing.md).padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
    
    private func savePart() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { showError = true; return }
        let part = CarPart(vehicleId: vehicleId, name: name, partNumber: partNumber, brand: brand,
                           installDate: installDate, cost: Double(cost) ?? 0, notes: notes)
        dataStore.addPart(part)
        withAnimation(.dnSpring) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
    }
}

// MARK: - Tires View
struct TiresView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showAdd = false
    
    var tireSets: [TireSet] { dataStore.tireSets.filter { $0.vehicleId == vehicleId }.sorted { $0.installDate > $1.installDate } }
    
    var body: some View {
        VStack(spacing: 0) {
            DNNavBar(title: "Tires & Seasonal", subtitle: "\(tireSets.count) sets",
                     trailingContent: AnyView(
                        Button(action: { showAdd = true }) {
                            ZStack {
                                Circle().fill(Color(hex: "#E67E22")).frame(width: 34, height: 34)
                                Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                        }
                     ))
            
            if tireSets.isEmpty {
                DNEmptyState(icon: "circle.fill", title: "No Tire Sets", message: "Track your summer, winter, and all-season tires.", actionTitle: "Add Tire Set", action: { showAdd = true })
            } else {
                ScrollView {
                    VStack(spacing: DNSpacing.sm) {
                        ForEach(tireSets) { set in TireSetCard(tireSet: set) }
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, DNSpacing.md).padding(.top, DNSpacing.sm)
                }
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAdd) { AddTireSetView(vehicleId: vehicleId) }
    }
}

struct TireSetCard: View {
    let tireSet: TireSet
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @State private var showDelete = false
    
    var seasonIcon: String {
        switch tireSet.season {
        case .summer: return "sun.max.fill"
        case .winter: return "snowflake"
        case .allSeason: return "cloud.sun.fill"
        }
    }
    
    var body: some View {
        DNCard {
            VStack(alignment: .leading, spacing: DNSpacing.sm) {
                HStack {
                    HStack(spacing: DNSpacing.sm) {
                        ZStack {
                            Circle().fill(Color(hex: "#E67E22").opacity(0.15)).frame(width: 42, height: 42)
                            Image(systemName: seasonIcon).font(.system(size: 20)).foregroundColor(Color(hex: "#E67E22"))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(tireSet.brand).font(DNFont.heading(15)).foregroundColor(.dnText)
                            Text(tireSet.season.rawValue).font(DNFont.body(12)).foregroundColor(.dnTextSecondary)
                        }
                    }
                    Spacer()
                    DNBadge(text: tireSet.condition.rawValue, color: tireSet.condition.color, filled: true)
                }
                Divider().background(Color.dnBorder)
                HStack {
                    VehicleInfoMini(label: "Size", value: tireSet.size.isEmpty ? "—" : tireSet.size)
                    Spacer()
                    VehicleInfoMini(label: "Installed", value: NumberHelper.shortDate(tireSet.installDate))
                    Spacer()
                    VehicleInfoMini(label: "At Mileage", value: NumberHelper.distance(tireSet.mileageAtInstall, unit: appState.distanceUnit))
                }
            }
        }
        .contextMenu {
            Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
        }
        .alert("Delete Tire Set", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dataStore.deleteTireSet(tireSet) }
        }
    }
}

struct AddTireSetView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var season = TireSet.TireSeason.summer
    @State private var brand = ""
    @State private var size = ""
    @State private var installDate = Date()
    @State private var mileage = ""
    @State private var condition = TireSet.TireCondition.good
    @State private var notes = ""
    @State private var showSuccess = false
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Tire Set", trailingContent: AnyView(EmptyView()))
                VStack(spacing: DNSpacing.md) {
                    // Season
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Season").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        HStack(spacing: 8) {
                            ForEach(TireSet.TireSeason.allCases, id: \.self) { s in
                                Button(action: { season = s }) {
                                    Text(s.rawValue).font(DNFont.label(13))
                                        .foregroundColor(season == s ? .white : .dnTextSecondary)
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(season == s ? Color(hex: "#E67E22") : Color.dnCardElevated)
                                        .cornerRadius(DNRadius.md)
                                }
                            }
                        }
                    }
                    DNTextField(title: "Brand", text: $brand, icon: "tag.fill")
                    DNTextField(title: "Size (e.g. 205/55R16)", text: $size, icon: "circle.fill")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Install Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        DatePicker("", selection: $installDate, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md).colorScheme(.dark)
                    }
                    DNTextField(title: "Mileage at Install (\(appState.distanceUnit))", text: $mileage, icon: "speedometer", keyboardType: .decimalPad)
                    // Condition
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Condition").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(TireSet.TireCondition.allCases, id: \.self) { c in
                                    Button(action: { condition = c }) {
                                        Text(c.rawValue).font(DNFont.label(12))
                                            .foregroundColor(condition == c ? .white : c.color)
                                            .padding(.horizontal, 14).padding(.vertical, 7)
                                            .background(condition == c ? c.color : c.color.opacity(0.15))
                                            .cornerRadius(DNRadius.pill)
                                    }
                                }
                            }
                        }
                    }
                }.padding(.horizontal, DNSpacing.md)
                if showError { DNAlertCard(title: "Error", message: "Please enter a tire brand.", type: .danger).padding(.horizontal, DNSpacing.md) }
                if showSuccess { DNAlertCard(title: "Tire Set Added!", message: "Set saved.", type: .success).padding(.horizontal, DNSpacing.md) }
                DNButton("Save Tire Set") {
                    guard !brand.trimmingCharacters(in: .whitespaces).isEmpty else { showError = true; return }
                    let set = TireSet(vehicleId: vehicleId, season: season, brand: brand, size: size,
                                     installDate: installDate, mileageAtInstall: Double(mileage) ?? 0, condition: condition, notes: notes)
                    dataStore.addTireSet(set)
                    withAnimation(.dnSpring) { showSuccess = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
                }
                .padding(.horizontal, DNSpacing.md).padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
}

// MARK: - Insurance View
struct InsuranceView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showAdd = false
    
    var records: [InsuranceRecord] { dataStore.insuranceRecords.filter { $0.vehicleId == vehicleId }.sorted { $0.startDate > $1.startDate } }
    
    var body: some View {
        VStack(spacing: 0) {
            DNNavBar(title: "Insurance & Legal", subtitle: "\(records.count) policies",
                     trailingContent: AnyView(
                        Button(action: { showAdd = true }) {
                            ZStack {
                                Circle().fill(Color.dnGreen).frame(width: 34, height: 34)
                                Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            }
                        }
                     ))
            
            if records.isEmpty {
                DNEmptyState(icon: "shield.fill", title: "No Insurance Records", message: "Track your insurance policies and never miss a renewal.", actionTitle: "Add Policy", action: { showAdd = true })
            } else {
                ScrollView {
                    VStack(spacing: DNSpacing.sm) {
                        ForEach(records) { record in InsuranceCard(record: record) }
                        Color.clear.frame(height: 30)
                    }
                    .padding(.horizontal, DNSpacing.md).padding(.top, DNSpacing.sm)
                }
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .sheet(isPresented: $showAdd) { AddInsuranceView(vehicleId: vehicleId) }
    }
}

struct InsuranceCard: View {
    let record: InsuranceRecord
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showDelete = false
    
    var statusColor: Color { record.isExpired ? .dnRed : (record.daysRemaining < 30 ? .dnAccentOrange : .dnGreen) }
    var statusText: String { record.isExpired ? "Expired" : "\(record.daysRemaining) days left" }
    
    var body: some View {
        DNCard {
            VStack(alignment: .leading, spacing: DNSpacing.sm) {
                HStack {
                    HStack(spacing: DNSpacing.sm) {
                        ZStack {
                            Circle().fill(Color.dnGreen.opacity(0.15)).frame(width: 42, height: 42)
                            Image(systemName: "shield.fill").font(.system(size: 20)).foregroundColor(.dnGreen)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.provider).font(DNFont.heading(15)).foregroundColor(.dnText)
                            Text("Policy: \(record.policyNumber)").font(DNFont.mono(11)).foregroundColor(.dnTextSecondary)
                        }
                    }
                    Spacer()
                    DNBadge(text: statusText, color: statusColor, filled: !record.isExpired)
                }
                Divider().background(Color.dnBorder)
                HStack {
                    VehicleInfoMini(label: "Start", value: NumberHelper.shortDate(record.startDate))
                    Spacer()
                    VehicleInfoMini(label: "End", value: NumberHelper.shortDate(record.endDate))
                    Spacer()
                    VehicleInfoMini(label: "Cost", value: NumberHelper.currency(record.cost, appState.currency))
                }
            }
        }
        .contextMenu {
            Button(role: .destructive, action: { showDelete = true }) { Label("Delete", systemImage: "trash") }
        }
        .alert("Delete Insurance Record", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { dataStore.deleteInsurance(record) }
        }
    }
}

struct AddInsuranceView: View {
    let vehicleId: UUID
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var provider = ""
    @State private var policyNumber = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var cost = ""
    @State private var notes = ""
    @State private var showSuccess = false
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                DNNavBar(title: "Add Insurance", trailingContent: AnyView(EmptyView()))
                VStack(spacing: DNSpacing.md) {
                    DNTextField(title: "Insurance Provider", text: $provider, icon: "building.fill")
                    DNTextField(title: "Policy Number", text: $policyNumber, icon: "doc.text.fill")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md).colorScheme(.dark)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("End Date").font(DNFont.label(12)).foregroundColor(.dnTextSecondary)
                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(.horizontal, DNSpacing.md).padding(.vertical, 10)
                            .background(Color.dnCardElevated).cornerRadius(DNRadius.md).colorScheme(.dark)
                    }
                    DNTextField(title: "Annual Cost (\(appState.currency))", text: $cost, icon: "dollarsign.circle.fill", keyboardType: .decimalPad)
                    DNTextField(title: "Notes", text: $notes, icon: "note.text")
                }.padding(.horizontal, DNSpacing.md)
                if showError { DNAlertCard(title: "Error", message: "Please enter provider name.", type: .danger).padding(.horizontal, DNSpacing.md) }
                if showSuccess { DNAlertCard(title: "Policy Added!", message: "Insurance saved.", type: .success).padding(.horizontal, DNSpacing.md) }
                DNButton("Save Policy", gradient: .dnGreenGradient) {
                    guard !provider.trimmingCharacters(in: .whitespaces).isEmpty else { showError = true; return }
                    let record = InsuranceRecord(vehicleId: vehicleId, provider: provider, policyNumber: policyNumber,
                                                 startDate: startDate, endDate: endDate, cost: Double(cost) ?? 0, notes: notes)
                    dataStore.addInsurance(record)
                    withAnimation(.dnSpring) { showSuccess = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { presentationMode.wrappedValue.dismiss() }
                }
                .padding(.horizontal, DNSpacing.md).padding(.bottom, DNSpacing.xxl)
            }
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
}

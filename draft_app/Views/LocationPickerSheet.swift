//
//  LocationPickerSheet.swift
//  draft_app
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerSheet: View {
    var initialPayload: MapPayload?
    var card: MemoryCard?
    var onSelect: (MapPayload) -> Void
    var onCancel: () -> Void
    
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var locationTitle: String
    @State private var locationSubtitle: String?
    
    // Search
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching: Bool = false
    @State private var showSearchResults: Bool = false
    
    // Photo & Preset Suggestions
    @State private var suggestedLocations: [SuggestedLocation] = []
    
    init(
        initialPayload: MapPayload? = nil,
        card: MemoryCard? = nil,
        onSelect: @escaping (MapPayload) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialPayload = initialPayload
        self.card = card
        self.onSelect = onSelect
        self.onCancel = onCancel
        
        let initialCoord = CLLocationCoordinate2D(
            latitude: initialPayload?.latitude ?? 40.8518,
            longitude: initialPayload?.longitude ?? 14.2681
        )
        _selectedCoordinate = State(initialValue: initialCoord)
        _locationTitle = State(initialValue: initialPayload?.title ?? "Naples, Italy")
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoord,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Interactive Apple Map
                MapReader { mapProxy in
                    Map(position: $cameraPosition) {
                        Marker(locationTitle, coordinate: selectedCoordinate)
                            .tint(.red)
                    }
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                        MapPitchToggle()
                    }
                    .onTapGesture { screenCoord in
                        if let coord = mapProxy.convert(screenCoord, from: .local) {
                            selectCoordinate(coord)
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                // Overlay Top: Search Bar + Suggested Chips
                VStack(spacing: 8) {
                    searchBarView
                    
                    if !suggestedLocations.isEmpty && !showSearchResults {
                        suggestionsScrollView
                    }
                    
                    if showSearchResults && !searchResults.isEmpty {
                        searchResultsList
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
                
                // Bottom Floating Confirmation Card
                bottomActionCard
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .task {
                await loadSuggestedLocations()
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search Apple Maps for city or landmark...", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    performSearch()
                }
                .onChange(of: searchText) { _, newValue in
                    if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        showSearchResults = false
                        searchResults = []
                    } else if newValue.count >= 2 {
                        performSearch()
                    }
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    showSearchResults = false
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Photo Suggestions Scroll View
    
    private var suggestionsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestedLocations) { suggestion in
                    Button {
                        applySuggestion(suggestion)
                    } label: {
                        HStack(spacing: 6) {
                            if case .photoMetadata = suggestion.source {
                                Image(systemName: "camera.fill")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.pink)
                            } else {
                                Image(systemName: "mappin")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(suggestion.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                if let sub = suggestion.subtitle {
                                    Text(sub)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.pink.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsList: some View {
        VStack(spacing: 0) {
            ForEach(searchResults.prefix(4), id: \.self) { item in
                Button {
                    selectMapItem(item)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Location")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            if let sub = item.placemark.title {
                                Text(sub)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                }
                
                if item != searchResults.prefix(4).last {
                    Divider()
                        .padding(.leading, 42)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Bottom Action Card
    
    private var bottomActionCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundStyle(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(locationTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(locationSubtitle ?? String(format: "%.4f, %.4f", selectedCoordinate.latitude, selectedCoordinate.longitude))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            Button {
                onSelect(MapPayload(
                    title: locationTitle,
                    latitude: selectedCoordinate.latitude,
                    longitude: selectedCoordinate.longitude,
                    zoom: 0.04
                ))
            } label: {
                Text(initialPayload != nil ? "Update Location" : "Add Location to Memory")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    
    private func selectCoordinate(_ coord: CLLocationCoordinate2D) {
        selectedCoordinate = coord
        cameraPosition = .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        ))
        
        Task {
            let info = await PhotoLocationHelper.reverseGeocode(coordinate: coord)
            await MainActor.run {
                self.locationTitle = info.title
                self.locationSubtitle = info.subtitle
            }
        }
    }
    
    private func selectMapItem(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        selectedCoordinate = coord
        locationTitle = item.name ?? "Selected Location"
        locationSubtitle = item.placemark.title
        searchText = item.name ?? ""
        showSearchResults = false
        
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }
    
    private func applySuggestion(_ suggestion: SuggestedLocation) {
        selectedCoordinate = suggestion.coordinate
        locationTitle = suggestion.title
        locationSubtitle = suggestion.subtitle
        
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: suggestion.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }
    
    private func performSearch() {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = term
        request.region = MKCoordinateRegion(center: selectedCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            if let mapItems = response?.mapItems, !mapItems.isEmpty {
                self.searchResults = mapItems
                self.showSearchResults = true
            }
        }
    }
    
    // MARK: - Photo Metadata Extraction
    
    private func loadSuggestedLocations() async {
        var suggestions: [SuggestedLocation] = []
        
        // 1. Inspect photos in the current memory card
        if let card = card {
            for item in card.items {
                if case .photo(let payload) = item.content {
                    if let lat = payload.latitude, let lon = payload.longitude {
                        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        let title = payload.locationName ?? payload.caption ?? "Photo Location"
                        suggestions.append(SuggestedLocation(
                            title: title,
                            subtitle: "From Photo in Memory",
                            coordinate: coord,
                            source: .photoMetadata(imageName: payload.imageFilename)
                        ))
                    } else if let data = payload.imageData, let coord = PhotoLocationHelper.extractCoordinates(from: data) {
                        let info = await PhotoLocationHelper.reverseGeocode(coordinate: coord)
                        suggestions.append(SuggestedLocation(
                            title: info.title,
                            subtitle: "From Photo in Memory",
                            coordinate: coord,
                            source: .photoMetadata(imageName: nil)
                        ))
                    }
                }
            }
        }
        
        // 2. Add smart context presets if few or no suggestions found
        if suggestions.isEmpty {
            suggestions.append(contentsOf: [
                SuggestedLocation(
                    title: "Castel Sant'Elmo",
                    subtitle: "Naples, Italy",
                    coordinate: CLLocationCoordinate2D(latitude: 40.8444, longitude: 14.2389),
                    source: .landmarkPreset
                ),
                SuggestedLocation(
                    title: "Spiaggia Grande",
                    subtitle: "Positano, Amalfi",
                    coordinate: CLLocationCoordinate2D(latitude: 40.6281, longitude: 14.4850),
                    source: .landmarkPreset
                ),
                SuggestedLocation(
                    title: "Piazza del Plebiscito",
                    subtitle: "Naples, Italy",
                    coordinate: CLLocationCoordinate2D(latitude: 40.8359, longitude: 14.2488),
                    source: .landmarkPreset
                ),
                SuggestedLocation(
                    title: "Eiffel Tower",
                    subtitle: "Paris, France",
                    coordinate: CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
                    source: .landmarkPreset
                )
            ])
        }
        
        let finalSuggestions = suggestions
        await MainActor.run {
            self.suggestedLocations = finalSuggestions
        }
    }
}

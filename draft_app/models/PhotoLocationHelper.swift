//
//  PhotoLocationHelper.swift
//  draft_app
//

import Foundation
import CoreLocation
import ImageIO

struct SuggestedLocation: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let source: LocationSource
    
    enum LocationSource: Equatable {
        case photoMetadata(imageName: String?)
        case searchResult
        case landmarkPreset
    }
    
    static func == (lhs: SuggestedLocation, rhs: SuggestedLocation) -> Bool {
        lhs.id == rhs.id
    }
}

enum PhotoLocationHelper {
    static func extractCoordinates(from imageData: Data) -> CLLocationCoordinate2D? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
              let longitude = gps[kCGImagePropertyGPSLongitude] as? Double,
              let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef] as? String else {
            return nil
        }
        let lat = (latitudeRef == "S") ? -latitude : latitude
        let lon = (longitudeRef == "W") ? -longitude : longitude
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    static func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> (title: String, subtitle: String?) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let pm = placemarks.first {
                let title = pm.name ?? pm.locality ?? "Selected Location"
                let subParts = [pm.locality, pm.administrativeArea, pm.country].compactMap { $0 }
                let subtitle = subParts.joined(separator: ", ")
                return (title, subtitle)
            }
        } catch {
            // fallback
        }
        return ("Selected Location", String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
    }
}

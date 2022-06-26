//
//  MapViewModel.swift
//  peddles
//
//  Created by Mike  Van Amburg on 6/25/22.
//


import Foundation
import Combine
import CoreLocation
import SwiftUI

class MapViewModel: ObservableObject {
    @AppStorage("token") var token: String?
    @Published var state = MapState()
    
    private let client: APIClient
    private var cancellables = Set<AnyCancellable>()
    
    init(client: APIClient, state: MapState = MapState()) {
        self.client = client
        self.state = state
    }
    
    func fetchAllOrgs() {
        client
            .dispatch(GetAllOrgs())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard case .failure(let error) = completion else {
                    print(completion)
                    return
                }
                self?.state.error = error.identifiable
            } receiveValue: { [weak self] response in
                print(response)
            }
            .store(in: &cancellables)
    }

    func fetchOrgsInArea(zipCode: String) {
        client
            .dispatch(GetAllOrgs(queryParams:
                                    [
                                        "location": zipCode,
                                        "limit": "100"
                                    ]))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard case .failure(let error) = completion else {
                    print(completion)
                    return
                }
                self?.state.error = error.identifiable
            } receiveValue: { [weak self] response in
                self?.state.organizations = response
                self?.state.organizationAnnotations.removeAll()
                for org in response.organizations {
                    let address = (org.address.address1 ?? "") + " " + (org.address.address2 ?? "") + " " + "\(org.address.city) \(org.address.state) \(org.address.postcode) "
                    self?.getCoordinate(addressString: address, completionHandler: { coord, error in
                            let annotation = AnnotationModel(id: org.id, img: org.photos?.first?.small ?? "", latlong: coord)
                             self?.state.organizationAnnotations.append(annotation)
                    })
            }
            }
            .store(in: &cancellables)
    }

    private func getCoordinate( addressString : String,
            completionHandler: @escaping(CLLocationCoordinate2D, NSError?) -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                        
                    completionHandler(location.coordinate, nil)
                    return
                }
            }
                
            completionHandler(kCLLocationCoordinate2DInvalid, error as NSError?)
        }
    }
}

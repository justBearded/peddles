//
//  Map.swift
//  peddles (iOS)
//
//  Created by Mike  Van Amburg on 6/25/22.
//

import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var location: LocationManager
    @ObservedObject var viewModel: MapViewModel
    @State private var trackingMode = MapUserTrackingMode.follow
    @State private var region: MKCoordinateRegion = .init()

    var body: some View {

        ZStack {
            ///
            ///this is to fix the pop view bug intoduced in iOS 14
            ///https://developer.apple.com/forums/thread/677333
            ///
            ///
            NavigationLink(destination: EmptyView()) {
                EmptyView()
            }
            Map(
                    coordinateRegion: $region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    userTrackingMode: $trackingMode,
                    annotationItems: viewModel.state.organizationAnnotations
                ) { item in
                    MapAnnotation(coordinate: item.latlong) {
                        NavigationLink(destination: {
                            OrganizationView(orgViewModel: viewModel, orgLocation: item)
                        }, label: {
                            annotationImage(img: item.img)

                        })
                        .buttonStyle(.plain)
                    }
            }
        }
    }
    private func annotationImage(img: String) -> some View {
        AsyncImage(url: URL(string: img)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "photo")
                .imageScale(.large)
                .foregroundColor(.gray)
        }
        .overlay(
            Circle().stroke(Color.white, lineWidth: 8)
        )
        .clipShape(Circle())
        .frame(width: 60, height: 60)
    }
}

#if DEBUG
struct Map_Previews: PreviewProvider {
    static var previews: some View {
        MapView(location: LocationManager(), viewModel: MapViewModel(client: InMemoryAPIClient()))
    }
}
#endif

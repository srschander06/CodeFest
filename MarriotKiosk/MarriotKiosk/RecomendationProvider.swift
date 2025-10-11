//
//  RecomendationProvider.swift
//  MarriotKiosk
//
//  Created by Aryan Palit on 10/11/25.
//

protocol RecomendationProvider {
    func fetchRecommendation(user : UserSession) async throws  -> [Place]
}

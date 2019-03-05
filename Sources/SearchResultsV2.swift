//
//  SearchResultsswift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 28/02/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

// Temporary enum without cases for defining namespace
enum V2 {
    
    public struct SearchResults<T: Decodable>: Decodable {
        
        enum CodingKeys: String, CodingKey {
            case totalHitsCount = "nbHits"
            case page
            case facets
            case pagesCount = "nbPages"
            case hits
            case hitsPerPage
            case processingTimeMS
            case query
            case queryID
            case areFacetsCountExhaustive = "exhaustiveFacetsCount"
            case message
            case queryAfterRemoval
            case aroundGeoLocation = "aroundLatLng"
            case automaticRadius
            case facetStats = "facets_stats"
        }
        
        /// Hits.
        public let hits: [T]
        
        /// Total number of hits.
        public let totalHitsCount: Int
        
        /// Facets that can be used to refine the result
        public let facets: [FacetName: [String: Int]]
        
        /// Last returned page.
        public let page: Int
        
        /// Total number of pages.
        public let pagesCount: Int
        
        /// Number of hits per page.
        public let hitsPerPage: Int
        
        /// Processing time of the last query (in ms).
        public let processingTimeMS: Int
        
        /// Query text that produced these results.
        public let query: String?
        
        /// Query ID that produced these results.
        /// Mandatory when reporting click and conversion events
        /// Only reported when `clickAnalytics=true` in the `Query`
        ///
        public let queryID: String?
        
        /// Whether facet counts are exhaustive.
        public let areFacetsCountExhaustive: Bool
        
        /// Used to return warnings about the query. Should be nil most of the time.
        public let message: String?
        
        /// A markup text indicating which parts of the original query have been removed in order to retrieve a non-empty
        /// result set. The removed parts are surrounded by `<em>` tags.
        ///
        /// + Note: Only returned when `removeWordsIfNoResults` is set.
        ///
        public let queryAfterRemoval: String?
        
        /// The computed geo location.
        ///
        /// + Note: Only returned when `aroundLatLngViaIP` is set.
        ///
        public let aroundGeoLocation: GeoLocation?
        
        /// The automatically computed radius.
        ///
        /// + Note: Only returned for geo queries without an explicitly specified radius (see `aroundRadius`).
        ///
        public let automaticRadius: Int?
        
        /// + Note: Only returned when `getRankingInfo` is true.
        public let rankingInfo: RankingInfo?
        
        /// Statistics for a numerical facets.
        public let facetStats: [FacetName: FacetStats]
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.hits = try container.decode([T].self, forKey: .hits)
            self.totalHitsCount = try container.decode(Int.self, forKey: .totalHitsCount)
            self.page = try container.decode(Int.self, forKey: .page)
            self.pagesCount = try container.decode(Int.self, forKey: .pagesCount)
            self.hitsPerPage = try container.decode(Int.self, forKey: .hitsPerPage)
            self.processingTimeMS = try container.decode(Int.self, forKey: .processingTimeMS)
            self.query = try container.decodeIfPresent(String.self, forKey: .query)
            self.queryID = try container.decodeIfPresent(String.self, forKey: .queryID)
            self.areFacetsCountExhaustive = try container.decode(Bool.self, forKey: .areFacetsCountExhaustive)
            self.message = try container.decodeIfPresent(String.self, forKey: .message)
            self.queryAfterRemoval = try container.decodeIfPresent(String.self, forKey: .queryAfterRemoval)
            self.automaticRadius = try container.decodeIfPresent(Int.self, forKey: .automaticRadius)
            self.rankingInfo = try RankingInfo(from: decoder)
            self.aroundGeoLocation = try container.decodeIfPresent(GeoLocation.self, forKey: .aroundGeoLocation)
            let rawFacets = try container.decode(Dictionary<String, [String: Int]>.self, forKey: .facets)
            self.facets = .init(uniqueKeysWithValues: rawFacets.map { (FacetName(rawValue: $0.key), $0.value) })
            
            let rawFacetStats = try container.decode([String: FacetStats].self, forKey: .facetStats)
            self.facetStats = .init(uniqueKeysWithValues: rawFacetStats.map { (FacetName(rawValue: $0.key), $0.value) })
        }
    }
    
}

extension V2.SearchResults where T == JSON {
    
    func rawHits() -> [[String: Any]] {
        return hits.compactMap([String: Any].init)
    }
    
}

extension V2.SearchResults {
    
    func facetStats(forFacetWithName facetName: FacetName) -> FacetStats? {
        return facetStats[facetName]
    }
    
    func facetOptions(forFacetWithName facetName: FacetName) -> [String: Int]? {
        return facets[facetName]
    }
    
}

extension V2.SearchResults {
    
    public struct RankingInfo: Codable {
        /// Actual host name of the server that processed the request. (Our DNS supports automatic failover and load
        /// balancing, so this may differ from the host name used in the request.)
        ///
        public let serverUsed: String
        
        /// The name of index to which the request has been sent
        public let indexUsed: String
        
        /// The query string that will be searched, after normalization.
        ///
        public let parsedQuery: String
        
        /// Whether a timeout was hit when computing the facet counts. When true, the counts will be interpolated
        /// (i.e. approximate). See also `exhaustiveFacetsCount`.
        ///
        public let timeoutCounts: Bool
        
        /// Whether a timeout was hit when retrieving the hits. When true, some results may be missing.
        ///
        public let timeoutHits: Bool
        
    }
    
}

extension V2.SearchResults {
    
    /// Statistics for a numerical facet.

    public struct FacetStats: Codable {
        
        /// The minimum value.
        public let min: Float
        
        /// The maximum value.
        public let max: Float
        
        /// The average of all values.
        public let avg: Float
        
        /// The sum of all values.
        public let sum: Float
        
    }
    
}

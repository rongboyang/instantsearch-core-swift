//
//  Copyright (c) 2016 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import AlgoliaSearch
import Foundation


/// Sort order.
fileprivate enum SortOrder {
    case ascending
    case descending
}

/// Merges two (or more) lists of search results according to a ranking formula specified by index settings.
///
public class SearchResultsMerger {
    // MARK: Types

    /// Ranking criterion in a ranking formula.
    private enum RankingCriterion: String {
        /// Number of typos (always ascending).
        case typo
        /// Geo distance (always ascending).
        case geo
        /// Number of matching query words (always descending).
        case words
        /// Score reflecting the (optional) custom boosts set at query time in tags and facets (always descending).
        case filters
        /// Number of words matching exactly, i.e. without prefix matching (always descending).
        case exact
        /// How physically near are the query words in the matching record (always ascending).
        case proximity
        /// Position of the matching words in the `searchableAttributes` list (always ascending).
        case attribute
        /// Custom ranking.
        case custom
    }
    
    /// Sort criterion in a custom ranking.
    private struct SortCriterion {
        /// Name of the attribute to sort upon.
        let attributeName: String
        /// Order of the sort.
        let order: SortOrder
        
        /// Parse a sort criterion from its string representation.
        ///
        /// - parameter from: The string to parse from.
        /// - returns: The corresponding sort criterion, or `nil` if the string could not be parsed.
        ///
        static func parse(_ string: String) -> SortCriterion? {
            if let prefixRange = string.range(of: "asc("), let suffixRange = string.range(of: ")"), prefixRange.lowerBound == string.startIndex, suffixRange.upperBound == string.endIndex {
                let attributeName = string.substring(with: prefixRange.upperBound..<suffixRange.lowerBound)
                return SortCriterion(attributeName: attributeName, order: .ascending)
            }
            if let prefixRange = string.range(of: "desc("), let suffixRange = string.range(of: ")"), prefixRange.lowerBound == string.startIndex, suffixRange.upperBound == string.endIndex {
                let attributeName = string.substring(with: prefixRange.upperBound..<suffixRange.lowerBound)
                return SortCriterion(attributeName: attributeName, order: .descending)
            }
            return nil
        }
    }
    
    // MARK: Properties
    
    /// The global ranking formula.
    private var rankingFormula: [RankingCriterion]
    
    /// The ranking criteria for the `custom` step.
    private var customRanking: [SortCriterion]
    
    // MARK: Initialization
    
    /// Create a new search results merger from index settings.
    ///
    /// - parameter settings: The index settings.
    /// - throws: `InvalidJSONException` if the settings do not specify valid ranking formula and custom ranking.
    ///
    public init(settings: JSONObject) throws {
        (rankingFormula, customRanking) = try SearchResultsMerger.parseRankingFormula(settings: settings)
    }
    
    /// Parse the ranking formula from index settings.
    ///
    /// - parameter settings: The index settings to parse.
    /// - returns: The corresponding ranking formula and custom ranking.
    /// - throws: `InvalidJSONException` if the settings do not specify valid ranking formula and custom ranking.
    ///
    private static func parseRankingFormula(settings: JSONObject) throws -> ([RankingCriterion], [SortCriterion]) {
        var rankingFormula = [RankingCriterion]()
        var customRanking = [SortCriterion]()
        guard let ranking = settings["ranking"] as? [String] else {
            throw InvalidJSONError(description: "Settings missing a valid `ranking` attribute")
        }
        for rawCriterion in ranking {
            guard let criterion = RankingCriterion(rawValue: rawCriterion) else {
                throw InvalidJSONError(description: "Unknown ranking criterion \"\(rawCriterion)\"")
            }
            rankingFormula.append(criterion)
        }
        guard let rawCustomRanking = settings["customRanking"] as? [String] else {
            throw InvalidJSONError(description: "Settings missing a valid `customRanking` attribute")
        }
        for rawSortCriterion in rawCustomRanking {
            guard let sortCriterion = SortCriterion.parse(rawSortCriterion) else {
                throw InvalidJSONError(description: "Invalid sort criterion \"\(rawSortCriterion)\"")
            }
            customRanking.append(sortCriterion)
        }
        return (rankingFormula, customRanking)
    }
    
    /// Compare two hits.
    ///
    /// - parameter lhs: Left-hand term of the comparison.
    /// - parameter rhs: Right-hand term of the comparison.
    /// - returns: Comparison result.
    ///
    public func compareHits(lhs: JSONObject, rhs: JSONObject) throws -> ComparisonResult {
        guard let lhsRankingInfo = SearchResults.rankingInfo(hit: lhs), let rhsRankingInfo = SearchResults.rankingInfo(hit: rhs) else {
            throw InvalidJSONError(description: "No ranking information in hit")
        }
        var result: ComparisonResult = .orderedSame
        for rankingCriterion in rankingFormula {
            switch rankingCriterion {
            case .typo: result = compare(lhs: lhsRankingInfo.nbTypos, rhs: rhsRankingInfo.nbTypos, order: .ascending)
            case .geo: result = compare(lhs: lhsRankingInfo.geoDistance, rhs: rhsRankingInfo.geoDistance, order: .ascending)
            case .words: result = compare(lhs: lhsRankingInfo.words, rhs: rhsRankingInfo.words, order: .descending)
            case .filters: result = compare(lhs: lhsRankingInfo.filters, rhs: rhsRankingInfo.filters, order: .descending)
            case .exact: result = compare(lhs: lhsRankingInfo.nbExactWords, rhs: rhsRankingInfo.nbExactWords, order: .descending)
            case .proximity: result = compare(lhs: lhsRankingInfo.proximityDistance, rhs: rhsRankingInfo.proximityDistance, order: .ascending)
            case .attribute: result = compare(lhs: lhsRankingInfo.firstMatchedWord, rhs: rhsRankingInfo.firstMatchedWord, order: .ascending)
            case .custom:
                result = .orderedSame
                for sortCriterion in customRanking {
                    // TODO: What to do with `nil` values?
                    // TODO: Handle other types than `Int`
                    let lhsValue = JSONHelper.valueForKeyPath(json: lhs, path: sortCriterion.attributeName) as? Int ?? 0
                    let rhsValue = JSONHelper.valueForKeyPath(json: rhs, path: sortCriterion.attributeName) as? Int ?? 0
                    result = compare(lhs: lhsValue, rhs: rhsValue, order: sortCriterion.order)
                    if result != .orderedSame {
                        break
                    }
                }
            }
            if result != .orderedSame {
                break
            }
        }
        return result
    }

    /// Merge two lists of hits.
    ///
    /// + Warning: Each list must already be sorted according to this merger's settings. If they are not, results
    ///   are unspecified.
    ///
    /// - parameter lhs: First list to merge.
    /// - parameter rhs: Second list to merge.
    /// - returns: The merged list.
    /// - throws: `InvalidJSONException` if hits don't contain valid ranking information.
    ///
    public func mergeHits(_ lhs: [JSONObject], _ rhs: [JSONObject]) throws -> [JSONObject] {
        var results = [JSONObject]()
        var p = 0
        var q = 0
        while p < lhs.count || q < rhs.count {
            if p < lhs.count && q < rhs.count {
                let l = lhs[p]
                let r = rhs[q]
                let cmp = try compareHits(lhs: l, rhs: r)
                switch cmp {
                case .orderedAscending:
                    results.append(l)
                    p += 1
                case .orderedDescending:
                    results.append(r)
                    q += 1
                case .orderedSame:
                    // CAUTION: We may have duplicate objects (same object ID) or two distinct objects that rank
                    // exactly the same.
                    guard let lid = l["objectID"] as? String, let rid = r["objectID"] as? String else {
                        throw InvalidJSONError(description: "Object missing required `objectID` attribute")
                    }
                    results.append(l)
                    if lid != rid {
                        results.append(r)
                    }
                    p += 1
                    q += 1
                }
            } else if p < lhs.count {
                results.append(lhs[p])
                p += 1
            } else {
                results.append(rhs[q])
                q += 1
            }
        }
        assert(p == lhs.count && q == rhs.count)
        assert(results.count <= lhs.count + rhs.count)
        return results
    }

    /// Merge an arbitrary number of lists of hits.
    ///
    /// - parameter results: Lists of hits to merge.
    /// - returns: The merged list.
    /// - throws: `InvalidJSONException` if hits don't contain valid ranking information.
    ///
    public func mergeHits(_ results: [[JSONObject]]) throws -> [JSONObject] {
        return try results.reduce([], { (lhs: [JSONObject], rhs: [JSONObject]) -> [JSONObject] in
            return try self.mergeHits(lhs, rhs)
        })
    }
}

/// Compare two integers.
fileprivate func compare(lhs: Int, rhs: Int, order: SortOrder) -> ComparisonResult {
    if lhs < rhs {
        return order == .ascending ? .orderedAscending : .orderedDescending
    } else if lhs == rhs {
        return .orderedSame
    } else {
        return order == .ascending ? .orderedDescending : .orderedAscending
    }
}

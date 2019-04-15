//
//  OrGroupProxy.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 24/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

/// Provides a specific type-safe interface for FilterState specialized for a disjunctive group

public struct OrGroupProxy<T: FilterType>: GroupProxy {
    
    let filterState: FilterState
    let groupID: FilterGroupID
    
    /// A Boolean value indicating whether group contains at least on filter
    public var isEmpty: Bool {
        if let filtersForGroup = filterState.groups[groupID] {
            return filtersForGroup.isEmpty
        } else {
            return true
        }
    }
    
    init(filterState: FilterState, groupName: String) {
        self.filterState = filterState
        self.groupID = .or(name: groupName)
    }
    
    /// Adds filter to group
    /// - parameter filter: filter to add
    public func add(_ filter: T) {
        filterState.add(filter, to: groupID)
    }
    
    /// Adds the filters of a sequence to group
    /// - parameter filters: sequence of filters to add
    public func addAll<S: Sequence>(_ filters: S) where S.Element == T {
        filterState.addAll(filters: filters, to: groupID)
    }
    
    /// Tests whether group contains a filter
    /// - parameter filter: sought filter
    public func contains(_ filter: T) -> Bool {
        return filterState.contains(filter, in: groupID)
    }
    
    /// Removes all filters with specified attribute from group
    /// - parameter attribute: specified attribute
    public func removeAll(for attribute: Attribute) {
        return filterState.removeAll(for: attribute, from: groupID)
    }
    
    @discardableResult public func remove(_ filter: T) -> Bool {
        return filterState.remove(filter, from: groupID)
    }
    
    /// Removes a sequence of filters from group
    /// - parameter filters: sequence of filters to remove
    @discardableResult public func removeAll<S: Sequence>(_ filters: S) -> Bool where S.Element == T {
        return filterState.removeAll(filters, from: groupID)
    }
    
    /// Removes all filters in group
    public func removeAll() {
        filterState.removeAll(from: groupID)
    }
    
    /// Removes filter from group if contained by it, otherwise adds filter to group
    /// - parameter filter: filter to toggleE
    public func toggle(_ filter: T) {
        filterState.toggle(filter, in: groupID)
    }
    
}
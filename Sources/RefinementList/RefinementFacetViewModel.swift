//
//  RefinementFacetViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 19/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

typealias RefinementFacetsViewModel = SelectableListViewModel<String, FacetValue>

extension RefinementFacetsViewModel {
  
  func connect<R: Codable>(attribute: Attribute, searcher: SingleIndexSearcher<R>, operator: RefinementOperator, groupName: String? = nil) {
    
    let groupID: FilterGroup.ID
    
    switch `operator` {
    case .and:
      groupID = .and(name: groupName ?? attribute.name)
    case .or:
      groupID = .or(name: groupName ?? attribute.name)
    }
    
    let filterStateListener: (FiltersReadable) -> Void = { filterState in
      self.selections = Set(filterState.getFilters(forGroupWithID: groupID).map { filter -> String? in
        if
          case .facet(let filterFacet) = filter,
          case .string(let stringValue) = filterFacet.value {
          return stringValue
        } else {
          return nil
        }
        }.compactMap { $0 })
      searcher.search()
    }
    
    filterStateListener(searcher.indexSearchData.filterState)
    
    searcher.indexSearchData.filterState.onChange.subscribe(with: self, callback: filterStateListener)
    
    searcher.onSearchResults.subscribe(with: self) { (_, result) in
      if case .success(let searchResults) = result {
        self.values = searchResults.facets?[attribute] ?? []
      }
    }
    
    onSelectedChanged.subscribe(with: self) { selections in
      let filters = selections.map { Filter.Facet(attribute: attribute, stringValue: $0) }
      searcher.indexSearchData.filterState.removeAll(fromGroupWithID: groupID)
      searcher.indexSearchData.filterState.addAll(filters: filters, toGroupWithID: groupID)
    }
    
  }
  
}

extension RefinementFacetsViewModel {
  
  func connect(presenter: RefinementFacetsPresenter) {
    onValuesChanged.subscribe(with: self) { facetValues in
      presenter.values = facetValues.map { ($0, self.selections.contains($0.value)) }
    }
    onSelectionsChanged.subscribe(with: self) { selections in
      presenter.values = self.values.map { ($0, selections.contains($0.value)) }
    }
  }
  
}
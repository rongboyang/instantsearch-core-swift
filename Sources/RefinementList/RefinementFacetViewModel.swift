//
//  RefinementFacetViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 19/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias SelectableFacetsViewModel = SelectableListViewModel<String, FacetValue>

public class RefinementFacetsViewModel: SelectableFacetsViewModel {
  public init() {
    super.init(selectionMode: .multiple)
  }
}

public class MenuFacetsViewModel: SelectableFacetsViewModel {
  public init() {
    super.init(selectionMode: .single)
  }
}

public enum FacetSortCriterion {
  case count(order: Order)
  case alphabetical(order: Order)
  case isRefined

  public enum Order {
    case ascending
    case descending
  }
}

public enum RefinementOperator {
  // when operator is 'and' + one single value can be selected,
  // we want to keep the other values visible, so we have to do a disjunctive facet
  // In the case of multi value that can be selected in conjunctive case,
  // then we avoid doing a disjunctive facet and just do normal conjusctive facet
  // and only the remaining possible facets will appear.
  case and
  case or

}

public extension SelectableFacetsViewModel {

  func connectController<T: RefinementFacetsViewController>(_ controller: T, with presenter: SelectableListPresentable? = nil) {

    /// Add missing refinements with a count of 0 to all returned facetValues
    /// Example: if in result we have color: [(red, 10), (green, 5)] and that in the refinements
    /// we have "color: red" and "color: yellow", the final output would be [(red, 10), (green, 5), (yellow, 0)]
    func merge(_ facetValues: [FacetValue], withSelectedValues selectedValues: Set<String>) -> [RefinementFacet] {

      return facetValues.map { RefinementFacet($0, selectedValues.contains($0.value)) }
//      var values = [RefinementFacet]()
//
//      facetValues.forEach { (facetValue) in
//          values.append((facetValue, selectedValues.contains(facetValue.value)))
//      }
//
//      // Make sure there is a value at least for the refined values.
//      selectedValues.forEach { (refinementValue) in
//        if !facetValues.contains { $0.value == refinementValue } {
//          values.append((FacetValue(value: refinementValue, count: 0, highlighted: .none), true))
//        }
//      }
//
//      return values
    }

    func assignSelectableItems(facetValues: [FacetValue], selections: Set<String>) {
      let refinementFacets = merge(facetValues, withSelectedValues: self.selections)

      let sortedFacetValues = presenter?.transform(refinementFacets: refinementFacets) ?? refinementFacets

      controller.setSelectableItems(selectableItems: sortedFacetValues)
      controller.reload()
    }

    controller.onClick = { facetValue in
      self.selectItem(forKey: facetValue.value)
    }

    assignSelectableItems(facetValues: items, selections: selections)

    self.onItemsChanged.subscribe(with: self) { [weak self] (facetValues) in
      guard let strongSelf = self else { return }

      assignSelectableItems(facetValues: facetValues, selections: strongSelf.selections)
    }

    self.onSelectionsChanged.subscribe(with: self) { [weak self] (selections) in
      guard let strongSelf = self else { return }

      assignSelectableItems(facetValues: strongSelf.items, selections: selections)
    }
  }

  func connectSearcher<R: Codable>(_ searcher: SingleIndexSearcher<R>, with attribute: Attribute, operator: RefinementOperator, groupName: String? = nil) {
    
    let groupID = self.groupID(with: `operator`, attribute: attribute, groupName: groupName)

    whenSelectionsComputedThenUpdateFilterState(attribute, searcher, groupID)

    whenFilterStateChangedThenUpdateSelections(of: searcher, groupID: groupID)

    whenNewSearchResultsThenUpdateItems(of: searcher, attribute)
  }
  
}

fileprivate extension SelectableFacetsViewModel {

  func whenSelectionsComputedThenUpdateFilterState<R: Codable>(_ attribute: Attribute, _ searcher: SingleIndexSearcher<R>, _ groupID: FilterGroup.ID) {

    onSelectionsComputed.subscribe(with: self) { selections in
      let filters = selections.map { Filter.Facet(attribute: attribute, stringValue: $0) }
      searcher.indexSearchData.filterState.removeAll(fromGroupWithID: groupID)
      searcher.indexSearchData.filterState.addAll(filters: filters, toGroupWithID: groupID)
      searcher.indexSearchData.filterState.notifyOnChange()
      
      print(searcher.indexSearchData.filterState.toFilterGroups().compactMap({ $0 as? FilterGroupType & SQLSyntaxConvertible }).sqlForm)
    }
  }

  func groupID(with operator: RefinementOperator, attribute: Attribute, groupName: String?) -> FilterGroup.ID {
    switch `operator` {
    case .and:
      return .and(name: groupName ?? attribute.name)
    case .or:
      return .or(name: groupName ?? attribute.name)
    }
  }

  func whenFilterStateChangedThenUpdateSelections<R: Codable>(of searcher: SingleIndexSearcher<R>, groupID: FilterGroup.ID) {
    let onChange: (FiltersReadable) -> Void = { filterState in
      self.selections = Set(filterState.getFilters(forGroupWithID: groupID).map { filter -> String? in
        if
          case .facet(let filterFacet) = filter,
          case .string(let stringValue) = filterFacet.value {
          return stringValue
        } else {
          return nil
        }
        }.compactMap { $0 })
    }

    onChange(searcher.indexSearchData.filterState)

    searcher.indexSearchData.filterState.onChange.subscribe(with: self, callback: onChange)
  }

  func whenNewSearchResultsThenUpdateItems<R: Codable>(of searcher: SingleIndexSearcher<R>, _ attribute: Attribute) {
    searcher.onResultsChanged.subscribe(with: self) { (_, result) in
      if case .success(let searchResults) = result {
        self.items = searchResults.disjunctiveFacets?[attribute] ?? searchResults.facets?[attribute] ?? []
      }
    }
  }
}

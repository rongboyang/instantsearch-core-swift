//
//  SpecializedAndGroupOperators.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 21/01/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

// MARK: Appending

@discardableResult public func +++ <T: FilterType>(left: SpecializedAndGroupProxy<T>, right: T) -> SpecializedAndGroupProxy<T> {
    left.add(right)
    return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: SpecializedAndGroupProxy<T>, right: S) -> SpecializedAndGroupProxy<T> where S.Element == T {
    left.addAll(right)
    return left
}

@discardableResult public func +++ (left: SpecializedAndGroupProxy<Filter.Facet>, right: FacetTuple) -> SpecializedAndGroupProxy<Filter.Facet> {
    left.add(Filter.Facet(right))
    return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: SpecializedAndGroupProxy<T>, right: S) -> SpecializedAndGroupProxy<T> where S.Element == FacetTuple {
    left.addAll(right.map(Filter.Facet.init))
    return left
}

@discardableResult public func +++ (left: SpecializedAndGroupProxy<Filter.Numeric>, right: ComparisonTuple) -> SpecializedAndGroupProxy<Filter.Numeric> {
    left.add(Filter.Numeric(right))
    return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: SpecializedAndGroupProxy<T>, right: S) -> SpecializedAndGroupProxy<T> where S.Element == ComparisonTuple {
    left.addAll(right.map(Filter.Numeric.init))
    return left
}

@discardableResult public func +++ (left: SpecializedAndGroupProxy<Filter.Numeric>, right: RangeTuple) -> SpecializedAndGroupProxy<Filter.Numeric> {
    left.add(Filter.Numeric(right))
    return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: SpecializedAndGroupProxy<T>, right: S) -> SpecializedAndGroupProxy<T> where S.Element == RangeTuple {
    left.addAll(right.map(Filter.Numeric.init))
    return left
}

@discardableResult public func +++ (left: SpecializedAndGroupProxy<Filter.Tag>, right: String) -> SpecializedAndGroupProxy<Filter.Tag> {
    left.add(Filter.Tag(value: right))
    return left
}

// MARK: Removal

@discardableResult public func --- <T: FilterType>(left: SpecializedAndGroupProxy<T>, right: T) -> SpecializedAndGroupProxy<T> {
    left.remove(right)
    return left
}

@discardableResult public func --- <T: FilterType, S: Sequence>(left: SpecializedAndGroupProxy<T>, right: S) -> SpecializedAndGroupProxy<T> where S.Element == T {
    left.removeAll(right)
    return left
}

@discardableResult public func --- (left: SpecializedAndGroupProxy<Filter.Facet>, right: FacetTuple) -> SpecializedAndGroupProxy<Filter.Facet> {
    left.remove(Filter.Facet(right))
    return left
}

@discardableResult public func --- <S: Sequence>(left: SpecializedAndGroupProxy<Filter.Facet>, right: S) -> SpecializedAndGroupProxy<Filter.Facet> where S.Element == FacetTuple {
    left.removeAll(right.map(Filter.Facet.init))
    return left
}

@discardableResult public func --- (left: SpecializedAndGroupProxy<Filter.Numeric>, right: ComparisonTuple) -> SpecializedAndGroupProxy<Filter.Numeric> {
    left.remove(Filter.Numeric(right))
    return left
}

@discardableResult public func --- <S: Sequence>(left: SpecializedAndGroupProxy<Filter.Numeric>, right: S) -> SpecializedAndGroupProxy<Filter.Numeric> where S.Element == ComparisonTuple {
    left.removeAll(right.map(Filter.Numeric.init))
    return left
}

@discardableResult public func --- (left: SpecializedAndGroupProxy<Filter.Numeric>, right: RangeTuple) -> SpecializedAndGroupProxy<Filter.Numeric> {
    left.remove(Filter.Numeric(right))
    return left
}

@discardableResult public func --- <S: Sequence>(left: SpecializedAndGroupProxy<Filter.Numeric>, right: S) -> SpecializedAndGroupProxy<Filter.Numeric> where S.Element == RangeTuple {
    left.removeAll(right.map(Filter.Numeric.init))
    return left
}

@discardableResult public func --- (left: SpecializedAndGroupProxy<Filter.Tag>, right: String) -> SpecializedAndGroupProxy<Filter.Tag> {
    left.remove(Filter.Tag(value: right))
    return left
}

// MARK: - Toggling

@discardableResult public func <> <T: FilterType>(left: SpecializedAndGroupProxy<T>, right: T) -> SpecializedAndGroupProxy<T> {
    left.toggle(right)
    return left
}

@discardableResult public func <> <T: FilterType, S: Sequence>(left: SpecializedAndGroupProxy<T>, right: S) -> SpecializedAndGroupProxy<T> where S.Element == T {
    right.forEach(left.toggle)
    return left
}

@discardableResult public func <> (left: SpecializedAndGroupProxy<Filter.Facet>, right: FacetTuple) -> SpecializedAndGroupProxy<Filter.Facet> {
    left.toggle(Filter.Facet(right))
    return left
}

@discardableResult public func <> <S: Sequence>(left: SpecializedAndGroupProxy<Filter.Facet>, right: S) -> SpecializedAndGroupProxy<Filter.Facet> where S.Element == FacetTuple {
    right.map(Filter.Facet.init).forEach(left.toggle)
    return left
}

@discardableResult public func <> (left: SpecializedAndGroupProxy<Filter.Numeric>, right: ComparisonTuple) -> SpecializedAndGroupProxy<Filter.Numeric> {
    left.toggle(Filter.Numeric(right))
    return left
}

@discardableResult public func <> <S: Sequence>(left: SpecializedAndGroupProxy<Filter.Numeric>, right: S) -> SpecializedAndGroupProxy<Filter.Numeric> where S.Element == ComparisonTuple {
    right.map(Filter.Numeric.init).forEach(left.toggle)
    return left
}

@discardableResult public func <> (left: SpecializedAndGroupProxy<Filter.Numeric>, right: RangeTuple) -> SpecializedAndGroupProxy<Filter.Numeric> {
    left.toggle(Filter.Numeric(right))
    return left
}

@discardableResult public func <> <S: Sequence>(left: SpecializedAndGroupProxy<Filter.Numeric>, right: S) -> SpecializedAndGroupProxy<Filter.Numeric> where S.Element == RangeTuple {
    right.map(Filter.Numeric.init).forEach(left.toggle)
    return left
}

@discardableResult public func <> (left: SpecializedAndGroupProxy<Filter.Tag>, right: String) -> SpecializedAndGroupProxy<Filter.Tag> {
    left.toggle(Filter.Tag.init(stringLiteral: right))
    return left
}
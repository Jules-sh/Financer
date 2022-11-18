//
//  LegalPerson.swift
//  Financer
//
//  Created by Julian Schumacher on 14.11.22.
//

import Foundation

/// The Protocol all the
/// different Types of Relations have
/// to correspond to
internal protocol Relation : CaseIterable, Identifiable, Equatable {}

/// The class all Legal Persons extend from
internal class LegalPerson : Equatable {
    /// The Type of this Legal Person
    internal enum LegalPersonType : String, CaseIterable, Identifiable {
        var id : Self { self }

        /// no Value given
        case none

        /// This Legal Person is
        /// a Company
        case company

        /// This Legal Person is
        /// an Organization
        case organization

        /// This Legal Person is a person
        case person
    }

    /// The Relation if this Legal Person
    /// is a Company
    internal enum CompanyRelation : String, Relation {
        var id : Self { self }

        /// The User is an Employee of this Company
        case employee

        /// The User is an external working Person
        /// that is arranged in this Company
        case externalWorker

        /// A Customer of this Company
        case customer

        /// A single Supplier of this Company.
        case supplier

        /// The CEO of this Company
        case ceo

        /// The User is a Share Holder of this Company.
        /// The Incomes and Expenses are dividents.
        case shareholder
    }

    /// The Relation if this Legal Person is
    /// a Person
    internal enum PersonRelation : String, Relation {
        var id : Self { self }

        /// The Legal Person that can accept Finances is
        /// a Person of the Users Family
        case family

        /// The Legal Person is a friend of
        /// the User
        case friend

        /// The Person is a public figure
        /// as a  Youtuber, Streamer or Influencer
        case publicFigure
    }

    /// The Relation if this LEgal Person is an Organization
    internal enum OrganizationRelation : String, Relation {
        var id : Self { self }

        /// The User is a member
        /// of this Organization
        case member
    }

    /// The Name of this Legal Person
    internal let name : String

    /// The Relation of this Legal Person and
    /// the User of this App
    internal let relation : any Relation

    /// The Phone Number of this Legal Person
    internal let phone : String

    /// The Notes to this Object
    internal let notes : String

    /// Initializer with all Values
    internal init(
        name : String,
        relation : any Relation,
        phone : String,
        notes : String
    ) {
        self.name = name
        self.relation = relation
        self.phone = phone
        self.notes = notes
    }

    // Override to conform to Equatable
    static func == (lhs: LegalPerson, rhs: LegalPerson) -> Bool {
        return lhs.name == rhs.name && lhs.notes == rhs.notes && lhs.phone == rhs.phone
        // TODO: check this: && lhs.relation == rhs.relation
    }
}
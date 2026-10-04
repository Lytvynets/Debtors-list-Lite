//
//  DebtorModel.swift
//  Debtors-list
//
//  Created by Vlad Lytvynets on 18.03.2022.
//
//  v3: стара модель Realm. Використовується ЛИШЕ для одноразового перенесення
//  даних у SwiftData (див. LegacyRealmMigrator у Data Manager.swift).
//
//  ⚠️ НЕ змінюйте назву класу, назви полів і їхні типи:
//  саме за ними Realm відкриває файл default.realm користувача.
//  Перехід з `@objc dynamic` на `@Persisted` схему не змінює
//  (офіційно підтримується з Realm 10.10), тому міграція Realm не потрібна.
//

import Foundation
import RealmSwift

class Debtor: Object {
    @Persisted var name: String?
    @Persisted var lastName: String?
    @Persisted var sum: Double = 0.0
    @Persisted var currency: String?
    @Persisted var date: String?
    @Persisted var givenDebt: Bool = true
}

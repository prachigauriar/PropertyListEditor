//
//  main.swift
//  plistedit
//
//  Created by Prachi Gauriar on 7/20/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


var dictionary = PropertyListDictionary()
dictionary.addKey("Key", value: .DictionaryItem(PropertyListDictionary()))

print("dictionary = \(dictionary)")

let item: PropertyListItem = .DictionaryItem(dictionary)
let newItem = item.itemBySettingItem(.DictionaryItem(PropertyListDictionary()), atIndexPath: NSIndexPath(indexes: 0))
print("newItem = \(newItem)")


//(lldb) po self.rootItem
//["Key": []]
//
//
//(lldb) po indexPath
//<NSIndexPath: 0x610000024f60> {length = 1, path = 0}
//
//
//(lldb) po item
//["Key": []]
//
//

# PropertyListEditor

PropertyListEditor is an example Mac app written to help me (and others) become more familiar with
practical Swift. While I’ve read a lot about Swift and understand the language pretty well at an
academic level, I’ve generally found the information online to be too limited, academic, and/or
unrealistic. I wanted to build a full app so that I could identify the gaps in my knowledge and gain
practical experience with the language and its development patterns.

I’ve intentionally avoided less mainstream patterns or language features. For example, autoclosures
are not used—though I considered it—nor is there much in the way of operator overloading or
functional programming paradigms. This is merely to keep things understandable for typical Mac and
iOS developers.

Here are the features I did use:

* Protocol-oriented programming
    * Model built using value types (enums, structs)
    * Protocol extensions with default method implementations
* Classes (reference types) used for UI-related model objects and controllers
* Extensive use of enums with associated values
* Extensive use of type extensions to add functionality to types and to group related methods
* Use of typealiases for creating generic protocols
* Basic use of operator overloading and generic functions for implementing the `Equatable` protocol
* Swift error handling
* Lots more!


## Requirements

PropertyListEditor is written using Swift 2. You must be using Xcode 7 or higher to build the
code.


## License

All code is licensed under the MIT license. Do with it as you will.

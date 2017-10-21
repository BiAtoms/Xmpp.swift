[![Platform Linux](https://img.shields.io/badge/platform-Linux-green.svg)](#)
[![Platform](https://img.shields.io/cocoapods/p/Xmpp.swift.svg?style=flat)](https://github.com/BiAtoms/Xmpp.swift)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/Xmpp.swift.svg)](https://cocoapods.org/pods/Xmpp.swift)
[![Build Status - Master](https://travis-ci.org/BiAtoms/Xmpp.swift.svg?branch=master)](https://travis-ci.org/BiAtoms/Xmpp.swift)


# Xmpp.swift

A tiny xmpp client written in swift.

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate Xmpp.swift into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
target '<Your Target Name>' do
    pod 'Xmpp.swift', '~> 1.0'
end
```

Then, run the following command:

```bash
$ pod install
```
### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but Xmpp.swift does support its use on supported platforms. 

Once you have your Swift package set up, adding Xmpp.swift as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
import PackageDescription

let package = Package(
    name: "MyServer",
    dependencies: [
        .Package(url: "https://github.com/BiAtoms/Xmpp.swift.git", majorVersion: 2)
    ]
)
```

## Authors

* **Orkhan Alikhanov** - *Initial work* - [OrkhanAlikhanov](https://github.com/OrkhanAlikhanov)

See also the list of [contributors](https://github.com/BiAtoms/Xmpp.swift/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

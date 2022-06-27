// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "LeapCreatorSDK",
    products: [
        .library( name: "LeapCreatorSDK", targets: ["LeapCreatorSDK" ])
    ],
    targets: [
        .binaryTarget(
            name: "LeapCreatorSDK", path: "LeapCreatorSDK.xcframework"
        )
    ]
)

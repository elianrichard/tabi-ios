#!/bin/bash
#
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing..."
    brew install xcodegen
fi

ls .

cd ..

echo "Generating Xcode project..."
xcodegen generate

if [ ! -d "Tabi Split.xcodeproj" ]; then
    echo "Error: Tabi Split.xcodeproj not found!"
    exit 1
fi

if [ ! -d "Tabi Split.xcodeproj/project.xcworkspace" ]; then
    echo "Error: project.xcworkspace not found!"
    exit 1
fi

echo "Checking xcshareddata directory..."

if [ ! -d "Tabi Split.xcodeproj/project.xcworkspace/xcshareddata" ]; then
    echo "Creating xcshareddata directory..."
    mkdir -p "Tabi Split.xcodeproj/project.xcworkspace/xcshareddata"
fi

if [ ! -d "Tabi Split.xcodeproj/project.xcworkspace/xcshareddata/swiftpm" ]; then
    echo "Creating swiftpm directory..."
    mkdir -p "Tabi Split.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"
fi

if [ ! -f "Tabi Split.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "Creating Package.resolved file..."
    touch "Tabi Split.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
fi

echo "Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project "Tabi Split.xcodeproj" -scheme "Tabi Split"

if [ -f "Tabi Split.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "Package.resolved generated successfully."
else
    echo "Failed to generate Package.resolved."
    exit 1
fi

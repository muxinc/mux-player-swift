//
//  SemanticVersion.swift
//

import Foundation

/// Version information about the SDK
public struct SemanticVersion {

    /// Major version component.
    public static let major = 1

    /// Minor version component.
    public static let minor = 3

    /// Patch version component.
    public static let patch = 0

    /// String form of the version number in the format X.Y.Z
    /// where X, Y, and Z are the major, minor, and patch
    /// version components.
    public static let versionString = "\(major).\(minor).\(patch)"
}

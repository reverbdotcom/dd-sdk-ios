/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

/*
 A collection of mocks for different `Foundation` types. The convention we use is to extend
 types with static factory function prefixed with "mock". For example:
 
 ```
 extension URL {
    static func mockAny() -> URL {
        // ...
    }
 }
 
 extension URLSession {
    static func mockDeliverySuccess(data: Data, response: HTTPURLResponse) -> URLSessionMock {
        // ...
    }
 }
 ```
 
 Other conventions to follow:
 * Use the name `mockAny()` to name functions that return any value of given type.
 * Use descriptive function and parameter names for functions that configure the object for particular scenario.
 * Always use the minimal set of parameters which is required by given mock scenario.
 
 */

// MARK: - Basic types

extension Data {
    static func mockAny() -> Data {
        return Data()
    }

    static func mockRepeating(byte: UInt8, times count: Int) -> Data {
        return Data(repeating: byte, count: count)
    }

    static func mock(ofSize size: UInt64) -> Data {
        return mockRepeating(byte: 0x41, times: Int(size))
    }
}

extension Array where Element == Data {
    /// Returns chunks of mocked data. Accumulative size of all chunks equals `totalSize`.
    static func mockChunksOf(totalSize: UInt64) -> [Data] {
        var chunks: [Data] = []
        var bytesWritten: UInt64 = 0

        while bytesWritten < totalSize {
            let bytesLeft = totalSize - bytesWritten
            let nextChunkSize: Int = bytesLeft > Int.max ? Int.max : Int(bytesLeft) // prevent `Int` overflow
            chunks.append(.mockRepeating(byte: 0x1, times: nextChunkSize))
            bytesWritten += UInt64(nextChunkSize)
        }

        return chunks
    }
}

extension Date {
    static func mockAny() -> Date {
        return Date(timeIntervalSinceReferenceDate: 1)
    }

    static func mockRandomInThePast() -> Date {
        return Date(timeIntervalSinceReferenceDate: TimeInterval.random(in: 0..<Date().timeIntervalSinceReferenceDate))
    }

    static func mockSpecificUTCGregorianDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0, second: Int = 0) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        dateComponents.timeZone = .UTC
        dateComponents.calendar = .gregorian
        return dateComponents.date!
    }

    static func mockDecember15th2019At10AMUTC(addingTimeInterval timeInterval: TimeInterval = 0) -> Date {
        return mockSpecificUTCGregorianDate(year: 2_019, month: 12, day: 15, hour: 10)
            .addingTimeInterval(timeInterval)
    }
}

extension URL {
    static func mockAny() -> URL {
        return URL(string: "https://www.datadoghq.com")!
    }
}

extension String {
    static func mockAny() -> String {
        return "abc"
    }

    static func mockRandom(length: Int = 10) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    static func mockRepeating(character: Character, times: Int) -> String {
        let characters = (0..<times).map { _ in character }
        return String(characters)
    }
}

extension Bool {
    static func mockAny() -> Bool {
        return false
    }
}

extension Float {
    static func mockAny() -> Float {
        return 0
    }
}

struct ErrorMock: Error, CustomStringConvertible {
    let description: String

    init(_ description: String = "") {
        self.description = description
    }
}

struct FailingEncodableMock: Encodable {
    let errorMessage: String

    func encode(to encoder: Encoder) throws {
        throw ErrorMock(errorMessage)
    }
}

extension Bundle {
    static func mockAny() -> Bundle {
        return Bundle.main
    }
}

// MARK: - HTTP

extension HTTPURLResponse {
    static func mockResponseWith(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(url: .mockAny(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

extension URLRequest {
    static func mockAny() -> URLRequest {
        return URLRequest(url: .mockAny())
    }
}

// MARK: - Process

class ProcessInfoMock: ProcessInfo {
    private var _isLowPowerModeEnabled: Bool

    init(isLowPowerModeEnabled: Bool = .mockAny()) {
        _isLowPowerModeEnabled = isLowPowerModeEnabled
    }

    override var isLowPowerModeEnabled: Bool { _isLowPowerModeEnabled }
}

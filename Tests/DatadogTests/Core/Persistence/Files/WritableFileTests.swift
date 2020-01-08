import XCTest
@testable import Datadog

class WritableFileTests: XCTestCase {
    override func setUp() {
        super.setUp()
        temporaryDirectory.create()
    }

    override func tearDown() {
        temporaryDirectory.delete()
        super.tearDown()
    }

    func testItCreatesNewEmptyFile() throws {
        let file = try WritableFile(newFileInDirectory: temporaryDirectory, createdAt: .mockDecember15th2019At10AMUTC())

        XCTAssertEqual(file.fileURL.lastPathComponent, fileNameFrom(fileCreationDate: .mockDecember15th2019At10AMUTC()))
        XCTAssertEqual(file.creationDate, .mockDecember15th2019At10AMUTC())
        XCTAssertEqual(file.size, 0)
        XCTAssertTrue(file.isEmpty)
    }

    func testWhenFileCannotBeCreated_itThrows() {
        let readonlyDirectory = obtainUniqueTemporaryDirectory()
        readonlyDirectory.create(attributes: [.appendOnly: true])
        defer {
            readonlyDirectory.set(attributes: [.appendOnly: false])
            readonlyDirectory.delete()
        }
        XCTAssertThrowsError(try WritableFile(newFileInDirectory: readonlyDirectory, createdAt: .mockAny()))
    }

    func testItOpensExistingFile() throws {
        let file = try WritableFile(newFileInDirectory: temporaryDirectory, createdAt: .mockDecember15th2019At10AMUTC())
        let chunk: Data = .mockRepeating(byte: 0x41, times: 10) // 10x uppercase "A"
        try file.append { write in write(chunk) }

        let existingFile = try WritableFile(existingFileFromURL: file.fileURL)
        XCTAssertEqual(existingFile.fileURL.lastPathComponent, fileNameFrom(fileCreationDate: .mockDecember15th2019At10AMUTC()))
        XCTAssertEqual(existingFile.creationDate, .mockDecember15th2019At10AMUTC())
        XCTAssertEqual(existingFile.size, 10)
        XCTAssertFalse(existingFile.isEmpty)
    }

    func testWhenFileCannotBeOpened_itThrows() {
        let notExistingFileURL = temporaryDirectory.urlFor(fileNamed: "123")
        XCTAssertThrowsError(try WritableFile(existingFileFromURL: notExistingFileURL))
    }

    func testItAppendsDataInFile() throws {
        let file = try WritableFile(newFileInDirectory: temporaryDirectory, createdAt: .mockDecember15th2019At10AMUTC())
        let chunkA: Data = .mockRepeating(byte: 0x41, times: 10) // 10x uppercase "A"
        let chunkB: Data = .mockRepeating(byte: 0x42, times: 10) // 10x uppercase "B"

        try file.append { write in
            write(chunkA)
        }

        XCTAssertFalse(file.isEmpty)
        XCTAssertEqual(file.size, 10)
        XCTAssertEqual(try temporaryDirectory.sizeOfFile(named: file.fileURL.lastPathComponent), 10)
        XCTAssertEqual(
            temporaryDirectory.contentsOfFile(fileName: file.fileURL.lastPathComponent),
            Data([0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41])
        )

        try file.append { write in
            write(chunkB)
            write(chunkA)
        }

        XCTAssertEqual(file.size, 30)
        XCTAssertEqual(try temporaryDirectory.sizeOfFile(named: file.fileURL.lastPathComponent), 30)
        XCTAssertEqual(
            temporaryDirectory.contentsOfFile(fileName: file.fileURL.lastPathComponent),
            Data(
                [
                0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
                0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42,
                0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
                ]
            )
        )
    }

    func testWhenFileWasDeletedWhileWritting_itDoesNotCrash() throws {
        let expectation = self.expectation(description: "100 writes completed")
        expectation.expectedFulfillmentCount = 100
        let file = try WritableFile(newFileInDirectory: temporaryDirectory, createdAt: .mockDecember15th2019At10AMUTC())
        let chunk: Data = .mockRepeating(byte: 0x41, times: 10) // 10x uppercase "A"

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            try? file.append { write in write(chunk) }
            temporaryDirectory.deleteFile(fileName: file.fileURL.lastPathComponent)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
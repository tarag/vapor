import Vapor
import XCTVapor
import AsyncHTTPClient
import XCTest
import NIOCore
import NIOEmbedded
import NIOConcurrencyHelpers

final class ApplicationTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        app = try await Application.make(.testing)
    }

    override func tearDown() async throws {
        try await app.asyncShutdown()
    }

    @available(*, deprecated, message: "Test future APIs")
    func testApplicationStopFuture() throws {
        app.environment.arguments = ["serve"]
        app.http.server.configuration.port = 0
        try app.start()
        let running = try XCTUnwrap(app.running, "app started without setting 'running'")
        running.stop()
        try running.onStop.wait()
    }

    func testApplicationStop() async throws {
        app.environment.arguments = ["serve"]
        app.http.server.configuration.port = 0
        try await app.startup()
        let running = try XCTUnwrap(app.running, "app started without setting 'running'")
        running.stop()
        try await running.onStop.get()
    }

    @available(*, deprecated, message: "Test future APIs")
    func testLifecycleHandler() throws {
        final class Foo: LifecycleHandler {
            let willBootFlag: NIOLockedValueBox<Bool>
            let didBootFlag: NIOLockedValueBox<Bool>
            let shutdownFlag: NIOLockedValueBox<Bool>
            let willBootAsyncFlag: NIOLockedValueBox<Bool>
            let didBootAsyncFlag: NIOLockedValueBox<Bool>
            let shutdownAsyncFlag: NIOLockedValueBox<Bool>

            init() {
                self.willBootFlag = .init(false)
                self.didBootFlag = .init(false)
                self.shutdownFlag = .init(false)
                self.didBootAsyncFlag = .init(false)
                self.willBootAsyncFlag = .init(false)
                self.shutdownAsyncFlag = .init(false)
            }
            
            func willBootAsync(_ application: Application) async throws {
                self.willBootAsyncFlag.withLockedValue { $0 = true }
            }
            
            func didBootAsync(_ application: Application) async throws {
                self.didBootAsyncFlag.withLockedValue { $0 = true }
            }
            
            func shutdownAsync(_ application: Application) async {
                self.shutdownAsyncFlag.withLockedValue { $0 = true }
            }

            func willBoot(_ application: Application) throws {
                self.willBootFlag.withLockedValue { $0 = true }
            }

            func didBoot(_ application: Application) throws {
                self.didBootFlag.withLockedValue { $0 = true }
            }

            func shutdown(_ application: Application) {
                self.shutdownFlag.withLockedValue { $0 = true }
            }
        }
        
        let app = Application(.testing)

        let foo = Foo()
        app.lifecycle.use(foo)

        XCTAssertEqual(foo.willBootFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.didBootFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.shutdownFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.willBootAsyncFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.didBootAsyncFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.shutdownAsyncFlag.withLockedValue({ $0 }), false)

        try app.boot()

        XCTAssertEqual(foo.willBootFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.didBootFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.shutdownFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.willBootAsyncFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.didBootAsyncFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.shutdownAsyncFlag.withLockedValue({ $0 }), false)

        app.shutdown()

        XCTAssertEqual(foo.willBootFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.didBootFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.shutdownFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.willBootAsyncFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.didBootAsyncFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.shutdownAsyncFlag.withLockedValue({ $0 }), false)
    }
    
    func testLifecycleHandlerAsync() async throws {
        final class Foo: LifecycleHandler {
            let willBootFlag: NIOLockedValueBox<Bool>
            let didBootFlag: NIOLockedValueBox<Bool>
            let shutdownFlag: NIOLockedValueBox<Bool>
            let willBootAsyncFlag: NIOLockedValueBox<Bool>
            let didBootAsyncFlag: NIOLockedValueBox<Bool>
            let shutdownAsyncFlag: NIOLockedValueBox<Bool>

            init() {
                self.willBootFlag = .init(false)
                self.didBootFlag = .init(false)
                self.shutdownFlag = .init(false)
                self.didBootAsyncFlag = .init(false)
                self.willBootAsyncFlag = .init(false)
                self.shutdownAsyncFlag = .init(false)
            }

            func willBootAsync(_ application: Application) async throws {
                self.willBootAsyncFlag.withLockedValue { $0 = true }
            }
            
            func didBootAsync(_ application: Application) async throws {
                self.didBootAsyncFlag.withLockedValue { $0 = true }
            }
            
            func shutdownAsync(_ application: Application) async {
                self.shutdownAsyncFlag.withLockedValue { $0 = true }
            }
            
            func willBoot(_ application: Application) throws {
                self.willBootFlag.withLockedValue { $0 = true }
            }

            func didBoot(_ application: Application) throws {
                self.didBootFlag.withLockedValue { $0 = true }
            }

            func shutdown(_ application: Application) {
                self.shutdownFlag.withLockedValue { $0 = true }
            }
        }
        
        let app = try await Application.make(.testing)

        let foo = Foo()
        app.lifecycle.use(foo)

        XCTAssertEqual(foo.willBootFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.didBootFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.shutdownFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.willBootAsyncFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.didBootAsyncFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.shutdownAsyncFlag.withLockedValue({ $0 }), false)

        try await app.asyncBoot()

        XCTAssertEqual(foo.willBootFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.didBootFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.shutdownFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.willBootAsyncFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.didBootAsyncFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.shutdownAsyncFlag.withLockedValue({ $0 }), false)

        try await app.asyncShutdown()

        XCTAssertEqual(foo.willBootFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.didBootFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.shutdownFlag.withLockedValue({ $0 }), false)
        XCTAssertEqual(foo.willBootAsyncFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.didBootAsyncFlag.withLockedValue({ $0 }), true)
        XCTAssertEqual(foo.shutdownAsyncFlag.withLockedValue({ $0 }), true)
    }

    @available(*, deprecated, message: "Test future APIs")
    func testBootDoesNotTriggerLifecycleHandlerMultipleTimes() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        final class Handler: LifecycleHandler, Sendable {
            let bootCount = NIOLockedValueBox(0)
            func willBoot(_ application: Application) throws {
                bootCount.withLockedValue { $0 += 1 }
            }
        }
        
        let handler = Handler()
        app.lifecycle.use(handler)
        
        try app.boot()
        try app.boot()

        XCTAssertEqual(handler.bootCount.withLockedValue({ $0 }), 1)
    }
    
    func testAsyncBootDoesNotTriggerLifecycleHandlerMultipleTimes() async throws {
        let app = try await Application.make(.testing)
        
        final class Handler: LifecycleHandler, Sendable {
            let bootCount = NIOLockedValueBox(0)
            func willBoot(_ application: Application) throws {
                bootCount.withLockedValue { $0 += 1 }
            }
        }
        
        let handler = Handler()
        app.lifecycle.use(handler)
        
        try await app.asyncBoot()
        try await app.asyncBoot()

        XCTAssertEqual(handler.bootCount.withLockedValue({ $0 }), 1)
        
        try await app.asyncShutdown()
    }

    @available(*, deprecated, message: "Test future APIs")
    func testThrowDoesNotCrash() throws {
        enum Static {
            static let app: NIOLockedValueBox<Application?> = .init(nil)
        }
        Static.app.withLockedValue { $0 = Application(.testing) }
        Static.app.withLockedValue { $0 = nil }
    }

    func testSwiftError() throws {
        struct Foo: Error { }
        
        app.get("error") { req -> String in
            throw Foo()
        }

        try app.testable().test(.GET, "/error") { res in
            XCTAssertEqual(res.status, .internalServerError)
        }
    }

    func testAsyncKitExport() throws {
        let eventLoop: EventLoop = EmbeddedEventLoop()
        let a = eventLoop.makePromise(of: Int.self)
        let b = eventLoop.makePromise(of: Int.self)

        let c = [a.futureResult, b.futureResult].flatten(on: eventLoop)

        a.succeed(1)
        b.succeed(2)

        try XCTAssertEqual(c.wait(), [1, 2])
    }

    func testBoilerplate() throws {
        app.get("hello") { req in
            "Hello, world!"
        }

        app.environment.arguments = ["serve"]
        app.http.server.configuration.port = 0
        try app.start()
        
        XCTAssertNotNil(app.http.server.shared.localAddress)
        guard let localAddress = app.http.server.shared.localAddress,
              let port = localAddress.port else {
            XCTFail("couldn't get ip/port from \(app.http.server.shared.localAddress.debugDescription)")
            return
        }

        let res = try app.client.get("http://localhost:\(port)/hello").wait()
        XCTAssertEqual(res.body?.string, "Hello, world!")
    }

    func testAutomaticPortPickingWorks() {
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = 0

        app.get("hello") { req in
            "Hello, world!"
        }

        XCTAssertNil(app.http.server.shared.localAddress)

        app.environment.arguments = ["serve"]
        XCTAssertNoThrow(try app.start())

        XCTAssertNotNil(app.http.server.shared.localAddress)
        guard let localAddress = app.http.server.shared.localAddress,
              let ip = localAddress.ipAddress,
              let port = localAddress.port else {
            XCTFail("couldn't get ip/port from \(app.http.server.shared.localAddress.debugDescription)")
            return
        }

        XCTAssertEqual("127.0.0.1", ip)
        XCTAssertGreaterThan(port, 0)

        XCTAssertEqual("Hello, world!",
                       try app.client.get("http://localhost:\(port)/hello").wait().body?.string)
    }

    func testConfigurationAddressDetailsReflectedAfterBeingSet() throws {
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 0

        struct AddressConfig: Content {
            let hostname: String
            let port: Int
        }
        
        app.get("hello") { req -> AddressConfig in
            let config = AddressConfig(hostname: req.application.http.server.configuration.hostname, port: req.application.http.server.configuration.port)
            return config
        }

        app.environment.arguments = ["serve"]
        XCTAssertNoThrow(try app.start())

        XCTAssertNotNil(app.http.server.shared.localAddress)
        XCTAssertEqual("0.0.0.0", app.http.server.configuration.hostname)
        XCTAssertEqual(app.http.server.shared.localAddress?.port, app.http.server.configuration.port)
        
        guard let localAddress = app.http.server.shared.localAddress,
              localAddress.ipAddress != nil,
              let port = localAddress.port else {
            XCTFail("couldn't get ip/port from \(app.http.server.shared.localAddress.debugDescription)")
            return
        }
        let response = try app.client.get("http://localhost:\(port)/hello").wait()
        let returnedConfig = try response.content.decode(AddressConfig.self)
        XCTAssertEqual(returnedConfig.hostname, "0.0.0.0")
        XCTAssertEqual(returnedConfig.port, port)
    }

    func testConfigurationAddressDetailsReflectedWhenProvidedThroughServeCommand() throws {
        struct AddressConfig: Content {
            let hostname: String
            let port: Int
        }

        app.get("hello") { req -> AddressConfig in
            let config = AddressConfig(hostname: req.application.http.server.configuration.hostname, port: req.application.http.server.configuration.port)
            return config
        }

        app.environment.arguments = ["vapor", "serve", "--hostname", "0.0.0.0", "--port", "3000"]
        XCTAssertNoThrow(try app.start())

        XCTAssertNotNil(app.http.server.shared.localAddress)
        XCTAssertEqual("0.0.0.0", app.http.server.configuration.hostname)
        XCTAssertEqual(3000, app.http.server.configuration.port)

        guard let localAddress = app.http.server.shared.localAddress,
              localAddress.ipAddress != nil,
              let port = localAddress.port else {
            XCTFail("couldn't get ip/port from \(app.http.server.shared.localAddress.debugDescription)")
            return
        }
        let response = try app.client.get("http://localhost:\(port)/hello").wait()
        let returnedConfig = try response.content.decode(AddressConfig.self)
        XCTAssertEqual(returnedConfig.hostname, "0.0.0.0")
        XCTAssertEqual(returnedConfig.port, 3000)
    }

    func testStorageKeepsEveryWriteWhenTwoKeysAreWrittenAtTheSameTime() {
        struct First: StorageKey { typealias Value = Int }
        struct Second: StorageKey { typealias Value = Int }
        let app: Application = self.app
        let dropped = NIOLockedValueBox<[Int]>([0, 0])

        // Each worker writes a key of its own and reads it back. Nothing else writes that key, so a value
        // that isn't there was dropped by the other worker's write.
        DispatchQueue.concurrentPerform(iterations: 2) { worker in
            var lost = 0
            for value in 0..<10_000 {
                if worker == 0 {
                    app.storage[First.self] = value
                    if app.storage[First.self] != value { lost += 1 }
                } else {
                    app.storage[Second.self] = value
                    if app.storage[Second.self] != value { lost += 1 }
                }
            }
            dropped.withLockedValue { $0[worker] = lost }
        }

        XCTAssertEqual(dropped.withLockedValue { $0 }, [0, 0], "writes dropped out of 10,000, per key")
    }

    func testStorageKeepsAWriteMadeWhileAnotherWriteIsUnderway() {
        struct Outer: StorageKey { typealias Value = Int }
        struct Inner: StorageKey { typealias Value = Int }
        let app: Application = self.app

        // The default value is computed in the middle of the write of `Outer`, and writes `Inner` itself.
        let outer = app.storage[Outer.self, default: {
            app.storage[Inner.self] = 2
            return 1
        }()]

        XCTAssertEqual(outer, 1)
        XCTAssertEqual(app.storage[Outer.self], 1)
        XCTAssertEqual(app.storage[Inner.self], 2)
    }

    func testStorageKeepsAWriteMadeWhileAnAsyncWriteIsSuspended() async {
        struct Removed: StorageKey { typealias Value = Int }
        struct Written: StorageKey { typealias Value = Int }
        let app: Application = self.app
        await app.storage.setWithAsyncShutdown(Removed.self, to: 1) { _ in
            await Task.yield()
            app.storage[Written.self] = 2
        }

        // Removing the value runs its shutdown in the middle of the removal, and the shutdown writes `Written`.
        await app.storage.setWithAsyncShutdown(Removed.self, to: nil)

        XCTAssertNil(app.storage[Removed.self])
        XCTAssertEqual(app.storage[Written.self], 2)
    }
}

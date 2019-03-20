//
//  ThreadTests.swift
//  ThreadTests
//
//  Created by Tobias Due Munk on 27/11/15.
//  Copyright © 2015 developmunk. All rights reserved.
//

import XCTest
#if os(iOS)
    @testable import ThreadiOS
#elseif os(tvOS)
    @testable import ThreadtvOS
#elseif os(OSX)
    @testable import ThreadOSX
#endif

class ThreadTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEnqueueSingle() {
        let ex = expectation(description: "First")

        let thread = ThreadQueue()
        thread.enqueue {
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSync() {
        let ex = expectation(description: "First")
        
        let thread = ThreadQueue()
        var ran = false
        
        thread.sync {
            Thread.sleep(forTimeInterval: 0.1)
            ex.fulfill()
            ran = true
        }
        
        if (!ran) {
            XCTFail("didn't execute synchronously")
        }
        
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testEnqueueMultiple() {
        let expectation1 = expectation(description: "First")
        let expectation2 = expectation(description: "Second")

        let thread = ThreadQueue()
        var visitedFirst = false
        thread.enqueue {
            expectation1.fulfill()
            visitedFirst = true
        }
        thread.enqueue {
            expectation2.fulfill()
            XCTAssert(visitedFirst, "Didn't run first before this secondary block")
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCancel() {
        let expectation1 = expectation(description: "First")
        let expectationWait = expectation(description: "Wait")

        let thread = ThreadQueue()
        thread.enqueue {
            thread.cancel()
            expectation1.fulfill()
        }
        thread.enqueue {
            XCTFail("This block is enqueued after first block, so shouldn't be run")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectationWait.fulfill()
        }

        // Wait
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testEmptyQueue() {
        let expectation1 = expectation(description: "First")
        let expectationWait = expectation(description: "Wait")

        let thread = ThreadQueue()
        thread.enqueue {
            expectation1.fulfill()
            Thread.sleep(forTimeInterval: 0.1)
        }
        thread.enqueue {
            XCTFail("This block is enqueued after first block, so shouldn't be run")
        }
        DispatchQueue.main.async {
            XCTAssertEqual(thread.queue.count, 1)
            thread.emptyQueue()
            XCTAssertEqual(thread.queue.count, 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectationWait.fulfill()
        }

        // Wait
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testPause() {
        let expectation1 = expectation(description: "First")
        let expectation2 = expectation(description: "Second")
        let expectationWait = expectation(description: "Wait")

        let thread = ThreadQueue()
        var paused: Bool = false
        var resumed: Bool = false
        thread.enqueue {
            paused = true
            thread.pause()
            XCTAssert(thread.paused, "Should be in paused state")
            expectation1.fulfill()
        }
        thread.enqueue {
            XCTAssert(paused, "Should have been stopped once")
            XCTAssert(resumed, "Should have been restarted again")
            expectation2.fulfill()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectationWait.fulfill()
            resumed = true
            thread.resume()
            XCTAssertFalse(thread.paused, "Shouldn't be in paused state")
        }

        // Wait
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testInitialQueue() {
        let thread = ThreadQueue(start: false, queue: [{}, {}, {}])
        XCTAssertEqual(thread.queue.count, 3, "Thread initialized with 3 blocks.")
    }
}


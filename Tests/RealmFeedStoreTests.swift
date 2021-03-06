//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
@testable import FeedStoreChallenge
import RealmSwift
import Realm

class RealmFeedStoreTests: XCTestCase, FeedStoreSpecs {
	
	//  ***********************
	//
	//  Follow the TDD process:
	//
	//  1. Uncomment and run one test at a time (run tests with CMD+U).
	//  2. Do the minimum to make the test pass and commit.
	//  3. Refactor if needed and commit again.
	//
	//  Repeat this process until all tests are passing.
	//
	//  ***********************
		
	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() {
		let sut = makeSUT()
		
		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}
	
	func test_delete_deliversNoErrorOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		
		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_delete_deliversNoErrorOnNonEmptyCache() {
		let sut = makeSUT()
		
		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_delete_emptiesPreviouslyInsertedCache() {
		let sut = makeSUT()
		
		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}
	
	func test_storeSideEffects_runSerially() {
		let sut = makeSUT()
		
		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
	private func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedStore {
		let sut = try! RealmFeedStore(configuration: RealmFeedStoreTests.testSpecificRealmConfiguration)
		trackForMemoryLeaks(sut, file: file, line: line)
		
		return sut
	}
		
	private static var testSpecificInMemoryIdentifier: String {
		"\(type(of: self)).realm"
	}
	
	private static var testSpecificRealmConfiguration: Realm.Configuration {
		Realm.Configuration(inMemoryIdentifier: RealmFeedStoreTests.testSpecificInMemoryIdentifier)
	}
	
	private func cacheWithInvalidImage() -> RealmCache {
		let invalidImage = RealmFeedImage(value: ["_id": "invalidUUID", "desc": nil, "location": nil, "url": "invalidURL"])
		return RealmCache(value: ["feed": [invalidImage], "timestamp": Date()])
	}
	
	private func insertCacheWithInvalidImageIntoRealm(with configuration: Realm.Configuration) {
		let realmInstance = autoreleasepool {
			return try! Realm(configuration: configuration)
		}
		try! realmInstance.write {
			realmInstance.add(cacheWithInvalidImage())
		}
	}
	
	private func activateRealmTransactionFailureForTestDuration() {
		let swizzler = makeSwizzlerForFailingRealmTransaction()
		addTeardownBlock {
			withExtendedLifetime(swizzler) { }
		}
	}
	
	private func makeSwizzlerForFailingRealmTransaction() -> Swizzler {
		return try! Swizzler(firstClass: RLMRealm.self,
							 firstSelector: #selector(RLMRealm.commitWriteTransactionWithoutNotifying(_:)),
							 secondClass: FailingTransactionsRLMRealm.self,
							 secondSelector: #selector(FailingTransactionsRLMRealm.cancelWriteTransactionAndThrowAnError(_:)))
	}
	
	private class FailingTransactionsRLMRealm: RLMRealm {
		@objc func cancelWriteTransactionAndThrowAnError(_ tokens: [NotificationToken]) throws {
			cancelWriteTransaction()
			throw Realm.Error(.fail)
		}
	}
	
	private class Swizzler {
		private var firstMethod: Method
		private var secondMethod: Method
		
		init(firstClass: AnyClass, firstSelector: Selector, secondClass: AnyClass, secondSelector: Selector) throws {
			guard let firstMethod = class_getInstanceMethod(firstClass, firstSelector),
				  let secondMethod = class_getInstanceMethod(secondClass, secondSelector) else {
				throw Error.methodNotFound
			}
			self.firstMethod = firstMethod
			self.secondMethod = secondMethod
			swizzle()
		}
		
		deinit {
			swizzle()
		}
		
		private func swizzle() {
			method_exchangeImplementations(firstMethod, secondMethod)
		}
		
		private enum Error: Swift.Error {
			case methodNotFound
		}
	}
	
}

//  ***********************
//
//  Uncomment the following tests if your implementation has failable operations.
//
//  Otherwise, delete the commented out code!
//
//  ***********************

extension RealmFeedStoreTests: FailableRetrieveFeedStoreSpecs {

	func test_retrieve_deliversFailureOnRetrievalError() {
		let sut = makeSUT()
		let configuration = RealmFeedStoreTests.testSpecificRealmConfiguration
		insertCacheWithInvalidImageIntoRealm(with: configuration)
		
		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure() {
		let sut = makeSUT()
		let configuration = RealmFeedStoreTests.testSpecificRealmConfiguration
		insertCacheWithInvalidImageIntoRealm(with: configuration)

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}
}

extension RealmFeedStoreTests: FailableInsertFeedStoreSpecs {
	
	func test_insert_deliversErrorOnInsertionError() {
		let sut = makeSUT()
		activateRealmTransactionFailureForTestDuration()
		
		assertThatInsertDeliversErrorOnInsertionError(on: sut)
	}
	
	func test_insert_hasNoSideEffectsOnInsertionError() {
		let sut = makeSUT()
		activateRealmTransactionFailureForTestDuration()

		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
	}
}

extension RealmFeedStoreTests: FailableDeleteFeedStoreSpecs {

	func test_delete_deliversErrorOnDeletionError() {
		let sut = makeSUT()
		activateRealmTransactionFailureForTestDuration()

		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
	}

	func test_delete_hasNoSideEffectsOnDeletionError() {
		let sut = makeSUT()
		activateRealmTransactionFailureForTestDuration()

		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
	}
	
	func test_delete_hasNoSideEffectsOnDeletionErrorOnNonEmptyCache() {
		let sut = makeSUT()
		let feed = uniqueImageFeed()
		let timestamp = Date()
		insert((feed, timestamp), to: sut)
		activateRealmTransactionFailureForTestDuration()
		
		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
		
		expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
	}
}

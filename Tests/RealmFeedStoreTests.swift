//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
@testable import FeedStoreChallenge
import RealmSwift

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
	private func makeSUT(cacheId: UUID = UUID(), shouldHoldReferenceToRealm: Bool = true, encrypted: Bool = false, file: StaticString = #file, line: UInt = #line) -> FeedStore {
		let configuration = makeConfiguration(with: cacheId, encrypted: encrypted)
		
		if shouldHoldReferenceToRealm {
			_ = strongReferenceToInMemoryRealm(cacheId: cacheId, encrypted: encrypted)
		}
		
		let sut = RealmFeedStore(configuration: configuration, cacheId: cacheId)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}
	
	/// Opens a Realm so we can hold a strong reference to it for the duration of the tests.
	///
	/// From Realm Documentation: When all in-memory Realm instances with a particular identifier go out of scope
	/// with no references, all data in that Realm is deleted. We recommend holding onto a strong reference to any
	/// in-memory Realms during your app’s lifetime. (This is not necessary for on-disk Realms.)
	private func strongReferenceToInMemoryRealm(cacheId: UUID, encrypted: Bool = false) -> Realm {
		return try! Realm(configuration: makeConfiguration(with: cacheId, encrypted: encrypted))
	}
	
	private func makeConfiguration(with cacheId: UUID, encrypted: Bool = false) -> Realm.Configuration {
		var configuration = Realm.Configuration(inMemoryIdentifier: cacheId.uuidString)
		if encrypted {
			configuration.encryptionKey = Data(count: 64)
		}
		return configuration
	}
	
	private func cacheWithInvalidImage(withId cacheId: UUID) -> RealmCache {
		let invalidImage = RealmFeedImage(value: ["_id": "invalidUUID", "desc": nil, "location": nil, "url": "invalidURL"])
		return RealmCache(value: ["_id": cacheId.uuidString, "feed": [invalidImage], "timestamp": Date()])
	}
	
	private func insertCacheWithInvalidImageIntoRealm(withCacheId cacheId: UUID) {
		let configuration = makeConfiguration(with: cacheId)
		let realmInstance = try! Realm(configuration: configuration)
		try! realmInstance.write {
			realmInstance.add(cacheWithInvalidImage(withId: cacheId))
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
		let cacheId = UUID()
		_ = strongReferenceToInMemoryRealm(cacheId: cacheId, encrypted: true)
		
		let sut = makeSUT(cacheId: cacheId, shouldHoldReferenceToRealm: false)
		
		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnFailure() {
		let cacheId = UUID()
		_ = strongReferenceToInMemoryRealm(cacheId: cacheId, encrypted: true)
		
		let sut = makeSUT(cacheId: cacheId, shouldHoldReferenceToRealm: false)

		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
	}

	func test_retrieve_deliversFailureOnInvalidObject() {
		let cacheId = UUID()
		let sut = makeSUT(cacheId: cacheId)
		
		insertCacheWithInvalidImageIntoRealm(withCacheId: cacheId)
		
		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
	}
}

extension RealmFeedStoreTests: FailableInsertFeedStoreSpecs {

	func test_insert_deliversErrorOnInsertionError() {
		let cacheId = UUID()
		_ = strongReferenceToInMemoryRealm(cacheId: cacheId, encrypted: true)
		
		let sut = makeSUT(cacheId: cacheId, shouldHoldReferenceToRealm: false)

		assertThatInsertDeliversErrorOnInsertionError(on: sut)
	}

	func test_insert_hasNoSideEffectsOnInsertionError() {
		let cacheId = UUID()
		let sut = makeSUT(cacheId: cacheId, encrypted: true)
		
		let nonEncryptedSUT = makeSUT(cacheId: cacheId, shouldHoldReferenceToRealm: false)
		assertThatInsertDeliversErrorOnInsertionError(on: nonEncryptedSUT)
		
		expect(sut, toRetrieve: .empty, file: #filePath, line: #line)
	}
}

extension RealmFeedStoreTests: FailableDeleteFeedStoreSpecs {

	func test_delete_deliversErrorOnDeletionError() {
		let cacheId = UUID()
		_ = strongReferenceToInMemoryRealm(cacheId: cacheId, encrypted: true)
		
		let sut = makeSUT(cacheId: cacheId, shouldHoldReferenceToRealm: false)

		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
	}

	func test_delete_hasNoSideEffectsOnDeletionError() {
		let cacheId = UUID()
		let sut = makeSUT(cacheId: cacheId, encrypted: true)
		
		let nonEncryptedSUT = makeSUT(cacheId: cacheId, shouldHoldReferenceToRealm: false)
		assertThatDeleteDeliversErrorOnDeletionError(on: nonEncryptedSUT)
		
		expect(sut, toRetrieve: .empty, file: #filePath, line: #line)
	}

}

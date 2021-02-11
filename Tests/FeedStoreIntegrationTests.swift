//
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import RealmSwift

class FeedStoreIntegrationTests: XCTestCase {
	
	//  ***********************
	//
	//  Uncomment and implement the following tests if your
	//  implementation persists data to disk (e.g., CoreData/Realm)
	//
	//  ***********************
	
	override func setUp() {
		super.setUp()
		
		setupEmptyStoreState()
	}
	
	override func tearDown() {
		super.tearDown()
		
		undoStoreSideEffects()
	}
	
	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()
		
		expect(sut, toRetrieve: .empty)
	}
	
	func test_retrieve_deliversFeedInsertedOnAnotherInstance() {
		let storeToInsert = makeSUT()
		let storeToLoad = makeSUT()
		let feed = uniqueImageFeed()
		let timestamp = Date()
		
		insert((feed, timestamp), to: storeToInsert)
		
		expect(storeToLoad, toRetrieve: .found(feed: feed, timestamp: timestamp))
	}
	
	func test_insert_overridesFeedInsertedOnAnotherInstance() {
		let storeToInsert = makeSUT()
		let storeToOverride = makeSUT()
		let storeToLoad = makeSUT()
		
		insert((uniqueImageFeed(), Date()), to: storeToInsert)
		
		let latestFeed = uniqueImageFeed()
		let latestTimestamp = Date()
		insert((latestFeed, latestTimestamp), to: storeToOverride)
		
		expect(storeToLoad, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
	}
	
	func test_delete_deletesFeedInsertedOnAnotherInstance() {
		let storeToInsert = makeSUT()
		let storeToDelete = makeSUT()
		let storeToLoad = makeSUT()
		
		insert((uniqueImageFeed(), Date()), to: storeToInsert)
		
		deleteCache(from: storeToDelete)
		
		expect(storeToLoad, toRetrieve: .empty)
	}
	
	// - MARK: Helpers
	
	private func makeSUT() -> FeedStore {
		return RealmFeedStore(configuration: testSpecificRealmConfiguration, cacheId: testSpecificCacheID)
	}
	
	
	private func setupEmptyStoreState() {
		deleteStoreArtifacts()
	}
	
	private func undoStoreSideEffects() {
		deleteStoreArtifacts()
	}
	
	private func deleteStoreArtifacts() {
		_ = try! Realm.deleteFiles(for: testSpecificRealmConfiguration)
	}
	
	private lazy var testSpecificRealmConfiguration = Realm.Configuration(fileURL: testSpecificRealmStoreURL)
	
	private let testSpecificRealmStoreURL: URL = {
		let defaultRealmURL = Realm.Configuration.defaultConfiguration.fileURL
		let defaultRealmParentDirectoryURL = defaultRealmURL?.deletingLastPathComponent()
		let testSpecificRealmURL = defaultRealmParentDirectoryURL?.appendingPathComponent("\(FeedStoreIntegrationTests.self).realm")
		return testSpecificRealmURL!
	}()
	
	private let testSpecificCacheID = UUID(uuidString: "00000000-0000-4000-0000-000000000000")!
	
}

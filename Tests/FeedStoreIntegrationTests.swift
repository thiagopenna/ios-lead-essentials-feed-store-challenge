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
	
	private func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedStore {
		let sut = try! RealmFeedStore(configuration: testSpecificRealmConfiguration)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
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
	
	private var testSpecificRealmConfiguration: Realm.Configuration {
		Realm.Configuration(fileURL: testSpecificRealmStoreURL)
	}
	
	private var testSpecificRealmStoreURL: URL {
		let defaultRealmURL = Realm.Configuration.defaultConfiguration.fileURL
		let defaultRealmParentDirectoryURL = defaultRealmURL?.deletingLastPathComponent()
		let testSpecificRealmURL = defaultRealmParentDirectoryURL?.appendingPathComponent("\(FeedStoreIntegrationTests.self).realm")
		return testSpecificRealmURL!
	}
}

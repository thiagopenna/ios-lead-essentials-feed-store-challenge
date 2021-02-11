//
//  RealmFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Thiago Penna on 09/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import RealmSwift

public class RealmFeedStore: FeedStore {
	private let configuration: Realm.Configuration
	private var cacheId: UUID
	
	public init(configuration: Realm.Configuration, cacheId: UUID) {
		self.configuration = configuration
		self.cacheId = cacheId
	}
	
	private static func openRealm(with configuration: Realm.Configuration) throws -> Realm {
		return try Realm(configuration: configuration, queue: queue)
	}
	
	private static let queue = DispatchQueue(label: "\(RealmFeedStore.self)Queue", qos: .userInitiated)
	
	private lazy var retrievalPredicate = NSPredicate(format: "_id = %@", cacheId.uuidString)
	
	private static func retrieveCache(on realm: Realm, with predicate: NSPredicate) -> RealmCache? {
		let caches = realm.objects(RealmCache.self)
		let filteredCache = caches.filter(predicate)
		return filteredCache.first
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		RealmFeedStore.performRealmOperation ({ [configuration, retrievalPredicate] in
			RealmFeedStore.performRetrieve(with: configuration, and: retrievalPredicate)
		}, completion: completion)
	}
	
	private static func performRetrieve(with configuration: Realm.Configuration, and predicate: NSPredicate) -> RetrieveCachedFeedResult {
		do {
			let realm = try RealmFeedStore.openRealm(with: configuration)
			realm.refresh()
			guard let cache = RealmFeedStore.retrieveCache(on: realm, with: predicate) else {
				return .empty
			}
			return .found(feed: cache.local, timestamp: cache.timestamp)
		} catch {
			return .failure(error)
		}
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let cache = RealmCache(_id: cacheId.uuidString, feed: feed.map(RealmFeedImage.init(withLocalImage:)), timestamp: timestamp)
		RealmFeedStore.performRealmOperation({ [configuration]in
			RealmFeedStore.performInsert(of: cache, with: configuration)
		}, completion: completion)
	}
	
	private static func performInsert(of cache: RealmCache, with configuration: Realm.Configuration) -> Error? {
		do {
			let realm = try RealmFeedStore.openRealm(with: configuration)
			try realm.write {
				realm.add(cache, update: .modified)
			}
			return nil
		} catch {
			return error
		}
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		RealmFeedStore.performRealmOperation ({ [configuration, retrievalPredicate] in
			RealmFeedStore.performDelete(with: configuration, and: retrievalPredicate)
		}, completion: completion)
	}
	
	private static func performDelete(with configuration: Realm.Configuration, and predicate: NSPredicate) -> Error? {
		do {
			let realm = try RealmFeedStore.openRealm(with: configuration)
			guard let cache = RealmFeedStore.retrieveCache(on: realm, with: predicate) else {
				return nil
			}
			try realm.write {
				realm.delete(cache)
			}
			return nil
		} catch {
			return error
		}
	}
	
	/// Performs the block passed inside an autoreleasepool, from the correct thread.
	///
	/// From [Realm documentation](https://docs.mongodb.com/realm-legacy/docs/swift/latest/#threading):
	/// Realm read transaction lifetimes are tied to the memory lifetime of Realm instances. Avoid “pinning” old Realm transactions by
	/// using auto-refreshing Realms and wrapping all use of Realm APIs from background threads in **explicit autorelease pools**.
	///
	/// - parameter blockToPerform: The operation to be performed
	/// - parameter completion: The completion block to be executed with the blockToPerform result
	private static func performRealmOperation<ResultType>(_ blockToPerform: @escaping () -> ResultType, completion: @escaping (ResultType) -> Void) {
		RealmFeedStore.queue.async {
			var result: ResultType!
			autoreleasepool {
				result = blockToPerform()
			}
			completion(result)
		}
	}
}

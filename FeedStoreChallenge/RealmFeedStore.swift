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
	
	public init(configuration: Realm.Configuration) {
		self.configuration = configuration
	}
	
	private static func openRealm(with configuration: Realm.Configuration) throws -> Realm {
		return try Realm(configuration: configuration, queue: queue)
	}
	
	private static let queue = DispatchQueue(label: "\(RealmFeedStore.self)Queue", qos: .userInitiated)
		
	private static func retrieveCache(on realm: Realm) -> RealmCache? {
		let caches = realm.objects(RealmCache.self)
		return caches.first
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		RealmFeedStore.performRealmOperation ({ [configuration] in
			RealmFeedStore.performRetrieve(with: configuration)
		}, completion: completion)
	}
	
	private static func performRetrieve(with configuration: Realm.Configuration) -> RetrieveCachedFeedResult {
		do {
			let realm = try RealmFeedStore.openRealm(with: configuration)
			realm.refresh()
			guard let cache = RealmFeedStore.retrieveCache(on: realm) else {
				return .empty
			}
			let localFeed = try cache.toLocal()
			return .found(feed: localFeed, timestamp: cache.timestamp)
		} catch {
			return .failure(error)
		}
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let cache = RealmCache(feed: feed.map(RealmFeedImage.init(withLocalImage:)), timestamp: timestamp)
		RealmFeedStore.performRealmOperation({ [configuration] in
			RealmFeedStore.performInsert(of: cache, with: configuration)
		}, completion: completion)
	}
	
	private static func performInsert(of cache: RealmCache, with configuration: Realm.Configuration) -> Error? {
		do {
			let realm = try RealmFeedStore.openRealm(with: configuration)
			try realm.write {
				realm.deleteAll()
				realm.add(cache)
			}
			return nil
		} catch {
			return error
		}
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		RealmFeedStore.performRealmOperation ({ [configuration] in
			RealmFeedStore.performDelete(with: configuration)
		}, completion: completion)
	}
	
	private static func performDelete(with configuration: Realm.Configuration) -> Error? {
		do {
			let realm = try RealmFeedStore.openRealm(with: configuration)
			try realm.write {
				realm.deleteAll()
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

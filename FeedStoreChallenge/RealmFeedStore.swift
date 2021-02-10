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
	
	private func openRealm() throws -> Realm {
		return try Realm(configuration: self.configuration)
	}
	
	private lazy var retrievalPredicate = NSPredicate(format: "_id = %@", cacheId.uuidString)
	
	private func retrieveCache(on realm: Realm) -> RealmCache? {
		let caches = realm.objects(RealmCache.self)
		let filteredCache = caches.filter(self.retrievalPredicate)
		return filteredCache.first
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		do {
			let realm = try self.openRealm()
			guard let cache = retrieveCache(on: realm) else {
				return completion(.empty)
			}
			completion(.found(feed: cache.local, timestamp: cache.timestamp))
		} catch {
			completion(.failure(error))
		}
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		do {
			let realm = try self.openRealm()
			try realm.write {
				let cache = RealmCache(_id: cacheId.uuidString, feed: feed.map(RealmFeedImage.init(withLocalImage:)), timestamp: timestamp)
				realm.add(cache, update: .modified)
				completion(nil)
			}
		} catch {
			completion(error)
		}
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		do {
			let realm = try self.openRealm()
			guard let cache = retrieveCache(on: realm) else {
				return completion(nil)
			}
			try realm.write {
				realm.delete(cache)
				completion(nil)
			}
		} catch {
			completion(error)
		}
	}
}

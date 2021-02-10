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
	private var realm: Realm!
	private var cacheId: UUID
	
	public init(configuration: Realm.Configuration, cacheId: UUID) {
		self.realm = try! Realm(configuration: configuration)
		self.cacheId = cacheId
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		let predicate = NSPredicate(format: "_id = %@", cacheId.uuidString)
		guard let cache = realm.objects(RealmCache.self).filter(predicate).first else {
			return completion(.empty)
		}
		return completion(.found(feed: cache.local, timestamp: cache.timestamp))
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		do {
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
		let predicate = NSPredicate(format: "_id = %@", cacheId.uuidString)
		guard let cache = realm.objects(RealmCache.self).filter(predicate).first else {
			return completion(nil)
		}
		do {
			try realm.write {
				realm.delete(cache)
				completion(nil)
			}
		} catch {
			completion(error)
		}
	}
}

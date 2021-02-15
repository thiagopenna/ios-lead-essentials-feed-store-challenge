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
	private var realm: Realm?
	
	public init(configuration: Realm.Configuration) {
		self.configuration = configuration
	}
		
	private func createRealmInstance(with configuration: Realm.Configuration) throws -> Realm {
		try RealmFeedStore.queue.sync {
			try autoreleasepool {
				try Realm(configuration: configuration, queue: RealmFeedStore.queue)
			}
		}
	}
	
	private func getRealmInstance() throws -> Realm {
		guard let realm = realm else {
			let newRealm = try createRealmInstance(with: configuration)
			self.realm = newRealm
			return newRealm
		}
		return realm
	}
	
	private static let queue = DispatchQueue(label: "\(RealmFeedStore.self)Queue", qos: .userInitiated)
		
	public func retrieve(completion: @escaping RetrievalCompletion) {
		do {
			let realm: Realm = try getRealmInstance()
			RealmFeedStore.performRetrieve(on: realm, completion: completion)
		} catch {
			completion(.failure(error))
		}
	}
	
	private static func performRetrieve(on realm: Realm, completion: @escaping RetrievalCompletion) {
		RealmFeedStore.queue.async {
			do {
				guard let cache = realm.objects(RealmCache.self).first else {
					return completion(.empty)
				}
				let localFeed = try cache.toLocal()
				completion(.found(feed: localFeed, timestamp: cache.timestamp))
			} catch {
				completion(.failure(error))
			}
		}
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let cache = RealmCache(feed: feed.map(RealmFeedImage.init(withLocalImage:)), timestamp: timestamp)
		do {
			let realm: Realm = try getRealmInstance()
			RealmFeedStore.performInsert(of: cache, on: realm, completion: completion)
		} catch {
			completion(error)
		}
	}
	
	private static func performInsert(of cache: RealmCache, on realm: Realm, completion: @escaping InsertionCompletion) {
		RealmFeedStore.queue.async {
			do {
				try realm.write {
					realm.deleteAll()
					realm.add(cache)
				}
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		do {
			let realm: Realm = try getRealmInstance()
			RealmFeedStore.performDelete(on: realm, completion: completion)
		} catch {
			completion(error)
		}
	}
	
	private static func performDelete(on realm: Realm, completion: @escaping DeletionCompletion) {
		RealmFeedStore.queue.async {
			do {
				try realm.write {
					realm.deleteAll()
				}
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
}

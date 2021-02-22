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
	private var realm: Realm
	
	public init(configuration: Realm.Configuration) throws {
		self.realm = try RealmFeedStore.createRealmInstance(with: configuration)
	}
		
	private static func createRealmInstance(with configuration: Realm.Configuration) throws -> Realm {
		try RealmFeedStore.queue.sync {
			try autoreleasepool {
				try Realm(configuration: configuration, queue: RealmFeedStore.queue)
			}
		}
	}
	
	private static let queue = DispatchQueue(label: "\(RealmFeedStore.self)Queue", qos: .userInitiated)
		
	public func retrieve(completion: @escaping RetrievalCompletion) {
		RealmFeedStore.perform({ [realm] in
			RealmFeedStore.retrieve(on: realm)
		}, completion: completion)
	}
	
	private static func retrieve(on realm: Realm) -> RetrieveCachedFeedResult {
		do {
			guard let cache = realm.objects(RealmCache.self).first else {
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
		RealmFeedStore.perform({ [realm] in
			RealmFeedStore.insert(cache, on: realm)
		}, completion: completion)
	}
	
	private static func insert(_ cache: RealmCache, on realm: Realm) -> Error? {
		do {
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
		RealmFeedStore.perform({ [realm] in
			RealmFeedStore.delete(on: realm)
		}, completion: completion)
	}
	
	private static func delete(on realm: Realm) -> Error? {
		do {
			try realm.write {
				realm.deleteAll()
			}
			return nil
		} catch {
			return error
		}
	}
	
	private static func perform<ResultType>(_ block: @escaping () -> ResultType, completion: @escaping (ResultType) -> ()) {
		RealmFeedStore.queue.async {
			let result = block()
			completion(result)
		}
	}
}

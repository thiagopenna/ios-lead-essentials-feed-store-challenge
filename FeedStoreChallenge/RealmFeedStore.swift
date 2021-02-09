//
//  RealmFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Thiago Penna on 09/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import RealmSwift

internal class RealmCache: Object {
	let feed: List<RealmFeedImage> = List<RealmFeedImage>()
	@objc dynamic var timestamp: Date = Date()
	
	internal convenience init(feed: [RealmFeedImage], timestamp: Date) {
		self.init()
		self.feed.append(objectsIn: feed)
		self.timestamp = timestamp
	}
	
	internal var local: [LocalFeedImage] {
		return feed.map { $0.local }
	}
}

internal class RealmFeedImage: Object {
	@objc dynamic var _id: String!
	@objc dynamic var desc: String?
	@objc dynamic var location: String?
	@objc dynamic var url: String!
		
	internal convenience init(withLocalImage image: LocalFeedImage) {
		self.init()
		self._id = image.id.uuidString
		self.desc = image.description
		self.location = image.location
		self.url = image.url.absoluteString
	}
		
	internal var local: LocalFeedImage {
		return LocalFeedImage(id: UUID(uuidString: _id)!, description: desc, location: location, url: URL(string: url)!)
	}
}

public class RealmFeedStore: FeedStore {
	
	private var realm: Realm!
	
	public init(configuration: Realm.Configuration) {
		self.realm = try! Realm(configuration: configuration)
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		guard let cache = realm.objects(RealmCache.self).first else {
			return completion(.empty)
		}
		return completion(.found(feed: cache.local, timestamp: cache.timestamp))
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		try! realm.write {
			let cache = RealmCache(feed: feed.map(RealmFeedImage.init(withLocalImage:)), timestamp: timestamp)
			realm.add(cache)
			completion(nil)
		}
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		// TODO: implement deletion
	}
}

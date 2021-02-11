//
//  RealmCache.swift
//  FeedStoreChallenge
//
//  Created by Thiago Penna on 10/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import RealmSwift

internal class RealmCache: Object {
	@objc dynamic var _id: String!
	@objc dynamic var timestamp: Date = Date()
	let feed: List<RealmFeedImage> = List<RealmFeedImage>()
	
	internal convenience init(_id: String, feed: [RealmFeedImage], timestamp: Date) {
		self.init()
		self._id = _id
		self.feed.append(objectsIn: feed)
		self.timestamp = timestamp
	}
	
	override class func primaryKey() -> String? {
		return "_id"
	}
	
	func toLocal() throws -> [LocalFeedImage] {
		return try feed.map { try $0.toLocal() }
	}
}

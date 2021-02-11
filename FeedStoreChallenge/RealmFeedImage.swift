//
//  RealmFeedImage.swift
//  FeedStoreChallenge
//
//  Created by Thiago Penna on 10/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import RealmSwift

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
		
	internal func toLocal() throws -> LocalFeedImage {
		guard let id = UUID(uuidString: _id), let url = URL(string: url) else {
			throw Realm.Error(.fail)
		}
		return LocalFeedImage(id: id, description: desc, location: location, url: url)
	}
}

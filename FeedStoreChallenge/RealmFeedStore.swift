//
//  RealmFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Thiago Penna on 09/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public class RealmFeedStore: FeedStore {
	
	public init() {
		
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		completion(.empty)
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		// TODO: implement insertion
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		// TODO: implement deletion
	}
}

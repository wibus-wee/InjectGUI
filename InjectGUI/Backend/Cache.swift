//
//  Cache.swift
//  InjectGUI
//
//  Created by wibus on 2024/7/31.
//
//
//import Cache
//
//enum CacheKey {
//    static let latestCommitHash = "latestCommitHash"
//}
//
//// MARK: - Cache Configuration
//
//// 存一个有关 main/latest commit hash 的缓存
//let diskConfig = DiskConfig(name: "InjectLib")
//let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
//let transformer = TransformerFactory.forCodable(ofType: String.self)
//let storage = try! Storage<String, String>(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: transformer)

//
//  AdsUtils.swift
//  UiKitQa
//
//  Created by Boris on 30.07.2022.
//


let baseURL = "https://bigstar.xani.space"

struct Category: Decodable {
    let uuid: String
    let name: String
    let updatedAt: String
    let createdAt: String
}

struct ClientAds: Decodable {
    let uuid: String
    let title: String
    let description: String
    let thumbnailUuid: String
    let bannerUuid: String
    let advertiserUuid: String
    let youtubeUrl: String
    let instagramUrl: String
    let bigstarUrl: String
    let websiteUrl: String
    let createdAt: String
    let updatedAt: String
    let startsAt: String
    let endsAt: String
}

struct AdvertiserAds: Decodable {
    let uuid: String
    let title: String
    let description: String
    let thumbnailUuid: String
    let bannerUuid: String
    let advertiserUuid: String
    let youtubeUrl: String
    let instagramUrl: String
    let bigstarUrl: String
    let websiteUrl: String
    let showsNumber: Int
    let clicksNumber: Int
    let bigstarClicksNumber: Int
    let youtubeClicksNumber: Int
    let websiteClicksNumber: Int
    let instagramClicksNumber: Int
    let createdAt: String
    let updatedAt: String
    let startsAt: String
    let endsAt: String
}

struct CreateClientAds: Decodable {
    let uuid: String
    let title: String
    let description: String
    let thumbnailUuid: String
    let bannerUuid: String
    let advertiserUuid: String
    let startsAt: String
    let endsAt: String
    let youtubeUrl: String
    let instagramUrl: String
    let bigstarUrl: String
    let websiteUrl: String
    let createdAt: String
    let updatedAt: String
    let showsNumber: Int
    let clicksNumber: Int
    let bigstarClicksNumber: Int
    let youtubeClicksNumber: Int
    let websiteClicksNumber: Int
    let instagramClicksNumber: Int
}

struct FileResponse: Decodable {
    let fieldname: String
    let originalname: String
    let filename: String
    let mimetype: String
    let path: String
    let destination: String
    let encoding: String
    let size: Int
    let id: Int
    let uuid: String
    let createdAt: String
    let updatedAt: String
}

struct LoginResponse: Decodable{
    let access_token: String
}

struct CreateAdvertiserResponse: Decodable {
    let uuid: String
    let firstname: String?
    let lastname: String?
    let company: String?
    let createdAt: String
    let updatedAt: String
}

struct MeAdvertiser: Decodable {
    let id: Int
    let uuid: String
    let firstname: String?
    let lastname: String?
    let company: String?
    let userUuid: String
    let createdAt: String
    let updatedAt: String
}

struct MeResponse: Decodable {
    let id: Int
    let uuid: String
    let username: String
    let password: String
    let createdAt: String
    let updatedAt: String
    let advertiser: MeAdvertiser
}

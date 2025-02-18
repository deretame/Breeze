// To parse this JSON data, do
//
//     final githubReleaseJson = githubReleaseJsonFromJson(jsonString);

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'github_release_json.freezed.dart';
part 'github_release_json.g.dart';

List<GithubReleaseJson> githubReleaseJsonFromJson(String str) =>
    List<GithubReleaseJson>.from(
      json.decode(str).map((x) => GithubReleaseJson.fromJson(x)),
    );

String githubReleaseJsonToJson(List<GithubReleaseJson> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@freezed
class GithubReleaseJson with _$GithubReleaseJson {
  const factory GithubReleaseJson({
    @JsonKey(name: "url") required String url,
    @JsonKey(name: "assets_url") required String assetsUrl,
    @JsonKey(name: "upload_url") required String uploadUrl,
    @JsonKey(name: "html_url") required String htmlUrl,
    @JsonKey(name: "id") required int id,
    @JsonKey(name: "author") required Author author,
    @JsonKey(name: "node_id") required String nodeId,
    @JsonKey(name: "tag_name") required String tagName,
    @JsonKey(name: "target_commitish") required String targetCommitish,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "draft") required bool draft,
    @JsonKey(name: "prerelease") required bool prerelease,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "published_at") required DateTime publishedAt,
    @JsonKey(name: "assets") required List<Asset> assets,
    @JsonKey(name: "tarball_url") required String tarballUrl,
    @JsonKey(name: "zipball_url") required String zipballUrl,
    @JsonKey(name: "body") required String body,
  }) = _GithubReleaseJson;

  factory GithubReleaseJson.fromJson(Map<String, dynamic> json) =>
      _$GithubReleaseJsonFromJson(json);
}

@freezed
class Asset with _$Asset {
  const factory Asset({
    @JsonKey(name: "url") required String url,
    @JsonKey(name: "id") required int id,
    @JsonKey(name: "node_id") required String nodeId,
    @JsonKey(name: "name") required String name,
    @JsonKey(name: "label") required dynamic label,
    @JsonKey(name: "uploader") required Author uploader,
    @JsonKey(name: "content_type") required String contentType,
    @JsonKey(name: "state") required String state,
    @JsonKey(name: "size") required int size,
    @JsonKey(name: "download_count") required int downloadCount,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "updated_at") required DateTime updatedAt,
    @JsonKey(name: "browser_download_url") required String browserDownloadUrl,
  }) = _Asset;

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
}

@freezed
class Author with _$Author {
  const factory Author({
    @JsonKey(name: "login") required String login,
    @JsonKey(name: "id") required int id,
    @JsonKey(name: "node_id") required String nodeId,
    @JsonKey(name: "avatar_url") required String avatarUrl,
    @JsonKey(name: "gravatar_id") required String gravatarId,
    @JsonKey(name: "url") required String url,
    @JsonKey(name: "html_url") required String htmlUrl,
    @JsonKey(name: "followers_url") required String followersUrl,
    @JsonKey(name: "following_url") required String followingUrl,
    @JsonKey(name: "gists_url") required String gistsUrl,
    @JsonKey(name: "starred_url") required String starredUrl,
    @JsonKey(name: "subscriptions_url") required String subscriptionsUrl,
    @JsonKey(name: "organizations_url") required String organizationsUrl,
    @JsonKey(name: "repos_url") required String reposUrl,
    @JsonKey(name: "events_url") required String eventsUrl,
    @JsonKey(name: "received_events_url") required String receivedEventsUrl,
    @JsonKey(name: "type") required String type,
    @JsonKey(name: "user_view_type") required String userViewType,
    @JsonKey(name: "site_admin") required bool siteAdmin,
  }) = _Author;

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);
}

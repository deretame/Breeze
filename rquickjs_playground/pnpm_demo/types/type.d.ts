export type StringMap = Record<string, unknown>;

export type ActionItem = {
  name: string;
  onTap: StringMap;
  extern: StringMap;
};

export type ImageItem = {
  id: string;
  url: string;
  name: string;
  path: string;
  extern: StringMap;
};

export type MetadataListItem = {
  type: string;
  name: string;
  value: ActionItem[];
};

export type PagingInfo = {
  page: number;
  pages: number;
  total: number;
  hasReachedMax: boolean;
};

export type ComicListItem = {
  source: string;
  id: string;
  title: string;
  subtitle: string;
  finished: boolean;
  likesCount: number;
  viewsCount: number;
  updatedAt: string;
  cover: ImageItem;
  metadata: MetadataListItem[];
  raw: StringMap;
  extern: StringMap;
};

export type SearchComicPayload = {
  keyword?: string;
  page?: number;
  extern?: StringMap;
};

export type ComicDetailPayload = {
  comicId?: string;
  extern?: StringMap;
};

export type ChapterPayload = {
  comicId?: string;
  chapterId?: string | number;
  page?: number;
  extern?: StringMap;
};

export type ReadSnapshotPayload = {
  comicId?: string;
  chapterId?: string | number;
  extern?: StringMap;
};

export type FetchImageBytesPayload = {
  url?: string;
  timeoutMs?: number;
  taskGroupKey?: string;
  extern?: StringMap;
};

/**
 * @deprecated 旧版返回 { id: string }，新插件请直接返回 Uint8Array
 */
export type FetchImageBytesResult = Uint8Array<ArrayBufferLike>;

export type ToggleLikePayload = {
  comicId?: string;
  currentLiked?: boolean;
  extern?: StringMap;
};

export type ToggleLikeResult = {
  liked: boolean;
};

export type ToggleFavoritePayload = {
  comicId?: string;
  currentFavorite?: boolean;
  extern?: StringMap;
};

export type ToggleFavoriteResult = {
  favorited: boolean;
  nextStep: "none" | "selectFolder";
};

export type ListFavoriteFoldersResult = {
  items: Array<{
    id: string;
    name: string;
  }>;
};

export type MoveFavoriteToFolderPayload = {
  comicId?: string;
  folderId?: string;
  folderName?: string;
  extern?: StringMap;
};

export type UserInfoBundleContract = {
  source: string;
  scheme: {
    version: "1.0.0";
    type: "userInfo";
  };
  data: {
    title?: string;
    avatar: ImageItem;
    lines: string[];
    extern?: StringMap;
  };
};

export type CommentItem = {
  id: string;
  author: {
    name: string;
    avatar: {
      url: string;
      path: string;
    };
  };
  content: string;
  createdAt: string;
  replyCount: number;
  replies: CommentItem[];
  extern: StringMap;
};

export type CommentFeedPayload = {
  comicId?: string;
  page?: number;
  extern?: StringMap;
};

export type CommentFeedContract = {
  source: string;
  extern: StringMap | null;
  scheme: {
    version: "1.0.0";
    type: "commentFeed";
  };
  data: {
    topItems: CommentItem[];
    items: CommentItem[];
    paging: {
      hasReachedMax: boolean;
    };
    /** "lazy" = replies on demand, "embedded" = replies inline */
    replyMode: "lazy" | "embedded";
    canComment: {
      comic: boolean;
      reply: boolean;
    };
  };
};

export type CommentRepliesPayload = {
  comicId?: string;
  commentId?: string;
  page?: number;
  extern?: StringMap;
};

export type CommentRepliesContract = {
  source: string;
  extern: StringMap | null;
  scheme: {
    version: "1.0.0";
    type: "commentReplies";
  };
  data: {
    commentId: string;
    items: CommentItem[];
    paging: {
      hasReachedMax: boolean;
    };
  };
};

export type CommentPostPayload = {
  comicId?: string;
  content?: string;
  extern?: StringMap;
};

export type CommentReplyPayload = {
  comicId?: string;
  commentId?: string;
  content?: string;
  extern?: StringMap;
};

export type CommentMutationContract = {
  source: string;
  scheme: {
    version: "1.0.0";
    type: "commentMutation";
  };
  data: {
    ok: boolean;
    mode: "postComment" | "postReply";
    parentId?: string;
    created: CommentItem | null;
    insertHint: {
      needsRefetch: boolean;
      /** "prependAfterTop" = insert at top of feed, "prepend" = insert as reply */
      strategy?: "prependAfterTop" | "prepend";
      targetCommentId?: string;
    };
  };
};

export type SearchAction = {
  type: "openSearch";
  payload: {
    source: string;
    keyword: string;
    extern: StringMap;
  };
};

export type PluginFunctionItem = {
  id: string;
  title: string;
  action:
    | { type: "openSearch"; payload: { source: string; keyword?: string } }
    | { type: "openComicDetail"; payload: { comicId: string } }
    | { type: "openWeb"; payload: { title?: string; url: string } }
    | {
        type: "openComicList";
        payload: {
          scene: {
            title: string;
            source: string;
            body: {
              type: "pluginPagedComicList" | "pluginPagedCreatorList";
              request: ComicListRequest;
            };
            filter?: ComicListRequest;
          };
        };
      }
    | {
        type: "openPluginFunction";
        payload: {
          id: string;
          title?: string;
          presentation?: "page" | "dialog";
        };
      }
    | { type: "openCloudFavorite"; payload: { title: string } };
};

export type ComicListRequest = {
  fnPath: string;
  core?: StringMap;
  extern?: StringMap;
};

export type ComicListScene = {
  title: string;
  source: string;
  body: {
    type: "pluginPagedComicList" | "pluginPagedCreatorList";
    request: ComicListRequest;
  };
  filter?: ComicListRequest;
};

export type ComicListSceneBundleContract = {
  source: string;
  scheme: {
    version: "1.0.0";
    type: "comicListSceneBundle";
  };
  data: {
    scene: ComicListScene;
  };
};

export type AdvancedSearchOption = {
  label: string;
  value: unknown;
};

export type AdvancedSearchField = {
  key: string;
  kind: "text" | "switch" | "choice" | "multiChoice";
  label: string;
  options?: AdvancedSearchOption[];
};

export type AdvancedSearchScheme = {
  version: "1.0.0";
  type: "advancedSearch";
  title?: string;
  fields: AdvancedSearchField[];
};

export type AdvancedSearchContract = {
  source: string;
  scheme: AdvancedSearchScheme;
  data: {
    values: StringMap;
  };
};

export type FilterOptionResult = {
  core?: StringMap;
  extern?: StringMap;
  params?: StringMap;
} & StringMap;

export type FilterOption = {
  label: string;
  value: unknown;
  result?: FilterOptionResult;
  children?: FilterOption[];
};

export type FilterField = {
  key: string;
  kind: "choice";
  label: string;
  options: FilterOption[];
};

export type FilterScheme = {
  version: "1.0.0";
  type?: string;
  title?: string;
  fields: FilterField[];
};

export type FilterBundleContract = {
  source: string;
  scheme: FilterScheme;
  data: {
    values: StringMap;
  };
};

export type FunctionPageChipItem = {
  label: string;
  action: SearchAction | StringMap;
  raw?: StringMap;
};

export type FunctionPageActionGridItem = {
  title: string;
  cover: {
    url: string;
    path: string;
    extern: StringMap;
  };
  action: StringMap;
  raw?: StringMap;
};

export type FunctionPageComicSectionItem = {
  title: string;
  subtitle: string;
  action: StringMap;
  items: ComicListItem[];
  raw?: StringMap;
};

export type FunctionPageBodyNode =
  | {
      type: "list";
      children: FunctionPageBodyNode[];
    }
  | {
      type: "chip-list" | "action-grid";
      key: string;
    }
  | {
      type: "comic-section-list";
      key: string;
    }
  | {
      type: "comic-grid";
      key: string;
      title?: string;
      action?: StringMap;
    };

export type FunctionPageData =
  | {
      items: FunctionPageChipItem[];
      hasReachedMax?: boolean;
      [key: string]: unknown;
    }
  | {
      items: FunctionPageActionGridItem[];
      hasReachedMax?: boolean;
      [key: string]: unknown;
    }
  | {
      items: ComicListItem[];
      paging?: PagingInfo;
      hasReachedMax?: boolean;
      [key: string]: unknown;
    }
  | {
      sections: FunctionPageComicSectionItem[];
      hasReachedMax?: boolean;
      [key: string]: unknown;
    }
  | StringMap;

export type PageSchemeBase = {
  version: "1.0.0";
  type: "page";
  title: string;
};

export type FunctionPageScheme = PageSchemeBase & {
  body: FunctionPageBodyNode;
};

export type FunctionPageContract = {
  source: string;
  scheme: FunctionPageScheme;
  data: FunctionPageData;
};

export type GetFunctionPagePayload = {
  id?: string;
  page?: number;
  core?: StringMap;
  extern?: StringMap;
  [key: string]: unknown;
};

export type InfoContract = {
  name: string;
  uuid: string;
  iconUrl: string;
  creator: {
    name: string;
    describe: string;
    coverUrl?: string;
  };
  describe: string;
  version: string;
  home?: string;
  updateUrl?: string;
  npmName?: string;
  function: PluginFunctionItem[];
};

export type PluginInfo = InfoContract;

export type ChapterPage = {
  id: string;
  name: string;
  path: string;
  url: string;
  extern: StringMap;
};

export type ComicDetailNormal = {
  comicInfo: {
    id: string;
    title: string;
    titleMeta: ActionItem[];
    creator: {
      id: string;
      name: string;
      avatar: ImageItem;
      onTap: StringMap;
      extern: StringMap;
    };
    description: string;
    cover: ImageItem;
    metadata: MetadataListItem[];
    extern: StringMap;
  };
  eps: ChapterSummary[];
  recommend: RecommendItem[];
  totalViews: number;
  totalLikes: number;
  totalComments: number;
  isFavourite: boolean;
  isLiked: boolean;
  allowComments: boolean;
  allowLike: boolean;
  allowCollected: boolean;
  allowDownload: boolean;
  extern: StringMap;
};

export type ComicDetailData = {
  normal: ComicDetailNormal;
  raw: unknown;
};

export type ChapterSummary = {
  id: string;
  requestId: string;
  logicalKey: string;
  storageChapterId: string;
  name: string;
  order: number;
  extern: StringMap;
};

export type RecommendItem = {
  source: string;
  id: string;
  title: string;
  subtitle: string;
  finished: boolean;
  likesCount: number;
  viewsCount: number;
  updatedAt: string;
  cover: ImageItem;
  metadata: ActionItem[];
  raw: StringMap;
  extern: StringMap;
};

export type ChapterWithPages = ChapterSummary & {
  pages: ChapterPage[];
};

export type ChapterContent = {
  comic: {
    id: string;
    source: string;
    title: string;
    extern: StringMap;
  };
  chapter: ChapterWithPages;
  chapters: ChapterSummary[];
};

export type ReadSnapshotData = {
  comic: {
    id: string;
    source: string;
    title: string;
    extern: StringMap;
  };
  chapter: ChapterWithPages;
  chapters: Array<{
    id: string;
    name: string;
    order: number;
    extern: StringMap;
  }>;
};

export type SearchResultContract = {
  source: string;
  extern: StringMap | null;
  scheme: {
    version: "1.0.0";
    type: "searchResult";
    source: string;
    list: string;
  };
  data: {
    paging: PagingInfo;
    items: ComicListItem[];
  };
  paging: PagingInfo;
  items: ComicListItem[];
};

export type ComicPagedListContract = {
  source: string;
  extern?: StringMap | null;
  scheme?: Record<string, unknown>;
  data: {
    items: ComicListItem[];
    hasReachedMax: boolean;
  };
};

export type ComicDetailContract = {
  source: string;
  comicId: string;
  extern: StringMap | null;
  scheme: {
    version: "1.0.0";
    type: "comicDetail";
    source: string;
  };
  data: ComicDetailData;
};

export type ChapterContentContract = {
  source: string;
  comicId: string;
  chapterId: string;
  extern: StringMap | null;
  scheme: {
    version: "1.0.0";
    type: "chapterContent";
    source: string;
  };
  data: ChapterContent;
};

export type ReadSnapshotContract = {
  source: string;
  extern: StringMap | null;
  data: ReadSnapshotData;
};

export type FieldKind =
  | "text"
  | "password"
  | "switch"
  | "select"
  | "choice"
  | "multiChoice";

export type BaseField = {
  key: string;
  kind: FieldKind;
  label: string;
  fnPath?: string;
  persist?: boolean;
};

export type OptionField = BaseField & {
  kind: "select" | "choice" | "multiChoice";
  options?: Array<{ label: string; value: unknown }>;
};

export type PlainField = BaseField & {
  kind: "text" | "password" | "switch";
};

export type SettingsField = OptionField | PlainField;

export type SettingsSection = {
  id?: string;
  title: string;
  fields: SettingsField[];
};

export type SettingsBundleContract = {
  source: string;
  scheme: {
    version: "1.0.0";
    type: "settings";
    sections: SettingsSection[];
  };
  data: {
    canShowUserInfo: boolean;
    values: StringMap;
  };
};

export type CapabilityAction = {
  key?: string;
  title: string;
  fnPath: string;
};

export type CapabilitiesBundleContract = {
  source: string;
  scheme: {
    version: "1.0.0";
    type: "capabilities";
    actions: CapabilityAction[];
  };
  data: StringMap;
};

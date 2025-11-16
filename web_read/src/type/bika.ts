export interface BikaInfo {
  comic: Comic;
  eps: Eps;
}

export interface Comic {
  _id: string;
  _creator: Creator;
  title: string;
  description: string;
  thumb: Thumb;
  author: string;
  chineseTeam: string;
  categories: string[];
  tags: string[];
  pagesCount: number;
  epsCount: number;
  finished: boolean;
  updated_at: string;
  created_at: string;
  allowDownload: boolean;
  allowComment: boolean;
  totalLikes: number;
  totalViews: number;
  totalComments: number;
  viewsCount: number;
  likesCount: number;
  commentsCount: number;
  isFavourite: boolean;
  isLiked: boolean;
}

export interface Creator {
  _id: string;
  gender: string;
  name: string;
  verified: boolean;
  exp: number;
  level: number;
  characters: string[];
  role: string;
  avatar: Thumb;
  title: string;
  slogan: string;
}

export interface Thumb {
  originalName: string;
  path: string;
  fileServer: string;
}

export interface Eps {
  docs: EpsDoc[];
}

export interface EpsDoc {
  _id: string;
  title: string;
  order: number;
  updated_at: string;
  id: string;
  pages: Pages;
}

export interface Pages {
  docs: PagesDoc[];
}

export interface PagesDoc {
  _id: string;
  media: Thumb;
  id: string;
}

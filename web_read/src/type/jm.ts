export interface JmInfo {
  id: number;
  name: string;
  images: any[];
  addtime: string;
  description: string;
  total_views: string;
  likes: string;
  series: Series[];
  series_id: string;
  comment_total: string;
  author: string[];
  tags: string[];
  works: string[];
  actors: string[];
  related_list: any[];
  liked: boolean;
  is_favorite: boolean;
  is_aids: boolean;
  price: string;
  purchased: string;
}

export interface Series {
  id: string;
  name: string;
  sort: string;
  info: Info;
}

export interface Info {
  id: number;
  series: any[];
  tags: string;
  name: string;
  images: string[];
  addtime: string;
  series_id: string;
  is_favorite: boolean;
  liked: boolean;
}

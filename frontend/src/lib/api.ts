const API_BASE = process.env.NEXT_PUBLIC_API_URL || '';

export interface NewsItem {
  id: string;
  title: string;
  summary: string;
  source: string;
  url: string;
  published_at: string;
  score: number;
  category: string;
  tags: string[];
  image_url?: string;
}

export interface Channel {
  id: string;
  name: string;
  count: number;
}

export interface Pagination {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}

export interface NewsResponse {
  success: boolean;
  data: {
    items: NewsItem[];
    pagination: Pagination;
  };
}

export interface ChannelsResponse {
  success: boolean;
  data: Channel[];
}

export async function getNews(page = 1, pageSize = 10, channel = 'all', keyword = ''): Promise<NewsResponse> {
  const params = new URLSearchParams({
    page: String(page),
    pageSize: String(pageSize),
    channel,
    keyword,
  });

  const res = await fetch(`${API_BASE}/api/news?${params}`, { cache: 'no-store' });
  return res.json();
}

export async function getChannels(): Promise<ChannelsResponse> {
  const res = await fetch(`${API_BASE}/api/channels`, { cache: 'no-store' });
  return res.json();
}
'use client';

import { useState, useEffect } from 'react';
import { getNews, getChannels, NewsItem, Channel } from '@/lib/api';
import Header from '@/components/Header';
import NewsCard from '@/components/NewsCard';
import Pagination from '@/components/Pagination';

export default function Home() {
  const [news, setNews] = useState<NewsItem[]>([]);
  const [channels, setChannels] = useState<Channel[]>([]);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(6);
  const [total, setTotal] = useState(0);
  const [currentChannel, setCurrentChannel] = useState('all');
  const [keyword, setKeyword] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, [page, currentChannel]);

  async function fetchData() {
    setLoading(true);
    try {
      const [newsRes, channelsRes] = await Promise.all([
        getNews(page, pageSize, currentChannel, keyword),
        getChannels(),
      ]);

      if (newsRes.success) {
        setNews(newsRes.data.items);
        setTotal(newsRes.data.pagination.total);
      }
      if (channelsRes.success) {
        setChannels(channelsRes.data);
      }
    } catch (error) {
      console.error('Failed to fetch data:', error);
    } finally {
      setLoading(false);
    }
  }

  function handleSearch(key: string) {
    setKeyword(key);
    setPage(1);
    fetchData();
  }

  function handleChannelChange(channel: string) {
    setCurrentChannel(channel);
    setPage(1);
  }

  const totalPages = Math.ceil(total / pageSize);

  return (
    <main className="min-h-screen bg-black">
      <Header
        channels={channels}
        currentChannel={currentChannel}
        onChannelChange={handleChannelChange}
        onSearch={handleSearch}
      />

      {/* Hero Section */}
      <section className="pt-28 pb-12 px-8 md:px-16 lg:px-20">
        <div className="max-w-6xl mx-auto">
          <h1 className="text-4xl md:text-5xl lg:text-6xl font-semibold tracking-apple text-white mb-3">
            AI资讯中心
          </h1>
          <p className="text-lg md:text-xl text-[#86868b] tracking-apple">
            精选人工智能前沿资讯
          </p>
        </div>
      </section>

      {/* News Grid */}
      <section className="px-8 md:px-16 lg:px-20 pb-20">
        <div className="max-w-6xl mx-auto">
          <div className="flex items-center gap-4 mb-10">
            <span className="w-1 h-6 bg-[#2997ff] rounded-full" />
            <h2 className="text-xl font-semibold text-white tracking-apple">最新资讯</h2>
          </div>
          {loading ? (
            <div className="flex items-center justify-center h-64">
              <div className="w-8 h-8 border-2 border-[#2997ff] border-t-transparent rounded-full animate-spin" />
            </div>
          ) : (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {news.map((item) => (
                  <NewsCard key={item.id} item={item} />
                ))}
              </div>

              {news.length === 0 && (
                <div className="text-center py-20 text-[#86868b]">
                  暂无数据
                </div>
              )}
            </>
          )}
        </div>
      </section>

      {/* Pagination */}
      {!loading && news.length > 0 && (
        <Pagination
          currentPage={page}
          totalPages={totalPages}
          onPageChange={setPage}
        />
      )}

      {/* Footer */}
      <footer className="border-t border-[#424245] py-12 px-8 md:px-16 lg:px-20">
        <div className="max-w-6xl mx-auto text-center text-[#86868b] text-sm tracking-apple">
          <p>AI资讯中心 - 探索AI的无限可能</p>
        </div>
      </footer>
    </main>
  );
}
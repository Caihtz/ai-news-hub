'use client';

import { useState } from 'react';
import { Channel } from '@/lib/api';

interface HeaderProps {
  channels: Channel[];
  currentChannel: string;
  onChannelChange: (channel: string) => void;
  onSearch: (keyword: string) => void;
}

// 频道中文名称映射
const CHANNEL_NAME_MAP: Record<string, string> = {
  '36氪AI': '36氪AI',
  'DeepMind': 'DeepMind',
  'Engadget': '瘾科技',
  'GitHub AI': 'GitHub AI',
  'Google AI': '谷歌 AI',
  'Hugging Face': 'Hugging Face',
  'Imaging Resource': '影像资源',
  'Microsoft Research': '微软研究院',
  'Meta AI': 'Meta AI',
  'PetaPixel': 'PetaPixel',
  'TechCrunch AI': 'TechCrunch AI',
  'The Verge': 'The Verge',
  'WIRED AI': '连线 AI',
  'arXiv cs.AI': 'arXiv AI',
  'DPReview': 'DPReview',
  '机器之心': '机器之心',
  '色影无忌': '色影无忌',
  '蜂鸟网': '蜂鸟网',
  'PChome数码': 'PChome数码',
};

function getChannelName(name: string): string {
  return CHANNEL_NAME_MAP[name] || name;
}

export default function Header({ channels, currentChannel, onChannelChange, onSearch }: HeaderProps) {
  const [searchValue, setSearchValue] = useState('');
  const [showSearch, setShowSearch] = useState(false);

  function handleSearchSubmit(e: React.FormEvent) {
    e.preventDefault();
    onSearch(searchValue);
  }

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-black/80 backdrop-blur-xl border-b border-[#424245]/50">
      <div className="max-w-6xl mx-auto px-8 md:px-16 lg:px-20">
        <div className="flex items-center justify-between h-14">
          {/* Logo */}
          <div className="flex items-center">
            <h1 className="text-xl font-semibold text-white tracking-apple">
              AI资讯中心
            </h1>
          </div>

          {/* Navigation */}
          <nav className="hidden md:flex items-center gap-8">
            {channels.map((channel) => (
              <button
                key={channel.id}
                onClick={() => onChannelChange(channel.id)}
                className={`text-sm tracking-apple transition-colors duration-300 ${
                  currentChannel === channel.id
                    ? 'text-[#2997ff]'
                    : 'text-[#86868b] hover:text-white'
                }`}
              >
                {getChannelName(channel.name)}
              </button>
            ))}
          </nav>

          {/* Search */}
          <div className="flex items-center gap-4">
            <form onSubmit={handleSearchSubmit} className="relative">
              <input
                type="text"
                value={searchValue}
                onChange={(e) => setSearchValue(e.target.value)}
                placeholder="搜索新闻..."
                className="w-40 md:w-60 px-4 py-2 bg-[#1d1d1f] border border-[#424245] rounded-full text-sm text-white placeholder-[#86868b] focus:outline-none focus:border-[#2997ff] transition-colors duration-300"
              />
            </form>
          </div>
        </div>

        {/* Mobile Channel Nav */}
        <div className="md:hidden flex items-center gap-4 py-3 overflow-x-auto scrollbar-hide">
          <button
            onClick={() => onChannelChange('all')}
            className={`whitespace-nowrap text-sm px-4 py-2 rounded-full transition-colors duration-300 ${
              currentChannel === 'all'
                ? 'bg-[#2997ff] text-white'
                : 'bg-[#1d1d1f] text-[#86868b]'
            }`}
          >
            全部
          </button>
          {channels.map((channel) => (
            <button
              key={channel.id}
              onClick={() => onChannelChange(channel.id)}
              className={`whitespace-nowrap text-sm px-4 py-2 rounded-full transition-colors duration-300 ${
                currentChannel === channel.id
                  ? 'bg-[#2997ff] text-white'
                  : 'bg-[#1d1d1f] text-[#86868b]'
              }`}
            >
              {getChannelName(channel.name)}
            </button>
          ))}
        </div>
      </div>
    </header>
  );
}
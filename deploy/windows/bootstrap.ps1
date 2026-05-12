# ============================================
# AI资讯中心 - 全自动部署脚本 (Windows Server)
# RDP 登录后，以管理员身份在 PowerShell 中运行此脚本
# ============================================
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

Write-Host @"
==============================================
  AI资讯中心 - 全自动部署
  目标: http://avenchoi.top
==============================================
"@ -ForegroundColor Cyan

$ProjectDir = "C:\www\avenchoi.top"
$NginxDir = "C:\nginx"

# ============ 创建目录 ============
Write-Host "[1/7] 创建目录..." -ForegroundColor Yellow
$dirs = @(
    "$ProjectDir\frontend\src\app\test",
    "$ProjectDir\frontend\src\components",
    "$ProjectDir\frontend\src\lib",
    "$ProjectDir\frontend\src\types",
    "$ProjectDir\frontend\public",
    "$ProjectDir\backend",
    "$NginxDir\conf\conf.d",
    "$NginxDir\logs",
    "$NginxDir\ssl"
)
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

# ============ 防火墙 ============
Write-Host "[2/7] 配置防火墙..." -ForegroundColor Yellow
@(80, 443, 3000, 3001) | ForEach-Object {
    New-NetFirewallRule -DisplayName "Port $_" -Direction Inbound -Protocol TCP -LocalPort $_ -Action Allow -Profile Any 2>$null
}

# ============ 创建项目源文件 ============
Write-Host "[3/7] 写入项目文件..." -ForegroundColor Yellow

# ---- 前端文件 ----
@'
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'AI资讯中心',
  description: 'AI热点新闻聚合平台',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body>{children}</body>
    </html>
  );
}
'@ | Out-File -FilePath "$ProjectDir\frontend\src\app\layout.tsx" -Encoding UTF8

@'
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

      {!loading && news.length > 0 && (
        <Pagination
          currentPage={page}
          totalPages={totalPages}
          onPageChange={setPage}
        />
      )}

      <footer className="border-t border-[#424245] py-12 px-8 md:px-16 lg:px-20">
        <div className="max-w-6xl mx-auto text-center text-[#86868b] text-sm tracking-apple">
          <p>AI资讯中心 - 探索AI的无限可能</p>
        </div>
      </footer>
    </main>
  );
}
'@ | Out-File -FilePath "$ProjectDir\frontend\src\app\page.tsx" -Encoding UTF8

@'
'use client';

import { useState } from 'react';
import { Channel } from '@/lib/api';

interface HeaderProps {
  channels: Channel[];
  currentChannel: string;
  onChannelChange: (channel: string) => void;
  onSearch: (keyword: string) => void;
}

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

  function handleSearchSubmit(e: React.FormEvent) {
    e.preventDefault();
    onSearch(searchValue);
  }

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-black/80 backdrop-blur-xl border-b border-[#424245]/50">
      <div className="max-w-6xl mx-auto px-8 md:px-16 lg:px-20">
        <div className="flex items-center justify-between h-14">
          <div className="flex items-center">
            <h1 className="text-xl font-semibold text-white tracking-apple">
              AI资讯中心
            </h1>
          </div>

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

        <div className="md:hidden flex items-center gap-4 py-3 overflow-x-auto">
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
'@ | Out-File -FilePath "$ProjectDir\frontend\src\components\Header.tsx" -Encoding UTF8

@'
import { NewsItem } from '@/lib/api';
import Link from 'next/link';

interface NewsCardProps {
  item: NewsItem;
}

const CATEGORY_NAME_MAP: Record<string, string> = {
  'AI': '人工智能',
  '摄影': '摄影',
  '器材': '器材',
  '消费电子': '消费电子',
};

const SOURCE_NAME_MAP: Record<string, string> = {
  'Google AI': '谷歌 AI',
  'Microsoft Research': '微软研究院',
  'Hugging Face': 'Hugging Face',
  'DeepMind': 'DeepMind',
  'Meta AI': 'Meta AI',
  'GitHub AI': 'GitHub AI',
  'arXiv cs.AI': 'arXiv AI',
  'TechCrunch AI': 'TechCrunch AI',
  'WIRED AI': '连线 AI',
  '机器之心': '机器之心',
  '36氪AI': '36氪AI',
  'PetaPixel': 'PetaPixel',
  'The Verge': 'The Verge',
  'Engadget': '瘾科技',
  'Imaging Resource': '影像资源',
  'DPReview': 'DPReview',
  '色影无忌': '色影无忌',
  '蜂鸟网': '蜂鸟网',
  'PChome数码': 'PChome数码',
};

function getCategoryName(name: string): string {
  return CATEGORY_NAME_MAP[name] || name;
}

function getSourceName(name: string): string {
  return SOURCE_NAME_MAP[name] || name;
}

function formatTime(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleDateString('zh-CN', {
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export default function NewsCard({ item }: NewsCardProps) {
  const tags = Array.isArray(item.tags)
    ? item.tags
    : typeof item.tags === 'string'
    ? JSON.parse(item.tags || '[]')
    : [];

  return (
    <Link href={item.url} target="_blank" rel="noopener noreferrer">
      <article className="group bg-[#1d1d1f] rounded-3xl overflow-hidden border border-[#424245]/30 hover:border-[#424245] transition-all duration-500 hover:transform hover:scale-[1.01] hover:bg-[#252527]">
        <div className="aspect-video overflow-hidden">
          <img
            src={item.image_url || 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800'}
            alt={item.title}
            className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
          />
        </div>

        <div className="p-8">
          <div className="flex items-center justify-between mb-5">
            <span className="text-xs font-medium text-[#2997ff] bg-[#2997ff]/10 px-4 py-1.5 rounded-full">
              {getCategoryName(item.category) || getSourceName(item.source)}
            </span>
            <div className="flex items-center gap-1.5">
              <span className="text-xs text-[#86868b]">热度</span>
              <span className="text-sm font-semibold text-white">{item.score}</span>
            </div>
          </div>

          <h2 className="text-xl font-semibold text-white mb-4 line-clamp-2 group-hover:text-[#2997ff] transition-colors duration-300 tracking-apple leading-snug">
            {item.title}
          </h2>

          <p
            className="text-sm text-[#86868b] mb-5 line-clamp-2 leading-relaxed"
            dangerouslySetInnerHTML={{ __html: item.summary.replace(/<[^>]*>/g, '').slice(0, 200) }}
          />

          <div className="flex items-center justify-between text-xs text-[#86868b] mb-5">
            <span className="flex items-center gap-1">
              <span>{getSourceName(item.source)}</span>
            </span>
            <time>{formatTime(item.published_at)}</time>
          </div>

          <div className="flex items-center gap-2 flex-wrap">
            {tags.slice(0, 4).map((tag, index) => (
              <span
                key={index}
                className="text-xs text-[#86868b] bg-[#2d2d2f] px-3 py-1.5 rounded-lg"
              >
                {tag}
              </span>
            ))}
          </div>
        </div>
      </article>
    </Link>
  );
}
'@ | Out-File -FilePath "$ProjectDir\frontend\src\components\NewsCard.tsx" -Encoding UTF8

@'
'use client';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}

export default function Pagination({ currentPage, totalPages, onPageChange }: PaginationProps) {
  if (totalPages <= 1) return null;

  const pages: (number | string)[] = [];
  for (let i = 1; i <= totalPages; i++) {
    if (i === 1 || i === totalPages || (i >= currentPage - 1 && i <= currentPage + 1)) {
      pages.push(i);
    } else if (pages[pages.length - 1] !== '...') {
      pages.push('...');
    }
  }

  return (
    <div className="flex items-center justify-center gap-2 pb-16">
      <button
        onClick={() => onPageChange(currentPage - 1)}
        disabled={currentPage <= 1}
        className="px-4 py-2 text-sm text-[#86868b] hover:text-white disabled:opacity-30 transition-colors"
      >
        上一页
      </button>
      {pages.map((p, i) => (
        <button
          key={i}
          onClick={() => typeof p === 'number' && onPageChange(p)}
          className={`w-10 h-10 rounded-full text-sm transition-colors ${
            p === currentPage
              ? 'bg-[#2997ff] text-white'
              : typeof p === 'number'
              ? 'text-[#86868b] hover:text-white hover:bg-[#1d1d1f]'
              : 'text-[#86868b] cursor-default'
          }`}
        >
          {p}
        </button>
      ))}
      <button
        onClick={() => onPageChange(currentPage + 1)}
        disabled={currentPage >= totalPages}
        className="px-4 py-2 text-sm text-[#86868b] hover:text-white disabled:opacity-30 transition-colors"
      >
        下一页
      </button>
    </div>
  );
}
'@ | Out-File -FilePath "$ProjectDir\frontend\src\components\Pagination.tsx" -Encoding UTF8

@'
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
'@ | Out-File -FilePath "$ProjectDir\frontend\src\lib\api.ts" -Encoding UTF8

@'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --bg-primary: #000000;
  --bg-secondary: #1d1d1f;
  --bg-tertiary: #2d2d2f;
  --text-primary: #f5f5f7;
  --text-secondary: #86868b;
  --accent: #2997ff;
  --border: #424245;
}

html {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

body {
  background-color: var(--bg-primary);
  color: var(--text-primary);
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif;
}

.tracking-apple {
  letter-spacing: -0.022em;
}

* {
  scrollbar-width: thin;
  scrollbar-color: #424245 transparent;
}

*::-webkit-scrollbar {
  width: 6px;
}

*::-webkit-scrollbar-track {
  background: transparent;
}

*::-webkit-scrollbar-thumb {
  background-color: #424245;
  border-radius: 3px;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
'@ | Out-File -FilePath "$ProjectDir\frontend\src\app\globals.css" -Encoding UTF8

# ---- 前端配置 ----
@'
/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
    ],
  },
  webpack: (config) => {
    config.resolve.alias = {
      ...config.resolve.alias,
      '@': require('path').resolve(__dirname, 'src'),
    };
    return config;
  },
};

module.exports = nextConfig;
'@ | Out-File -FilePath "$ProjectDir\frontend\next.config.js" -Encoding UTF8

@'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
'@ | Out-File -FilePath "$ProjectDir\frontend\tsconfig.json" -Encoding UTF8

@'
{
  "name": "ai-news-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "autoprefixer": "^10.5.0",
    "next": "^14.2.35",
    "postcss": "^8.5.14",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "tailwindcss": "^3.4.19"
  },
  "devDependencies": {
    "@types/node": "25.6.2",
    "@types/react": "19.2.14",
    "typescript": "6.0.3"
  }
}
'@ | Out-File -FilePath "$ProjectDir\frontend\package.json" -Encoding UTF8

@'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {},
  },
  plugins: [],
};
'@ | Out-File -FilePath "$ProjectDir\frontend\tailwind.config.js" -Encoding UTF8

@'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
'@ | Out-File -FilePath "$ProjectDir\frontend\postcss.config.js" -Encoding UTF8

# ---- 后端文件 ----
@'
"""
翻译模块 — 支持 Microsoft Translator / DeepL
"""
import hashlib
import os
import re
import requests
from functools import lru_cache


def _detect_contains_chinese(text: str) -> bool:
    return bool(re.search(r'[一-鿿]', text))


def _env(key: str, default: str = "") -> str:
    return os.environ.get(key, default).strip()


class BaseTranslator:
    def translate(self, text: str) -> str:
        raise NotImplementedError


class MicrosoftTranslator(BaseTranslator):
    def __init__(self, key: str = "", region: str = ""):
        self.key = key or _env("MS_TRANSLATOR_KEY")
        self.region = region or _env("MS_TRANSLATOR_REGION", "eastasia")
        self.endpoint = "https://api.cognitive.microsofttranslator.com"

    def translate(self, text: str) -> str:
        if not text or not text.strip():
            return text
        if _detect_contains_chinese(text):
            return text
        if not self.key:
            return text
        try:
            resp = requests.post(
                f"{self.endpoint}/translate?api-version=3.0&to=zh-Hans",
                headers={
                    "Ocp-Apim-Subscription-Key": self.key,
                    "Ocp-Apim-Subscription-Region": self.region,
                    "Content-Type": "application/json",
                },
                json=[{"Text": text}],
                timeout=10,
            )
            if resp.status_code == 200:
                data = resp.json()
                return data[0]["translations"][0]["text"]
            return text
        except Exception as e:
            print(f"    [翻译] 请求失败: {e}")
            return text


class DeepLTranslator(BaseTranslator):
    def __init__(self, key: str = ""):
        self.key = key or _env("DEEPL_API_KEY")
        self.endpoint = "https://api-free.deepl.com/v2/translate"

    def translate(self, text: str) -> str:
        if not text or not text.strip():
            return text
        if _detect_contains_chinese(text):
            return text
        if not self.key:
            return text
        try:
            resp = requests.post(
                self.endpoint,
                data={"text": text, "target_lang": "ZH"},
                headers={"Authorization": f"DeepL-Auth-Key {self.key}"},
                timeout=10,
            )
            if resp.status_code == 200:
                data = resp.json()
                return data["translations"][0]["text"]
            return text
        except Exception as e:
            print(f"    [翻译] 请求失败: {e}")
            return text


@lru_cache(maxsize=4096)
def _cached_translate(translator: BaseTranslator, text: str) -> str:
    return translator.translate(text)


def create_translator() -> BaseTranslator:
    backend = _env("TRANSLATOR_API", "microsoft").lower()
    if backend == "deepl":
        key = _env("DEEPL_API_KEY")
        if key:
            print(f"[翻译] 使用 DeepL API")
            return DeepLTranslator(key)
    elif backend == "microsoft":
        key = _env("MS_TRANSLATOR_KEY")
        if key:
            region = _env("MS_TRANSLATOR_REGION", "eastasia")
            print(f"[翻译] 使用 Microsoft Translator (区域: {region})")
            return MicrosoftTranslator(key, region)
    elif backend == "none":
        print("[翻译] 翻译功能已关闭")
    return BaseTranslator()


def translate(text: str, translator: BaseTranslator = None) -> str:
    if translator is None or isinstance(translator, BaseTranslator):
        return text
    if not text or not text.strip():
        return text
    return _cached_translate(translator, text)
'@ | Out-File -FilePath "$ProjectDir\backend\translator.py" -Encoding UTF8

@'
"""
AI新闻数据采集器 - 基于RSS订阅源
"""
import feedparser
import requests
from lxml import html
from flask import Flask, jsonify, request
from flask_cors import CORS
import hashlib
import json
import time
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict, field
from typing import Optional
import sqlite3
from translator import create_translator, translate, BaseTranslator


def fix_encoding(s):
    if not isinstance(s, str):
        return s
    if '?' not in s:
        return s
    try:
        return s.encode('utf-8', errors='replace').decode('gbk')
    except:
        return s


# ==================== 配置 ====================

AI_RSS_SOURCES = [
    {"name": "Google AI", "url": "https://blog.google/technology/ai/rss/", "type": "official", "lang": "en", "weight": 1.0, "category": "AI"},
    {"name": "Microsoft Research", "url": "https://microsoft.com/en-us/research/blog/feed/", "type": "research", "lang": "en", "weight": 0.9, "category": "AI"},
    {"name": "Hugging Face", "url": "https://huggingface.co/blog/feed.xml", "type": "developer", "lang": "en", "weight": 0.9, "category": "AI"},
    {"name": "DeepMind", "url": "https://deepmind.google/discover/blog/feed/", "type": "research", "lang": "en", "weight": 0.9, "category": "AI"},
    {"name": "Meta AI", "url": "https://ai.meta.com/blog/rss.xml", "type": "official", "lang": "en", "weight": 0.85, "category": "AI"},
    {"name": "GitHub AI", "url": "https://github.blog/ai-and-ml/feed/", "type": "developer", "lang": "en", "weight": 0.8, "category": "AI"},
    {"name": "arXiv cs.AI", "url": "https://arxiv.org/rss/cs.AI", "type": "academic", "lang": "en", "weight": 0.85, "category": "AI"},
    {"name": "TechCrunch AI", "url": "https://techcrunch.com/category/artificial-intelligence/feed/", "type": "media", "lang": "en", "weight": 0.7, "category": "AI"},
    {"name": "WIRED AI", "url": "https://www.wired.com/feed/tag/ai/latest/rss", "type": "media", "lang": "en", "weight": 0.7, "category": "AI"},
    {"name": "机器之心", "url": "https://www.jiqizhixin.com/rss", "type": "media", "lang": "zh", "weight": 0.8, "category": "AI"},
    {"name": "36氪AI", "url": "https://www.36kr.com/feed", "type": "media", "lang": "zh", "weight": 0.7, "category": "AI"},
]

PHOTO_RSS_SOURCES = [
    {"name": "PetaPixel", "url": "https://petapixel.com/feed", "type": "media", "lang": "en", "weight": 0.85, "category": "摄影"},
    {"name": "The Verge", "url": "https://www.theverge.com/rss/index.xml", "type": "media", "lang": "en", "weight": 0.75, "category": "消费电子"},
    {"name": "Engadget", "url": "https://www.engadget.com/rss.xml", "type": "media", "lang": "en", "weight": 0.75, "category": "消费电子"},
    {"name": "Imaging Resource", "url": "https://imaging-resource.com/review/feed", "type": "media", "lang": "en", "weight": 0.8, "category": "器材"},
    {"name": "DPReview", "url": "https://www.dpreview.com/feed", "type": "media", "lang": "en", "weight": 0.85, "category": "器材"},
    {"name": "色影无忌", "url": "https://www.xitek.com/rss.php", "type": "media", "lang": "zh", "weight": 0.8, "category": "摄影"},
    {"name": "蜂鸟网", "url": "https://www.fengniao.com/feed", "type": "media", "lang": "zh", "weight": 0.75, "category": "摄影"},
    {"name": "PChome数码", "url": "https://news.pchome.com.tw/rss/digital-camera.xml", "type": "media", "lang": "zh", "category": "器材"},
]

RSS_SOURCES = AI_RSS_SOURCES + PHOTO_RSS_SOURCES

SOURCE_TRUST_LEVELS = {
    "Google AI": "high", "Microsoft Research": "high", "DeepMind": "high",
    "Hugging Face": "high", "arXiv cs.AI": "high", "Meta AI": "high",
    "TechCrunch AI": "high", "WIRED AI": "high", "PetaPixel": "high",
    "Imaging Resource": "high", "The Verge": "medium", "Engadget": "medium",
    "DPReview": "medium", "机器之心": "medium", "36氪AI": "low",
}

TRUST_WEIGHTS = {"high": 1.0, "medium": 0.7, "low": 0.3, "blocked": 0.0}

CLICKBAIT_PATTERNS = [
    "震惊", "刚刚", "突发", "揭秘", "惊人", "曝光", "必看", "绝了", "炸裂",
    "刷屏", "疯传", "万万没想到", "竟然", "不看后悔", "太神奇了",
    "you won't believe", "shocking", "unbelievable", "breaking",
    "exclusive", "leaked", "mind-blowing",
]

SPAM_PATTERNS = [
    "点击此处", "立即购买", "限时优惠", "扫码关注", "免费领取",
    "广告推广", "赞助内容", "click here", "buy now", "limited time",
    "subscribe now", "free gift",
]

HIGH_STAKES_TOPICS = [
    "ai取代人类", "ai威胁", "重大突破", "颠覆性技术",
    "agi实现", "ai意识", "里程碑",
]

AI_KEYWORDS = [
    "ai", "artificial intelligence", "machine learning", "deep learning",
    "llm", "gpt", "transformer", "neural network", "nlp",
    "生成式ai", "大模型", "人工智能", "深度学习", "机器学习",
    "语言模型", "神经网络", "自动驾驶", "机器人"
]

PHOTO_KEYWORDS = [
    "camera", "photography", "lens", "sensor", "dslr", "mirrorless",
    "sony", "canon", "nikon", "fujifilm",
    "富士", "索尼", "佳能", "尼康", "相机", "镜头", "摄影",
    "评测", "测评", "样片", "实拍", "器材"
]


@dataclass
class Article:
    id: str
    source: str
    title: str
    url: str
    summary: str
    content: str
    author: str
    published_at: str
    language: str
    tags: list
    image_url: str
    category: str = "AI"
    score: float = 0.0
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())

    def to_dict(self):
        return asdict(self)


class Database:
    def __init__(self, db_path="news.db"):
        self.db_path = db_path
        self.init_db()

    def init_db(self):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('''
            CREATE TABLE IF NOT EXISTS articles (
                id TEXT PRIMARY KEY, source TEXT NOT NULL, title TEXT NOT NULL,
                url TEXT UNIQUE NOT NULL, summary TEXT, content TEXT, author TEXT,
                published_at TEXT, language TEXT, tags TEXT, image_url TEXT,
                category TEXT DEFAULT 'AI', score REAL DEFAULT 0, created_at TEXT,
                content_hash TEXT
            )
        ''')
        c.execute('''
            CREATE TABLE IF NOT EXISTS sources (
                name TEXT PRIMARY KEY, url TEXT NOT NULL, type TEXT, lang TEXT,
                weight REAL, last_checked TEXT, last_success TEXT, error_count INTEGER DEFAULT 0
            )
        ''')
        c.execute('CREATE INDEX IF NOT EXISTS idx_published ON articles(published_at)')
        c.execute('CREATE INDEX IF NOT EXISTS idx_score ON articles(score)')
        conn.commit()
        conn.close()

    def cleanup_old_articles(self, days=7):
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute('DELETE FROM articles WHERE created_at < ?', (cutoff_date,))
        deleted = c.rowcount
        conn.commit()
        conn.close()
        if deleted > 0:
            conn2 = sqlite3.connect(self.db_path)
            conn2.execute('VACUUM')
            conn2.close()
        return deleted

    def upsert_article(self, article: Article) -> bool:
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        content_hash = hashlib.md5(article.content.encode()).hexdigest() if article.content else ""
        try:
            c.execute('''
                INSERT INTO articles (id, source, title, url, summary, content, author,
                    published_at, language, tags, image_url, category, score, created_at, content_hash)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                article.id, article.source, article.title, article.url,
                article.summary, article.content, article.author, article.published_at,
                article.language, json.dumps(article.tags), article.image_url,
                article.category, article.score, article.created_at, content_hash
            ))
            conn.commit()
            return True
        except sqlite3.IntegrityError:
            return False
        finally:
            conn.close()

    def get_articles(self, page=1, page_size=20, channel="all", keyword=""):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        sql = "SELECT * FROM articles WHERE 1=1"
        params = []
        if channel != "all":
            sql += " AND source = ?"
            params.append(channel)
        if keyword:
            sql += " AND (title LIKE ? OR summary LIKE ?)"
            params.extend([f"%{keyword}%", f"%{keyword}%"])
        sql += " ORDER BY score DESC, published_at DESC"
        offset = (page - 1) * page_size
        sql += f" LIMIT {page_size} OFFSET {offset}"
        c.execute(sql, params)
        rows = c.fetchall()
        count_sql = "SELECT COUNT(*) FROM articles WHERE 1=1"
        if channel != "all":
            count_sql += " AND source = ?"
        c.execute(count_sql, params[:1] if channel != "all" else [])
        total = c.fetchone()[0]
        conn.close()
        columns = ["id", "source", "title", "url", "summary", "content", "author",
                   "published_at", "language", "tags", "image_url", "category",
                   "score", "created_at", "content_hash"]
        return [dict(zip(columns, row)) for row in rows], total

    def get_channels(self):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("SELECT source, COUNT(*) as count FROM articles GROUP BY source")
        rows = c.fetchall()
        conn.close()
        return [{"id": r[0], "name": r[0], "count": r[1]} for r in rows]


class Scorer:
    def __init__(self):
        self.ai_keywords = AI_KEYWORDS
        self.photo_keywords = PHOTO_KEYWORDS

    def calculate(self, article: Article, source_config: dict) -> dict:
        category = source_config.get("category", "AI")
        source_name = source_config.get("name", "")
        freshness = self.calc_freshness(article.published_at)
        trust_level = SOURCE_TRUST_LEVELS.get(source_name, "medium")
        trust_score = TRUST_WEIGHTS.get(trust_level, 0.5)
        content_quality = self.calc_content_quality(article.title, article.summary)
        relevance = self.calc_relevance(article.title, article.summary, article.content, category)
        multi_source_bonus = self.calc_multi_source_bonus(article.title)
        final_score = round(
            0.25 * freshness + 0.25 * trust_score +
            0.20 * content_quality + 0.15 * relevance +
            0.15 * multi_source_bonus, 4
        )
        return {
            "final_score": final_score, "freshness": freshness,
            "trust_level": trust_level, "trust_score": trust_score,
            "content_quality": content_quality, "relevance": relevance,
            "multi_source_bonus": multi_source_bonus,
            "is_spam": content_quality < 0.3,
        }

    def calc_freshness(self, published_at: str) -> float:
        if not published_at:
            return 0.3
        try:
            pub_time = datetime.fromisoformat(published_at.replace('Z', '+00:00'))
            now = datetime.now(pub_time.tzinfo) if pub_time.tzinfo else datetime.now()
            age_hours = (now - pub_time).total_seconds() / 3600
            if age_hours <= 24:
                return 1.0
            return max(0.1, 1.0 - (age_hours - 24) * 0.02)
        except:
            return 0.5

    def calc_content_quality(self, title: str, summary: str) -> float:
        text = f"{title} {summary}".lower()
        score = 1.0
        clickbait_count = sum(1 for p in CLICKBAIT_PATTERNS if p.lower() in text)
        if clickbait_count > 0:
            score -= min(0.4, clickbait_count * 0.15)
        spam_count = sum(1 for p in SPAM_PATTERNS if p.lower() in text)
        if spam_count > 0:
            score -= min(0.5, spam_count * 0.25)
        if len(summary) < 50:
            score -= 0.1
        elif len(summary) > 200:
            score += 0.05
        return max(0.0, min(1.0, score))

    def calc_relevance(self, title: str, summary: str, content: str, category: str) -> float:
        keywords = self.ai_keywords if category == "AI" else self.photo_keywords
        text = f"{title} {summary} {content}".lower()
        matches = sum(1 for kw in keywords if kw.lower() in text)
        return min(1.0, matches / 5)

    def calc_multi_source_bonus(self, title: str) -> float:
        text = title.lower()
        is_high_stakes = any(topic in text for topic in HIGH_STAKES_TOPICS)
        if is_high_stakes:
            return 0.5
        return 1.0


class Collector:
    def __init__(self, db_path="news.db", translator: BaseTranslator = None):
        self.db = Database(db_path)
        self.scorer = Scorer()
        self.translator = translator
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (compatible; AI-News-Aggregator/1.0)'
        })
        self.stats = {"total_fetched": 0, "spam_filtered": 0, "duplicate": 0}

    def fetch_feed(self, source: dict) -> list:
        source_name = source["name"]
        try:
            print(f"  抓取: {source_name}...")
            resp = self.session.get(source["url"], timeout=30)
            resp.raise_for_status()
            feed = feedparser.parse(resp.content)
            articles = []
            for entry in feed.entries[:20]:
                try:
                    summary = ""
                    if hasattr(entry, 'summary'):
                        summary = entry.summary[:500]
                    elif hasattr(entry, 'description'):
                        summary = entry.description[:500]
                    entry_id = entry.get('id', entry.get('link', ''))
                    article_id = hashlib.md5(f"{source_name}:{entry_id}".encode()).hexdigest()
                    published = ""
                    if hasattr(entry, 'published'):
                        published = entry.published
                    elif hasattr(entry, 'updated'):
                        published = entry.updated
                    title = entry.get('title', 'No Title')
                    article = Article(
                        id=article_id, source=source_name,
                        title=title, url=entry.get('link', ''),
                        summary=summary, content="",
                        author=entry.get('author', ''),
                        published_at=published, language=source["lang"],
                        tags=[], image_url="",
                        category=source.get("category", "AI")
                    )
                    if self.translator and article.language != "zh":
                        article.title = translate(article.title, self.translator)
                        article.summary = translate(article.summary, self.translator)
                    score_result = self.scorer.calculate(article, source)
                    article.score = score_result["final_score"]
                    self.stats["total_fetched"] += 1
                    if score_result["is_spam"]:
                        print(f"    过滤垃圾: {title[:40]}...")
                        self.stats["spam_filtered"] += 1
                        continue
                    content_hash = hashlib.md5((title + summary).encode()).hexdigest()
                    if self.is_duplicate(title, content_hash):
                        self.stats["duplicate"] += 1
                        continue
                    articles.append(article)
                except Exception as e:
                    print(f"    解析条目失败: {e}")
                    continue
            print(f"    成功: {len(articles)}条")
            return articles
        except Exception as e:
            print(f"    失败: {e}")
            return []

    def is_duplicate(self, title: str, content_hash: str = "") -> bool:
        conn = sqlite3.connect(self.db.db_path)
        c = conn.cursor()
        c.execute('SELECT COUNT(*) FROM articles WHERE title = ?', (title,))
        title_exists = c.fetchone()[0] > 0
        conn.close()
        return title_exists

    def run(self):
        print(f"\n{'='*50}")
        print(f"AI新闻采集器 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"{'='*50}\n")
        self.stats = {"total_fetched": 0, "spam_filtered": 0, "duplicate": 0}
        deleted = self.db.cleanup_old_articles(days=7)
        if deleted > 0:
            print(f"已清理 {deleted} 条过期数据(7天前)\n")
        total_new = 0
        for source in RSS_SOURCES:
            articles = self.fetch_feed(source)
            for article in articles:
                if self.db.upsert_article(article):
                    total_new += 1
        print(f"\n统计: 抓取 {self.stats['total_fetched']} 条, 新增 {total_new} 条, 垃圾 {self.stats['spam_filtered']} 条, 重复 {self.stats['duplicate']} 条\n")
        return total_new


# Flask API
app = Flask(__name__)
CORS(app)
db = Database()

@app.route('/api/news')
def get_news():
    page = int(request.args.get('page', 1))
    page_size = int(request.args.get('pageSize', 10))
    channel = request.args.get('channel', 'all')
    keyword = request.args.get('keyword', '')
    articles, total = db.get_articles(page, page_size, channel, keyword)
    total_pages = (total + page_size - 1) // page_size
    for a in articles:
        a['tags'] = json.loads(a['tags']) if a['tags'] else []
    return jsonify({
        'success': True,
        'data': {
            'items': articles,
            'pagination': {
                'page': page, 'pageSize': page_size,
                'total': total, 'totalPages': total_pages
            }
        }
    })

@app.route('/api/channels')
def get_channels():
    channels = db.get_channels()
    return jsonify({'success': True, 'data': channels})

@app.route('/api/collect')
def trigger_collect():
    collector = Collector()
    count = collector.run()
    return jsonify({'success': True, 'message': f'采集完成，新增 {count} 条'})

@app.route('/api/cleanup')
def trigger_cleanup():
    deleted = db.cleanup_old_articles(days=7)
    return jsonify({'success': True, 'message': f'已清理 {deleted} 条过期数据'})

@app.route('/api/stats')
def get_stats():
    conn = sqlite3.connect('news.db')
    c = conn.cursor()
    c.execute('SELECT COUNT(*) FROM articles')
    total = c.fetchone()[0]
    conn.close()
    return jsonify({'success': True, 'data': {'total': total, 'retention_days': 7}})

if __name__ == '__main__':
    import sys
    translator = create_translator()
    if len(sys.argv) > 1 and sys.argv[1] == 'collect':
        collector = Collector(translator=translator)
        collector.run()
    elif len(sys.argv) > 1 and sys.argv[1] == 'api':
        app.run(port=3001, debug=True)
    else:
        collector = Collector(translator=translator)
        collector.run()
        print("\n启动API服务...")
        app.run(port=3001, debug=True)
'@ | Out-File -FilePath "$ProjectDir\backend\collector.py" -Encoding UTF8

@'
feedparser>=6.0.0
requests>=2.31.0
lxml>=5.0.0
flask>=3.0.0
flask-cors>=4.0.0
waitress>=3.0.0
'@ | Out-File -FilePath "$ProjectDir\backend\requirements.txt" -Encoding UTF8

# ---- Nginx 配置 ----
@'
# Nginx config for avenchoi.top
server {
    listen 80;
    server_name avenchoi.top www.avenchoi.top;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    gzip_min_length 1000;
    gzip_comp_level 6;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
    }

    location /_next/static/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_cache_valid 200 365d;
        add_header Cache-Control "public, immutable";
    }
}
'@ | Out-File -FilePath "$NginxDir\conf\conf.d\avenchoi.top.conf" -Encoding UTF8

# ---- PM2 配置 ----
@'
module.exports = {
  apps: [
    {
      name: 'ai-news-frontend',
      script: 'node_modules\\next\\dist\\bin\\next',
      args: 'start -p 3000',
      cwd: 'C:\\www\\avenchoi.top\\frontend',
      env: { NODE_ENV: 'production' },
      instances: 1,
      autorestart: true,
      max_memory_restart: '500M',
    },
    {
      name: 'ai-news-backend',
      script: 'python',
      args: '-m waitress --host 127.0.0.1 --port 3001 collector:app',
      cwd: 'C:\\www\\avenchoi.top\\backend',
      instances: 1,
      autorestart: true,
      max_memory_restart: '300M',
    },
  ],
};
'@ | Out-File -FilePath "$ProjectDir\ecosystem.config.js" -Encoding UTF8

Write-Host "项目文件写入完成" -ForegroundColor Green

# ============ 安装 Node.js ============
Write-Host "[4/7] 安装 Node.js..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    $nodeUrl = "https://nodejs.org/dist/v18.20.4/node-v18.20.4-win-x64.zip"
    Write-Host "  下载 Node.js..."
    Invoke-WebRequest -Uri $nodeUrl -OutFile "$env:TEMP\nodejs.zip"
    Expand-Archive -Path "$env:TEMP\nodejs.zip" -DestinationPath "C:\nodejs" -Force
    [Environment]::SetEnvironmentVariable("Path", "C:\nodejs;" + [Environment]::GetEnvironmentVariable("Path", "Machine"), "Machine")
    $env:Path = "C:\nodejs;" + $env:Path
    Write-Host "  Node.js $(node -v) 安装完成" -ForegroundColor Green
} else {
    Write-Host "  Node.js $(node -v) 已安装" -ForegroundColor Green
}

# ============ 安装 Python ============
Write-Host "[5/7] 安装 Python..." -ForegroundColor Yellow
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    $pyUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
    Write-Host "  下载 Python..."
    Invoke-WebRequest -Uri $pyUrl -OutFile "$env:TEMP\python-installer.exe"
    Start-Process -Wait -FilePath "$env:TEMP\python-installer.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1"
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine")
    Write-Host "  Python 安装完成" -ForegroundColor Green
} else {
    Write-Host "  Python 已安装" -ForegroundColor Green
}

# ============ 安装 Nginx ============
Write-Host "[6/7] 安装 Nginx..." -ForegroundColor Yellow
if (-not (Test-Path "$NginxDir\nginx.exe")) {
    $nginxUrl = "https://nginx.org/download/nginx-1.26.2.zip"
    Write-Host "  下载 Nginx..."
    Invoke-WebRequest -Uri $nginxUrl -OutFile "$env:TEMP\nginx.zip"
    $extractDir = "$env:TEMP\nginx-extract"
    Expand-Archive -Path "$env:TEMP\nginx.zip" -DestinationPath $extractDir -Force
    $nginxSrc = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
    Copy-Item -Path "$($nginxSrc.FullName)\*" -Destination $NginxDir -Recurse -Force
    Remove-Item $extractDir -Recurse -Force
    Write-Host "  Nginx 安装完成" -ForegroundColor Green
} else {
    Write-Host "  Nginx 已安装" -ForegroundColor Green
}

# ============ 安装 PM2 ============
Write-Host "[7/7] 安装 PM2 并部署..." -ForegroundColor Yellow
if (-not (Get-Command pm2 -ErrorAction SilentlyContinue)) {
    npm install -g pm2
}

# 安装 Python 依赖
Set-Location "$ProjectDir\backend"
pip install -r requirements.txt --quiet

# 安装前端依赖并构建
Set-Location "$ProjectDir\frontend"
npm install --silent
npm run build

# 配置 Nginx
$mainConf = "$NginxDir\conf\nginx.conf"
$nginxConfContent = Get-Content $mainConf -Raw
if ($nginxConfContent -notmatch "include conf.d") {
    $newLine = "`n    include conf.d/*.conf;`n"
    # Add before the last closing brace
    $nginxConfContent = $nginxConfContent -replace '\}\s*$', "$newLine}`n"
    $nginxConfContent | Out-File -FilePath $mainConf -Encoding ASCII
}

# 测试并启动 Nginx
& "$NginxDir\nginx.exe" -t
$nginxProc = Get-Process nginx -ErrorAction SilentlyContinue
if (-not $nginxProc) {
    Start-Process "$NginxDir\nginx.exe" -WindowStyle Hidden
    Write-Host "  Nginx 已启动" -ForegroundColor Green
} else {
    & "$NginxDir\nginx.exe" -s reload
    Write-Host "  Nginx 已重载" -ForegroundColor Green
}

# PM2 启动服务
Set-Location $ProjectDir
pm2 delete all 2>$null
pm2 start ecosystem.config.js
pm2 save
pm2 startup | Invoke-Expression 2>$null

Write-Host @"

==============================================
  部署完成！
==============================================

  网站: http://avenchoi.top
  API:  http://avenchoi.top/api/news

  管理:
    pm2 status    查看服务状态
    pm2 logs      查看日志

  采集新闻:
    cd C:\www\avenchoi.top\backend
    python collector.py collect

==============================================
"@ -ForegroundColor Green

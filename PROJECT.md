# AI资讯中心 - 项目概述

## 项目简介

基于 RSS 订阅源的 AI/科技/摄影新闻聚合平台，自动采集、翻译、评分并展示。Apple 风格深色主题，全中文界面，前后端分离架构。

**技术栈：** Next.js 14 + Tailwind CSS / Python Flask + SQLite

**访问地址：** 前端 http://localhost:3000 / 后端 http://localhost:3001

---

## 已实现功能

### 新闻采集
- 18 个 RSS 源（AI/科技/摄影/消费电子），中英文混合
- 自动定时采集（每小时），7 天自动清理过期数据
- 反垃圾：信息源分级、点击诱饵检测、高风险话题多源验证

### 新闻评分算法
- 新鲜度 25% + 信任度 25% + 内容质量 20% + 相关性 15% + 多源验证 15%

### 自动翻译
- 采集时自动将英文标题/摘要翻译为中文（中文源自动跳过）
- 支持 Microsoft Translator（推荐，200 万字符/月免费）和 DeepL（50 万/月免费）
- 内置 LRU 缓存避免重复翻译，通过环境变量切换后端
- 命令 `python collector.py translate` 可批量翻译已有数据

### 中文界面
- 频道导航、分类标签、来源名称全部中文化
- HTML lang="zh-CN"，日期格式中文本地化

### UI 排版
- Apple 风格深色主题，2 列宽屏卡片网格
- 频道筛选 + 关键词搜索 + 分页
- 卡片展示：封面图、分类、热度、标题、摘要、来源、时间、标签

---

## 项目结构

```
新闻/
├── backend/
│   ├── collector.py        # 主程序（数据库+采集+评分+API）
│   ├── translator.py       # 翻译模块（Microsoft/DeepL）
│   ├── .env.example        # 环境变量配置模板
│   └── news.db             # SQLite 数据库
├── frontend/
│   ├── src/
│   │   ├── app/
│   │   │   ├── layout.tsx      # 根布局（metadata 中文）
│   │   │   ├── page.tsx        # 首页（2列网格+hero+分页）
│   │   │   └── globals.css     # 全局样式
│   │   ├── components/
│   │   │   ├── Header.tsx      # 导航栏（频道+搜索，中文频道名）
│   │   │   ├── NewsCard.tsx    # 新闻卡片（中文分类/来源）
│   │   │   └── Pagination.tsx  # 分页组件
│   │   └── lib/api.ts          # API 封装
│   └── .env.local              # API 地址配置
├── start.bat                   # 一键启动
└── stop.bat                    # 停止服务
```

---

## 启动方式

```bash
# 方式一：一键启动
双击 start.bat

# 方式二：手动启动
cd backend && python collector.py api    # 终端1：后端
cd frontend && npm run dev               # 终端2：前端
```

---

## 翻译 API 配置

```bash
# Windows 环境变量
set TRANSLATOR_API=microsoft
set MS_TRANSLATOR_KEY=你的Key
set MS_TRANSLATOR_REGION=eastasia

# 或使用 DeepL
set TRANSLATOR_API=deepl
set DEEPL_API_KEY=你的Key
```

不配置 API Key 时翻译功能自动禁用，不影响其他功能。

---

## API 接口

| 接口 | 说明 |
|------|------|
| `GET /api/news` | 新闻列表（分页/频道/搜索） |
| `GET /api/channels` | 频道列表 |
| `GET /api/stats` | 数据库统计 |
| `POST /api/collect` | 手动触发采集 |
| `POST /api/cleanup` | 手动清理过期数据 |

---

## 常用命令

```bash
cd backend
python collector.py collect     # 仅采集
python collector.py api         # 仅启动 API
python collector.py translate   # 批量翻译已有数据
python collector.py             # 采集 + 启动 API
```

---

## 后续开发提示

1. **页面空白**：清除 `.next` 缓存 `rm -rf frontend/.next`，停掉 node 进程后重启
2. **数据不足**：运行 `python collector.py collect` 手动采集
3. **英文内容未翻译**：先配好翻译 API 环境变量，再运行 `python collector.py translate`
4. **新增 RSS 源**：在 `collector.py` 的 `AI_RSS_SOURCES` 或 `PHOTO_RSS_SOURCES` 添加，同步更新 Header.tsx 和 NewsCard.tsx 中的映射表
5. **修改 UI 文案**：中文映射集中在 Header.tsx（`CHANNEL_NAME_MAP`）和 NewsCard.tsx（`CATEGORY_NAME_MAP`、`SOURCE_NAME_MAP`）

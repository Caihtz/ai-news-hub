# AI热点监控系统 - 项目需求文档

## 1. 项目概述

**项目名称**: AI News Hub
**项目类型**: 全栈Web应用 (Next.js + Express)
**核心功能**: 采集、展示AI热点新闻，带评分系统和分类筛选
**目标用户**: AI从业者、研究者、爱好者

## 2. 功能需求

### 2.1 后端功能
- 数据采集：从公开源抓取AI热点新闻
- 数据处理：多维度评分计算
- API服务：提供RESTful API
  - `GET /api/news` - 获取新闻列表(支持分页、筛选)
  - `GET /api/channels` - 获取频道分类
  - `GET /api/news/:id` - 获取单条新闻详情
- 数据存储：JSON文件存储(便于部署)

### 2.2 前端功能
- 新闻列表展示：卡片式展示热点新闻
- 分页功能：支持page参数分页
- 频道筛选：通过channel参数筛选分类
- 搜索功能：关键词搜索新闻
- 响应式设计：适配桌面/平板/手机

### 2.3 数据模型
```
News {
  id: string
  title: string
  summary: string
  source: string
  url: string
  publishTime: string
  score: number
  channel: string
  tags: string[]
  imageUrl?: string
}

Channel {
  id: string
  name: string
  count: number
}
```

## 3. UI设计规范 (Apple风格)

### 3.1 色彩系统
```
--bg-primary: #000000 (深色模式背景)
--bg-secondary: #1d1d1f (卡片背景)
--bg-tertiary: #2d2d2f (hover状态)
--text-primary: #f5f5f7 (主文字)
--text-secondary: #86868b (次要文字)
--accent: #2997ff (Apple蓝)
--border: #424245 (边框)
```

### 3.2 字体规范
- 主字体: SF Pro Display, -apple-system, BlinkMacSystemFont, sans-serif
- 标题: 48px/36px/28px, font-weight: 600
- 正文: 17px/15px/13px, font-weight: 400
- 字间距: -0.022em (Apple风格)

### 3.3 间距系统
- 基础单位: 8px
- 页面边距: 80px (桌面) / 40px (平板) / 20px (手机)
- 卡片间距: 24px
- 组件内间距: 16px/24px

### 3.4 动效规范
- 过渡时长: 300ms - 500ms
- 缓动函数: cubic-bezier(0.25, 0.1, 0.25, 1)
- Hover效果: scale(1.02), 背景色渐变

## 4. 技术架构

### 4.1 前端
- 框架: Next.js 14 (App Router)
- 样式: Tailwind CSS
- HTTP客户端: fetch API

### 4.2 后端
- 框架: Express.js
- 数据存储: 本地JSON文件
- 端口: 3001

### 4.3 部署结构
```
/news
├── frontend/     # Next.js前端
├── backend/     # Express后端
└── data/         # 新闻数据JSON
```

## 5. 数据采集方案

### 5.1 RSS订阅源清单

#### AI/科技类 (11个)

| 名称 | RSS地址 | 类型 | 语言 | 权重 | 分类 |
|------|---------|------|------|------|------|
| Google AI | blog.google/technology/ai/rss/ | 官方 | EN | 1.0 | AI |
| Microsoft Research | microsoft.com/en-us/research/blog/feed/ | 研究机构 | EN | 0.9 | AI |
| Hugging Face | huggingface.co/blog/feed.xml | 开发者平台 | EN | 0.9 | AI |
| DeepMind | deepmind.google/discover/blog/feed/ | 研究机构 | EN | 0.9 | AI |
| Meta AI | ai.meta.com/blog/rss.xml | 官方 | EN | 0.85 | AI |
| GitHub AI | github.blog/ai-and-ml/feed/ | 开发者平台 | EN | 0.8 | AI |
| arXiv cs.AI | arxiv.org/rss/cs.AI | 学术 | EN | 0.85 | AI |
| TechCrunch AI | techcrunch.com/category/artificial-intelligence/feed/ | 科技媒体 | EN | 0.7 | AI |
| WIRED AI | wired.com/feed/tag/ai/latest/rss | 科技媒体 | EN | 0.7 | AI |
| 机器之心 | jiqizhixin.com/rss | AI媒体 | 中文 | 0.8 | AI |
| 36氪AI | 36kr.com/feed | 科技媒体 | 中文 | 0.7 | AI |

#### 摄影/器材/消费电子类 (8个)

| 名称 | RSS地址 | 类型 | 语言 | 权重 | 分类 |
|------|---------|------|------|------|------|
| PetaPixel | petapixel.com/feed | 摄影媒体 | EN | 0.85 | 摄影 |
| The Verge | theverge.com/rss/index.xml | 科技媒体 | EN | 0.75 | 消费电子 |
| Engadget | engadget.com/rss.xml | 科技媒体 | EN | 0.75 | 消费电子 |
| Imaging Resource | imaging-resource.com/review/feed | 器材评测 | EN | 0.8 | 器材 |
| DPReview | dpreview.com/feed | 器材评测 | EN | 0.85 | 器材 |
| 色影无忌 | xitek.com/rss.php | 摄影媒体 | 中文 | 0.8 | 摄影 |
| 蜂鸟网 | fengniao.com/feed | 摄影媒体 | 中文 | 0.75 | 摄影 |
| PChome数码 | news.pchome.com.tw/rss/digital-camera.xml | 科技媒体 | 中文 | 0.7 | 器材 |

### 5.2 关键词库

#### AI类关键词
```
ai, artificial intelligence, machine learning, deep learning,
llm, gpt, bert, transformer, neural network,
nlp, natural language, computer vision, reinforcement learning,
生成式ai, 大模型, 人工智能, 深度学习, 机器学习,
语言模型, 神经网络, 自动驾驶, 机器人
```

#### 摄影/器材类关键词
```
camera, photography, lens, sensor, dslr, mirrorless,
sony, canon, nikon, fujifilm, leica, hasselblad,
富士, 索尼, 佳能, 尼康, 相机, 镜头, 摄影,
sensor, iso, aperture, shutter, exposure,
camera body, digital camera, compact camera, action camera,
drone, gopro, insta360, stabilizer, gimbal,
lightroom, photoshop, raw, jpeg, image quality,
评测, 测评, 样片, 实拍, 器材
```

### 5.2 技术栈

- **RSS解析**: feedparser
- **HTML解析**: lxml + requests
- **数据库**: SQLite (开发) / PostgreSQL (生产)
- **评分算法**: 规则评分 (时效性30% + 权威性25% + 相关性25% + 热度10% + 原创性10%)
- **定时任务**: cron / APScheduler

### 5.3 评分算法

```
final_score = 0.30 * freshness + 0.25 * authority + 0.25 * relevance + 0.10 * heat + 0.10 * originality
```

- **时效性**: 发布时间越近分数越高
- **权威性**: 官方/研究机构权重更高
- **相关性**: AI关键词匹配度
- **热度**: 多源共现代理指标
- **原创性**: 内容哈希去重

### 5.4 运行命令

```bash
# 安装依赖
pip install feedparser requests lxml flask

# 仅采集数据
python collector.py collect

# 仅启动API
python collector.py api

# 采集 + API服务
python collector.py
```

## 6. 开发计划

### Day 1: 项目初始化
- [ ] 创建项目目录结构
- [ ] 初始化Next.js前端项目
- [ ] 初始化Express后端项目
- [ ] 配置Tailwind CSS

### Day 2: 后端开发
- [ ] 设计数据模型和模拟数据
- [ ] 实现新闻列表API (分页/筛选)
- [ ] 实现频道分类API
- [ ] 测试API功能

### Day 3: 前端开发
- [ ] 创建Apple风格布局组件
- [ ] 实现新闻列表页面
- [ ] 实现分页组件
- [ ] 实现频道筛选功能

### Day 4: 集成与优化
- [ ] 前后端联调
- [ ] 响应式设计适配
- [ ] 动画效果添加
- [ ] 性能优化

### Day 5: 测试上线
- [ ] 全功能测试
- [ ] 浏览器兼容性测试
- [ ] 部署准备
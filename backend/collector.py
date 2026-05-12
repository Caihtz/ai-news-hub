"""
AI新闻数据采集器
基于RSS订阅源 + 正文补抓 + 评分算法
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
    """修复UTF-8编码错误，使用GBK重新解码"""
    if not isinstance(s, str):
        return s
    # Only fix if string contains replacement characters (indicating decode failure)
    if '�' not in s:
        return s
    try:
        return s.encode('utf-8', errors='replace').decode('gbk')
    except Exception:
        return s

def fix_bytes(b):
    """修复被UTF-8错误解读的字节串"""
    if isinstance(b, bytes):
        try:
            return b.decode('gbk')
        except Exception:
            return b.decode('utf-8', errors='replace')
    return fix_encoding(b)

# ==================== 配置 ====================

# AI新闻订阅源
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

# 摄影/器材/消费电子订阅源
PHOTO_RSS_SOURCES = [
    # 摄影媒体
    {"name": "PetaPixel", "url": "https://petapixel.com/feed", "type": "media", "lang": "en", "weight": 0.85, "category": "摄影"},
    {"name": "The Verge", "url": "https://www.theverge.com/rss/index.xml", "type": "media", "lang": "en", "weight": 0.75, "category": "消费电子"},
    {"name": "Engadget", "url": "https://www.engadget.com/rss.xml", "type": "media", "lang": "en", "weight": 0.75, "category": "消费电子"},
    {"name": "Imaging Resource", "url": "https://imaging-resource.com/review/feed", "type": "media", "lang": "en", "weight": 0.8, "category": "器材"},
    {"name": "DPReview", "url": "https://www.dpreview.com/feed", "type": "media", "lang": "en", "weight": 0.85, "category": "器材"},

    # 中文摄影媒体
    {"name": "色影无忌", "url": "https://www.xitek.com/rss.php", "type": "media", "lang": "zh", "weight": 0.8, "category": "摄影"},
    {"name": "蜂鸟网", "url": "https://www.fengniao.com/feed", "type": "media", "lang": "zh", "weight": 0.75, "category": "摄影"},
    {"name": "PChome数码", "url": "https://news.pchome.com.tw/rss/digital-camera.xml", "type": "media", "lang": "zh", "category": "器材"},
]

# 合并所有订阅源
RSS_SOURCES = AI_RSS_SOURCES + PHOTO_RSS_SOURCES

# ==================== 信息源信任等级配置 ====================

# 信任等级: high / medium / low / blocked
# 只有 high 和 medium 会被采集，low 会被降权，blocked 会直接过滤
SOURCE_TRUST_LEVELS = {
    # 最高信任 - 官方/学术机构
    "Google AI": "high",
    "Microsoft Research": "high",
    "DeepMind": "high",
    "Hugging Face": "high",
    "arXiv cs.AI": "high",
    "Meta AI": "high",

    # 高信任 - 知名媒体
    "TechCrunch AI": "high",
    "WIRED AI": "high",
    "PetaPixel": "high",
    "Imaging Resource": "high",
    "The Verge": "medium",
    "Engadget": "medium",
    "DPReview": "medium",

    # 中等信任 - 中文媒体
    "机器之心": "medium",
    "36氪AI": "low",  # 可能包含营销内容，降权处理

    # 被屏蔽的源 (示例)
    # "某些不可信网站": "blocked",
}

# 信任等级权重
TRUST_WEIGHTS = {
    "high": 1.0,
    "medium": 0.7,
    "low": 0.3,
    "blocked": 0.0,
}

# ==================== 反垃圾内容检测 ====================

# 点击诱饵标题词汇 (检测到会降低评分)
CLICKBAIT_PATTERNS = [
    # 中文点击诱饵
    "震惊", "刚刚", "突发", "重磅", "揭秘", "惊人", "真相", "曝光",
    "必看", "绝了", "炸裂", "爆款", "刷屏", "疯传", "引爆", "震撼",
    "万万没想到", "竟然", "居然", "99%的人", "不看后悔", "太神奇了",
    "央视曝光", "内部消息", "刚刚宣布", "重大突破", "全球首个",

    # 英文点击诱饵
    "you won't believe", "shocking", "unbelievable", "breaking",
    "exclusive", "leaked", "confidential", "this is why",
    "here's why", "what happened", "mind-blowing", "game-changing",
]

# 垃圾内容模式 (直接过滤)
SPAM_PATTERNS = [
    # 可能是垃圾/营销内容
    "点击此处", "立即购买", "限时优惠", "扫码关注", "粉丝福利",
    "免费领取", "恭喜获得", "广告推广", "赞助内容",
    "click here", "buy now", "limited time", "special offer",
    "subscribe now", "follow us", "free gift", "ad sponsored",
]

# 需要多源验证的话题 (这类新闻需要多个高信任源同时报道)
HIGH_STAKES_TOPICS = [
    "ai取代人类", "ai威胁", "重大突破", "颠覆性技术",
    "agi实现", "ai意识", "核弹级", "里程碑",
    "ai takes over", "ai threat", "major breakthrough", "agi achieved",
    "artificial general intelligence", "existential risk",
]

# ==================== 关键词配置 ====================

# AI相关关键词
AI_KEYWORDS = [
    "ai", "artificial intelligence", "machine learning", "deep learning",
    "llm", "gpt", "bert", "transformer", "neural network",
    "nlp", "natural language", "computer vision", "reinforcement learning",
    "生成式ai", "大模型", "人工智能", "深度学习", "机器学习",
    "语言模型", "神经网络", "自动驾驶", "机器人"
]

# 摄影/器材相关关键词
PHOTO_KEYWORDS = [
    "camera", "photography", "lens", "sensor", "dslr", "mirrorless",
    "sony", "canon", "nikon", "fujifilm", "leica", "hasselblad",
    "富士", "索尼", "佳能", "尼康", "相机", "镜头", "摄影",
    "sensor", "iso", "aperture", "shutter", "exposure",
    "camera body", "digital camera", "compact camera", "action camera",
    "drone", "gopro", " insta360", "stabilizer", "gimbal",
    "lightroom", "photoshop", "raw", "jpeg", "image quality",
    "评测", "测评", "样片", "实拍", "器材"
]


# ==================== 数据模型 ====================

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
    category: str = "AI"  # AI / 摄影 / 器材 / 消费电子
    score: float = 0.0
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())

    def to_dict(self):
        return asdict(self)


# ==================== 数据库 ====================

class Database:
    def __init__(self, db_path="news.db"):
        self.db_path = db_path
        self.init_db()

    def init_db(self):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()

        c.execute('''
            CREATE TABLE IF NOT EXISTS articles (
                id TEXT PRIMARY KEY,
                source TEXT NOT NULL,
                title TEXT NOT NULL,
                url TEXT UNIQUE NOT NULL,
                summary TEXT,
                content TEXT,
                author TEXT,
                published_at TEXT,
                language TEXT,
                tags TEXT,
                image_url TEXT,
                category TEXT DEFAULT 'AI',
                score REAL DEFAULT 0,
                created_at TEXT,
                content_hash TEXT
            )
        ''')

        c.execute('''
            CREATE TABLE IF NOT EXISTS sources (
                name TEXT PRIMARY KEY,
                url TEXT NOT NULL,
                type TEXT,
                lang TEXT,
                weight REAL,
                last_checked TEXT,
                last_success TEXT,
                error_count INTEGER DEFAULT 0
            )
        ''')

        c.execute('CREATE INDEX IF NOT EXISTS idx_published ON articles(published_at)')
        c.execute('CREATE INDEX IF NOT EXISTS idx_score ON articles(score)')
        c.execute('CREATE INDEX IF NOT EXISTS idx_source ON articles(source)')
        c.execute('CREATE INDEX IF NOT EXISTS idx_created ON articles(created_at)')

        conn.commit()
        conn.close()

    def cleanup_old_articles(self, days=7):
        """删除days天前的文章，默认7天"""
        from datetime import datetime, timedelta
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()

        c.execute('DELETE FROM articles WHERE created_at < ?', (cutoff_date,))
        deleted = c.rowcount

        conn.commit()
        conn.close()

        # 单独执行VACUUM需要重新连接
        if deleted > 0:
            conn2 = sqlite3.connect(self.db_path)
            conn2.execute('VACUUM')
            conn2.close()

        return deleted

    def upsert_article(self, article: Article) -> bool:
        """插入或更新文章，返回是否新插入"""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()

        content_hash = hashlib.md5(article.content.encode()).hexdigest() if article.content else ""

        try:
            c.execute('''
                INSERT INTO articles (id, source, title, url, summary, content, author, published_at, language, tags, image_url, category, score, created_at, content_hash)
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
            params.append(fix_encoding(channel) if isinstance(channel, str) else channel)

        if keyword:
            sql += " AND (title LIKE ? OR summary LIKE ?)"
            params.extend([f"%{keyword}%", f"%{keyword}%"])

        sql += " ORDER BY score DESC, published_at DESC"

        offset = (page - 1) * page_size
        sql += f" LIMIT {page_size} OFFSET {offset}"

        c.execute(sql, params)
        rows = c.fetchall()

        c.execute("SELECT COUNT(*) FROM articles WHERE 1=1" + (" AND source = ?" if channel != "all" else ""), params[:1] if channel != "all" else [])
        total = c.fetchone()[0]

        conn.close()

        columns = ["id", "source", "title", "url", "summary", "content", "author", "published_at", "language", "tags", "image_url", "category", "score", "created_at", "content_hash"]
        return [dict(zip(columns, row)) for row in rows], total

    def get_channels(self):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("SELECT source, COUNT(*) as count FROM articles GROUP BY source")
        rows = c.fetchall()
        conn.close()

        return [{"id": fix_encoding(r[0]), "name": fix_encoding(r[0]), "count": r[1]} for r in rows]


# ==================== 评分算法 ====================

class Scorer:
    def __init__(self):
        self.ai_keywords = AI_KEYWORDS
        self.photo_keywords = PHOTO_KEYWORDS

    def calculate(self, article: Article, source_config: dict) -> dict:
        """计算文章评分，返回详细评分报告"""
        category = source_config.get("category", "AI")
        source_name = source_config.get("name", "")

        # 时效性 (25%)
        freshness = self.calc_freshness(article.published_at)

        # 信任等级 (25%)
        trust_level = self.calc_trust_level(source_name)
        trust_score = TRUST_WEIGHTS.get(trust_level, 0.5)

        # 内容质量 (20%)
        content_quality = self.calc_content_quality(article.title, article.summary)

        # 相关性 (15%) - 根据分类使用不同关键词
        relevance = self.calc_relevance(article.title, article.summary, article.content, category)

        # 多源验证 (15%) - 高风险话题需要多源确认
        multi_source_bonus = self.calc_multi_source_bonus(article.title)

        # 最终评分
        final_score = round(
            0.25 * freshness +
            0.25 * trust_score +
            0.20 * content_quality +
            0.15 * relevance +
            0.15 * multi_source_bonus,
            4
        )

        return {
            "final_score": final_score,
            "freshness": freshness,
            "trust_level": trust_level,
            "trust_score": trust_score,
            "content_quality": content_quality,
            "relevance": relevance,
            "multi_source_bonus": multi_source_bonus,
            "is_spam": content_quality < 0.3,
            "needs_verification": trust_level in ["low", "medium"] and multi_source_bonus < 0.5
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

    def calc_trust_level(self, source_name: str) -> str:
        """获取信息源信任等级"""
        return SOURCE_TRUST_LEVELS.get(source_name, "medium")

    def calc_content_quality(self, title: str, summary: str) -> float:
        """
        计算内容质量评分
        - 检测点击诱饵
        - 检测垃圾模式
        - 评估内容长度
        """
        text = f"{title} {summary}".lower()
        score = 1.0

        # 检测点击诱饵词汇
        clickbait_count = sum(1 for pattern in CLICKBAIT_PATTERNS if pattern.lower() in text)
        if clickbait_count > 0:
            score -= min(0.4, clickbait_count * 0.15)

        # 检测垃圾模式
        spam_count = sum(1 for pattern in SPAM_PATTERNS if pattern.lower() in text)
        if spam_count > 0:
            score -= min(0.5, spam_count * 0.25)

        # 内容长度评估 (摘要太短可能是低质量)
        if len(summary) < 50:
            score -= 0.1
        elif len(summary) > 200:
            score += 0.05

        return max(0.0, min(1.0, score))

    def calc_authority(self, source_config: dict) -> float:
        return source_config.get("weight", 0.5)

    def calc_relevance(self, title: str, summary: str, content: str, category: str) -> float:
        keywords = self.ai_keywords if category == "AI" else self.photo_keywords
        text = f"{title} {summary} {content}".lower()
        matches = sum(1 for kw in keywords if kw.lower() in text)
        return min(1.0, matches / 5)

    def calc_multi_source_bonus(self, title: str) -> float:
        """
        高风险话题需要多源验证
        返回多源验证加分
        """
        text = title.lower()
        is_high_stakes = any(topic in text for topic in HIGH_STAKES_TOPICS)

        if is_high_stakes:
            # 高风险话题默认需要多源验证，这里返回中间值
            # 实际验证在采集时通过数据库查询完成
            return 0.5
        return 1.0  # 非高风险话题不需要额外验证


# ==================== 采集器 ====================

class Collector:
    def __init__(self, db_path="news.db", translator: BaseTranslator = None):
        self.db = Database(db_path)
        self.scorer = Scorer()
        self.translator = translator
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (compatible; AI-News-Aggregator/1.0)'
        })
        self.stats = {
            "total_fetched": 0,
            "blocked_source": 0,
            "spam_filtered": 0,
            "low_quality": 0,
            "needs_verification": 0,
            "duplicate": 0,
            "high_stakes_filtered": 0
        }

    def is_source_blocked(self, source_name: str) -> bool:
        """检查源是否被屏蔽"""
        level = SOURCE_TRUST_LEVELS.get(source_name, "medium")
        return level == "blocked"

    def is_duplicate(self, title: str, content_hash: str = "") -> bool:
        """检查是否为重复内容"""
        conn = sqlite3.connect(self.db.db_path)
        c = conn.cursor()

        # 检查相同标题
        c.execute('SELECT COUNT(*) FROM articles WHERE title = ?', (title,))
        title_exists = c.fetchone()[0] > 0

        # 检查内容哈希
        if content_hash:
            c.execute('SELECT COUNT(*) FROM articles WHERE content_hash = ?', (content_hash,))
            hash_exists = c.fetchone()[0] > 0
        else:
            hash_exists = False

        conn.close()
        return title_exists or hash_exists

    def check_multi_source_validation(self, title: str, source_name: str) -> bool:
        """
        检查高风险话题是否有多源验证
        返回True表示通过验证
        """
        conn = sqlite3.connect(self.db.db_path)
        c = conn.cursor()

        # 检查是否是高风险话题
        is_high_stakes = any(topic in title.lower() for topic in HIGH_STAKES_TOPICS)

        if not is_high_stakes:
            conn.close()
            return True

        # 高风险话题：检查是否有多个高信任源报道
        c.execute('SELECT DISTINCT source FROM articles WHERE title LIKE ?',
                 (f"%{title[:50]}%",))
        reporting_sources = [row[0] for row in c.fetchall()]

        # 计算高信任源数量
        high_trust_count = sum(1 for src in reporting_sources
                               if SOURCE_TRUST_LEVELS.get(src, "medium") == "high")

        conn.close()

        # 需要至少1个高信任源报道
        return high_trust_count >= 1

    def fetch_feed(self, source: dict) -> list:
        """抓取RSS feed"""
        source_name = source["name"]

        # 检查源是否被屏蔽
        if self.is_source_blocked(source_name):
            print(f"  跳过: {source_name} (信任等级: blocked)")
            self.stats["blocked_source"] += 1
            return []

        try:
            print(f"  抓取: {source_name}...")
            resp = self.session.get(source["url"], timeout=30)
            resp.raise_for_status()

            feed = feedparser.parse(resp.content)

            articles = []
            for entry in feed.entries[:20]:  # 每次最多取20条
                try:
                    # 提取正文摘要
                    summary = ""
                    if hasattr(entry, 'summary'):
                        summary = entry.summary[:500]
                    elif hasattr(entry, 'description'):
                        summary = entry.description[:500]

                    # 生成ID
                    entry_id = entry.get('id', entry.get('link', ''))
                    article_id = hashlib.md5(f"{source_name}:{entry_id}".encode()).hexdigest()

                    # 发布时间
                    published = ""
                    if hasattr(entry, 'published'):
                        published = entry.published
                    elif hasattr(entry, 'updated'):
                        published = entry.updated

                    title = entry.get('title', 'No Title')

                    article = Article(
                        id=article_id,
                        source=source_name,
                        title=title,
                        url=entry.get('link', ''),
                        summary=summary,
                        content="",  # 详情页补抓
                        author=entry.get('author', ''),
                        published_at=published,
                        language=source["lang"],
                        tags=[],
                        image_url=self.extract_image(entry),
                        category=source.get("category", "AI")
                    )

                    # 翻译标题和摘要（中文源跳过）
                    if self.translator and article.language != "zh":
                        article.title = translate(article.title, self.translator)
                        article.summary = translate(article.summary, self.translator)

                    # 计算评分
                    score_result = self.scorer.calculate(article, source)
                    article.score = score_result["final_score"]

                    self.stats["total_fetched"] += 1

                    # 过滤垃圾内容
                    if score_result["is_spam"]:
                        print(f"    过滤垃圾: {title[:40]}...")
                        self.stats["spam_filtered"] += 1
                        continue

                    # 检查重复
                    content_hash = hashlib.md5((title + summary).encode()).hexdigest()
                    if self.is_duplicate(title, content_hash):
                        self.stats["duplicate"] += 1
                        continue

                    # 高风险话题多源验证
                    if not self.check_multi_source_validation(title, source_name):
                        print(f"    高风险话题待验证: {title[:40]}...")
                        self.stats["high_stakes_filtered"] += 1
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

    def extract_image(self, entry) -> str:
        """从entry中提取图片URL"""
        # 尝试media_content
        if hasattr(entry, 'media_content'):
            for mc in entry.media_content:
                if 'url' in mc:
                    return mc['url']

        # 尝试 enclosures
        if hasattr(entry, 'enclosures'):
            for enc in entry.enclosures:
                if enc.get('type', '').startswith('image/'):
                    return enc.get('url', '')

        # 尝试从summary/description中提取img标签
        if hasattr(entry, 'summary'):
            import re
            img_match = re.search(r'<img[^>]+src="([^"]+)"', entry.summary)
            if img_match:
                return img_match.group(1)

        return ""

    def fetch_detail(self, article: Article) -> Article:
        """补抓详情页正文"""
        try:
            resp = self.session.get(article.url, timeout=30)
            resp.raise_for_status()

            tree = html.fromstring(resp.content)

            # 尝试提取article标签内容
            article_elem = tree.xpath("//article")
            if article_elem:
                article.content = article_elem[0].text_content()[:3000]

            # 尝试meta description
            if not article.content:
                desc = tree.xpath("//meta[@name='description']/@content")
                if desc:
                    article.content = desc[0]

        except Exception as e:
            print(f"    详情页抓取失败: {e}")

        return article

    def run(self):
        """运行采集"""
        print(f"\n{'='*50}")
        print(f"AI新闻采集器 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"{'='*50}\n")

        # 重置统计
        self.stats = {
            "total_fetched": 0,
            "blocked_source": 0,
            "spam_filtered": 0,
            "low_quality": 0,
            "needs_verification": 0,
            "duplicate": 0,
            "high_stakes_filtered": 0
        }

        # 采集前清理7天前的旧数据
        deleted = self.db.cleanup_old_articles(days=7)
        if deleted > 0:
            print(f"已清理 {deleted} 条过期数据(7天前)\n")

        total_new = 0

        for source in RSS_SOURCES:
            articles = self.fetch_feed(source)

            for article in articles:
                if self.db.upsert_article(article):
                    total_new += 1

        # 打印统计
        print(f"\n{'='*50}")
        print(f"采集统计:")
        print(f"  总抓取: {self.stats['total_fetched']} 条")
        print(f"  新增入库: {total_new} 条")
        if self.stats['spam_filtered'] > 0:
            print(f"  垃圾过滤: {self.stats['spam_filtered']} 条")
        if self.stats['duplicate'] > 0:
            print(f"  重复过滤: {self.stats['duplicate']} 条")
        if self.stats['high_stakes_filtered'] > 0:
            print(f"  高风险待验证: {self.stats['high_stakes_filtered']} 条")
        print(f"{'='*50}\n")

        return total_new


# ==================== API服务 ====================

from flask import Flask, jsonify, request

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

    # 序列化
    for a in articles:
        a['tags'] = json.loads(a['tags']) if a['tags'] else []
        for k, v in a.items():
            if isinstance(v, str):
                a[k] = fix_encoding(v)

    return jsonify({
        'success': True,
        'data': {
            'items': articles,
            'pagination': {
                'page': page,
                'pageSize': page_size,
                'total': total,
                'totalPages': total_pages
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
    """手动清理过期数据"""
    deleted = db.cleanup_old_articles(days=7)
    return jsonify({'success': True, 'message': f'已清理 {deleted} 条过期数据(7天前)'})


@app.route('/api/stats')
def get_stats():
    """获取数据库统计信息"""
    conn = sqlite3.connect('news.db')
    c = conn.cursor()
    c.execute('SELECT COUNT(*) FROM articles')
    total = c.fetchone()[0]
    c.execute('SELECT MIN(created_at), MAX(created_at) FROM articles')
    min_date, max_date = c.fetchone()
    conn.close()
    return jsonify({
        'success': True,
        'data': {
            'total': total,
            'oldest_record': min_date,
            'newest_record': max_date,
            'retention_days': 7
        }
    })


if __name__ == '__main__':
    import sys

    translator = create_translator()

    if len(sys.argv) > 1 and sys.argv[1] == 'collect':
        collector = Collector(translator=translator)
        collector.run()
    elif len(sys.argv) > 1 and sys.argv[1] == 'translate':
        # 批量翻译已有英文数据
        print("批量翻译已有数据...")
        count = 0
        conn = sqlite3.connect('news.db')
        cur = conn.cursor()
        cur.execute("SELECT id, title, summary, language FROM articles WHERE language != 'zh' OR language IS NULL")
        rows = cur.fetchall()
        print(f"  待翻译: {len(rows)} 条")
        for row in rows:
            aid, title, summary, lang = row
            new_title = translate(title, translator)
            new_summary = translate(summary, translator)
            if new_title != title or new_summary != summary:
                cur.execute("UPDATE articles SET title=?, summary=?, language='zh' WHERE id=?",
                           (new_title, new_summary, aid))
                count += 1
                if count % 10 == 0:
                    print(f"  已翻译: {count}/{len(rows)}")
        conn.commit()
        conn.close()
        print(f"  翻译完成: {count} 条")
    elif len(sys.argv) > 1 and sys.argv[1] == 'api':
        app.run(port=3001, debug=True)
    else:
        collector = Collector(translator=translator)
        collector.run()
        print("\n启动API服务...")
        app.run(port=3001, debug=True)
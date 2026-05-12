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
  // Handle tags as either array or JSON string
  const tags = Array.isArray(item.tags)
    ? item.tags
    : typeof item.tags === 'string'
    ? JSON.parse(item.tags || '[]')
    : [];

  return (
    <Link href={item.url} target="_blank" rel="noopener noreferrer">
      <article className="group bg-[#1d1d1f] rounded-3xl overflow-hidden border border-[#424245]/30 hover:border-[#424245] transition-all duration-500 hover:transform hover:scale-[1.01] hover:bg-[#252527]">
        {/* Image */}
        <div className="aspect-video overflow-hidden">
          <img
            src={item.image_url || 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800'}
            alt={item.title}
            className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
          />
        </div>

        {/* Content */}
        <div className="p-8">
          {/* Category & Score */}
          <div className="flex items-center justify-between mb-5">
            <span className="text-xs font-medium text-[#2997ff] bg-[#2997ff]/10 px-4 py-1.5 rounded-full">
              {getCategoryName(item.category) || getSourceName(item.source)}
            </span>
            <div className="flex items-center gap-1.5">
              <span className="text-xs text-[#86868b]">热度</span>
              <span className="text-sm font-semibold text-white">{item.score}</span>
            </div>
          </div>

          {/* Title */}
          <h2 className="text-xl font-semibold text-white mb-4 line-clamp-2 group-hover:text-[#2997ff] transition-colors duration-300 tracking-apple leading-snug">
            {item.title}
          </h2>

          {/* Summary - strip HTML tags */}
          <p
            className="text-sm text-[#86868b] mb-5 line-clamp-2 leading-relaxed"
            dangerouslySetInnerHTML={{ __html: item.summary.replace(/<[^>]*>/g, '').slice(0, 200) }}
          />

          {/* Footer */}
          <div className="flex items-center justify-between text-xs text-[#86868b] mb-5">
            <span className="flex items-center gap-1">
              <span>{getSourceName(item.source)}</span>
            </span>
            <time>{formatTime(item.published_at)}</time>
          </div>

          {/* Tags */}
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
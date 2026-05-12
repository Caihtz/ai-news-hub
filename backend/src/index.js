const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3001;
const DATA_PATH = path.join(__dirname, '../../data/news.json');

app.use(cors());
app.use(express.json());

// 获取新闻列表
app.get('/api/news', (req, res) => {
  try {
    const { page = 1, pageSize = 10, channel = 'all', keyword = '' } = req.query;
    const data = JSON.parse(fs.readFileSync(DATA_PATH, 'utf-8'));

    let filtered = data;

    // 频道筛选
    if (channel && channel !== 'all') {
      filtered = filtered.filter(item => item.channel === channel);
    }

    // 关键词搜索
    if (keyword) {
      const kw = keyword.toLowerCase();
      filtered = filtered.filter(item =>
        item.title.toLowerCase().includes(kw) ||
        item.summary.toLowerCase().includes(kw)
      );
    }

    // 分页
    const total = filtered.length;
    const start = (page - 1) * pageSize;
    const end = start + parseInt(pageSize);
    const items = filtered.slice(start, end);

    res.json({
      success: true,
      data: {
        items,
        pagination: {
          page: parseInt(page),
          pageSize: parseInt(pageSize),
          total,
          totalPages: Math.ceil(total / pageSize)
        }
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: '服务器错误' });
  }
});

// 获取频道分类
app.get('/api/channels', (req, res) => {
  try {
    const data = JSON.parse(fs.readFileSync(DATA_PATH, 'utf-8'));
    const channelMap = {};

    data.forEach(item => {
      if (!channelMap[item.channel]) {
        channelMap[item.channel] = { id: item.channel, name: item.channel, count: 0 };
      }
      channelMap[item.channel].count++;
    });

    const channels = Object.values(channelMap);
    res.json({ success: true, data: channels });
  } catch (error) {
    res.status(500).json({ success: false, message: '服务器错误' });
  }
});

// 获取单条新闻
app.get('/api/news/:id', (req, res) => {
  try {
    const { id } = req.params;
    const data = JSON.parse(fs.readFileSync(DATA_PATH, 'utf-8'));
    const item = data.find(item => item.id === id);

    if (!item) {
      return res.status(404).json({ success: false, message: '未找到' });
    }

    res.json({ success: true, data: item });
  } catch (error) {
    res.status(500).json({ success: false, message: '服务器错误' });
  }
});

app.listen(PORT, () => {
  console.log(`AI News Backend running at http://localhost:${PORT}`);
});
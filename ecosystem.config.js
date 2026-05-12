// PM2 process manager configuration (Windows Server)
module.exports = {
  apps: [
    {
      name: 'ai-news-frontend',
      script: 'node_modules\\next\\dist\\bin\\next',
      args: 'start -p 3000',
      cwd: './frontend',
      env: {
        NODE_ENV: 'production',
      },
      instances: 1,
      autorestart: true,
      max_memory_restart: '500M',
    },
    {
      name: 'ai-news-backend',
      script: 'python',
      args: '-m waitress --host 127.0.0.1 --port 3001 collector:app',
      cwd: './backend',
      instances: 1,
      autorestart: true,
      max_memory_restart: '300M',
    },
  ],
};

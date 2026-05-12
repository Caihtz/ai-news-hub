/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        apple: {
          black: '#000000',
          gray: '#1d1d1f',
          tertiary: '#2d2d2f',
          light: '#f5f5f7',
          muted: '#86868b',
          blue: '#2997ff',
          border: '#424245',
        }
      },
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', 'SF Pro Display', 'sans-serif'],
      },
      letterSpacing: {
        apple: '-0.022em',
      },
      transitionTimingFunction: {
        apple: 'cubic-bezier(0.25, 0.1, 0.25, 1)',
      }
    },
  },
  plugins: [],
}
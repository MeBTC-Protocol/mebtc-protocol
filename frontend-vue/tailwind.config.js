/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        display: ['var(--ui-font-display)'],
        body: ['var(--ui-font-body)']
      }
    }
  },
  plugins: []
}

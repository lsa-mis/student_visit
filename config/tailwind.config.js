const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        'um': {
          'blue': '#00274C',      // Example Michigan blue
          'maize': '#FFCB05',     // Example Michigan yellow/maize
          'neutral': '#989C97'    // Example neutral color
        },
        // You can add more custom colors:
        'lsa': {
          'primary': '#2F65A7',
          'secondary': '#333333',
          // Add more as needed
        }
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}

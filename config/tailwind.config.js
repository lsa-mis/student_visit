export default {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/components/**/*.{erb,haml,html,slim,rb}',
    './config/initializers/**/*.rb'
  ],
  plugins: [],
  // Safelist for dynamic classes that might be generated at runtime
  // Example: ['bg-red-500', 'text-blue-600'] if you have dynamic color classes
  safelist: [
    // Add any dynamic classes here if needed (e.g., from user input or JS)
    // Format: ['class-name', { pattern: /bg-(red|green|blue)-(100|200|300)/ }]
  ],
}

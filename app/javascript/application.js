// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

// Destroy questionnaire Chart.js instances before Turbo navigates away to prevent memory leaks
document.addEventListener("turbo:before-render", function () {
  if (window.questionnaireCharts && Array.isArray(window.questionnaireCharts)) {
    window.questionnaireCharts.forEach(function (chart) {
      try {
        if (chart && typeof chart.destroy === "function") chart.destroy();
      } catch (e) {
        console.warn("Questionnaire chart destroy:", e);
      }
    });
    window.questionnaireCharts = [];
  }
  delete window.initQuestionnaireCharts;
});

// Initialize questionnaire charts on pages that define initQuestionnaireCharts
function runInitQuestionnaireCharts() {
  if (typeof window.initQuestionnaireCharts === "function") {
    window.initQuestionnaireCharts();
  }
}

// DOMContentLoaded: for initial load/hard refresh when module runs in time
document.addEventListener("DOMContentLoaded", runInitQuestionnaireCharts);

// If the module ran after DOMContentLoaded (e.g. late ES module load), run immediately
if (document.readyState !== "loading") {
  runInitQuestionnaireCharts();
}

// turbo:load: for Turbo visits and when Turbo handles initial load
document.addEventListener("turbo:load", runInitQuestionnaireCharts);

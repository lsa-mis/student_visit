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
});

// Initialize questionnaire charts on pages that define initQuestionnaireCharts
document.addEventListener("DOMContentLoaded", function () {
  if (typeof window.initQuestionnaireCharts === "function") {
    window.initQuestionnaireCharts();
  }
});

document.addEventListener("turbo:load", function () {
  if (typeof window.initQuestionnaireCharts === "function") {
    window.initQuestionnaireCharts();
  }
});

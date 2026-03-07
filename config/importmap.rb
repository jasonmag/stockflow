# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@zxing/browser", to: "https://cdn.jsdelivr.net/npm/@zxing/browser@0.1.5/+esm"
pin_all_from "app/javascript/controllers", under: "controllers"

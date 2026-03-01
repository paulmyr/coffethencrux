(function () {
  var panel = document.getElementById("shelf-detail-panel");
  if (!panel) return;

  var activeItem = null;

  function getRowEnd(item) {
    var grid = item.closest(".shelf-grid");
    var items = Array.from(grid.querySelectorAll(".shelf-item"));
    var top = item.offsetTop;

    // Find the last item in this row (same offsetTop)
    var lastInRow = item;
    for (var i = items.indexOf(item) + 1; i < items.length; i++) {
      if (items[i].offsetTop === top) {
        lastInRow = items[i];
      } else {
        break;
      }
    }
    return lastInRow;
  }

  function stars(n) {
    var filled = "\u2605";
    var empty = "\u2606";
    var out = "";
    for (var i = 0; i < 5; i++) {
      out += i < n ? filled : empty;
    }
    return out;
  }

  function closePanel() {
    panel.classList.remove("shelf-detail-panel--open");
    if (activeItem) {
      activeItem.classList.remove("shelf-item--active");
      activeItem = null;
    }
  }

  function openPanel(item) {
    var d = item.dataset;
    var rowEnd = getRowEnd(item);

    // Set content
    panel.querySelector(".shelf-detail-title").textContent = d.title || "";
    panel.querySelector(".shelf-detail-creator").textContent = d.creator || "";
    panel.querySelector(".shelf-detail-rating").textContent = d.rating
      ? stars(parseInt(d.rating, 10))
      : "";
    panel.querySelector(".shelf-detail-date").textContent = d.date || "";
    panel.querySelector(".shelf-detail-review").innerHTML = d.review || "";

    // Tags
    var tagsEl = panel.querySelector(".shelf-detail-tags");
    tagsEl.innerHTML = "";
    if (d.tags) {
      d.tags.split(",").forEach(function (tag) {
        var pill = document.createElement("span");
        pill.className = "tag-pill";
        pill.textContent = tag.trim();
        tagsEl.appendChild(pill);
      });
    }

    // Move panel after the last item in the row
    rowEnd.after(panel);

    // Mark active
    if (activeItem) activeItem.classList.remove("shelf-item--active");
    item.classList.add("shelf-item--active");
    activeItem = item;

    // Open with slight delay to trigger transition
    requestAnimationFrame(function () {
      panel.classList.add("shelf-detail-panel--open");
    });
  }

  // Delegate clicks on shelf items
  document.addEventListener("click", function (e) {
    var item = e.target.closest(".shelf-item");
    if (item) {
      if (item === activeItem) {
        closePanel();
      } else {
        openPanel(item);
      }
      return;
    }

    // Close button
    if (e.target.closest(".shelf-detail-close")) {
      closePanel();
      return;
    }
  });

  // Escape to close
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && activeItem) {
      closePanel();
    }
  });
})();

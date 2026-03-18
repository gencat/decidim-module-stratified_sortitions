document.addEventListener("DOMContentLoaded", () => {
  const tabContainer = document.querySelector("[data-results-tabs]");
  if (!tabContainer) return;

  const tabs = tabContainer.querySelectorAll("[data-tab-target]");
  const panels = document.querySelectorAll("[data-tab-panel]");

  function activateTab(targetId) {
    tabs.forEach((t) => t.classList.remove("active"));
    panels.forEach((p) => (p.style.display = "none"));

    const tab = tabContainer.querySelector(`[data-tab-target="${targetId}"]`);
    if (tab) tab.classList.add("active");

    const targetPanel = document.getElementById(targetId);
    if (targetPanel) targetPanel.style.display = "";
  }

  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      const targetId = tab.dataset.tabTarget;

      // If the tab opens a confirmation modal, don't switch yet
      if (tab.dataset.dialogOpen) return;

      activateTab(targetId);
    });
  });

  // When the user confirms in the participants modal, switch to that tab
  const confirmBtn = document.getElementById("confirm-show-participants");
  if (confirmBtn) {
    confirmBtn.addEventListener("click", () => {
      activateTab("participants-section");

      // Log the view_participants action
      const logUrl = confirmBtn.dataset.logUrl;
      const csrfToken = confirmBtn.dataset.authenticityToken;
      if (logUrl && csrfToken) {
        fetch(logUrl, {
          method: "POST",
          headers: {
            "X-CSRF-Token": csrfToken,
            "Content-Type": "application/json",
          },
        }).catch(() => {
          // Silently ignore log errors
        });
      }

      // Close the modal
      const modal = document.getElementById("confirm-participants-modal");
      if (modal) {
        const closeBtn = modal.querySelector("[data-dialog-close]");
        if (closeBtn) closeBtn.click();
      }
    });
  }
});

document.addEventListener("DOMContentLoaded", () => {
  const form = document.getElementById("sample-upload-form");
  if (!form) return;

  const modal = form.querySelector("[data-dialog]");
  if (!modal) return;

  const saveButton = modal.querySelector("[data-dropzone-save]");
  if (!saveButton) return;

  saveButton.addEventListener("click", () => {
    // Allow Decidim's upload_field.js handler to run first (updateActiveUploads),
    // then submit the form.
    setTimeout(() => form.submit(), 100);
  });
});

document.addEventListener('DOMContentLoaded', () => {
  const fileInput = document.getElementById('sample-file-input');
  const submitButton = document.getElementById('sample-submit-button');

  if (!fileInput || !submitButton) return;

  const toggle = () => {
    const hasFile = fileInput.files && fileInput.files.length > 0;
    submitButton.disabled = !hasFile;
  };

  toggle();
  fileInput.addEventListener('change', toggle);
});

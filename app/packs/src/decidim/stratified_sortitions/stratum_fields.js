import AutoButtonsByPositionComponent from "src/decidim/admin/auto_buttons_by_position.component"
import AutoLabelByPositionComponent from "src/decidim/admin/auto_label_by_position.component"
import createSortList from "src/decidim/admin/sort_list.component"
import { initializeSubstrataWrapper } from "src/decidim/stratified_sortitions/substratum_fields"

$(() => {
  const wrapperSelector = ".stratified-sortition-strata";
  const fieldSelector = ".stratified-sortition-stratum";

  const autoLabelByPosition = new AutoLabelByPositionComponent({
    listSelector: ".stratified-sortition-stratum:not(.hidden)",
    labelSelector: ".card-title span:first",
    onPositionComputed: (el, idx) => {
      $(el).find("input[name$=\\[position\\]]").val(idx);
    }
  });

  const autoButtonsByPosition = new AutoButtonsByPositionComponent({
    listSelector: ".stratified-sortition-stratum:not(.hidden)",
    hideOnFirstSelector: ".move-up-stratum",
    hideOnLastSelector: ".move-down-stratum"
  });

  const createSortableList = () => {
    createSortList(".stratified-sortition-strata-list:not(.published)", {
      handle: ".stratum-divider",
      placeholder: '<div style="border-style: dashed; border-color: #000"></div>',
      forcePlaceholderSize: true,
      onSortUpdate: () => { autoLabelByPosition.run() }
    });
  };

  const hideDeletedStratum = ($target) => {
    const inputDeleted = $target.find("input[name$=\\[deleted\\]]").val();

    if (inputDeleted === "true") {
      $target.addClass("hidden");
      $target.hide();
    }
  };

  const runComponents = () => {
    autoLabelByPosition.run();
    autoButtonsByPosition.run();
  };

  $(document).on("click", ".add-stratum", function(e) {
    e.preventDefault();
    e.stopPropagation();
    
    const $button = $(this);
    const $wrapper = $button.closest(wrapperSelector);
    const $container = $(".stratified-sortition-strata-list");
    const $template = $wrapper.find("script.decidim-template");
    
    if ($template.length && $container.length) {
      const templateContent = $template.html();
      const uniqueId = new Date().getTime();
      let newField = templateContent.replace(/STRATUM_ID/g, uniqueId);
      newField = newField.replace(/substrata-\d+/g, `substrata-${uniqueId}`);
      $container.append(newField);
      
      const $newField = $container.find(fieldSelector).last();
      $newField.find(".stratified-sortition-substrata").each((idx, wrapperEl) => {
        if (!wrapperEl.id) {
          wrapperEl.id = `substrata-${uniqueId}`;
        }
        initializeSubstrataWrapper(wrapperEl);
      });

      createSortableList();
      runComponents();
    }
  });

  $(document).on("click", ".remove-stratum", function(e) {
    e.preventDefault();
    e.stopPropagation();
    
    const $field = $(this).closest(fieldSelector);
    
    $field.find("input[name$=\\[deleted\\]]").val("true");
    $field.addClass("hidden");
    $field.hide();
    
    runComponents();
  });

  $(document).on("click", ".move-up-stratum", function(e) {
    e.preventDefault();
    e.stopPropagation();
    
    const $field = $(this).closest(fieldSelector);
    const $prev = $field.prevAll(fieldSelector + ":not(.hidden)").first();
    
    if ($prev.length) {
      $field.insertBefore($prev);
      runComponents();
    }
  });

  $(document).on("click", ".move-down-stratum", function(e) {
    e.preventDefault();
    e.stopPropagation();
    
    const $field = $(this).closest(fieldSelector);
    const $next = $field.nextAll(fieldSelector + ":not(.hidden)").first();
    
    if ($next.length) {
      $field.insertAfter($next);
      runComponents();
    }
  });

  createSortableList();

  $(fieldSelector).each((idx, el) => {
    const $target = $(el);
    hideDeletedStratum($target);
  });

  runComponents();
})

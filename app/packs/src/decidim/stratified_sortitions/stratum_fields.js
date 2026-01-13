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
      let newField = templateContent.replace(/(?<!SUB)STRATUM_ID/g, uniqueId);
      newField = newField.replace(/substrata-\d+/g, `substrata-${uniqueId}`);
      $container.append(newField);
      
      const $newField = $container.find(fieldSelector).last();
      $newField.find(".stratified-sortition-substrata").each((idx, wrapperEl) => {
        if (!wrapperEl.id) {
          wrapperEl.id = `substrata-${uniqueId}`;
        }
        initializeSubstrataWrapper(wrapperEl);
      });

      $newField.find('[data-tabs]').each(function() {
        new Foundation.Tabs($(this));
      });

      updateSubstratumFieldsVisibility($newField);

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

  const updateSubstratumFieldsVisibility = ($stratum) => {
    const kind = $stratum.find("select[id$='_kind']").val();
    if (kind === "value") {
      $stratum.find(".substratum-value-field").show();
      $stratum.find(".substratum-range-field").hide();
    } else {
      $stratum.find(".substratum-value-field").hide();
      $stratum.find(".substratum-range-field").show();
    }
  };

  $(document).on("change", "select[id$='_kind']", function() {
    const $stratum = $(this).closest(fieldSelector);
    updateSubstratumFieldsVisibility($stratum);
  });

  const makeRequiredCatalanFields = () => {
    $(fieldSelector).find(".stratum-fields input[id$='_name_ca']").attr("required", true);
  };

  $("form").on("submit", function(e) {
    let hasEmptyName = false;
    let $firstInvalidStratum = null;
    
    $(fieldSelector).each((idx, el) => {
      const $stratum = $(el);
      const isDeleted = $stratum.find("input[name$='[deleted]']").val() === "true";
      const $nameField = $stratum.find(".stratum-fields input[id$='_name_ca']");

      $nameField.removeClass("is-invalid-input");
      
      if (!isDeleted) {
        const nameValue = $nameField.val();
        if (!nameValue || nameValue.trim() === "") {
          hasEmptyName = true;
          $nameField.addClass("is-invalid-input");

          if (!$firstInvalidStratum) {
            $firstInvalidStratum = $stratum;
          }
        }
      }
    });
    
    if (hasEmptyName) {
      e.preventDefault();
      if ($firstInvalidStratum) {
        $firstInvalidStratum[0].scrollIntoView({ behavior: "smooth", block: "center" });
      }
      return false;
    }
  });

  createSortableList();

  $(fieldSelector).each((idx, el) => {
    const $target = $(el);
    hideDeletedStratum($target);
    updateSubstratumFieldsVisibility($target);
  });

  makeRequiredCatalanFields();

  runComponents();
})

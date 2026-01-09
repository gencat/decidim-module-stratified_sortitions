import AutoButtonsByPositionComponent from "src/decidim/admin/auto_buttons_by_position.component"
import AutoLabelByPositionComponent from "src/decidim/admin/auto_label_by_position.component"
import createSortList from "src/decidim/admin/sort_list.component"
import createDynamicFields from "src/decidim/admin/dynamic_fields.component"

const fieldSelector = ".stratified-sortition-substratum";

const componentsByWrapper = new Map();

const hideDeletedSubstratum = ($target) => {
  const inputDeleted = $target.find("input[name$=\\[deleted\\]]").val();

  if (inputDeleted === "true") {
    $target.addClass("hidden");
    $target.hide();
  }
};

const getWrapperForElement = (element) => {
  return $(element).closest(".stratified-sortition-substrata")[0];
};

const runComponentsForWrapper = (wrapper) => {
  const components = componentsByWrapper.get(wrapper);
  if (components) {
    components.autoLabelByPosition.run();
    components.autoButtonsByPosition.run();
  }
};

export const initializeSubstrataWrapper = (wrapperEl) => {
  if (!wrapperEl) {
    return;
  }
  
  if (componentsByWrapper.has(wrapperEl)) {
    return;
  }

  const $wrapper = $(wrapperEl);
  let $container = $wrapper.find(".stratified-sortition-substrata-list");
  
  if ($container.length === 0) {
    $container = $('<div class="stratified-sortition-substrata-list"></div>');
    const $template = $wrapper.find("script.decidim-template");
    if ($template.length) {
      $template.after($container);
    } else {
      $wrapper.append($container);
    }
  }
  
  const autoLabelByPosition = new AutoLabelByPositionComponent({
    listSelector: `#${wrapperEl.id} .stratified-sortition-substratum:not(.hidden)`,
    labelSelector: ".card-title span:first",
    onPositionComputed: (el, idx) => {
      $(el).find("input[name$=\\[position\\]]").val(idx);
    }
  });

  const autoButtonsByPosition = new AutoButtonsByPositionComponent({
    listSelector: `#${wrapperEl.id} .stratified-sortition-substratum:not(.hidden)`,
    hideOnFirstSelector: ".move-up-substratum",
    hideOnLastSelector: ".move-down-substratum"
  });

  componentsByWrapper.set(wrapperEl, {
    autoLabelByPosition,
    autoButtonsByPosition
  });

  const createSortableList = () => {
    createSortList(`#${wrapperEl.id} .stratified-sortition-substrata-list:not(.published)`, {
      handle: ".substratum-divider",
      placeholder: '<div style="border-style: dashed; border-color: #000"></div>',
      forcePlaceholderSize: true,
      onSortUpdate: () => { autoLabelByPosition.run() }
    });
  };

  createSortableList();

  $container.find(fieldSelector).each((idx, el) => {
    const $target = $(el);
    hideDeletedSubstratum($target);
  });

  autoLabelByPosition.run();
  autoButtonsByPosition.run();
};

$(() => {
  $(".stratified-sortition-substrata").each((idx, wrapperEl) => {
    initializeSubstrataWrapper(wrapperEl);
  });

  $(document).on("click", ".add-substratum", function(e) {
    e.preventDefault();
    const wrapper = getWrapperForElement(this);
    const $wrapper = $(wrapper);
    const $container = wrapper.id ? $(`#${wrapper.id} .stratified-sortition-substrata-list`) : $wrapper.find(".stratified-sortition-substrata-list");
    const $template = $wrapper.find("script.decidim-template");
    
    if ($template.length && $container.length) {
      const templateContent = $template.html();
      const uniqueId = new Date().getTime();
      const newField = templateContent.replace(/SUBSTRATUM_ID/g, uniqueId);
      $container.append(newField);

      const $stratum = $wrapper.closest(".stratified-sortition-stratum");
      const kind = $stratum.find("select[id$='_kind']").val();
      const $newSubstratum = $container.find(fieldSelector).last();
      
      if (kind === "value") {
        $newSubstratum.find(".substratum-value-field").show();
        $newSubstratum.find(".substratum-range-field").hide();
      } else {
        $newSubstratum.find(".substratum-value-field").hide();
        $newSubstratum.find(".substratum-range-field").show();
      }
      
      runComponentsForWrapper(wrapper);
    }
  });

  $(document).on("click", ".stratified-sortition-substrata .remove-substratum", function(e) {
    e.preventDefault();
    const wrapper = getWrapperForElement(this);
    const $field = $(this).closest(fieldSelector);
    
    $field.find("input[name$=\\[deleted\\]]").val("true");
    $field.addClass("hidden");
    $field.hide();
    
    runComponentsForWrapper(wrapper);
  });

  $(document).on("click", ".stratified-sortition-substrata .move-up-substratum", function(e) {
    e.preventDefault();
    const wrapper = getWrapperForElement(this);
    const $field = $(this).closest(fieldSelector);
    const $prev = $field.prevAll(fieldSelector + ":not(.hidden)").first();
    
    if ($prev.length) {
      $field.insertBefore($prev);
      runComponentsForWrapper(wrapper);
    }
  });

  $(document).on("click", ".stratified-sortition-substrata .move-down-substratum", function(e) {
    e.preventDefault();
    const wrapper = getWrapperForElement(this);
    const $field = $(this).closest(fieldSelector);
    const $next = $field.nextAll(fieldSelector + ":not(.hidden)").first();
    
    if ($next.length) {
      $field.insertAfter($next);
      runComponentsForWrapper(wrapper);
    }
  });
})

import AutoButtonsByPositionComponent from "src/decidim/admin/auto_buttons_by_position.component"
import AutoLabelByPositionComponent from "src/decidim/admin/auto_label_by_position.component"
import createSortList from "src/decidim/admin/sort_list.component"
import createDynamicFields from "src/decidim/admin/dynamic_fields.component"

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

  createDynamicFields({
    placeholderId: "stratified-sortition-stratum-id",
    wrapperSelector: wrapperSelector,
    containerSelector: ".stratified-sortition-strata-list",
    fieldSelector: fieldSelector,
    addFieldButtonSelector: ".add-stratum",
    removeFieldButtonSelector: ".remove-stratum",
    moveUpFieldButtonSelector: ".move-up-stratum",
    moveDownFieldButtonSelector: ".move-down-stratum",
    onAddField: () => {
      createSortableList();

      autoLabelByPosition.run();
      autoButtonsByPosition.run();
    },
    onRemoveField: () => {
      autoLabelByPosition.run();
      autoButtonsByPosition.run();
    },
    onMoveUpField: () => {
      autoLabelByPosition.run();
      autoButtonsByPosition.run();
    },
    onMoveDownField: () => {
      autoLabelByPosition.run();
      autoButtonsByPosition.run();
    }
  });

  createSortableList();

  $(fieldSelector).each((idx, el) => {
    const $target = $(el);

    hideDeletedStratum($target);
  });

  autoLabelByPosition.run();
  autoButtonsByPosition.run();
})

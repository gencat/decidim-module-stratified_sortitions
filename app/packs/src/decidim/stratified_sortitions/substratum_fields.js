import AutoButtonsByPositionComponent from "src/decidim/admin/auto_buttons_by_position.component"
import AutoLabelByPositionComponent from "src/decidim/admin/auto_label_by_position.component"
import createSortList from "src/decidim/admin/sort_list.component"
import createDynamicFields from "src/decidim/admin/dynamic_fields.component"

$(() => {
  const wrapperSelector = ".stratified-sortition-substrata";
  const fieldSelector = ".stratified-sortition-substratum";

  const autoLabelByPosition = new AutoLabelByPositionComponent({
    listSelector: ".stratified-sortition-substratum:not(.hidden)",
    labelSelector: ".card-title span:first",
    onPositionComputed: (el, idx) => {
      $(el).find("input[name$=\\[position\\]]").val(idx);
    }
  });

  const autoButtonsByPosition = new AutoButtonsByPositionComponent({
    listSelector: ".stratified-sortition-substratum:not(.hidden)",
    hideOnFirstSelector: ".move-up-substratum",
    hideOnLastSelector: ".move-down-substratum"
  });

  const createSortableList = () => {
    createSortList(".stratified-sortition-substrata-list:not(.published)", {
      handle: ".substratum-divider",
      placeholder: '<div style="border-style: dashed; border-color: #000"></div>',
      forcePlaceholderSize: true,
      onSortUpdate: () => { autoLabelByPosition.run() }
    });
  };

  const hideDeletedSubstratum = ($target) => {
    const inputDeleted = $target.find("input[name$=\\[deleted\\]]").val();

    if (inputDeleted === "true") {
      $target.addClass("hidden");
      $target.hide();
    }
  };

  createDynamicFields({
    placeholderId: "stratified-sortition-substratum-id",
    wrapperSelector: wrapperSelector,
    containerSelector: ".stratified-sortition-substrata-list",
    fieldSelector: fieldSelector,
    addFieldButtonSelector: ".add-substratum",
    removeFieldButtonSelector: ".remove-substratum",
    moveUpFieldButtonSelector: ".move-up-substratum",
    moveDownFieldButtonSelector: ".move-down-substratum",
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

    hideDeletedSubstratum($target);
  });

  autoLabelByPosition.run();
  autoButtonsByPosition.run();
})

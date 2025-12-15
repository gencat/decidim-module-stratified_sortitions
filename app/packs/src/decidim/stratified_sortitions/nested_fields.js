import AutoButtonsByPositionComponent from "src/decidim/admin/auto_buttons_by_position.component"
import AutoLabelByPositionComponent from "src/decidim/admin/auto_label_by_position.component"
import createSortList from "src/decidim/admin/sort_list.component"
import createDynamicFields from "src/decidim/admin/dynamic_fields.component"

$(() => {
  const wrapperSelector = ".offer-tasks";
  const fieldSelector = ".offer-task";

  const autoLabelByPosition = new AutoLabelByPositionComponent({
    listSelector: ".offer-task:not(.hidden)",
    labelSelector: ".card-title span:first",
    onPositionComputed: (el, idx) => {
      $(el).find("input[name$=\\[position\\]]").val(idx);
    }
  });

  const autoButtonsByPosition = new AutoButtonsByPositionComponent({
    listSelector: ".offer-task:not(.hidden)",
    hideOnFirstSelector: ".move-up-task",
    hideOnLastSelector: ".move-down-task"
  });

  const createSortableList = () => {
    createSortList(".offer-tasks-list:not(.published)", {
      handle: ".task-divider",
      placeholder: '<div style="border-style: dashed; border-color: #000"></div>',
      forcePlaceholderSize: true,
      onSortUpdate: () => { autoLabelByPosition.run() }
    });
  };

  const hideDeletedTask = ($target) => {
    const inputDeleted = $target.find("input[name$=\\[deleted\\]]").val();

    if (inputDeleted === "true") {
      $target.addClass("hidden");
      $target.hide();
    }
  };

  createDynamicFields({
    placeholderId: "offer-task-id",
    wrapperSelector: wrapperSelector,
    containerSelector: ".offer-tasks-list",
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

    hideDeletedTask($target);
  });

  autoLabelByPosition.run();
  autoButtonsByPosition.run();
})

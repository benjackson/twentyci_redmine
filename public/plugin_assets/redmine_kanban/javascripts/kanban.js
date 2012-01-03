jQuery(function($) {
  $("#dialog-window").dialog({ position: [10,10], autoOpen: false, modal: true, minWidth: 400, width: 800 });

  receiveCrossListDrop = function(event, ui, list, options) {
    if (!options) { var options = {}; }

    // Popup when dragging out of Incoming
    if (ui.sender.attr('id').split('-')[0] == 'incoming') {
      var issue_id = ui.item.attr('id').split('_')[1];

      $('#dialog-window').
        dialog("option","buttons",
               {
                 "Cancel": function() {
                   $(ui.sender).sortable('cancel');
                   $(this).dialog("close");
                 },
                 "OK": function() {
                   options.issue_update = $('#issue-form').serialize();
                   updatePanes(ui.item,ui.sender,list, options);
                   $(this).dialog("close");
                 }
               });
      $('#dialog-window').
        html(''). // Gets cached
        load('kanban_issues/'+ issue_id + '/edit.js?from_pane=incoming').
        dialog('open');
    } else {
      updatePanes(ui.item,ui.sender,list, options);
    }
  },

  attachSortables = function() {
    // connectWith means that this item can be drug out of it's
    // sortable list and into an item in connectWith

    $("#incoming-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#backlog-issues',
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed',
        '.canceled-issues.allowed'
      ],
      placeholder: 'drop-accepted',
      dropOnEmpty: true
    });

    $("#backlog-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed',
        '.canceled-issues.allowed'
      ],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        receiveCrossListDrop(event, ui, $(this),
                             {
                               'additional_pane': '#quick-issues'
                             });
      }
    });

    $("#quick-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed',
        '.canceled-issues.allowed'
      ],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        receiveCrossListDrop(event, ui, $(this));
      }
    });

    $("#selected-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#backlog-issues',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed',
        '.canceled-issues.allowed'
      ],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        receiveCrossListDrop(event, ui, $(this));
      },
      update: function (event, ui) {
        // Allow drag and drop inside the list
        if (ui.sender == null && event.target == this) {
          updatePanes(ui.item,ui.sender,$(this), {});
        }
      }
    });

    $(".active-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#backlog-issues',
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed',
        '.canceled-issues.allowed'
      ],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        receiveCrossListDrop(event, ui, $(this));
      },
      update: function (event, ui) {
        // Allow drag and drop inside the list
        if (ui.sender == null && event.target == this) {
          updatePanes(ui.item,ui.sender,$(this), {});
        }
      }
    });


    $(".testing-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#backlog-issues',
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed',
        '.canceled-issues.allowed'
      ],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        receiveCrossListDrop(event, ui, $(this));
      },
      update: function (event, ui) {
        // Allow drag and drop inside the list
        if (ui.sender == null && event.target == this) {
          updatePanes(ui.item,ui.sender,$(this), {});
        }
      }
    });

    $(".finished-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed',
        '.canceled-issues.allowed'
      ],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        receiveCrossListDrop(event, ui, $(this));
      }
    });

    $(".canceled-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed',
        '.canceled-issues.allowed'
      ],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        receiveCrossListDrop(event, ui, $(this));
      }
    });

  },

  attachSortables();

  // * issue
  // * from
  // * to
  // * options
  //   *  additional_pane - (optional) the id selector for an additional 3rd
  //      pane to update
  updatePanes = function(issue, from, to, options) {
    var issue_id = issue.attr('id').split('_')[1];
    var to_pane = to.attr('id').split('-')[0];
    var to_order = to.sortable('serialize', {'key': 'to_issue[]'});

    if (from) {
      var from_pane = from.attr('id').split('-')[0];
      var from_order = from.sortable('serialize', {'key': 'from_issue[]'});
    } else {
      var from_pane = '';
      var from_order = [];
    }

    // Check for the optional additional pane
    if (options.additional_pane) {
      var additional_pane = options.additional_pane;
      var additional_pane_name = options.additional_pane.split('-')[0].replace('#','');
    } else {
      var additional_pane = '';
    }

    // Active panes needs to send which user was modified
    if (to_pane == 'active' || to_pane == 'testing' || to_pane == 'finished' || to_pane == 'canceled') {
      var to_user_id = to.attr('id').split('-')[3];
    } else {
      var to_user_id = null;
    }

    if (from_pane == 'active' || from_pane == 'testing' || from_pane == 'finished' || from_pane == 'canceled'){
      var from_user_id = from.attr('id').split('-')[3];
    } else {
      var from_user_id = null;
    }

    if (options.issue_update) {
      var issue_update = options.issue_update;
    } else {
      var issue_update = '';
    }

    // Only fire the Ajax requests if from_pane is set (cross list DnD) or
    // the new order has the tagert issue (same list DnD)
    if (from_pane.length > 0 || to_order.indexOf(issue_id) > 0) {

      $.ajaxQueue.put('kanban.js', {
        data: 'issue_id=' + issue_id + '&from=' + from_pane + '&to=' + to_pane + '&' + from_order + '&' + to_order + '&from_user_id=' + from_user_id + '&to_user_id=' + to_user_id + '&additional_pane=' + additional_pane_name + '&' + issue_update,
        success: function(response) {
          var partials = $.secureEvalJSON(response);
          $(from).parent().html(partials.from);
          $(to).parent().html(partials.to);

          if (additional_pane.length > 1) {
            $(additional_pane).parent().html(partials.additional_pane);
          }

          attachSortables();

        },
        error: function(response) {
          $("div.error").html("Error saving lists.  Please refresh the page and try again.").show();
        }
      });
    }
  };
});


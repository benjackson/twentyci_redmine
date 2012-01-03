(function($) {
  Kanban = {
    watched_issue: false,

    registerAjaxIndicator: function() {
      $("#ajax-indicator").ajaxStart(function(){ $(this).show();  });
      $("#ajax-indicator").ajaxStop(function(){ $(this).hide();  });

    },

    // Register callbacks for the New Issue popup form
    registerNewIssueCallbacks: function() {
      $('#issue_project_id').change(function() {
        $('#dialog-window').load('/kanban_issues/new.js', $('#issue-form').serialize())
      });

      $('#issue_tracker_id').change(function() {
        $('#dialog-window').load('/kanban_issues/new.js', $('#issue-form').serialize())
      });

      $('#issue-form').submit(function() {
        $(this).ajaxSubmit({
          dataType: 'xml', // TODO: json format would prompt for a file download in the iframe
          success: function(responseText, statusText, xhr, $form) {
            $('.flash.notice').html(i18n.kanban_text_issue_created_reload_to_see).show();
            $('#dialog-window').dialog("close");
          },
          error: function(response) {
            $('#issue-form-errors').html(i18n.kanban_text_error_saving_issue).show();
          }
        });

        return false;
      });
    },

    // Register callbacks for the Issue Show popup
    registerIssueShowCallbacks: function() {
      $('#issue-form').submit(function() {
        $(this).ajaxSubmit({
          url: this.action.replace('kanban_issues','issues'), // Change relative form endpoint
          dataType: 'xml', // TODO: json format would prompt for a file download in the iframe
          success: function(responseText, statusText, xhr, $form) {
            $('.flash.notice').html(i18n.kanban_text_issue_updated_reload_to_see).show();
            $('#dialog-window').dialog("close");
          },
          error: function(response) {
            $('#issue-form-errors').html(i18n.kanban_text_error_saving_issue).show();
          }
        });

        return false;
      });

    },

    // Registers the Issue Show popup form on all elements with the issue-show-popup
    // class.
    //
    // The css class attribute should have a value of 'issue-###'
    registerIssuePopup: function() {
      $('.issue-show-popup').
        not('.issue-show-popup-registered').
        click(function() {

        issueId = '';
        $.each($(this).attr('class').split(' '), function(index, cssClass) {
          if (cssClass.match('issue-id-')) {
            issueId = cssClass.replace('issue-id-','')
          }
        });

        $('#dialog-window').
          html('').
          load('/kanban_issues/' + issueId + '.js').
          dialog("option", "width", $('#content').width()). // Set width to the content width
          dialog('open');

        return false;
      }).addClass('issue-show-popup-registered');

    },

    // Take over the click events on the watch links used by redmine_recent_issues
    takeOverWatchLinks: function(jquerySelector) {
      $(jquerySelector).find('a.icon-fav-off').click(function() {
        this.watched_issue = true;
        $('#watch_and_cancel').html(i18n.kanban_text_watch_and_cancel_hint).show();
      });
    },

    registerUserSwitch: function() {
      $('#user_id').change(function() {
        $('form#user_switch').submit();
      });
    },

    // Load remote data from the server into the domId element
    remoteData: function(url, domId) {
      $('#' + domId).load(url, function() {
        Kanban.registerIssuePopup();
        // Remove temporary 'loading' styling
        $(this).removeClass('pane').removeClass('equal-column').width('100%'); 
      });
    },

    initilize: function() {
      $(function($) {
        Kanban.initilize_after_dom_loaded();
      });
      $.noConflict();
    },

    initilize_after_dom_loaded: function() {
      this.registerAjaxIndicator();
      this.registerIssuePopup();
    }
    
  };

  Kanban.initilize();

})(jQuery)

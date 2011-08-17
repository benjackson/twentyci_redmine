require 'test_helper'

class KanbanBoardTest < ActionController::IntegrationTest
  def setup
    configure_plugin
    setup_kanban_issues
    setup_all_issues

    @public_project = Project.generate!(:is_public => true)
    @project = @public_project
    @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
    @role = Role.generate!(:permissions => [:view_issues, :view_kanban, :edit_kanban])
    @member = Member.generate!({:principal => @user, :project => @public_project, :roles => [@role]})
  end

  context "viewing the board" do
    should "show a bubble icon on issues where the last journal was not made by the assigned user" do

      active_status = IssueStatus.find_by_name('Active')
      issue_with_note = Issue.find(:first, :conditions => {:status_id => active_status.id})
      issue_with_note_by_assigned = Issue.find(:last, :conditions => {:status_id => active_status.id})
      assert issue_with_note != issue_with_note_by_assigned

      issue_with_note.init_journal(User.generate, 'an update that triggers the bubble')
      assert issue_with_note.save
      issue_with_note_by_assigned.init_journal(issue_with_note_by_assigned.assigned_to, 'an update by assigned to')
      assert issue_with_note_by_assigned.save
      # Another journal but with no notes, should not trigger the bubble
      issue_with_note_by_assigned.reload
      issue_with_note_by_assigned.init_journal(issue_with_note_by_assigned.author, "")
      assert issue_with_note_by_assigned.save
      
      login_as
      get "/kanban"
      
      assert_response :success

      assert_select "#issue_#{issue_with_note_by_assigned.id}"
      assert_select "#issue_#{issue_with_note_by_assigned.id} .updated-note", :count => 0
      assert_select "#issue_#{issue_with_note.id}"
      assert_select "#issue_#{issue_with_note.id} .updated-note", :count => 1
    end

    should "show the user help content using the text formatting" do
      login_as
      visit_kanban_board

      assert_select '.user-help' do
        assert_select 'strong', :text => 'This is user help'
      end
    end

    should_show_deadlines(:all) { visit_kanban_board }
  end

end

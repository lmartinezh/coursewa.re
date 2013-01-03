module Coursewareable
  # Grades controller
  class GradesController < ApplicationController
    # Abilities checking for our nested resource
    load_and_authorize_resource :class => Coursewareable::Assignment
    skip_authorize_resource :only => [:create, :new, :index]

    before_filter :load_classroom_assignment

    # List index screen
    def index
      @grade = @assignment.grades.build
      @grade.classroom = @classroom
      authorize!(:manage, @grade)

      @grades = @assignment.grades.reload
    end

    # Creation screen
    def new
      @grade = @assignment.grades.build(params[:grade])
      @grade.classroom = @classroom
      authorize!(:create, @grade)

      # TODO: localize Number, Percent, Letter
      @forms = @grade.class::ALLOWED_FORMS.map { |f| [_(f.capitalize), f] }
      @members = @classroom.members.map { |u|
        [u.name, u.id] unless u.id == @classroom.owner.id
      }.compact
    end

    # Handles creation
    def create
      @grade = @assignment.grades.build(params[:grade])
      @grade.classroom = @classroom
      @grade.user = current_user

      authorize!(:create, @grade)

      if @grade.save
        flash[:success] = _('Grade saved.')
        redirect_to edit_lecture_assignment_grade_path(
          params[:lecture_id], @assignment, @grade)
      else
        flash[:error] = _('There was an error, please try again.')
        redirect_to new_lecture_assignment_grade_path(
          params[:lecture_id], @assignment)
      end
    end

    # Editing screen
    def edit
      @grade = @assignment.grades.find(params[:id])
      @forms = @grade.class::ALLOWED_FORMS.map { |f| [_(f.capitalize), f] }
    end

    # Handles editing
    def update
      grade = @assignment.grades.find(params[:id])

      if grade.update_attributes(params[:grade].except(:receiver_id))
        flash[:success] = _('Grade saved.')
      else
        flash[:error] = _('There was an error, please try again.')
      end

      redirect_to edit_lecture_assignment_grade_path(
        params[:lecture_id], @assignment, grade)
    end

    # Handles deletion
    def destroy
      grade = @assignment.grades.find(params[:id])

      if grade.destroy
        flash[:success] = _('Grade removed.')
      end

      redirect_to lecture_assignment_grades_path(
        params[:lecture_id], @assignment)
    end

    protected

    # Loads current classroom and assignment
    def load_classroom_assignment
      @classroom = Coursewareable::Classroom.find_by_slug!(request.subdomain)
      @assignment = @classroom.assignments.find_by_slug!(params[:assignment_id])
    end
  end
end

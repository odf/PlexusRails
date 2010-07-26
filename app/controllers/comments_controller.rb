class CommentsController < ApplicationController
  before_authorization_filter :find_commentable
  before_authorization_filter :find_comment, :except => [:new, :create]

  permit :new, :create            do may_edit(@commentable) end
  permit :edit, :update, :destroy do may_edit(@comment)     end

  before_filter :only => [:create, :update] do
    if params[:result] == 'Cancel'
      flash[:notice] = "#{action_name.humanize} was cancelled."
      render :action => action_name
    end
  end

  private

  def find_commentable
    tmp = params.clone
    project = Project.where(:_id => tmp.delete(:project_id)).first

    ids = tmp.select { |k, v| k.ends_with? '_id' }
    if ids.length == 1
      key, val = ids[0]
      resource = key.sub(/_id$/, '')
      model = resource.classify.constantize
      @commentable = model && if project
                                project.send(resource.pluralize).find(val)
                              else
                                model.find(val)
                              end
    elsif project
      @commentable = project 
    else
      raise 'Missing or ambiguous commentable.'
    end
  end

  def find_comment
    @comment = @commentable.comments.find(params[:id])
  end

  public

  def new
    @comment = Comment.new(:commentable => @commentable,
                           :author => current_user)
  end
  
  def edit
  end
  
  def create
    @comment = @commentable.comments.build(params[:comment])
    if @comment.save
      flash[:notice] = 'Comment was successfully added.'
    else
      flash[:alert] = 'Could not create comment.'
    end
  end

  def update
    if @comment.update_attributes(params[:comment])
      flash[:notice] = 'Comment was successfully updated.'
    else
      flash[:alert] = 'Could not update comment.'
    end
  end

  def destroy
    @comment.destroy
    @comment = nil
    flash[:notice] = "Successfully deleted comment."
  end
end

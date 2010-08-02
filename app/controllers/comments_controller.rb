class CommentsController < ApplicationController
  before_authorization_filter :find_commentable

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
    find_resource :parent_as => 'commentable'
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

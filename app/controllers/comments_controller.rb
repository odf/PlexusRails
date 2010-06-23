class CommentsController < ApplicationController
  before_authorization_filter :find_resource, :except => [:new, :create]
  before_authorization_filter :find_commentable, :only => [:new, :create]

  permit :new, :create            do may_edit(@commentable) end
  permit :edit, :update, :destroy do may_edit(@comment)     end

  redirect_if_cancelled

  private

  def find_commentable
    @commentable = params[:type].classify.constantize.find(params[:id])
  end


  public

  def new
    @comment = Comment.new
  end
  
  def edit
  end
  
  def create
    if @commentable.comments.create(params[:comment])
      redirect_to @commentable, :notice => 'Comment was successfully added.'
    else
      render :action => :new, :alert => 'Could not create comment.'
    end
  end

  def update
    if @comment.update_attributes(params[:comment])
      redirect_to @commentable, :notice => 'Comment was successfully updated.'
    else
      render :action => :edit, :alert => 'Could not update comment.'
    end
  end

  def destroy
    @comment.destroy
    redirect_to @commentable, :notice => "Successfully deleted comment."
  end
end

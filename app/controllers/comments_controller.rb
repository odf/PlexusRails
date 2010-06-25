class CommentsController < ApplicationController
  before_authorization_filter :find_commentable
  before_authorization_filter :find_comment, :except => [:new, :create]

  permit :new, :create            do may_edit(@commentable) end
  permit :edit, :update, :destroy do may_edit(@comment)     end

  redirect_if_cancelled

  private

  def find_comment
    @comment = @commentable.comments.find(params[:id])
  end

  def find_commentable
    ids = params.select { |k, v| k.ends_with? '_id' }
    if ids.length == 1
      key, val = ids[0]
      model = key.sub(/_id$/, '').classify.constantize
      @commentable = model && model.find(val)
    else
      raise 'Missing or ambiguous commentable.'
    end
  end

  public

  def new
    @comment = Comment.new(:commentable => @commentable, :author => current_user)
  end
  
  def edit
  end
  
  def create
    @comment = @commentable.comments.build(params[:comment])
    if @commentable.save
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
    flash[:notice] = "Successfully deleted comment."
  end
end

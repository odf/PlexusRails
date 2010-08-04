class Image
  include Mongoid::Document
  include Timestamps

  field :filename,     :type => String
  field :content_type, :type => String
  field :size,         :type => Fixnum
  field :width,        :type => Fixnum
  field :height,       :type => Fixnum
  field :caption,      :type => String
  field :info,         :type => Hash

  embedded_in :illustratable, :inverse_of => :image

  after_create :write_data
  before_destroy :delete_file

  def allows?(action, user)
    commentable.allows?(action, user)
  end

  def content=(uploaded)
    self.filename = uploaded.original_filename
    @content = uploaded.read
  end

  def data
    read_file(stored_path)
  end

  private

  # TODO flesh these out

  def path_components
    [Rails.root, "assets", "images", stored_as]
  end

  def stored_path
    File.join(*path_components)
  end

  def write_data
    self.stored_as = "#{self.id}__#{self.name}"
    self.save!
    write_file(@content, *path_components)
  end

  def delete_file
    File.unlink stored_path if File.exist? stored_path
  end
end

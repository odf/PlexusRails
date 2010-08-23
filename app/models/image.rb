# The model to represent an image attachment.

class Image < ActiveRecord::Base

  # -- where to write files
  #TODO this needs to go into an initializer
  ASSET_PATH = File.join(Rails.root, "assets")

  # -- add timestamps and authors for creation and modification
  include Blame

  # --  simple persistent attributes
  # field :filename,     :type => String
  # field :stored_path,  :type => String
  # field :content_type, :type => String
  # field :size,         :type => Fixnum
  # field :width,        :type => Fixnum
  # field :height,       :type => Fixnum
  # field :caption,      :type => String
  # field :info,         :type => Hash

  # -- associations
  belongs_to :illustratable, :polymorphic => true

  # -- filename must be unique within illustratable
  validates :filename,
    :presence => true,
    :uniqueness => { :case_sensitive => false }

  # -- these handle the storage of the actual image files
  before_create :store_file
  before_destroy :delete_file

  # Pseudo-attribute for getting the uploaded data in.
  def uploaded_data=(uploaded)
    self.filename = uploaded.original_filename
    self.content_type = uploaded.content_type

    @content = uploaded.read
  end

  # Getting the data out.
  def data
    File.open(stored_path) { |fp| fp.read }
  end
  
  # This method returns the caption, if any, or else the filename.
  def nice_caption
    caption.blank? ? filename.sub(/\_[^_]*$/, '') : caption
  end

  # Permissions are as in the project this image belongs to.
  def allows?(action, user)
    illustratable.allows?(action, user)
  end

  # -- the methods for storing and deleting files are private
  private

  def make_path
    on = illustratable
    File.join([on.class.name.underscore.pluralize, on.id.to_s, 
               'images', filename])
  end

  def store_file
    raise "No directory #{ASSET_PATH}." unless File.directory?(ASSET_PATH)

    self.stored_path = make_path
    FileUtils.mkpath(File.dirname(stored_path))
    File.open(stored_path, "wb") { |fp| fp.write(@content) }
  end

  def delete_file
    File.unlink(stored_path) if File.exist?(stored_path)
  end
end

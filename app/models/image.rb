# The model to represent an image attachment.

class Image < ActiveRecord::Base
  # -- where to write files - TODO this needs to go into an initializer
  DATA_PATH = File.join(Rails.root, "data")

  # -- add timestamps and authors for creation and modification
  include Blame

  # t.string   "filename"
  # t.string   "stored_path"
  # t.string   "content_type"
  # t.integer  "size"
  # t.integer  "width"
  # t.integer  "height"
  # t.string   "caption"
  # t.text     "info"
  # t.datetime "created_at"
  # t.datetime "updated_at"

  # -- associations
  belongs_to :illustratable, :polymorphic => true

  # -- filename must be unique within illustratable
  validates :filename,
    :presence => true,
    :uniqueness => { :case_sensitive => false,
                     :scope => [:illustratable_id, :illustratable_type] }

  # -- scopes for selecting main images and thumbnails
  scope :main,      where("filename not like '!_!_%' escape '!'")
  scope :thumbnail, where("filename like '!_!_%' escape '!'")

  # -- these handle the storage of the actual image files
  before_create :store_file
  before_destroy :delete_file
  #TODO when deleting, also remove associated thumbnails

  # Pseudo-attribute for getting the uploaded data in.
  def uploaded_data=(uploaded)
    self.filename = uploaded.original_filename
    self.content_type = uploaded.content_type

    @content = uploaded.read
  end

  # Getting the data out.
  def data
    File.open(computed_path) { |fp| fp.read }
  end
  
  # This method returns the caption, if any, or else the filename.
  def nice_caption
    caption.blank? ? filename.sub(/\_[^_]*$/, '') : caption
  end

  # Permissions are as in the illustratable this image belongs to.
  def allows?(action, user)
    illustratable.allows?(action, user)
  end

  def thumbnail(width, height)
    name = "__#{width}x#{height}__#{filename}"
    illustratable.images.thumbnail.where(:filename => name).first
  end

  def computed_path
    make_path
  end

  # -- the methods for storing and deleting files are private
  private

  def make_path
    on = illustratable
    on_type = on.class.name.underscore.pluralize
    on_id = on.id_for_assets || on.id.to_s
    File.join([DATA_PATH, on_type,
               on_id[0..1], on_id[2..3], on_id, 'images', filename])
  end

  def store_file
    raise "No directory #{DATA_PATH}." unless File.directory?(DATA_PATH)

    if self.stored_path.blank?
      path = make_path
      FileUtils.mkpath(File.dirname(path))
      File.open(path, "wb") { |fp| fp.write(@content) }
      self.stored_path = path
    end
  end

  def delete_file
    File.unlink(stored_path) if File.exist?(stored_path)
  end
end

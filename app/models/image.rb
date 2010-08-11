# The model to represent an image attachment.

class Image
  # -- where to write files
  #TODO this needs to go into an initializer
  ASSET_PATH = File.join(Rails.root, "assets")

  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- add timestamps and authors for creation and modification
  include Timestamps

  # --  simple persistent attributes
  field :filename,     :type => String
  field :stored_path,  :type => String
  field :content_type, :type => String
  field :size,         :type => Fixnum
  field :width,        :type => Fixnum
  field :height,       :type => Fixnum
  field :caption,      :type => String
  field :info,         :type => Hash

  # -- use the filename as the document key
  key :filename

  # -- associations
  embedded_in :illustratable, :inverse_of => :images

  # -- filename must be unique within illustratable
  validates :filename, :presence => true, :strong_uniqueness => true

  # -- these handle the storage of the actual image files
  after_create :store_file
  before_destroy :delete_file

  # Pseudo-attribute for getting the uploaded data in.
  def uploaded_data=(uploaded)
    self.filename = uploaded.original_filename
    self.content_type = uploaded.content_type
    self.stored_path = make_path

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
  include Nesting

  def make_path
    File.join(nesting_for(illustratable).inject([ASSET_PATH]) { |list, obj|
                list + [obj.class.name.underscore.pluralize, obj._id]
              } + ['images', filename])
  end

  def store_file
    raise "No directory #{ASSET_PATH}." unless File.directory?(ASSET_PATH)

    FileUtils.mkpath(File.dirname(self.stored_path))
    File.open(stored_path, "wb") { |fp| fp.write(@content) }
  end

  def delete_file
    File.unlink(stored_path) if File.exist?(stored_path)
  end
end

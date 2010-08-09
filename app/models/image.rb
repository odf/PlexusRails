class Image
  include Mongoid::Document
  include Timestamps

  field :filename,     :type => String
  field :stored_path,  :type => String
  field :content_type, :type => String
  field :size,         :type => Fixnum
  field :width,        :type => Fixnum
  field :height,       :type => Fixnum
  field :caption,      :type => String
  field :info,         :type => Hash

  key :filename

  embedded_in :illustratable, :inverse_of => :images

  include Nesting

  ASSET_PATH = File.join(Rails.root, "assets")

  after_create :store_file
  before_destroy :delete_file

  def allows?(action, user)
    illustratable.allows?(action, user)
  end

  def content=(uploaded)
    self.filename = uploaded.original_filename
    components = nesting_for(illustratable).inject([ASSET_PATH]) do |list, obj|
      list + [obj.class.name.underscore.pluralize, obj._id]
    end + ['images', filename]
    self.stored_path = File.join(*components)

    @content = uploaded.read
  end

  def data
    File.open(stored_path) { |fp| fp.read }
  end

  private

  def store_file
    raise "No directory #{ASSET_PATH}." unless File.directory?(ASSET_PATH)

    FileUtils.mkpath(File.dirname(self.stored_path))
    File.open(stored_path, "wb") { |fp| fp.write(@content) }
  end

  def delete_file
    File.unlink(stored_path) if File.exist?(stored_path)
  end
end

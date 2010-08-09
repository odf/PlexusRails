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

  before_create :store_file
  before_destroy :delete_file

  def allows?(action, user)
    illustratable.allows?(action, user)
  end

  def content=(uploaded)
    self.filename = uploaded.original_filename
    @content = uploaded.read
  end

  def data
    read_file(stored_path)
  end

  private

  def store_file
    raise "No directory #{ASSET_PATH}." unless File.directory?(ASSET_PATH)

    components = nesting_for(illustratable).map(&:_id) + [filename]
    self.stored_path = File.join(ASSET_PATH, *components)
    FileUtils.mkpath(File.dirname(self.stored_path))
  end

  def delete_file
    File.unlink(stored_path) if File.exist?(stored_path)
  end
end

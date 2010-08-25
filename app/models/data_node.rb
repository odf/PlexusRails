# The model to represent a data node.

class DataNode < ActiveRecord::Base
  # -- simple persistent attributes
  # field :fingerprint,     :type => String
  # field :sample,          :type => String
  # field :name,            :type => String
  # field :data_type,       :type => String
  # field :identifier,      :type => String
  # field :messages,        :type => String
  # field :status,          :type => String
  # field :hidden,          :type => Boolean
  # field :filename,        :type => String
  # field :synchronized_at, :type => Time
  # field :producer_id,     :type => String

  # -- domain attributes
  # field :origin,     :type => Array
  # field :size,       :type => Array
  # field :voxel_size, :type => Array
  # field :voxel_unit, :type => String

  # -- associations
  belongs_to :project
  belongs_to :producer, :class_name => "ProcessNode"
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :images, :as => :illustratable, :dependent => :destroy

  # -- fingerprint must be unique within project
  validates :fingerprint,
    :presence => true,
    :uniqueness => { :case_sensitive => false }

  # -- some named scopes
  scope :visible,  where(:hidden => false)
  scope :resolved, where('status != ?', 'missing')
  scope :valid,    where(:status => 'valid')
  scope :missing,  where(:status => 'missing')
  scope :with_ids, lambda { |ids| where("id in (?)", ids.to_a) }

  # -- domain access
  [:domain_origin, :domain_size, :voxel_size].each do |attr|
    define_method attr do
      (read_attribute(attr) || '').split(' ').map(&:to_f)
    end

    define_method "#{attr}=" do |values|
      write_attribute(attr, (values || []).map(&:to_s).join(' '))
    end

    %w{x y z}.each_with_index do |axis_name, axis_index|
      define_method "#{attr}_#{axis_name}" do
        self.send(attr)[axis_index]
      end

      define_method "#{attr}_#{axis_name}=" do |value|
        tmp = self.send(attr)
        tmp[axis_index] = value
        self.send("#{attr}=", tmp)
      end
    end
  end

  def has_domain_info
    [:domain_origin, :domain_size, :voxel_size, :voxel_unit].any? do |attr|
      not read_attribute(attr).blank?
    end
  end

  # -- convenience methods
  def date
    producer && producer.date
  end

  def suffix
    (name || "").sub(/\A[a-z_]*/, '')
  end

  def last_suffix
    case suffix
    when /\A\d/, /_/
      suffix.scan(/[^_]+/)[-1]
    else
      suffix[0,2]
    end
  end

  def predecessors
    find_related project.graph.pred(self.id)
  end

  def successors
    find_related project.graph.succ(self.id)
  end

  def descendants
    find_related project.graph.reachable(self.id)
  end

  def ancestors
    adj = project.graph.method(:pred)
    find_related Persistent::Depth_First_Traversal.new([self.id], &adj)
  end

  def hideable?
    project.bottlenecks.include? self.id
  end

  def toggle_visibility
    value = self.hidden ? false : true
    descendants.each do |node|
      node.hidden = value
      node.save!
    end
  end

  # -- permissions are as in the project this data node belongs to
  def allows?(action, user)
    project.allows?(action, user)
  end

  private
  def find_related(ids)
    self.class.with_ids(ids)
  end
end

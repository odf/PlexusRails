# The model to represent a data domain.

class Domain
  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- simple persistent attributes
  field :origin,     :type => Array, :default => []
  field :size,       :type => Array, :default => []
  field :voxel_size, :type => Array, :default => []
  field :voxel_unit, :type => String

  # -- associations
  embedded_in :data_node, :inverse_of => :domain

  # -- pseudo-attributes for easier access
  %w{x y z}.each_with_index do |axis_name, axis_index|
    define_method "domain_origin_#{axis_name}" do
      origin[axis_index]
    end

    define_method "domain_origin_#{axis_name}=" do |value|
      origin[axis_index] = value
    end

    define_method "domain_size_#{axis_name}" do
      size[axis_index]
    end

    define_method "domain_size_#{axis_name}=" do |value|
      size[axis_index] = value
    end

    define_method "voxel_size_#{axis_name}" do
      voxel_size[axis_index]
    end

    define_method "voxel_size_#{axis_name}=" do |value|
      voxel_size[axis_index] = value
    end
  end
end

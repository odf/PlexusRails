# The model associated with an individual import action.
#
# Instances of this model have a dual role: each instance receives a
# JSON-encoded collection of data node descriptions and, via an
# 'after_create' hook, establishes the corresponding entries in the
# database. After the import is completed, the instance retains the
# original JSON-source and in addition stores a log of the actions
# taken and their outcome.

class Import
  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- make 'pluralize' and such available (for logging)
  include ActionView::Helpers::TextHelper

  # -- add timestamps with user ids
  include Timestamps

  # -- simple persistent attributes
  field :source_timestamp, :type => Time
  field :sample_name,      :type => String
  field :content,          :type => Hash
  field :source_log,       :type => String
  field :import_log,       :type => Hash
  field :description,      :type => String

  # -- associations
  referenced_in :user
  embedded_in :project, :inverse_of => :imports

  # -- before saving, perform the actions prescribed by this import
  before_save :run_this_import

  # -- pseudo-attributes for use with Rails-generated forms
  def data=(value)
    self.content = JSON::load(value.read)
  end

  def time=(value)
    time_args = ParseDate::parsedate(value) unless value.blank?
    self.source_timestamp = time_args ? Time.local(*time_args).utc : nil
  end

  def sample=(value)
    self.sample_name = value
  end

  # -- permissions are as in the project this import belongs to
  def allows?(action, user)
    project.allows?(action, user)
  end

  private

  # After-create hook to perform the import action prescribed by this
  # instance. This will typically create a number of data nodes and
  # the interconnections between them. A log of the performed actions
  # is saved to the database as a part of the table row associated
  # with this instance.
  def run_this_import
    if import_log.blank?
      self.import_log = { :status => 'Unsupported' }
    end
  end
end

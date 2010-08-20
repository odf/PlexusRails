class Project < ActiveRecord::Base
  # -- add timestamps with user ids
  include Timestamps

  # -- declaration of persistent fields
  #field :name, :type => String, :accessible => false
  #field :organization, :type => String

  # -- associations
  # embeds_many :memberships
  # embeds_many :comments
  # embeds_many :images
  # embeds_many :imports
  # embeds_many :data_nodes
  # embeds_many :process_nodes

  # -- whitespace in the project name is normalized to single spaces
  before_validation do |project|
    project.name = project.name.strip.gsub(/\s+/, ' ')
  end
  
  # -- make sure project names are unique (case-insensitive)
  validates :name, :presence => true, :strong_uniqueness => true

  # -- methods to inquire project memberships and user permissions
  def members
    memberships.sorted.map &:user
  end

  def role_of(user)
    (m = membership_of(user)) && m.role
  end

  def allows?(action, user)
    role = role_of(user)
    case action.to_sym
    when :view
      user and user.may_view and not role.nil?
    when :edit
      user and user.may_edit and %w{contributor manager}.include? role
    when :manage
      user and user.may_edit and (user.may_authorize or role == 'manager')
    when :upload
      user and user.may_upload
    else
      false
    end
  end

  # -- pseudo-attribute for editing memberships and roles
  def roles
    User.sorted.map do |user|
      membership_of(user) || Membership.new(:user => user, :role => '')
    end
  end

  def roles_attributes=(data)
    data.each { |key, value| set_role(User.find(value[:user_id]), value[:role]) }
  end

  # Assigns the given user the given role.
  def set_role(user, role)
    membership = membership_of(user)

    if membership
      if role.blank?
        membership.destroy
      else
        membership.update_attributes(:role => role)
      end
    elsif user and not role.blank?
      memberships.create(:user_id => user.id, :role => role)
    end
  end

  # -- methods pertaining to the data relationships graph

  def graph
    @graph ||= data_nodes.inject(Persistent::DAG.new) do |gr, v|
      inputs = v.producer ? v.producer.inputs : []
      gr.with_vertex(v.id) + inputs.map { |w| [w.id, v.id] }
    end
  end

  def bottlenecks
    @bottlenecks ||= graph.bottlenecks
  end

  def nodes_by_id
    @nodes ||= Persistent::HashMap.new +
      graph.vertices.map { |n| [n, data_nodes.find(n)] }
  end

  # The list of valid and rejected node ids, with each node listed
  # before its successors.
  def nodes_sorted
    node_dates = nodes_by_id.apply { |v| (v && v.date) || Time.at(0) }

    visit = proc do |state, v|
      if state.marked?(v)
        state
      else
        children = graph.succ(v).sort_by(&node_dates).reverse
        children.inject(state.with_mark(v), &visit).after(v)
      end
    end

    sources = graph.sources.sort_by(&node_dates).reverse
    sources.inject(Persistent::Accumulator.new, &visit)
  end
  
  # A list of node id/level pairs, selected and ordered as in
  # nodes_sorted, where the level of a node is one higher than the
  # maximum level of any of its predecessors.
  def nodes_with_levels
    level = nodes_sorted.inject(Persistent::HashMap.new) do |h, v|
      h.with(v, 1 + (graph.pred(v).map { |w| h[w] }.compact.max || -1))
    end

    nodes_sorted.map { |v| [v, level[v], bottlenecks.include?(v)] }
  end

  def stored_data()
    good_nodes = data_nodes.valid.reject do |node|
      node.filename.blank? and node.images.empty?
    end

    good_nodes.map do |node|
      sync_time = node.synchronized_at || Time.at(0)
      name = node.filename.blank? ? node.name : node.filename
      { "Name"       => name,
        "Identifier" => node.identifier,
        "IdInt"      => node.id,
        "IdExt"      => node.identifier,
        "Date"       => sync_time.getutc.strftime("%Y/%m/%d %H:%M:%S ") + 'UTC',
        "External"   => (not node.filename.blank?),
        "Images"     => node.images.map(&:filename)
      }
    end
  end

  def add_link(source, target)
    @graph = graph.with_edge(source.id, target.id)
    target.producer.add_input(source)
  end

  def destroy_node(v)
    @graph = graph.without_vertex(v.id)
    v.destroy
  end

  # -- private methods start here
  private

  def membership_of(user)
    user && memberships.where(:user_id => user.id).first
  end
end

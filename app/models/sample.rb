class Sample < ActiveRecord::Base
  include Blame

  # t.string   "name"
  # t.string   "external_id"
  # t.datetime "created_at"
  # t.datetime "updated_at"

  # -- associations
  belongs_to :project
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :images, :as => :illustratable, :dependent => :destroy
  has_many :data_nodes, :dependent => :destroy
  has_many :process_nodes, :dependent => :destroy
  has_many :imports, :dependent => :destroy

  # -- make sure sample names are unique (case-insensitive)
  validates :name, :presence => true, :uniqueness => { :scope => :project_id }

  # -- callbacks
  after_validation :generate_name

  # -- permissions are as in the project this sample belongs to
  def allows?(action, user)
    project.allows?(action, user)
  end

  # -- methods pertaining to the data relationships graph

  def data_nodes_by_id
    @nodes ||= Persistent::HashMap.new + data_nodes.map { |v| [v.id, v] }
  end

  def process_nodes_by_id
    @procs ||= Persistent::HashMap.new + process_nodes.map { |v| [v.id, v] }
  end

  def graph
    procs = process_nodes_by_id
    @graph ||= data_nodes_by_id.values.inject(Persistent::DAG.new) do |gr, v|
      input_ids = v.producer_id ? procs[v.producer_id].input_ids : []
      gr.with_vertex(v.id) + input_ids.map { |w_id| [w_id, v.id] }
    end
  end

  def bottlenecks
    @bottlenecks ||= graph.bottlenecks
  end

  # The list of valid and rejected node ids, with each node listed
  # before its successors.
  def nodes_sorted
    node_dates = data_nodes_by_id.apply { |v| (v && v.date) || Time.at(0) }

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

  private
  
  def generate_name
    if self.name.blank?
      date = date_received.strftime("%Y%m%d")
      # self.name = LastUsedSampleName.next(date)
    end
  end
end

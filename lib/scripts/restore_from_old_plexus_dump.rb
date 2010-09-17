class GenericLoader
  def initialize(options = {})
    @path = options[:path] || "."
    @id_mapping = {}
  end

  def restore_all
    read_data('__dependencies').each { |entry| restore_table(*entry) }
  end

  def restore_table(model_name, *associations)
    puts "Restoring #{model_name}..."

    assoc = associations.map { |attr, options| keyed_dependency(attr, options) }
    assoc = Hash[*assoc.flatten]
    table_name = model_name.underscore.pluralize
    mapping = (@id_mapping[table_name] ||= {})
    rows = read_data(table_name)

    if self.respond_to?("restore_#{table_name}")
      self.send("restore_#{table_name}", rows, mapping, assoc)
    else
      default_restore_table(model_name.classify, rows, mapping, assoc)
    end

    puts "  done!"
  end

  private
  def default_restore_table(model_name, rows, mapping, associations, &block)
    model = model_name.constantize

    attr_protected  = model.read_inheritable_attribute("attr_protected")
    attr_accessible = model.read_inheritable_attribute("attr_accessible")
    model.write_inheritable_attribute("attr_protected",  nil)
    model.write_inheritable_attribute("attr_accessible", nil)

    count = 0
    model.transaction do
      rows.each do |item|
        attr = mapped_attributes(item, associations)
        attr = block.call(attr) if block
        if attr
          instance = model.new(attr)
          instance.save!(:validate => false)
          mapping[item['id']] = instance.id
        end
        count += 1
        puts "    #{count}/#{rows.length}" if count % 1000 == 0
      end
    end

    model.write_inheritable_attribute("attr_protected",  attr_protected)
    model.write_inheritable_attribute("attr_accessible", attr_accessible)
  end

  def read_data(name)
    filename = "#{@path}/#{name}.json.gz"
    JSON::load(Zlib::GzipReader.open(filename) { |gz| gz.read })
  end

  def keyed_dependency(attr, options)
    key = options["foreign_key"] || "#{attr}_id"
    table = if options["polymorphic"]
              options["foreign_type"] || "#{attr}_type"
            else
              (options["class_name"] || attr).pluralize.underscore
            end
    [key, { :table => table, :polymorphic => options["polymorphic"] }]
  end

  def mapped_attributes(item, assoc)
    attr = {}
    item.each do |key, val|
      if assoc[key]
        table = assoc[key][:table]
        table = item[table].underscore.pluralize if assoc[key][:polymorphic]
        begin
          val = @id_mapping[table][val]
        rescue
          #TODO fix references to the same table
          val = nil
        end
      elsif val.is_a?(String)
        val = val.strip
      end
      attr[key] = val
    end
    attr
  end
end


class Loader < GenericLoader
  def initialize(options = {})
    super
    dependencies = read_data('__dependencies')
    class << self; self end.class_eval do
      dependencies.each do |entry|
        method_name = "restore_#{entry[0].pluralize.underscore}"
        unless method_defined?(method_name)
          define_method(method_name) { |a, b, c| puts '  (ignored)' }
        end
      end
    end
  end

  def restore_users(*args)
    default_restore_table('User', *args) do |attr|
      (attr['login_name'] != 'bootstrap') && attr.merge('abilities' => [])
    end
  end

  def restore_permissions(rows, mapping, associations)
    count = 0
    User.transaction do
      rows.each do |item|
        attr = mapped_attributes(item, associations)
        user = User.find_by_id(attr['user_id'])
        if user
          ability = attr['ability_name'].sub(/update/, 'upload')
          user.send(User.ability_setter(ability), '1')
          user.save!
        end
        count += 1
        puts "    #{count}/#{rows.length}" if count % 1000 == 0
      end
    end
  end

  def restore_activity_logs(rows, mapping, associations)
    count = 0
    User.transaction do
      rows.each do |item|
        attr = mapped_attributes(item, associations)
        user = User.find_by_id(attr['user_id'])
        if user and not attr['timestamp'].blank?
          user.log_activity(Time.parse(attr['timestamp']))
        end
        count += 1
        puts "    #{count}/#{rows.length}" if count % 1000 == 0
      end
    end
  end

  def restore_projects(*args)
    #TODO - restore project managers
    default_restore_table('Project', *args) do |attr|
      attr.select { |key, val| %w{name organization}.include? key }
    end
  end

  def restore_project_memberships(*args)
    default_restore_table('Membership', *args) do |attr|
      attr.merge('role' => 'client')
    end
  end

  def restore_samples(*args)
    #TODO - restore extra information as annotations
    default_restore_table('Sample', *args) do |attr|
      {
        'name'        => attr['nickname'],
        'external_id' => attr['name'],
        'project_id'  => attr['project_id']
      }
    end
  end

  def restore_process_nodes(*args)
    default_restore_table('ProcessNode', *args)
  end

  def restore_domains(rows, mapping, associations)
    count = 0
    @domains = []

    def grab(item, base_key)
      %w{x y z}.map { |axis| item["#{base_key}_#{axis}"] }
    end

    rows.each do |item|
      mapping[item['id']] = @domains.count
      @domains << {
        'domain_origin' => grab(item, 'domain_origin'),
        'domain_size'   => grab(item, 'domain_size'),
        'voxel_size'    => grab(item, 'voxel_size'),
        'voxel_unit'    => item['voxel_unit']
      }
      count += 1
      puts "    #{count}/#{rows.length}" if count % 1000 == 0
    end
  end

  def restore_data_nodes(*args)
    #TODO - add fingerprints
    default_restore_table('DataNode', *args) do |attr|
      attr.reject { |k| %w{process_node_id domain_id}.include? k }.
        merge({ 'producer_id' => attr['process_node_id'] }).
        merge(attr['domain_id'].blank? ? {} : @domains[attr['domain_id']])
    end

    ProcessNode.transaction do
      DataNode.all.each do |v|
        v.producer.update_attribute(:sample, v.sample) if v.producer
      end
    end
  end
end


Loader.new(:path => ARGV[0]).restore_all

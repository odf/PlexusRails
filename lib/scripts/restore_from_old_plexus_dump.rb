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
    specific = "restore_#{model_name.pluralize.underscore}"
    if self.respond_to?(specific)
      self.send(specific, associations)
    else
      default_restore_table(model_name, *associations)
    end
  end

  private
  def default_restore_table(model_name, *associations, &block)
    model = model_name.classify.constantize
    table_name = model_name.underscore.pluralize
    mapping = (@id_mapping[table_name] ||= {})
    assoc = associations.map { |attr, options| keyed_dependency(attr, options) }
    assoc = Hash[*assoc.flatten]

    attr_protected  = model.read_inheritable_attribute("attr_protected")
    attr_accessible = model.read_inheritable_attribute("attr_accessible")
    model.write_inheritable_attribute("attr_protected",  nil)
    model.write_inheritable_attribute("attr_accessible", nil)

    rows = read_data(table_name)
    count = 0
    model.transaction do
      rows.each do |item|
        instance = model.new(mapped_attributes(item, assoc))
        if (not block) or block.call(instance)
          instance.save!
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
          define_method(method_name) { |args| puts "  (ignored)" }
        end
      end
    end
  end

  def restore_users(associations)
    default_restore_table('User', *associations) do |user|
      user.abilities = []
      user.login_name != "bootstrap"
    end
    puts "  done!"
  end
end


Loader.new(:path => ARGV[0]).restore_all

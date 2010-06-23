Before do
  Mongoid.master.collections.each do |collection|
    collection.drop unless collection.name == 'system.indexes'
  end
end

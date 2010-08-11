class StrongUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.new_record? || key_changed?(record)
      if record.embedded?
        assoc = record.associations.values.find do |v|
          v.association == Mongoid::Associations::EmbeddedIn
        end
        if assoc and (parent = record.send(assoc.name))
          children = parent.send(assoc.inverse_of) - [record]
          if children.any? { |child| child.send(attribute) =~ /\A#{value}\Z/i }
            record.errors[attribute] << 'already taken'
          end
        end
      else
        if record.class.where(attribute => /\A#{value}\Z/i).any?
          record.errors[attribute] << 'already taken'
        end
      end    
    end
  end

  private

  def key_changed?(record)
    (record.primary_key || []).any? { |key| record.send("#{key}_changed?") }
  end
end

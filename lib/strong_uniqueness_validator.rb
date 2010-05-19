class StrongUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    if (record.class.where(attr.to_sym => /\A#{value}\Z/i) - [record]).any?
       record.errors[attr] << 'already taken'
     end
  end
end

class StrongUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.new_record? || key_changed?(record)
      if record.class.where(attribute => /\A#{value}\Z/i).any?
        record.errors[attribute] << 'already taken'
      end
    end
  end

  private

  def key_changed?(record)
    (record.primary_key || []).any? { |key| record.send("#{key}_changed?") }
  end
end

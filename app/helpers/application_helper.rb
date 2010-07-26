module ApplicationHelper
  include Formular::Helper

  def format_text(text)
    sanitize(RedCloth.new(text).to_html)
  end

  def format_date(time)
    time && time.strftime('%d %B %Y')
  end

  def format_time(time, options = {})
    mode = options[:mode] || :human_short
    zone = options[:zone] || false
    utc = options.has_key?(:utc) ? options[:utc] : mode == :mango
    if time
      fmt = case mode.to_sym
            when :human       then '%d %B %Y %H:%M:%S'
            when :human_short then '%d-%b-%Y %H:%M:%S'
            when :sortable    then '%Y/%m/%d %H:%M:%S'
            when :terse       then time < 22.hours.ago ? '%Y/%m/%d' : '%H:%M '
            when :mango       then '%Y%m%d_%H%M%S'
            end
      (utc ? time.utc : time).strftime(fmt) + (zone ? ' ' + time.zone : '')
    end
  end

  def dash
    '&mdash;'.html_safe
  end

  def timestamps(object)
    stamp = lambda do |type, time, user|
      if time
        author = "by <em>#{h user.name}</em>, " unless user.blank?
        "#{type} #{author}#{format_time(time)}"
      end
    end

    txt = [
           stamp.call('Created', object.created_at, object.created_by),
           stamp.call('Updated', object.updated_at, object.updated_by),
          ].compact.join("<br />")

    "<p class=\"note\">#{txt}</p>".html_safe unless txt.blank?
  end
end

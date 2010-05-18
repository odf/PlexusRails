module ApplicationHelper
  # Helper method for creating forms using our own custom form builder
  def make_form_for(name, *args, &block)
    # -- modify the arguments so that our form builder is specified
    options = args.last.is_a?(Hash) ? args.pop : {}
    args = (args << options.merge(:builder => NiftyFormBuilder))

    # -- now call the standard form_for helper
    form_for(name, *args, &block)
  end
end

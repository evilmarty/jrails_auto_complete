module Jrails
  module ActionController
    def auto_complete_for(object_name, method_name)
      self.send(:define_method, "auto_complete_for_#{object_name}_#{method_name}") do
        return render(:text => '') if params[object_name.to_sym].nil? || params[object_name.to_sym][method_name.to_sym].nil?
        
        value = params[object_name.to_sym][method_name.to_sym].gsub('%', '%%') + '%'
        
        @results = object_name.to_s.camelize.constantize.find :all
        render :text => @results.inject({}) {|attributes, result| attributes[result.send(method_name)] = result.send(method_name); attributes}.to_json
      end
    end
  end
end

module ActionView
  module Helpers
    module JavaScriptHelper
      def auto_complete_for(object_name, method_name, options = {})
        InstanceTag.new(object_name, method_name, self, options.delete(:object)).to_auto_complete(options)
      end
    end
    
    module FormHelper
      def text_field_with_auto_complete(object_name, method_name, options = {}, auto_complete_options = {})
        text_field(object_name, method_name, options) + auto_complete_for(object_name, method_name, auto_complete_options)
      end
      
      def auto_complete_for(object_name, method_name, options = {})
        InstanceTag.new(object_name, method_name, self, nil, options.delete(:object)).to_auto_complete(options)
      end
    end
    
    class InstanceTag
      def to_auto_complete(options = {})
        send(:add_default_name_and_id, options)
        url = options.delete(:url) || @template_object.send(:url_for, :action => "auto_complete_for_#{options['id']}")
        
        @template_object.send(:update_page_tag) do |page|
          page["#{options['id']}"].suggest url, (options[:options] || {})
        end
      end
      
      def to_text_field_with_auto_complete(options = {}, text_field_options = {})
        to_input_field_tag('text', text_field_options) + to_auto_complete(options)
      end
    end
    
    class FormBuilder
      def text_field_with_auto_complete(method, options = {}, auto_complete_options = {})
        text_field(method, options) + auto_complete_for(method, auto_complete_options)
      end
      
      def auto_complete_for(method, options = {})
        @template.auto_complete_for(@object_name, method, options)
      end
    end
  end
end
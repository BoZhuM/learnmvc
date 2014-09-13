module Srbmvc
  module Helpers
    def self.included(base)
        base.class_eval do
            #do something
        end
        base.send :include, InstanceMethods
    end
    module InstanceMethods
      #测试全局方法
      def test_for_helper_method
          "I can run, because I was defined in Srbmvc::Helpers module."
      end

      #这一部分方法用于实现content_for, yield_content
      #详情参见: https://github.com/winton/stasis/issues/62
      def content_for key, value=nil, &block
          saved_content[key].push value || block if value || block_given?
      end

      def yield_content key, *args
        saved_content[key].collect do |content|
          if content.respond_to? :call
            content.binding.eval '_erbout = ""'
            content.call *args
          else
            content
          end
        end.join
      end

      def content? key
        !saved_content[key].empty?
      end

      private

      def saved_content
        @saved_content ||= Hash.new {|h, k| h[k] = []}
      end
         
    end
  end
end
#   GET              content_length  get?               options?         post?           script_name=     user_agent
#   POST             content_type    head?              params           put?            session          values_at 
#   []               cookies         host               parseable_data?  query_string    session_options  xhr?      
#   []=              delete?         host_with_port     patch?           referer         ssl?           
#   accept_encoding  delete_param    ip                 path             referrer        trace?         
#   base_url         env             logger             path_info        request_method  trusted_proxy? 
#   body             form_data?      media_type         path_info=       scheme          update_param   
#   content_charset  fullpath        media_type_params  port             script_name     url
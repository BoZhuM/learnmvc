require 'tilt'

module Srbmvc
  class Controller
    include Srbmvc::Helpers
    def initialize(env)
      @env = env
    end

    def env
      @env
    end

    def self.action(act, prs)
      proc { |e| self.new(e).dispatch(act, prs) }
    end

    def dispatch(act, routing_params={})
      @routing_params = routing_params
      if request.get?
        text = self.render_body(act.intern, method(act.intern).call)
        return [200, {'Content-Type' => 'text/html'}, [text].flatten]
      else
        method(act.intern).call
      end
    end
    #简单的redirect_to方法, 比如说post请求之后, 一般会需要redirect到show.
    #如果不在代码运行时调用redirect_to, 就会render page, render layout.
    def redirect_to url
      case url
      when String
        if Srbmvc.app_obj.route_patterns.check_url url
          url
        else
          raise 'no string route match'
        end
      when ActiveRecord::Base
        url = "/#{url.class.name.downcase.pluralize}/#{url.id}"
      else
        raise 'no object route match'
      end    
      response('', 302, {}).redirect url
      @response.finish
    end

    protected
    #使用Rack::Request封装request
    def request
      @request ||= Rack::Request.new(@env)
    end

    def params
      request.params.merge @routing_params
    end

    def get_response
      @response
    end

    def response(text, status=200, head={})
      raise "respond" if @respond
      text = [text].flatten
      @response = Rack::Response.new(text, status, head)
    end

    def render_response(*arg)
      render_body(*args)
    end

    def render_layout
      layout = File.join "app", "views","layouts", "application.html.erb"
      Tilt.new(layout)
    end

    # def redirect(uri, *args)
    #   if env['HTTP_VERSION'] == 'HTTP/1.1' and env["REQUEST_METHOD"] != 'GET'
    #     status 303
    #   else
    #     status 302
    #   end

    #   # According to RFC 2616 section 14.30, "the field value consists of a
    #   # single absolute URI"
    #   response['Location'] = uri(uri.to_s, settings.absolute_redirects?, settings.prefixed_redirects?)
    #   halt(*args)
    # end

    def render_body(view_name, locals={})
      filename = File.join "app", "views", controller_name, "#{view_name}.html.erb"
      if File.exist? filename
        renderfile = Tilt.new(filename)
        body_content = renderfile.render(self)
        render_layout.render self do body_content end
      end
    end
    #在具体的页面中可以调用render, 只是简单的模拟
    def render(*arg)
      view_name = arg.shift.to_s
      filename = File.join "app", "views", controller_name, "#{view_name}.html.erb"
      renderfile = Tilt.new(filename)
      renderfile.render self, *arg
    end

    def controller_name
      klass = self.class
      klass = klass.to_s.gsub /Controller$/, ""
      Srbmvc.to_underscore klass
    end
  end
end

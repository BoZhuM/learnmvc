require 'rack'
require 'yaml'
module Srbmvc
  #设置项目根目录, 主要用于static assets请求.
  def self.root(r=nil)
    r ? @root = r : @root
  end

  def self.app_obj(o=nil)
    o ? @app_obj = o : @app_obj
  end

  #路由对象, 项目调用 routes 方法时自动生成一个新的 RouteObject实例, 在其中添加规则.
  class RouteObject
    def initialize
      @rules = {
        :get => [],
        :post => [],
        :put => [],
        :delete => []
      }
      #用于resources方法, 生成RESTful式的路由.
      @default_map = {
        :index   => [:get,   "" ],
        :show    => [:get,   "/:id"],
        :edit    => [:get,   "/:id/edit"],
        :new     => [:get,   "/:id/new"],
        :update  => [:put,   "/:id"],
        :create  => [:post,  "/:id"],
        :destroy => [:delete,"/:id"]
      }
    end
    #设置根目录
    def root arg
      match('/' => arg)
    end

    #配置路由的基础方法
    #match '/products/:id' => "products#index"
    #match '/products' => 'products#index'
    #以上两次调用生成如下模式的规则:
    # {:get => [
    #     {
    #       :regexp=>/^\/products\/([a-zA-Z0-9_]+)$/, 
    #       :vals=>["id"], 
    #       :params=>{
    #         :controller=>"products", 
    #         :action=>"create"}
    #     },
    #     {
    #       :regexp=>/^\/products$/, 
    #       :vals=>[], 
    #       :params=>{
    #         :controller=>"products", 
    #         :action=>"index"
    #       }
    #     }
    #   ]
    # }
    # 路由按其request method来分类. 以上只有:get的未例, 其他尚有 :post, :put, :delete等. 越往后的规则优先级越高.
    def match(arg, mtd=:get)
      #match '/welcome/hello' 这种模式不是hash, 未指定指向的ctrl#action, 这种情况会指向 "welcome#hello" 
      #match '/welcome' 指向"welcome#index"
      if String === arg
        arg_box = arg.chomp.split('/').compact.keep_if{|t| t != ''}
        ctrl = arg_box.shift
        act = arg_box.shift
        act = act ? act : "index"
        arg = {"/#{ctrl}/#{act}" => "#{ctrl}##{act}"}
      end
      return unless (Hash === arg)
      arg = arg.to_a
      pattern, dest = arg.shift
      raise 'illegal route' unless pattern =~ /([a-zA-z]+[a-zA-z0-9_\/]*|\/)$/
      ctrl, act = dest.split("#")
      additional_params = arg.length >= 1 ? Hash[arg] : {}
      reg = pattern.gsub(/\/\//, '/').split('/').compact.keep_if{|t| t != ''}
      vals, reg_box = [], []

      reg.each do |t|
        if t[0] == ':'
          vals << t[1..-1]
          reg_box << "([a-zA-Z0-9_]+)"
        elsif t =~ /\*{1}/
          reg_box << "(.*?)"  
        else
          reg_box << t
        end
      end

      reg_exp = Regexp.new("^/#{reg_box.join("/")}$")
      @rules[mtd].unshift({
        regexp: reg_exp,
        vals:   vals,
        params: {
          controller: ctrl,
          action: act
        }.merge(additional_params)
      })
    end

    #以指定响应方法的方式设置路由
    def get(arg);    match(arg, :get);   end
    def post(arg);   match(arg, :post);  end
    def put(arg);    match(arg, :put);   end
    def delete(arg); match(arg, :delete);end

    #这里模拟rails resources方法, 生成restfull routes.
    def resources(arg, opts={})
      mps = opts[:only] ? @default_map.select{|k, v| options[:only].include? k } : @default_map
      mps.each do |k, v|
        act = arg.to_s.downcase
        send v[0], (arg.to_s+v[1]) => "#{arg.to_s}##{k.to_s}"
      end
    end
    #检查由客户端request生成的env['PATH_INFO']路径, 查看是否匹配路由规则
    #若无匹配, 返回nil.
    def check_url(url, mtd=:get)
      @rules[mtd.intern].each do |t|
        m  = t[:regexp].match(url)
        if m
          p t
          t[:vals].each_with_index do |v, i|
            t[:params][v.intern] = m.captures[i]
          end
          return get_dest(t[:params])
        end
      end
      nil
    end

    #返回最终可调用的proc或报错
    def get_dest(prs)
      ctrl_name  = "#{prs[:controller].capitalize}Controller"
      act_name   = prs[:action]
      controller_const = Object.const_get(ctrl_name)
      #如果controller中没有定义相应的action, 报错.
      if controller_const.instance_methods(false).include? act_name.intern
        controller_const.action(act_name, prs)
      else
        raise "No Action #{act_name} defined in #{ctrl_name}"
      end
    end
  end


  class Application
    #此方法用于打开对象, 为之添加路由规则.
    def routes(&blk)
      @route_patterns = RouteObject.new()
      @route_patterns.instance_eval(&blk)
    end

    #返回路由规则表
    def route_patterns
      @route_patterns
    end

    #返回rack自动生成的环境变量对象.
    def env
      @env
    end

    #检查路由表, 根据请示调用controller#action生成返回的rack_app, 
    #每一个controller#action的返回值都是一个响应call方法的proc
    def get_rack_app(env)
      path_info = env['PATH_INFO'].split('/').join('/')
      @route_patterns.check_url((path_info == '' ? '/' : path_info), env['REQUEST_METHOD'].downcase.intern)
    end
  end
end

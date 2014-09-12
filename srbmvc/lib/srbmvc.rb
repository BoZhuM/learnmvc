require "srbmvc/version"
require "srbmvc/utils"
require "srbmvc/routing"
require "srbmvc/helpers"
require "srbmvc/controller"
require "active_record"
require 'active_support/inflector'
#项目通过在config.ru文件中Myapp < Srbmvc::Application的方式继承.
#run Myapp.new来运行rack server
#Myapp.new.routes &block生成一个路由表.
#接受http请求后判断是否staticfile, 判断是符合路由规则.
#如符合, 找到相应的controller与action, 调用, 并render view.
module Srbmvc
  class Application
    def call(env)
        rack_app = get_rack_app(env)
        #通过get_rack_app方法来返回一个callable proc
        if rack_app
          rack_app.call(env)
        #如果以/public开头, 则默认为表态文件, 使用Rack::Directory直接返回表态内容.
        elsif env['PATH_INFO'] =~ /^\/public.+/i
          Rack::Directory.new(Srbmvc.root).call(env)
        else
          [404, {},['not found']]
        end
    end

    def initialize
      #设置或获取项目根目录的绝对地址
      Srbmvc.root File.dirname(caller[0].split(":")[0])
      #获取数据库连接配置, 建立连接
      databse_config = File.join(Srbmvc.root, "config", "database.yml")
      if File.exist? databse_config
        ActiveRecord::Base.establish_connection YAML::load(File.open(databse_config))
      end
      Srbmvc.app_obj self
    end

  end
end

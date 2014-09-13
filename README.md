## 目标
这个项目的目的不是重写一个`Ruby web framework`, 而是在自己开发一个`Rails-like framework`时, 试着去理解一个`ruby mvc style web framework`的一些基本原理. 

## 为什么需要
`Rails`的源码就是头恐怖的怪兽, 无数的童鞋倒前仆后继地打开源码, 而后倒下. 

`Rails`看起来就像魔法, 运行`rails s`, 而后一切就开始运行了. 这些行为都是从哪里开始的? 客户端的请求到达后它如何接收?如何处理? 为什么在controller里可以调用 Model 里定义的模型? 为什么controller里的实例变量可以在view中运用? Rails是如何将erb文件渲染而后生成内容的? 它如何与layout协作并返回?如此种种.

对于新手来说, 这个就是魔法, 虽然很疑惑, 却是没有时间也没有能力去寻找这些答案. 同时, 新手也不需要去理解这些因为哪怕不理解, 只要懂得 rails 的规则, 把相应的东西写在相应的地方(MVC), rails 就会将它们组合在一起, 生成内容并打包发送.事实上, 很多人即使不了解这些, 只要对rails足够了解, 经验充足, 也可以写出很好的项目来.

但是这样是不够的, 只有更多地理解 rails 的内部原理, 才能更好地使用它, 写出灵活高效的代码. 

## 已经实现的功能
+ 以rails MVC的方式组织代码, 以rails的规则命名controller, view, model等之后, 相互之间可以协作.
+ 自定义route, 使用`match`, `resources`, `get`, `post`, `put`, `delete`等方法自定义路由. 如 `match '/products/:id' => 'products#show'`.
+ 自定义database.yml, 使用`activerecord`作为`ROM`
+ 实现layout yield, content_for, yield, render, redirect_to等等
+ 实现静态文件serve.

*注: 已实现的只是rails的九牛一毛. 展示的只是基本的调用链. 及MVC基本的结合方式. 许多功能诸如session, cache, secure, test, configable等都没有实现.*

## 基本逻辑
1. 一切从Rack开始. 几乎所有的ruby web framework都是rack app. Rack对象响应call方法, 返回三元素的array, 分别是status code, header, content body. 只要你的项目符合以上三个要求, 就是一个合法的rack app. 可以运行它, 在浏览器访问, 看到完整的响应内容. 所以, 主流程即是request与response的过程. 我们所做的事情就是在中间加入一些自己的东西.
+ http request 到达 web server 后会即被rack封装, 而后你得到一个env对象. 它包含了客户的请求类型(get/post/put/delete/..), 请求的地址(env['PATH_INFO'], QUERY_STRING等等.
    1. 通过分析env, 我们知道客户的请求是指向哪个controller#action. 而后查看路由表我们的app能否响应此请求.
    + 路由表在新建app对象时通过routes方法来定义, 具体的做法是接受一个block, block内调用`match`, `get`, `post`等方法时, 生成路由规则加入路由表. 路由表里包含路径字符串的匹配正则, controller, action, params等等.
    + 参照上一条, 在路由规则中检查 `env['PATH\_INFO']`, 若匹配, 就知道了指向哪个controller的哪个action, 以及其params. 通过 `ctrl_const = Object.const_get(params[:controller].capitalize)`来得到相应的controller.
    + 通过 ctrl_const.new(env).call(params[:action]) 可以调用到相应的方法.
    + 到这一步, 已经初步描述了一个请求从客户端到服务器端并指向需要的`controller#action`的基本过程. 也即处理request的过程完成.
+ Response的过程:
    1. 在ctrl_const.new上调用action后新的对象内就会拥有相应的实例变量. 这时通过`Tilt`gem, 按规则生成目标view的名字, 找到它, 而后render, render时将self作为scope传入. 至此view里可以调用action里所有的实例变量.`Tilt.new(view).render self` 得到了应该返回的html的内容.
    + 上一步render得到的只是Controller#action对应的view, 需要将它交给layout处理.同样的使用`Tilt`, 将上一步得到的partial view 放到block中提交过去. 这样layout中的`<%= yield %>`关键字生效. 至此, 得到完整的html内容.
    + Rack要求调用call后的返回的值是一个三值的array, 分别是[status code, head content, body].上一步得到的是html内容就是body部分.

## 如何使用和阅读本项目的源码

```
git clone https://github.com/suffering/learnmvc.git
cd learnmvc
#在编辑器中打开
cd srbmvc
bundle install
cd ../simpleapp
bundle install
rackup -p 3002
#通过rackup方式打开后, 代码在更改后不会自动重载, 可以考虑使用rerun
# gem install rerun
# reun 'rackup -p 3002'
#以这种方式运行, 对任何文件的修改都会重载代码. 简单模拟rails的development mode.
```
Demo app运行后, 可以看到项目正常运行. 

查看`simpleapp`的源码, 你会看到它的基本结构与rails app基本相同. 

查阅`srbmvc`的源码, 按前文的基本逻辑栏来查看代码, 观看其调用链. 代码中有少量的注释,没有解释具体的细节, 只简单标注出此方法实现的目的与功能. 此部分代码的关键点在于从request开始后的调用链, route规则的指定与检查, controller#action的定位 以及render view 部分. 其他皆渣.

请将`simpleapp`与`srbmvc`结合来阅读.


## 一切从Rack开始
Rails就是一个 Rack app. 实际上, 基本上所有的ruby web framework都是`rack app`.
> Rack provides a minimal, modular and adaptable interface for developing web applications in Ruby. By wrapping HTTP requests and responses in the simplest way possible, it unifies and distills the API for web servers, web frameworks, and software in between (the so-called middleware) into a single method call.

简单点说, rack 是ruby web应用的简单的模块化的接口. 它封装 HTTP 请求与响应, 并提供大量的实用工具.

### 一个`rack app`可以简单到什么地步?
```ruby
#app.rb
require 'rack'

class HelloWorld
  def call(env)
    [200, {"Content-Type" => "text/html"}, "Hello Rack!"]
  end
end

Rack::Handler::Mongrel.run HelloWorld.new, :Port => 9292
```
直接在terminal里运行`ruby app.rb`, 而后在浏览器里打开`http://localhost:9292`就可以看到返回的内容了.

### 一个使用middleware的rack app可以简单到什么地步?
```ruby
#config.ru
class ToUpper
  def initialize(app)
    @app = app
  end
  def call(env)
    status, head, body = @app.call(env)
    upcased_body = body.map{|chunk| chunk.upcase }
    [status, head, upcased_body]
  end
end

class WrapWithRedP
  def initialize(app)
    @app = app
  end
  def call(env)
    status, head, body = @app.call(env)
    red_body = body.map{|chunk| "<p style='color:red;'>#{chunk}</p>" }
    head['Content-type'] = 'text/html'
    [status, head, red_body]
  end
end

class WrapWithHtml
  def initialize(app)
    @app = app
  end

  def call(env)
    status, head, body = @app.call(env)
    wrap_html = <<-EOF
       <!DOCTYPE html>
       <html>
         <head>
         <title>hello</title>
         <body>
         #{body[0]}
         </body>
       </html>
    EOF
    [status, head, [wrap_html]]
  end
end

class Hello
  def initialize
    super
  end
  def call(env)
    [200, {'Content-Type' => 'text/plain'}, ["hello, this is a test."]]
  end
end
use WrapWithHtml
use WrapWithRedP
use ToUpper
run Hello.new
```
直接运行`rackup`就可以运行上述app.

use 与 run 本质上没有太大的差别, 只是run是最先调用的. 它们生成一个statck, 本质上是先调用Hello.new#call, 而后返回ternary-array, 而后再将之交给另一个ToUpper, ToUpper干完自己的活, 再交给WrapWithRedP, 如此一直到stack调用完成.
`use ToUpper; run Hello.new`本质上是完成如下调用:
```ruby
ToUpper.new(Hello.new.call(env)).call(env)
```

想更深入了解Rack, 可以参见:

http://rack.github.io/

http://m.onkey.org/ruby-on-rack-1-hello-rack

http://guides.rubyonrails.org/rails_on_rack.html

## 开始-新建一个gem, 新建app并引用它
我们需要自己写一个gem, 在你的项目中加入它, 就可以按rails的基本规则在不同的地方放入不同的代码, 然后它们一起工作, 返回你需要的内容.

运行命令`bundle gem srbmvc`. 得到新的gem

...

\#剩余内容努力书写中...
## 将request导向controller#action

## 指定route规则, 检查规则

## 找到并render view

## 加入layout

## 实现 yield :heade, yield :sidebar式的方法.

## issues

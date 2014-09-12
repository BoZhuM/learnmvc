class ProductsController < Srbmvc::Controller
    def index
        @name = 'suffering'
        @note = 'hello'
        @products = Product.limit(10)
    end

    def show
        @message = "this is the message from the products#show."
    end

    def create
        puts "hello, this is post"
        @product = Product.find params[:id]
        redirect_to @product
        # redirect_to '/products'
    end
end
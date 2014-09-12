class FriendsController < Srbmvc::Controller
    def index
        @name = 'suffering'
        @note = 'hello'
    end

    def show
        @message = "this is the message from the products#show."
    end
end
class ApplicationController < ActionController::Base
  def hello_world
    respond_to do |format|
      format.html { render body: '<body><h1>Hello World</h1></body>', status: 200 }
    end
  end
end

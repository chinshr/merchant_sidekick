# MerchantSidekick

MerchantSidekick is a light-weight E-commerce framework for Ruby on Rails applications.

## Features

MerchantSidekick includes in- and outbound order management and invoicing, 
a shopping cart, taxation and payment processing. It integrates with 
[ActiveMerchant](http://activemerchant.org) for payment processing by default.
The plugin can be extended to use other payment gateways outside the scope
of ActiveMerchant.

## Quickstart

    gem install merchant_sidekick

    rails new my_app

    cd my_app

    gem "merchant_sidekick"

    rails generate merchant_sidekick

    rake db:migrate

    # edit config/initializers/merchant_sidekick.rb
    MerchantSidekick::default_gateway = :bogus_gateway
    
    # edit app/models/user.rb
    class User < ActiveRecord::Base
      acts_as_buyer
    end

    # edit app/models/product.rb
    class Product < ActiveRecord::Base
      acts_as_sellable
    end

    rails generate controller orders

    # edit app/controllers/orders_controller.rb
    class OrdersController < ApplicationController
      # before_filter ...
      
      def create
        @credit_card = ActiveMerchant::Billing::CreditCard.new(params[:credit_card] || {})
        if @credit_card.valid?
          @order = @user.purchase(@cart)
          @payment = @order.pay(@credit_card)
          redirect_to [@order] and return if @payment.valid?
        end
        render :template => "new"
      end
      
      # ...
    
    end
    

## License

Copyright (c) 2008-2011 Juergen Fesslmeier, released under the MIT license.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
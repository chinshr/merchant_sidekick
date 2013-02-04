# MerchantSidekick Changelog

## 0.4.2 (NOT RELEASED YET)

* Renamed state transition exit callbacks for order and invoice
* Loosened active_record gem dependency to work with Rails 3.2.x
* Version bump
* @klebervirgilio merging pull request to fix specs and refactor
  BuyingUser and SellingUser test classes to Buyer and Seller

## 0.4.1 (NOT RELEASED YET)

* Fix overridden `build_#{relation}` method signature
* Fix deprecations on class\_inheritable\_writer
* Fix deprecations when using Money class with ActiveMerchant
* Fix authorize\_net\_gateway and paypal_gateway merchant gateways
* Refactored out active_merchant specific gateways into separate module
* Removed option to load gateway configuration from database
* Added gateway spec
* Allow for MerchantSidekick::Gateway.default_gateway to use type name
* Refactored default_gateway for active merchant gateway types into base class
* Added bogus gateway configuration wrapper
* Cart instances can now be added directly to purchase
* Cart instances can now be sold
* Change @customer.purchase syntax to accept :from => @merchant
* Change @merchant.sell syntax to accept :to => @customer
* Ignoring blank sellables from purchase and sell

## 0.4.0 (2011-12-27)

* Compatibility with ActiveRecord 3.1
* Refactored code into modules

## 0.0.2 (2009-04-28)

* Fixed invoice void, capture and purchase.

## 0.0.1 (2008-08-06)

* Initial release.
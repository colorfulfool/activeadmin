require 'rails_helper'
require 'active_admin/view_helpers/display_helper'

RSpec.describe "#pretty_format" do
  include ActiveAdmin::ViewHelpers::DisplayHelper

  def method_missing(*args, &block)
    mock_action_view.send *args, &block
  end

  klass_obj_map = [
    [:String, 'hello'],
    [:Float, 5.67],
    [:Symbol, :foo],
    ['Arbre::Element', Arbre::Element.new.br(:foo)]
  ]

  klass_obj_map += if RUBY_VERSION >= '2.4.0'
                     [[:Integer, 23], [:Integer, 10**30]]
                   else
                     [[:Fixnum, 23], [:Bignum, 10**30]]
                   end

  klass_obj_map.each do |klass, obj|
    it "should call `to_s` on #{klass}s" do
      expect(obj).to be_a klass.to_s.constantize # safeguard for Bignum
      expect(pretty_format(obj)).to eq obj.to_s
    end
  end

  context "given a Date or a Time" do
    it "should return a localized Date or Time with long format" do
      t = Time.now
      expect(self).to receive(:localize).with(t, {format: :long}) { "Just Now!" }
      expect(pretty_format(t)).to eq "Just Now!"
    end

    context "actually do the formatting" do
      it "should actually do the formatting" do
        t = Time.utc(1985,"feb",28,20,15,1)
        expect(pretty_format(t)).to eq "February 28, 1985 20:15"
      end

      context "apply custom localize format" do
        around do |example|
          previous_localize_format = ActiveAdmin.application.localize_format
          ActiveAdmin.application.localize_format = :short
          example.call
          ActiveAdmin.application.localize_format = previous_localize_format
        end
        it "should actually do the formatting" do
          t = Time.utc(1985, "feb", 28, 20, 15, 1)

          expect(pretty_format(t)).to eq "28 Feb 20:15"
        end
      end

      context "with non-English locale" do
        before do
          @previous_locale = I18n.locale.to_s
          I18n.locale = "es"
        end
        after do
          I18n.locale = @previous_locale
        end
        it "should return a localized Date or Time with long format for non-english locale" do
          t = Time.utc(1985,"feb",28,20,15,1)
          expect(pretty_format(t)).to eq "28 de febrero de 1985 20:15"
        end
      end
    end
  end

  context "given an ActiveRecord object" do
    it "should delegate to auto_link" do
      post = Post.new
      expect(self).to receive(:auto_link).with(post) { "model name" }
      expect(pretty_format(post)).to eq "model name"
    end
  end

  context "given an arbitrary object" do
    it "should delegate to `display_name`" do
      something = Class.new.new
      expect(self).to receive(:display_name).with(something) { "I'm not famous" }
      expect(pretty_format(something)).to eq "I'm not famous"
    end
  end
end
